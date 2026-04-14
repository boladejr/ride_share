import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/route_model.dart';
import '../services/mock_data_service.dart';
import '../theme.dart';
import 'checkout_page.dart';

class SeatSelectionPage extends StatefulWidget {
  final RouteModel route;

  const SeatSelectionPage({super.key, required this.route});

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  final _dataService = MockDataService();
  final Set<int> _selectedSeats = {};
  late Set<int> _takenSeats;

  @override
  void initState() {
    super.initState();
    _takenSeats = _dataService.getTakenSeats(widget.route.id);
  }

  void _toggleSeat(int seatNumber) {
    if (_takenSeats.contains(seatNumber)) return;
    setState(() {
      if (_selectedSeats.contains(seatNumber)) {
        _selectedSeats.remove(seatNumber);
      } else {
        _selectedSeats.add(seatNumber);
      }
    });
  }

  void _proceedToCheckout() {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one seat')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          route: widget.route,
          selectedSeats: _selectedSeats.toList()..sort(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _selectedSeats.length * widget.route.pricePerSeat;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Seats'),
      ),
      body: Column(
        children: [
          // Route info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            child: Row(
              children: [
                const Icon(Icons.directions_car, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.route.origin} → ${widget.route.destination}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('EEE, MMM d • hh:mm a')
                            .format(widget.route.departureTime),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${NumberFormat('#,##0.00').format(widget.route.pricePerSeat)}/seat',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem(AppTheme.seatAvailable, 'Available'),
                _legendItem(AppTheme.seatTaken, 'Taken'),
                _legendItem(AppTheme.seatSelected, 'Selected'),
              ],
            ),
          ),

          // Seat grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Front of car (driver seat)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.drive_eta, color: Colors.grey[600], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'DRIVER',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Passenger seats (up to 3 in a row)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 1; i <= widget.route.totalSeats; i++)
                        Builder(
                          builder: (context) {
                            final isTaken = _takenSeats.contains(i);
                            final isSelected = _selectedSeats.contains(i);
                            return _buildSeat(i, isTaken, isSelected);
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(
                    '${widget.route.totalSeats} passenger seats per car',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Bottom summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedSeats.length} seat${_selectedSeats.length != 1 ? 's' : ''} selected',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_selectedSeats.isNotEmpty)
                            Text(
                              'Seats: ${(_selectedSeats.toList()..sort()).join(', ')}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '\$${NumberFormat('#,##0.00').format(totalPrice)}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _selectedSeats.isEmpty ? null : _proceedToCheckout,
                      child: const Text('Proceed to Checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeat(int seatNumber, bool isTaken, bool isSelected) {
    Color bgColor;
    Color textColor;
    if (isTaken) {
      bgColor = AppTheme.seatTaken;
      textColor = Colors.white;
    } else if (isSelected) {
      bgColor = AppTheme.seatSelected;
      textColor = Colors.white;
    } else {
      bgColor = AppTheme.seatAvailable;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => _toggleSeat(seatNumber),
      child: Container(
        width: 52,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.seatSelected.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$seatNumber',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
