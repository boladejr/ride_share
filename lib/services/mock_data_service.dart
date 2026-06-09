import 'package:uuid/uuid.dart';
import '../models/route_model.dart';
import '../models/booking_model.dart';
import '../models/driver_model.dart';
import '../models/vehicle_type.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  final _uuid = const Uuid();

  // Mock routes data
  final List<RouteModel> _routes = [
    RouteModel(
      id: 'route_1',
      origin: 'Austin',
      destination: 'San Antonio',
      departureTime: DateTime.now().add(const Duration(hours: 3)),
      duration: const Duration(hours: 1, minutes: 20),
      vehicleType: VehicleType.suv,
      totalSeats: VehicleType.suv.seatCapacity,
      availableSeats: VehicleType.suv.seatCapacity - 1,
      pricePerSeat: 25.0,
      pickupPoint: '800 Brazos St, Austin, TX 78701',
      assignedDriverId: 'driver_1',
    ),
    RouteModel(
      id: 'route_2',
      origin: 'Austin',
      destination: 'Houston',
      departureTime: DateTime.now().add(const Duration(hours: 5)),
      duration: const Duration(hours: 2, minutes: 45),
      vehicleType: VehicleType.van,
      totalSeats: VehicleType.van.seatCapacity,
      availableSeats: VehicleType.van.seatCapacity,
      pricePerSeat: 35.0,
      pickupPoint: '600 Congress Ave, Austin, TX 78701',
      assignedDriverId: 'driver_2',
    ),
    RouteModel(
      id: 'route_3',
      origin: 'Austin',
      destination: 'Dallas',
      departureTime: DateTime.now().add(const Duration(hours: 6)),
      duration: const Duration(hours: 3, minutes: 15),
      vehicleType: VehicleType.sedan,
      totalSeats: VehicleType.sedan.seatCapacity,
      availableSeats: VehicleType.sedan.seatCapacity - 2,
      pricePerSeat: 40.0,
      pickupPoint: '1100 S Congress Ave, Austin, TX 78704',
      assignedDriverId: null,
    ),
    RouteModel(
      id: 'route_4',
      origin: 'San Antonio',
      destination: 'Austin',
      departureTime: DateTime.now().add(const Duration(hours: 4)),
      duration: const Duration(hours: 1, minutes: 20),
      vehicleType: VehicleType.minivan,
      totalSeats: VehicleType.minivan.seatCapacity,
      availableSeats: VehicleType.minivan.seatCapacity - 2,
      pricePerSeat: 25.0,
      pickupPoint: '300 Alamo Plaza, San Antonio, TX 78205',
      assignedDriverId: 'driver_1',
    ),
    RouteModel(
      id: 'route_5',
      origin: 'Houston',
      destination: 'Austin',
      departureTime: DateTime.now().add(const Duration(hours: 8)),
      duration: const Duration(hours: 2, minutes: 45),
      vehicleType: VehicleType.luxurySedan,
      totalSeats: VehicleType.luxurySedan.seatCapacity,
      availableSeats: VehicleType.luxurySedan.seatCapacity,
      pricePerSeat: 35.0,
      pickupPoint: '1001 Avenida de las Americas, Houston, TX 77010',
      assignedDriverId: 'driver_3',
    ),
    RouteModel(
      id: 'route_6',
      origin: 'San Antonio',
      destination: 'Houston',
      departureTime: DateTime.now().add(const Duration(hours: 7)),
      duration: const Duration(hours: 3),
      vehicleType: VehicleType.pickup,
      totalSeats: VehicleType.pickup.seatCapacity,
      availableSeats: VehicleType.pickup.seatCapacity - 1,
      pricePerSeat: 30.0,
      pickupPoint: '100 E Houston St, San Antonio, TX 78205',
      assignedDriverId: null,
    ),
  ];

  // Mock bookings data
  final List<BookingModel> _bookings = [
    BookingModel(
      id: 'BK-001',
      routeId: 'route_1',
      riderId: 'user_1',
      riderName: 'Sarah Mitchell',
      origin: 'Austin',
      destination: 'San Antonio',
      departureTime: DateTime.now().add(const Duration(hours: 3)),
      seatNumbers: [2],
      totalPrice: 25.0,
      pickupPoint: '800 Brazos St, Austin, TX 78701',
      tripStatus: TripStatus.notStarted,
      paymentStatus: PaymentStatus.paid,
      bookingDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    BookingModel(
      id: 'BK-002',
      routeId: 'route_3',
      riderId: 'user_2',
      riderName: 'James Cooper',
      origin: 'Austin',
      destination: 'Dallas',
      departureTime: DateTime.now().add(const Duration(hours: 6)),
      seatNumbers: [1, 3],
      totalPrice: 80.0,
      pickupPoint: '1100 S Congress Ave, Austin, TX 78704',
      tripStatus: TripStatus.notStarted,
      paymentStatus: PaymentStatus.paid,
      bookingDate: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  // Mock drivers data
  final List<DriverModel> _drivers = [
    DriverModel(
      id: 'driver_1',
      name: 'Carlos Rivera',
      email: 'carlos@rideshare.com',
      phone: '+1 (512) 555-0147',
      assignedRouteIds: ['route_1', 'route_4'],
      totalPayout: 1250.0,
    ),
    DriverModel(
      id: 'driver_2',
      name: 'Mike Thompson',
      email: 'mike@rideshare.com',
      phone: '+1 (512) 555-0238',
      assignedRouteIds: ['route_2'],
      totalPayout: 850.0,
    ),
    DriverModel(
      id: 'driver_3',
      name: 'David Chen',
      email: 'david@rideshare.com',
      phone: '+1 (713) 555-0391',
      assignedRouteIds: ['route_5'],
      totalPayout: 2000.0,
    ),
  ];

  // Taken seats per route (seat numbers that are booked)
  final Map<String, Set<int>> _takenSeats = {
    'route_1': {2},
    'route_2': {},
    'route_3': {1, 3},
    'route_4': {1, 2},
    'route_5': {},
    'route_6': {3},
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
      ['Austin', 'San Antonio', 'Houston', 'Dallas', 'Waco', 'El Paso'];

  // Route operations
  List<RouteModel> get routes => List.unmodifiable(_routes);

  List<RouteModel> searchRoutes(String origin, String destination, DateTime date) {
    // Guarantee there are always rides for any requested city pair: if no
    // seeded route serves this exact origin -> destination, synthesize a few.
    if (origin.isNotEmpty && destination.isNotEmpty) {
      _ensureRoutesForPair(origin, destination);
    }
    return _routes.where((route) {
      final matchOrigin =
          origin.isEmpty || route.origin.toLowerCase().contains(origin.toLowerCase());
      final matchDest = destination.isEmpty ||
          route.destination.toLowerCase().contains(destination.toLowerCase());
      // For demo purposes, always show routes regardless of date
      return matchOrigin && matchDest;
    }).toList();
  }

  /// Ensures at least a few rides exist for the given city pair. Generated
  /// routes are deterministic per pair and cached in [_routes], so re-searching
  /// the same pair doesn't create duplicates and booking/seat lookups by id
  /// keep working.
  void _ensureRoutesForPair(String origin, String destination) {
    final hasExisting = _routes.any((r) =>
        r.origin.toLowerCase() == origin.toLowerCase() &&
        r.destination.toLowerCase() == destination.toLowerCase());
    if (hasExisting) return;

    final slug =
        '${origin}_$destination'.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    // Vary the lineup deterministically based on the pair name.
    const lineups = <List<VehicleType>>[
      [VehicleType.suv, VehicleType.sedan, VehicleType.van],
      [VehicleType.minivan, VehicleType.luxurySedan, VehicleType.pickup],
      [VehicleType.sedan, VehicleType.van, VehicleType.suv],
    ];
    final lineup = lineups[origin.hashCode.abs() % lineups.length];

    for (var i = 0; i < lineup.length; i++) {
      final vt = lineup[i];
      final id = 'gen_${slug}_$i';
      if (_routes.any((r) => r.id == id)) continue;
      final hours = 2 + i * 3;
      final basePrice = 20.0 + (destination.length % 5) * 5 + i * 5;
      final route = RouteModel(
        id: id,
        origin: origin,
        destination: destination,
        departureTime: DateTime.now().add(Duration(hours: hours)),
        duration: Duration(hours: 1 + (i % 3), minutes: 15 * (i % 4)),
        vehicleType: vt,
        totalSeats: vt.seatCapacity,
        availableSeats: vt.seatCapacity,
        pricePerSeat: basePrice,
        pickupPoint: '$origin city center',
        assignedDriverId: null,
      );
      addRoute(route);
    }
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
    // Ensure the route has a driver before confirming the booking.
    final driver = assignDriverForRoute(routeId);
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
      assignedDriverId: driver?.id,
      assignedDriverName: driver?.name,
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

  /// Adds a newly registered driver to the active assignment pool immediately
  /// (no approval step). A fresh driver has no assigned routes, so their
  /// "current city" is unknown and they can be matched to a ride departing from
  /// any city for their first trip. After that they chain from their last
  /// drop-off. Idempotent by id.
  void addActiveDriver({
    required String id,
    required String name,
    required String email,
    required String phone,
  }) {
    if (id.isEmpty || _drivers.any((d) => d.id == id)) return;
    _drivers.add(DriverModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      assignedRouteIds: const [],
      totalPayout: 0.0,
    ));
  }

  /// The city a driver is currently in / will end up at: the destination of
  /// their most recent assigned route. Null means a brand-new driver with no
  /// trips yet, who is therefore available to start from any origin.
  String? driverCurrentCity(DriverModel driver) {
    RouteModel? latest;
    for (final id in driver.assignedRouteIds) {
      final r = getRouteById(id);
      if (r == null) continue;
      if (latest == null || r.departureTime.isAfter(latest.departureTime)) {
        latest = r;
      }
    }
    return latest?.destination;
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

  /// v1 driver-assignment algorithm.
  ///
  /// Ensures [routeId] has a driver and returns the assigned driver:
  /// - If the route already has a driver, that driver is kept.
  /// - Otherwise, among drivers with no time-conflicting route, the one with
  ///   the fewest current assignments is chosen (load-balanced), with a
  ///   deterministic tie-break by id.
  /// - Returns null if no driver is eligible (route stays pending).
  DriverModel? assignDriverForRoute(String routeId) {
    final route = getRouteById(routeId);
    if (route == null) return null;

    if (route.assignedDriverId != null) {
      return getDriverById(route.assignedDriverId!);
    }

    final candidates = _drivers.where((d) {
      if (_hasTimeConflict(d, route)) return false;
      // Direction-aware: a driver is only matched to a ride that departs from
      // where they currently are (no deadheading). Brand-new drivers (no current
      // city yet) are available to start from any origin.
      final city = driverCurrentCity(d);
      return city == null ||
          city.toLowerCase() == route.origin.toLowerCase();
    }).toList()
      ..sort((a, b) {
        final byLoad =
            a.assignedRouteIds.length.compareTo(b.assignedRouteIds.length);
        return byLoad != 0 ? byLoad : a.id.compareTo(b.id);
      });

    if (candidates.isEmpty) return null;

    final chosen = candidates.first;
    assignDriverToRoute(chosen.id, routeId);
    return getDriverById(chosen.id);
  }

  /// True if [driver] already has a route whose time window overlaps [newRoute].
  bool _hasTimeConflict(DriverModel driver, RouteModel newRoute) {
    final bStart = newRoute.departureTime;
    final bEnd = newRoute.departureTime.add(newRoute.duration);
    for (final routeId in driver.assignedRouteIds) {
      final r = getRouteById(routeId);
      if (r == null) continue;
      final aStart = r.departureTime;
      final aEnd = r.departureTime.add(r.duration);
      if (aStart.isBefore(bEnd) && bStart.isBefore(aEnd)) return true;
    }
    return false;
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
