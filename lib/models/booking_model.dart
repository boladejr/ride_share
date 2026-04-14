enum TripStatus { notStarted, inProgress, completed }

enum PaymentStatus { pending, paid, refunded }

class BookingModel {
  final String id;
  final String routeId;
  final String riderId;
  final String riderName;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final List<int> seatNumbers;
  final double totalPrice;
  final String pickupPoint;
  final TripStatus tripStatus;
  final PaymentStatus paymentStatus;
  final DateTime bookingDate;

  BookingModel({
    required this.id,
    required this.routeId,
    required this.riderId,
    required this.riderName,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.seatNumbers,
    required this.totalPrice,
    required this.pickupPoint,
    required this.tripStatus,
    required this.paymentStatus,
    required this.bookingDate,
  });

  BookingModel copyWith({
    String? id,
    String? routeId,
    String? riderId,
    String? riderName,
    String? origin,
    String? destination,
    DateTime? departureTime,
    List<int>? seatNumbers,
    double? totalPrice,
    String? pickupPoint,
    TripStatus? tripStatus,
    PaymentStatus? paymentStatus,
    DateTime? bookingDate,
  }) {
    return BookingModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      seatNumbers: seatNumbers ?? this.seatNumbers,
      totalPrice: totalPrice ?? this.totalPrice,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      tripStatus: tripStatus ?? this.tripStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingDate: bookingDate ?? this.bookingDate,
    );
  }
}
