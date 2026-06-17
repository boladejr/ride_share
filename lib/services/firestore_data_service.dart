import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';
import '../models/route_model.dart';
import '../models/driver_model.dart';
import '../models/booking_model.dart';
import 'mock_data_service.dart';

/// Thrown by [FirestoreDataService.createBooking] when one or more of the
/// requested seats were taken by another rider before the booking completed.
class SeatUnavailableException implements Exception {
  final List<int> seats;
  SeatUnavailableException(this.seats);
  @override
  String toString() => 'Seats already taken: ${seats.join(', ')}';
}

/// Seat inventory is the only thing persisted/shared via Firestore (collection
/// `route_seats`). Routes, drivers, and driver assignment stay in the in-memory
/// [MockDataService]. This keeps seat reservation atomic across all riders —
/// preventing double-booking — without migrating the whole catalog.
class FirestoreDataService {
  static final FirestoreDataService _instance = FirestoreDataService._internal();
  factory FirestoreDataService() => _instance;
  FirestoreDataService._internal();

  final MockDataService _mockService = MockDataService();
  FirebaseFirestore? _firestore;

  bool get _useFirestore => FirebaseConfig.isConfigured;

  void _init() {
    _firestore ??= FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> get _seats =>
      _firestore!.collection('route_seats');

  /// Shared driver pool. Each doc id is the driver's id (uid for registered
  /// drivers, or the seeded mock id). This is read at booking time so a rider
  /// on one device can be matched to a driver who registered on another.
  CollectionReference<Map<String, dynamic>> get _activeDrivers =>
      _firestore!.collection('active_drivers');

  bool _poolSeeded = false;

  Set<int> _seatsFrom(Map<String, dynamic>? data) =>
      (data?['takenSeats'] as List?)?.map((e) => (e as num).toInt()).toSet() ??
      {};

  /// Seeds the base (mock) drivers into the shared Firestore pool once, so
  /// auto-assignment works across devices even before anyone registers.
  /// Idempotent and best-effort.
  Future<void> _ensurePoolSeeded() async {
    if (_poolSeeded || !_useFirestore) return;
    _init();
    try {
      final existing = await _activeDrivers.limit(1).get();
      if (existing.docs.isEmpty) {
        final batch = _firestore!.batch();
        for (final d in _mockService.drivers) {
          final city = _mockService.driverCurrentCity(d);
          final busyUntil = _mockService.driverBusyUntil(d);
          batch.set(_activeDrivers.doc(d.id), {
            'name': d.name,
            'currentCity': city,
            'busyUntil':
                busyUntil != null ? Timestamp.fromDate(busyUntil) : null,
            'assignedCount': d.assignedRouteIds.length,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
      _poolSeeded = true;
    } catch (_) {
      // Best-effort; assignment falls back to the pending queue if the pool
      // can't be read/seeded.
    }
  }

  /// Picks the best available driver from the shared pool for [origin] departing
  /// at [departure]: a driver who is free (not busy past the departure) and
  /// either headed from [origin] or brand-new (no current city). Load-balanced
  /// by fewest assignments. Returns the chosen doc id + name, or null.
  Future<({String id, String name})?> _pickDriverFromPool(
      String origin, DateTime departure) async {
    try {
      final snap = await _activeDrivers.get();
      final eligible = snap.docs.where((doc) {
        final data = doc.data();
        final city = data['currentCity'] as String?;
        final busyUntil = (data['busyUntil'] as Timestamp?)?.toDate();
        final cityOk =
            city == null || city.toLowerCase() == origin.toLowerCase();
        final freeOk = busyUntil == null || !departure.isBefore(busyUntil);
        return cityOk && freeOk;
      }).toList()
        ..sort((a, b) {
          final byLoad = ((a.data()['assignedCount'] as num?) ?? 0)
              .compareTo((b.data()['assignedCount'] as num?) ?? 0);
          return byLoad != 0 ? byLoad : a.id.compareTo(b.id);
        });
      if (eligible.isEmpty) return null;
      final chosen = eligible.first;
      return (id: chosen.id, name: chosen.data()['name'] as String? ?? 'Driver');
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Routes from the mock catalog, with `availableSeats` adjusted to reflect the
  /// live (shared) seat reservations stored in Firestore.
  Future<List<RouteModel>> searchRoutes(
      String origin, String destination, DateTime date) async {
    final routes = _mockService.searchRoutes(origin, destination, date);
    if (!_useFirestore) return routes;
    _init();

    final snap = await _seats.get();
    final takenByRoute = <String, Set<int>>{
      for (final doc in snap.docs) doc.id: _seatsFrom(doc.data()),
    };

    return routes.map((r) {
      final taken = {..._mockService.getTakenSeats(r.id), ...?takenByRoute[r.id]};
      final available = (r.totalSeats - taken.length).clamp(0, r.totalSeats);
      return r.copyWith(availableSeats: available);
    }).toList();
  }

  /// Live taken seats = demo's pre-taken seats merged with Firestore reservations.
  Future<Set<int>> getTakenSeats(String routeId) async {
    final seed = _mockService.getTakenSeats(routeId);
    if (!_useFirestore) return seed;
    _init();
    final doc = await _seats.doc(routeId).get();
    return {...seed, ..._seatsFrom(doc.data())};
  }

  Future<DriverModel?> getDriverById(String id) async =>
      _mockService.getDriverById(id);

  // ---------------------------------------------------------------------------
  // Transactional booking: atomically re-checks seat availability and marks the
  // requested seats taken in Firestore, so concurrent riders can't grab the same
  // seat. Driver assignment runs through the in-memory mock algorithm.
  // ---------------------------------------------------------------------------
  Future<BookingModel> createBooking({
    required String routeId,
    required List<int> seatNumbers,
    required double totalPrice,
    required String riderId,
    required String riderName,
    String? pickupAddress,
    String? dropoffAddress,
    String? paymentIntentId,
  }) async {
    final route = _mockService.getRouteById(routeId);
    if (route == null) {
      throw Exception('Route not found');
    }

    if (!_useFirestore) {
      // Offline/demo fallback: in-memory load-balanced assignment.
      _mockService.assignDriverForRoute(routeId);
      return _mockService.createBooking(
        routeId: routeId,
        seatNumbers: seatNumbers,
        totalPrice: totalPrice,
      );
    }
    _init();
    await _ensurePoolSeeded();

    final routeEnd = route.departureTime.add(route.duration);
    // Pick a candidate from the shared pool (read outside the transaction),
    // then confirm + claim it atomically inside.
    final candidate =
        await _pickDriverFromPool(route.origin, route.departureTime);

    final seed = _mockService.getTakenSeats(routeId);
    final seatRef = _seats.doc(routeId);
    final driverRef = candidate != null ? _activeDrivers.doc(candidate.id) : null;

    // Reserve seats + claim the driver atomically so concurrent riders can't
    // take the same seat or the same driver for an overlapping trip.
    ({String id, String name})? assigned;
    await _firestore!.runTransaction((tx) async {
      final seatDoc = await tx.get(seatRef);
      final driverDoc =
          driverRef != null ? await tx.get(driverRef) : null;

      final taken = {...seed, ..._seatsFrom(seatDoc.data())};
      final conflicts = seatNumbers.where(taken.contains).toList()..sort();
      if (conflicts.isNotEmpty) {
        throw SeatUnavailableException(conflicts);
      }

      // Re-confirm the candidate is still eligible against fresh state.
      assigned = null;
      if (candidate != null && driverDoc != null && driverDoc.exists) {
        final d = driverDoc.data()!;
        final city = d['currentCity'] as String?;
        final busyUntil = (d['busyUntil'] as Timestamp?)?.toDate();
        final cityOk = city == null ||
            city.toLowerCase() == route.origin.toLowerCase();
        final freeOk =
            busyUntil == null || !route.departureTime.isBefore(busyUntil);
        if (cityOk && freeOk) {
          assigned = candidate;
        }
      }

      final newTaken = ({...taken, ...seatNumbers}.toList())..sort();
      tx.set(seatRef, {
        'routeId': routeId,
        'totalSeats': route.totalSeats,
        'takenSeats': newTaken,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Advance the assigned driver: they're now headed to the destination and
      // busy until the trip ends; bump their load for balancing.
      if (assigned != null && driverRef != null) {
        tx.update(driverRef, {
          'currentCity': route.destination,
          'busyUntil': Timestamp.fromDate(routeEnd),
          'assignedCount': FieldValue.increment(1),
        });
      }
    });

    final driver = assigned;

    final now = DateTime.now();
    final booking = BookingModel(
      id: 'BK-${now.millisecondsSinceEpoch.toString().substring(6)}',
      routeId: routeId,
      riderId: riderId,
      riderName: riderName,
      origin: route.origin,
      destination: route.destination,
      departureTime: route.departureTime,
      seatNumbers: seatNumbers,
      totalPrice: totalPrice,
      pickupPoint: pickupAddress ?? route.pickupPoint,
      dropoffPoint: dropoffAddress,
      tripStatus: TripStatus.notStarted,
      paymentStatus: PaymentStatus.paid,
      bookingDate: now,
      assignedDriverId: driver?.id,
      assignedDriverName: driver?.name,
    );

    // Persist the booking record (best-effort; seat reservation already done).
    try {
      final bookingRef = await _firestore!.collection('bookings').add({
        'bookingId': booking.id,
        'userId': riderId,
        'riderName': riderName,
        'routeId': routeId,
        'origin': route.origin,
        'destination': route.destination,
        'seats': seatNumbers.length,
        'seatNumbers': seatNumbers,
        'totalPrice': totalPrice,
        'pickupAddress': pickupAddress ?? route.pickupPoint,
        'dropoffAddress': dropoffAddress,
        'paymentIntentId': paymentIntentId,
        'departureTime': Timestamp.fromDate(route.departureTime),
        'assignedDriverId': driver?.id,
        'assignedDriverName': driver?.name,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // No driver qualified at booking time → publish to the shared queue so
      // any signed-in driver can claim the ride from the Drive page.
      if (driver == null) {
        await _firestore!.collection('pending_assignments').add({
          'bookingDocId': bookingRef.id,
          'bookingId': booking.id,
          'routeId': routeId,
          'origin': route.origin,
          'destination': route.destination,
          'departureTime': Timestamp.fromDate(route.departureTime),
          'pickupAddress': pickupAddress ?? route.pickupPoint,
          'dropoffAddress': dropoffAddress,
          'seatNumbers': seatNumbers,
          'seats': seatNumbers.length,
          'riderName': riderName,
          'totalPrice': totalPrice,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Booking record save failed; seats are still reserved and the rider
      // sees their confirmation. "My Trips" may not list it until retried.
    }

    return booking;
  }

  // ---------------------------------------------------------------------------
  // Pending driver assignments queue. When a booking gets no driver, it is
  // published here; signed-in drivers list open rides and claim them.
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getPendingAssignments() async {
    if (!_useFirestore) return [];
    _init();
    final snap = await _firestore!
        .collection('pending_assignments')
        .where('status', isEqualTo: 'open')
        .get();
    final results =
        snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    results.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return results;
  }

  /// Claims an open assignment for [driverId]. Atomic: succeeds only if the
  /// assignment is still `open`, then stamps the driver onto the booking too.
  /// Returns false if another driver claimed it first.
  Future<bool> claimAssignment({
    required String assignmentId,
    required String bookingDocId,
    required String driverId,
    required String driverName,
  }) async {
    if (!_useFirestore) return false;
    _init();
    final assignRef =
        _firestore!.collection('pending_assignments').doc(assignmentId);
    final bookingRef = _firestore!.collection('bookings').doc(bookingDocId);
    final driverRef =
        driverId.isNotEmpty ? _activeDrivers.doc(driverId) : null;
    try {
      return await _firestore!.runTransaction<bool>((tx) async {
        final doc = await tx.get(assignRef);
        if (!doc.exists || doc.data()?['status'] != 'open') return false;
        // Read the driver pool doc (if any) before writing.
        final driverDoc = driverRef != null ? await tx.get(driverRef) : null;
        final dest = doc.data()?['destination'] as String?;
        final departure = doc.data()?['departureTime'] as Timestamp?;

        tx.update(assignRef, {
          'status': 'claimed',
          'claimedByDriverId': driverId,
          'claimedByDriverName': driverName,
          'claimedAt': FieldValue.serverTimestamp(),
        });
        tx.update(bookingRef, {
          'assignedDriverId': driverId,
          'assignedDriverName': driverName,
        });
        // Advance the claiming driver's location in the shared pool so their
        // next auto-match chains from this ride's destination.
        if (driverRef != null && driverDoc != null && driverDoc.exists) {
          final driverUpdate = <String, dynamic>{
            'assignedCount': FieldValue.increment(1),
          };
          if (dest != null) driverUpdate['currentCity'] = dest;
          if (departure != null) driverUpdate['busyUntil'] = departure;
          tx.update(driverRef, driverUpdate);
        }
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  /// Advances the lifecycle of a ride the driver is assigned to.
  /// [status] is `'in_progress'` (picked up) or `'completed'`. On completion the
  /// driver is freed in the shared pool (busy-until set to now) so they can be
  /// matched to their next ride immediately.
  Future<bool> updateTripStatus({
    required String bookingDocId,
    required String driverId,
    required String status,
  }) async {
    if (!_useFirestore || bookingDocId.isEmpty) return false;
    _init();
    final bookingRef = _firestore!.collection('bookings').doc(bookingDocId);
    final driverRef =
        driverId.isNotEmpty ? _activeDrivers.doc(driverId) : null;
    try {
      return await _firestore!.runTransaction<bool>((tx) async {
        final bookingDoc = await tx.get(bookingRef);
        if (!bookingDoc.exists) return false;
        // Reads must precede writes: fetch the driver doc up front if needed.
        final driverDoc = (status == 'completed' && driverRef != null)
            ? await tx.get(driverRef)
            : null;

        tx.update(bookingRef, {'status': status});

        if (status == 'completed' &&
            driverRef != null &&
            driverDoc != null &&
            driverDoc.exists) {
          tx.update(driverRef, {
            'busyUntil': Timestamp.fromDate(DateTime.now()),
          });
        }
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  /// After a driver becomes active, auto-claim any already-open pending rides
  /// they're eligible for: the ride's origin matches the driver's current
  /// location (or they're brand-new with no location yet), processed in
  /// departure order so their location chains across successive claims.
  /// Returns how many rides were retroactively assigned.
  Future<int> retroMatchDriver({
    required String driverId,
    required String driverName,
  }) async {
    if (!_useFirestore || driverId.isEmpty) return 0;
    _init();
    int claimed = 0;
    try {
      final driverSnap = await _activeDrivers.doc(driverId).get();
      String? city = driverSnap.data()?['currentCity'] as String?;

      final openSnap = await _firestore!
          .collection('pending_assignments')
          .where('status', isEqualTo: 'open')
          .get();
      final open = openSnap.docs.toList()
        ..sort((a, b) {
          final at = a.data()['departureTime'] as Timestamp?;
          final bt = b.data()['departureTime'] as Timestamp?;
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return at.compareTo(bt);
        });

      for (final doc in open) {
        final data = doc.data();
        final origin = data['origin'] as String?;
        final dest = data['destination'] as String?;
        final bookingDocId = data['bookingDocId'] as String?;
        if (origin == null || bookingDocId == null) continue;

        // Direction-aware: a brand-new driver (no city) can take a first ride
        // from anywhere; afterwards they chain from their last destination.
        final cityOk =
            city == null || city.toLowerCase() == origin.toLowerCase();
        if (!cityOk) continue;

        final ok = await claimAssignment(
          assignmentId: doc.id,
          bookingDocId: bookingDocId,
          driverId: driverId,
          driverName: driverName,
        );
        if (ok) {
          claimed++;
          if (dest != null) city = dest;
        }
      }
    } catch (_) {
      // Best-effort; un-matched rides simply stay in the open queue.
    }
    return claimed;
  }

  Future<void> saveDriverApplication({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String vehicleInfo,
    required String licenseNumber,
  }) async {
    // Add the driver to the active assignment pool right away so they can start
    // getting matched to rides immediately (no approval step).
    _mockService.addActiveDriver(
      id: userId,
      name: name,
      email: email,
      phone: phone,
    );

    if (!_useFirestore) return;
    _init();

    // Register the driver in the shared pool (doc id = their uid) so riders on
    // other devices can be auto-matched to them. A fresh driver has no current
    // city, so they're available to start from any origin.
    if (userId.isNotEmpty) {
      try {
        await _activeDrivers.doc(userId).set({
          'name': name,
          'currentCity': null,
          'busyUntil': null,
          'assignedCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Already registered or write blocked; pool entry is best-effort.
      }
    }

    await _firestore!.collection('driver_applications').add({
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'vehicleInfo': vehicleInfo,
      'licenseNumber': licenseNumber,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Rides that have been assigned to [driverId] (across all devices). Lets a
  /// driver see their auto-assigned and claimed rides on the Drive page.
  Future<List<Map<String, dynamic>>> getAssignedRides(String driverId) async {
    if (!_useFirestore || driverId.isEmpty) return [];
    _init();
    try {
      final snap = await _firestore!
          .collection('bookings')
          .where('assignedDriverId', isEqualTo: driverId)
          .get();
      final results =
          snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      results.sort((a, b) {
        final aTime = a['departureTime'] as Timestamp?;
        final bTime = b['departureTime'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });
      return results;
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Live (real-time) streams. Same data as the Future-based reads above, but
  // emit a new list whenever the underlying Firestore docs change, so the UI
  // updates without a manual refresh.
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _withIds(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

  int _byTimestamp(Map<String, dynamic> a, Map<String, dynamic> b,
      String field, bool descending) {
    final aTime = a[field] as Timestamp?;
    final bTime = b[field] as Timestamp?;
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return descending ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
  }

  /// Live stream of a rider's bookings (newest first), for My Trips.
  Stream<List<Map<String, dynamic>>> userBookingsStream(String userId) {
    if (!_useFirestore || userId.isEmpty) {
      return Stream.value(<Map<String, dynamic>>[]);
    }
    _init();
    return _firestore!
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) =>
            _withIds(s)..sort((a, b) => _byTimestamp(a, b, 'createdAt', true)));
  }

  /// Live stream of rides assigned to a driver (soonest first), for the Drive
  /// page. Updates in real time as rides are auto-assigned or claimed.
  Stream<List<Map<String, dynamic>>> assignedRidesStream(String driverId) {
    if (!_useFirestore || driverId.isEmpty) {
      return Stream.value(<Map<String, dynamic>>[]);
    }
    _init();
    return _firestore!
        .collection('bookings')
        .where('assignedDriverId', isEqualTo: driverId)
        .snapshots()
        .map((s) => _withIds(s)
          ..sort((a, b) => _byTimestamp(a, b, 'departureTime', false)));
  }

  /// Live stream of open (unclaimed) rides in the shared queue (newest first).
  Stream<List<Map<String, dynamic>>> pendingAssignmentsStream() {
    if (!_useFirestore) return Stream.value(<Map<String, dynamic>>[]);
    _init();
    return _firestore!
        .collection('pending_assignments')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((s) =>
            _withIds(s)..sort((a, b) => _byTimestamp(a, b, 'createdAt', true)));
  }

  CollectionReference<Map<String, dynamic>> get _ratings =>
      _firestore!.collection('ratings');

  /// Live stream of the ratings a rider has left, keyed by the rated booking's
  /// doc id, so My Trips can show which completed trips are already rated.
  Stream<Map<String, Map<String, dynamic>>> userRatingsStream(String riderId) {
    if (!_useFirestore || riderId.isEmpty) {
      return Stream.value(<String, Map<String, dynamic>>{});
    }
    _init();
    return _ratings.where('riderId', isEqualTo: riderId).snapshots().map((s) {
      final map = <String, Map<String, dynamic>>{};
      for (final doc in s.docs) {
        final bookingDocId = doc.data()['bookingDocId'] as String?;
        if (bookingDocId != null) map[bookingDocId] = doc.data();
      }
      return map;
    });
  }

  /// Submits (or updates) a rider's rating for a completed trip. The rating doc
  /// id is the booking's doc id, so there's exactly one rating per booking.
  Future<bool> submitRating({
    required String bookingDocId,
    required String riderId,
    required String driverId,
    required String driverName,
    required int rating,
    String? review,
  }) async {
    if (!_useFirestore || bookingDocId.isEmpty || riderId.isEmpty) return false;
    _init();
    try {
      await _ratings.doc(bookingDocId).set({
        'bookingDocId': bookingDocId,
        'riderId': riderId,
        'driverId': driverId,
        'driverName': driverName,
        'rating': rating,
        'review': review ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    if (!_useFirestore) return [];
    _init();

    final snapshot = await _firestore!
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();

    final results =
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    results.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return results;
  }
}
