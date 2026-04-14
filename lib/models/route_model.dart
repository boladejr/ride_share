class RouteModel {
  final String id;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final Duration duration;
  final int totalSeats;
  final int availableSeats;
  final double pricePerSeat;
  final String pickupPoint;
  final String? assignedDriverId;

  RouteModel({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.duration,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.pickupPoint,
    this.assignedDriverId,
  });

  RouteModel copyWith({
    String? id,
    String? origin,
    String? destination,
    DateTime? departureTime,
    Duration? duration,
    int? totalSeats,
    int? availableSeats,
    double? pricePerSeat,
    String? pickupPoint,
    String? assignedDriverId,
  }) {
    return RouteModel(
      id: id ?? this.id,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      duration: duration ?? this.duration,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
    );
  }
}
