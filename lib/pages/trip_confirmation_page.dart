import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../services/mock_data_service.dart';
import '../theme.dart';

class TripConfirmationPage extends StatefulWidget {
  final String bookingId;

  const TripConfirmationPage({super.key, required this.bookingId});

  @override
  State<TripConfirmationPage> createState() => _TripConfirmationPageState();
}

class _TripConfirmationPageState extends State<TripConfirmationPage> {
  final _dataService = MockDataService();
  late BookingModel? _booking;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _booking = _dataService.getBookingById(widget.bookingId);
    // Simulate real-time status updates
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _booking = _dataService.getBookingById(widget.bookingId);
        });
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Color _statusColor(TripStatus status) {
    switch (status) {
      case TripStatus.notStarted:
        return Colors.orange;
      case TripStatus.inProgress:
        return AppTheme.seatSelected;
      case TripStatus.completed:
        return AppTheme.successColor;
    }
  }

  String _statusText(TripStatus status) {
    switch (status) {
      case TripStatus.notStarted:
        return 'Not Started';
      case TripStatus.inProgress:
        return 'In Progress';
      case TripStatus.completed:
        return 'Completed';
    }
  }

  IconData _statusIcon(TripStatus status) {
    switch (status) {
      case TripStatus.notStarted:
        return Icons.schedule;
      case TripStatus.inProgress:
        return Icons.directions_car;
      case TripStatus.completed:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Not Found')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final booking = _booking!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Trip Confirmed'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success banner — minimalist
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: AppTheme.primaryColor, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Booking Confirmed!',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your seat${booking.seatNumbers.length > 1 ? 's are' : ' is'} reserved',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Trip Status Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: _statusColor(booking.tripStatus).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _statusIcon(booking.tripStatus),
                    color: _statusColor(booking.tripStatus),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusText(booking.tripStatus),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(booking.tripStatus),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Booking Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Details',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailRow('Booking ID', booking.id),
                  _detailRow(
                    'Route',
                    '${booking.origin} → ${booking.destination}',
                  ),
                  _detailRow(
                    'Date',
                    DateFormat('EEE, MMM d, yyyy').format(booking.departureTime),
                  ),
                  _detailRow(
                    'Departure',
                    DateFormat('hh:mm a').format(booking.departureTime),
                  ),
                  _detailRow(
                    'Seats',
                    booking.seatNumbers.join(', '),
                  ),
                  _detailRow(
                    'Total Paid',
                    '\$${NumberFormat('#,##0.00').format(booking.totalPrice)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Pickup Point
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup Point',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          booking.pickupPoint,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Map placeholder
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Simulated map background
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            color: AppTheme.surfaceColor,
                            child: CustomPaint(
                              size: const Size(double.infinity, 180),
                              painter: _MapGridPainter(),
                            ),
                          ),
                        ),
                        // Pin marker
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Text(
                                'Pickup Here',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              Icons.location_on,
                              color: AppTheme.primaryColor,
                              size: 36,
                            ),
                          ],
                        ),
                        // Driver location indicator
                        if (booking.tripStatus == TripStatus.inProgress)
                          Positioned(
                            top: 40,
                            left: 60,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.directions_car,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        // Maps badge
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Text(
                              'Google Maps',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    booking.tripStatus == TripStatus.inProgress
                        ? 'Driver location updating in real time'
                        : 'Map will show live driver location when trip starts',
                    style: GoogleFonts.inter(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Back to home
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.home_outlined, size: 18),
                    const SizedBox(width: 8),
                    const Text('Back to Home'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.textTertiary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    // Draw grid lines to simulate a map
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some "roads"
    final roadPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.25)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.6),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.5, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
