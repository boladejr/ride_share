import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/route_model.dart';
import '../services/mock_data_service.dart';
import '../theme.dart';
import 'trip_confirmation_page.dart';

class CheckoutPage extends StatefulWidget {
  final RouteModel route;
  final List<int> selectedSeats;

  const CheckoutPage({
    super.key,
    required this.route,
    required this.selectedSeats,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _dataService = MockDataService();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _processing = false;

  double get _totalPrice => widget.selectedSeats.length * widget.route.pricePerSeat;

  Future<void> _confirmAndPay() async {
    if (_cardNumberController.text.isEmpty ||
        _expiryController.text.isEmpty ||
        _cvvController.text.isEmpty ||
        _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all payment details')),
      );
      return;
    }

    setState(() => _processing = true);

    // Simulate Stripe payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Create booking in mock Firestore
    final booking = _dataService.createBooking(
      routeId: widget.route.id,
      seatNumbers: widget.selectedSeats,
      totalPrice: _totalPrice,
    );

    if (!mounted) return;
    setState(() => _processing = false);

    // Navigate to confirmation
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => TripConfirmationPage(bookingId: booking.id),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
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
                    'Order Summary',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _summaryRow(
                    'Route',
                    '${widget.route.origin} → ${widget.route.destination}',
                  ),
                  _summaryRow(
                    'Departure',
                    DateFormat('EEE, MMM d • hh:mm a')
                        .format(widget.route.departureTime),
                  ),
                  _summaryRow(
                    'Seats',
                    widget.selectedSeats.join(', '),
                  ),
                  _summaryRow(
                    'Pickup Point',
                    widget.route.pickupPoint,
                  ),
                  _summaryRow(
                    'Price per seat',
                    '\$${NumberFormat('#,##0.00').format(widget.route.pricePerSeat)}',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: AppTheme.borderColor),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (${widget.selectedSeats.length} seat${widget.selectedSeats.length != 1 ? 's' : ''})',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '\$${NumberFormat('#,##0.00').format(_totalPrice)}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment Section
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
                  Row(
                    children: [
                      Text(
                        'Payment Details',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline, size: 13, color: AppTheme.primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Stripe',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Cardholder Name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Cardholder Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 14),

                  // Card Number
                  TextField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                      hintText: '4242 4242 4242 4242',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                  ),
                  const SizedBox(height: 6),

                  // Expiry and CVV
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expiryController,
                          decoration: const InputDecoration(
                            labelText: 'MM/YY',
                            prefixIcon: Icon(Icons.date_range_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cvvController,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            prefixIcon: Icon(Icons.security_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _processing ? null : _confirmAndPay,
                child: _processing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Confirm & Pay \$${NumberFormat('#,##0.00').format(_totalPrice)}',
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                'Your payment is secured by Stripe',
                style: GoogleFonts.inter(
                  color: AppTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
