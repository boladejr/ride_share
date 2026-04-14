import 'package:uuid/uuid.dart';
import '../models/route_model.dart';
import '../models/booking_model.dart';
import '../models/driver_model.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  final _uuid = const Uuid();

  // Mock routes data
  final List<RouteModel> _routes = [
    RouteModel(
      id: 'route_1',
      origin: 'Lagos',
      destination: 'Ibadan',
      departureTime: DateTime.now().add(const Duration(hours: 3)),
      duration: const Duration(hours: 2, minutes: 30),
      totalSeats: 15,
      availableSeats: 8,
      pricePerSeat: 5500.0,
      pickupPoint: 'Jibowu Bus Terminal, Lagos',
      assignedDriverId: 'driver_1',
    ),
    RouteModel(
      id: 'route_2',
      origin: 'Lagos',
      destination: 'Benin City',
      departureTime: DateTime.now().add(const Duration(hours: 5)),
      duration: const Duration(hours: 4, minutes: 15),
      totalSeats: 15,
      availableSeats: 12,
      pricePerSeat: 8500.0,
      pickupPoint: 'Ojota Motor Park, Lagos',
      assignedDriverId: 'driver_2',
    ),
    RouteModel(
      id: 'route_3',
      origin: 'Lagos',
      destination: 'Abuja',
      departureTime: DateTime.now().add(const Duration(hours: 6)),
      duration: const Duration(hours: 8),
      totalSeats: 20,
      availableSeats: 15,
      pricePerSeat: 15000.0,
      pickupPoint: 'Berger Bus Stop, Lagos',
      assignedDriverId: null,
    ),
    RouteModel(
      id: 'route_4',
      origin: 'Ibadan',
      destination: 'Lagos',
      departureTime: DateTime.now().add(const Duration(hours: 4)),
      duration: const Duration(hours: 2, minutes: 30),
      totalSeats: 15,
      availableSeats: 5,
      pricePerSeat: 5500.0,
      pickupPoint: 'Iwo Road Terminal, Ibadan',
      assignedDriverId: 'driver_1',
    ),
    RouteModel(
      id: 'route_5',
      origin: 'Abuja',
      destination: 'Lagos',
      departureTime: DateTime.now().add(const Duration(hours: 8)),
      duration: const Duration(hours: 8),
      totalSeats: 20,
      availableSeats: 18,
      pricePerSeat: 15000.0,
      pickupPoint: 'Utako Bus Station, Abuja',
      assignedDriverId: 'driver_3',
    ),
    RouteModel(
      id: 'route_6',
      origin: 'Benin City',
      destination: 'Lagos',
      departureTime: DateTime.now().add(const Duration(hours: 7)),
      duration: const Duration(hours: 4, minutes: 15),
      totalSeats: 15,
      availableSeats: 10,
      pricePerSeat: 8500.0,
      pickupPoint: 'Uselu Motor Park, Benin City',
      assignedDriverId: null,
    ),
  ];

  // Mock bookings data
  final List<BookingModel> _bookings = [
    BookingModel(
      id: 'BK-001',
      routeId: 'route_1',
      riderId: 'user_1',
      riderName: 'Ayo Johnson',
      origin: 'Lagos',
      destination: 'Ibadan',
      departureTime: DateTime.now().add(const Duration(hours: 3)),
      seatNumbers: [3, 4],
      totalPrice: 11000.0,
      pickupPoint: 'Jibowu Bus Terminal, Lagos',
      tripStatus: TripStatus.notStarted,
      paymentStatus: PaymentStatus.paid,
      bookingDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    BookingModel(
      id: 'BK-002',
      routeId: 'route_2',
      riderId: 'user_2',
      riderName: 'Chinedu Obi',
      origin: 'Lagos',
      destination: 'Benin City',
      departureTime: DateTime.now().add(const Duration(hours: 5)),
      seatNumbers: [1],
      totalPrice: 8500.0,
      pickupPoint: 'Ojota Motor Park, Lagos',
      tripStatus: TripStatus.notStarted,
      paymentStatus: PaymentStatus.paid,
      bookingDate: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  // Mock drivers data
  final List<DriverModel> _drivers = [
    DriverModel(
      id: 'driver_1',
      name: 'Ibrahim Musa',
      email: 'ibrahim@rideshare.com',
      phone: '+234 801 234 5678',
      assignedRouteIds: ['route_1', 'route_4'],
      totalPayout: 125000.0,
    ),
    DriverModel(
      id: 'driver_2',
      name: 'Tunde Bakare',
      email: 'tunde@rideshare.com',
      phone: '+234 802 345 6789',
      assignedRouteIds: ['route_2'],
      totalPayout: 85000.0,
    ),
    DriverModel(
      id: 'driver_3',
      name: 'Emeka Nwosu',
      email: 'emeka@rideshare.com',
      phone: '+234 803 456 7890',
      assignedRouteIds: ['route_5'],
      totalPayout: 200000.0,
    ),
  ];

  // Taken seats per route (seat numbers that are booked)
  final Map<String, Set<int>> _takenSeats = {
    'route_1': {1, 2, 3, 4, 9, 10, 14},
    'route_2': {1, 5, 7},
    'route_3': {2, 6, 11, 17, 20},
    'route_4': {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
    'route_5': {3, 12},
    'route_6': {1, 4, 8, 13, 15},
  };

  // Trip status tracking
  final Map<String, TripStatus> _tripStatuses = {
    'route_1': TripStatus.notStarted,
    'route_2': TripStatus.notStarted,
    'route_3': TripStatus.notStarted,
    'route_4': TripStatus.notStarted,
    'route_5': TripStatus.notStarted,
    'route_6': TripStatus.notStarted,
  };

  // Cities list
  List<String> get cities =>
      ['Lagos', 'Ibadan', 'Benin City', 'Abuja', 'Port Harcourt', 'Enugu'];

  // Route operations
  List<RouteModel> get routes => List.unmodifiable(_routes);

  List<RouteModel> searchRoutes(String origin, String destination, DateTime date) {
    return _routes.where((route) {
      final matchOrigin =
          origin.isEmpty || route.origin.toLowerCase().contains(origin.toLowerCase());
      final matchDest = destination.isEmpty ||
          route.destination.toLowerCase().contains(destination.toLowerCase());
      // For demo purposes, always show routes regardless of date
      return matchOrigin && matchDest;
    }).toList();
  }

  RouteModel? getRouteById(String id) {
    try {
      return _routes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  void addRoute(RouteModel route) {
    _routes.add(route);
    _takenSeats[route.id] = {};
    _tripStatuses[route.id] = TripStatus.notStarted;
  }

  void updateRoute(RouteModel route) {
    final index = _routes.indexWhere((r) => r.id == route.id);
    if (index != -1) {
      _routes[index] = route;
    }
  }

  void deleteRoute(String routeId) {
    _routes.removeWhere((r) => r.id == routeId);
    _takenSeats.remove(routeId);
    _tripStatuses.remove(routeId);
  }

  // Seat operations
  Set<int> getTakenSeats(String routeId) {
    return _takenSeats[routeId] ?? {};
  }

  void bookSeats(String routeId, List<int> seatNumbers) {
    _takenSeats[routeId] = (_takenSeats[routeId] ?? {})..addAll(seatNumbers);
    final route = getRouteById(routeId);
    if (route != null) {
      updateRoute(route.copyWith(
        availableSeats: route.availableSeats - seatNumbers.length,
      ));
    }
  }

  // Booking operations
  List<BookingModel> get bookings => List.unmodifiable(_bookings);

  List<BookingModel> getBookingsForUser(String userId) {
    return _bookings.where((b) => b.riderId == userId).toList();
  }

  List<BookingModel> getBookingsForRoute(String routeId) {
    return _bookings.where((b) => b.routeId == routeId).toList();
  }

  BookingModel? getBookingById(String id) {
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  BookingModel createBooking({
    required String routeId,
    required List<int> seatNumbers,
    required double totalPrice,
  }) {
    final route = getRouteById(routeId)!;
    final booking = BookingModel(
      id: 'BK-${_uuid.v4().substring(0, 6).toUpperCase()}',
      routeId: routeId,
      riderId: 'current_user',
      riderName: 'Current User',
      origin: route.origin,
      destination: route.destination,
      departureTime: route.departureTime,
      seatNumbers: seatNumbers,
      totalPrice: totalPrice,
      pickupPoint: route.pickupPoint,
      tripStatus: TripStatus.notStarted,
      paymentStatus: PaymentStatus.paid,
      bookingDate: DateTime.now(),
    );
    _bookings.add(booking);
    bookSeats(routeId, seatNumbers);
    return booking;
  }

  void cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final booking = _bookings[index];
      _bookings[index] = booking.copyWith(
        paymentStatus: PaymentStatus.refunded,
      );
      // Free up seats
      _takenSeats[booking.routeId]?.removeAll(booking.seatNumbers.toSet());
      final route = getRouteById(booking.routeId);
      if (route != null) {
        updateRoute(route.copyWith(
          availableSeats: route.availableSeats + booking.seatNumbers.length,
        ));
      }
    }
  }

  // Driver operations
  List<DriverModel> get drivers => List.unmodifiable(_drivers);

  DriverModel? getDriverById(String id) {
    try {
      return _drivers.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  List<RouteModel> getRoutesForDriver(String driverId) {
    return _routes.where((r) => r.assignedDriverId == driverId).toList();
  }

  void assignDriverToRoute(String driverId, String routeId) {
    updateRoute(getRouteById(routeId)!.copyWith(assignedDriverId: driverId));
    final driverIndex = _drivers.indexWhere((d) => d.id == driverId);
    if (driverIndex != -1) {
      final driver = _drivers[driverIndex];
      _drivers[driverIndex] = driver.copyWith(
        assignedRouteIds: [...driver.assignedRouteIds, routeId],
      );
    }
  }

  // Trip status operations
  TripStatus getTripStatus(String routeId) {
    return _tripStatuses[routeId] ?? TripStatus.notStarted;
  }

  void updateTripStatus(String routeId, TripStatus status) {
    _tripStatuses[routeId] = status;
    // Update all bookings for this route
    for (int i = 0; i < _bookings.length; i++) {
      if (_bookings[i].routeId == routeId) {
        _bookings[i] = _bookings[i].copyWith(tripStatus: status);
      }
    }
  }

  // Generate new route ID
  String generateRouteId() => 'route_${_uuid.v4().substring(0, 6)}';
}
