import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';
import '../models/route_model.dart';
import 'mock_data_service.dart';

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

  List<RouteModel> searchRoutes(String origin, String destination, DateTime date) {
    // Route search uses mock data for now; migrate to Firestore when routes are
    // managed via an admin panel or driver submissions.
    return _mockService.searchRoutes(origin, destination, date);
  }

  Future<void> saveBooking({
    required String userId,
    required String routeId,
    required int seats,
    required double totalPrice,
    String? pickupAddress,
    String? dropoffAddress,
    String? paymentIntentId,
    String? origin,
    String? destination,
    List<int>? seatNumbers,
    DateTime? departureTime,
  }) async {
    if (!_useFirestore) return;
    _init();

    await _firestore!.collection('bookings').add({
      'userId': userId,
      'routeId': routeId,
      'seats': seats,
      'totalPrice': totalPrice,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'paymentIntentId': paymentIntentId,
      'origin': origin,
      'destination': destination,
      'seatNumbers': seatNumbers,
      'departureTime': departureTime != null ? Timestamp.fromDate(departureTime) : null,
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
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
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}
