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

  // ---------------------------------------------------------------------------
  // Seeding: copy the built-in demo routes/drivers into Firestore once, so the
  // catalog is persistent and shared across all users. Idempotent — only runs
  // when the `routes` collection is empty, and uses fixed doc ids.
  // ---------------------------------------------------------------------------
  bool _seeded = false;

  Future<void> ensureSeeded() async {
    if (!_useFirestore || _seeded) return;
    _init();
    final existing = await _firestore!.collection('routes').limit(1).get();
    if (existing.docs.isEmpty) {
      final batch = _firestore!.batch();
      for (final route in _mockService.routes) {
        batch.set(
          _firestore!.collection('routes').doc(route.id),
          _routeToMap(route, _mockService.getTakenSeats(route.id)),
        );
      }
      for (final driver in _mockService.drivers) {
        batch.set(
          _firestore!.collection('drivers').doc(driver.id),
          _driverToMap(driver),
        );
      }
      await batch.commit();
    }
    _seeded = true;
  }

  Map<String, dynamic> _routeToMap(RouteModel r, Set<int> takenSeats) => {
        'origin': r.origin,
        'destination': r.destination,
        'departureTime': Timestamp.fromDate(r.departureTime),
        'durationMinutes': r.duration.inMinutes,
        'totalSeats': r.totalSeats,
        'availableSeats': r.availableSeats,
        'pricePerSeat': r.pricePerSeat,
        'pickupPoint': r.pickupPoint,
        'assignedDriverId': r.assignedDriverId,
        'takenSeats': takenSeats.toList(),
      };

  Map<String, dynamic> _driverToMap(DriverModel d) => {
        'name': d.name,
        'email': d.email,
        'phone': d.phone,
        'assignedRouteIds': d.assignedRouteIds,
        'totalPayout': d.totalPayout,
      };

  RouteModel _routeFromDoc(String id, Map<String, dynamic> data) => RouteModel(
        id: id,
        origin: data['origin'] as String? ?? '',
        destination: data['destination'] as String? ?? '',
        departureTime:
            (data['departureTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        duration: Duration(minutes: (data['durationMinutes'] as num?)?.toInt() ?? 0),
        totalSeats: (data['totalSeats'] as num?)?.toInt() ?? 0,
        availableSeats: (data['availableSeats'] as num?)?.toInt() ?? 0,
        pricePerSeat: (data['pricePerSeat'] as num?)?.toDouble() ?? 0,
        pickupPoint: data['pickupPoint'] as String? ?? '',
        assignedDriverId: data['assignedDriverId'] as String?,
      );

  DriverModel _driverFromDoc(String id, Map<String, dynamic> data) => DriverModel(
        id: id,
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        assignedRouteIds:
            (data['assignedRouteIds'] as List?)?.map((e) => e as String).toList() ??
                [],
        totalPayout: (data['totalPayout'] as num?)?.toDouble() ?? 0,
      );

  Set<int> _takenSeatsFrom(Map<String, dynamic> data) =>
      (data['takenSeats'] as List?)?.map((e) => (e as num).toInt()).toSet() ?? {};

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------
  Future<List<RouteModel>> searchRoutes(
      String origin, String destination, DateTime date) async {
    if (!_useFirestore) {
      return _mockService.searchRoutes(origin, destination, date);
    }
    _init();
    await ensureSeeded();
    final snap = await _firestore!.collection('routes').get();
    final routes = snap.docs.map((d) => _routeFromDoc(d.id, d.data())).where((r) {
      final matchOrigin = origin.isEmpty ||
          r.origin.toLowerCase().contains(origin.toLowerCase());
      final matchDest = destination.isEmpty ||
          r.destination.toLowerCase().contains(destination.toLowerCase());
      return matchOrigin && matchDest;
    }).toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return routes;
  }

  Future<Set<int>> getTakenSeats(String routeId) async {
    if (!_useFirestore) return _mockService.getTakenSeats(routeId);
    _init();
    final doc = await _firestore!.collection('routes').doc(routeId).get();
    if (!doc.exists) return {};
    return _takenSeatsFrom(doc.data()!);
  }

  Future<DriverModel?> getDriverById(String id) async {
    if (!_useFirestore) return _mockService.getDriverById(id);
    _init();
    final doc = await _firestore!.collection('drivers').doc(id).get();
    if (!doc.exists) return null;
    return _driverFromDoc(doc.id, doc.data()!);
  }

  // ---------------------------------------------------------------------------
  // Driver-assignment algorithm (v1): eligible = no time-conflicting route;
  // ordered by fewest current assignments (load-balanced), tie-break by id.
  // ---------------------------------------------------------------------------
  List<DriverModel> _eligibleDrivers(
      RouteModel route, List<RouteModel> allRoutes, List<DriverModel> drivers) {
    final bStart = route.departureTime;
    final bEnd = route.departureTime.add(route.duration);

    RouteModel? routeById(String id) {
      for (final r in allRoutes) {
        if (r.id == id) return r;
      }
      return null;
    }

    bool conflict(DriverModel d) {
      for (final rid in d.assignedRouteIds) {
        final r = routeById(rid);
        if (r == null) continue;
        final aStart = r.departureTime;
        final aEnd = r.departureTime.add(r.duration);
        if (aStart.isBefore(bEnd) && bStart.isBefore(aEnd)) return true;
      }
      return false;
    }

    return drivers.where((d) => !conflict(d)).toList()
      ..sort((a, b) {
        final byLoad = a.assignedRouteIds.length.compareTo(b.assignedRouteIds.length);
        return byLoad != 0 ? byLoad : a.id.compareTo(b.id);
      });
  }

  // ---------------------------------------------------------------------------
  // Transactional booking: atomically re-checks seat availability, marks the
  // seats taken, decrements availableSeats, assigns a driver, and writes the
  // booking — so concurrent riders can't grab the same seat.
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
    if (!_useFirestore) {
      return _mockService.createBooking(
        routeId: routeId,
        seatNumbers: seatNumbers,
        totalPrice: totalPrice,
      );
    }
    _init();
    await ensureSeeded();

    // Pre-read current routes + drivers to compute the load-balanced candidate
    // ordering (queries aren't allowed inside a transaction).
    final routesSnap = await _firestore!.collection('routes').get();
    final driversSnap = await _firestore!.collection('drivers').get();
    final allRoutes =
        routesSnap.docs.map((d) => _routeFromDoc(d.id, d.data())).toList();
    final allDrivers =
        driversSnap.docs.map((d) => _driverFromDoc(d.id, d.data())).toList();
    final driverNameById = {for (final d in allDrivers) d.id: d.name};

    final routeRef = _firestore!.collection('routes').doc(routeId);
    final bookingRef = _firestore!.collection('bookings').doc();

    return _firestore!.runTransaction<BookingModel>((tx) async {
      final routeSnap = await tx.get(routeRef);
      if (!routeSnap.exists) {
        throw Exception('Route not found');
      }
      final data = routeSnap.data()!;
      final taken = _takenSeatsFrom(data);

      final conflicts = seatNumbers.where(taken.contains).toList()..sort();
      if (conflicts.isNotEmpty) {
        throw SeatUnavailableException(conflicts);
      }

      // Resolve the driver: keep an existing assignment, otherwise pick the
      // best eligible candidate from the pre-read ordering.
      String? driverId = data['assignedDriverId'] as String?;
      if (driverId == null) {
        final route = _routeFromDoc(routeId, data);
        final candidates = _eligibleDrivers(route, allRoutes, allDrivers);
        if (candidates.isNotEmpty) {
          driverId = candidates.first.id;
          tx.update(_firestore!.collection('drivers').doc(driverId), {
            'assignedRouteIds': FieldValue.arrayUnion([routeId]),
          });
        }
      }
      final driverName = driverId != null ? driverNameById[driverId] : null;

      final newTaken = [...taken, ...seatNumbers]..sort();
      tx.update(routeRef, {
        'takenSeats': newTaken,
        'availableSeats': (data['totalSeats'] as num).toInt() - newTaken.length,
        'assignedDriverId': driverId,
      });

      final id = 'BK-${bookingRef.id.substring(0, 6).toUpperCase()}';
      final now = DateTime.now();
      tx.set(bookingRef, {
        'bookingId': id,
        'userId': riderId,
        'riderName': riderName,
        'routeId': routeId,
        'origin': data['origin'],
        'destination': data['destination'],
        'seats': seatNumbers.length,
        'seatNumbers': seatNumbers,
        'totalPrice': totalPrice,
        'pickupAddress': pickupAddress ?? data['pickupPoint'],
        'dropoffAddress': dropoffAddress,
        'paymentIntentId': paymentIntentId,
        'departureTime': data['departureTime'],
        'assignedDriverId': driverId,
        'assignedDriverName': driverName,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return BookingModel(
        id: id,
        routeId: routeId,
        riderId: riderId,
        riderName: riderName,
        origin: data['origin'] as String? ?? '',
        destination: data['destination'] as String? ?? '',
        departureTime:
            (data['departureTime'] as Timestamp?)?.toDate() ?? now,
        seatNumbers: seatNumbers,
        totalPrice: totalPrice,
        pickupPoint: (pickupAddress ?? data['pickupPoint'] as String?) ?? '',
        tripStatus: TripStatus.notStarted,
        paymentStatus: PaymentStatus.paid,
        bookingDate: now,
        assignedDriverId: driverId,
        assignedDriverName: driverName,
      );
    });
  }

  Future<void> saveDriverApplication({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String vehicleInfo,
    required String licenseNumber,
  }) async {
    if (!_useFirestore) return;
    _init();

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

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    if (!_useFirestore) return [];
    _init();

    final snapshot = await _firestore!
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();

    final results = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
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
