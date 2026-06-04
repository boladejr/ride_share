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

  Set<int> _seatsFrom(Map<String, dynamic>? data) =>
      (data?['takenSeats'] as List?)?.map((e) => (e as num).toInt()).toSet() ??
      {};

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

    // Driver assignment stays in the mock (in-memory, load-balanced v1).
    final driver = _mockService.assignDriverForRoute(routeId);

    if (!_useFirestore) {
      return _mockService.createBooking(
        routeId: routeId,
        seatNumbers: seatNumbers,
        totalPrice: totalPrice,
      );
    }
    _init();

    final seed = _mockService.getTakenSeats(routeId);
    final seatRef = _seats.doc(routeId);

    // Reserve the seats atomically.
    await _firestore!.runTransaction((tx) async {
      final doc = await tx.get(seatRef);
      final taken = {...seed, ..._seatsFrom(doc.data())};

      final conflicts = seatNumbers.where(taken.contains).toList()..sort();
      if (conflicts.isNotEmpty) {
        throw SeatUnavailableException(conflicts);
      }

      final newTaken = ({...taken, ...seatNumbers}.toList())..sort();
      tx.set(seatRef, {
        'routeId': routeId,
        'totalSeats': route.totalSeats,
        'takenSeats': newTaken,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

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
      tripStatus: TripStatus.notStarted,
      paymentStatus: PaymentStatus.paid,
      bookingDate: now,
      assignedDriverId: driver?.id,
      assignedDriverName: driver?.name,
    );

    // Persist the booking record (best-effort; seat reservation already done).
    try {
      await _firestore!.collection('bookings').add({
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
    } catch (_) {
      // Booking record save failed; seats are still reserved and the rider
      // sees their confirmation. "My Trips" may not list it until retried.
    }

    return booking;
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
