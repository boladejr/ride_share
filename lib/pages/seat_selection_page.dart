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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Your Seats'),
      ),
      body: Column(
        children: [
          // Route info
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.route.origin} → ${widget.route.destination}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEE, MMM d • hh:mm a')
                            .format(widget.route.departureTime),
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${NumberFormat('#,##0.00').format(widget.route.pricePerSeat)}/seat',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem(AppTheme.seatAvailable, 'Available'),
                const SizedBox(width: 24),
                _legendItem(AppTheme.seatTaken, 'Taken'),
                const SizedBox(width: 24),
                _legendItem(AppTheme.seatSelected, 'Selected'),
              ],
            ),
          ),

          // Seat grid
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Driver label
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 32),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.drive_eta_outlined, color: AppTheme.textTertiary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'DRIVER',
                          style: GoogleFonts.inter(
                            color: AppTheme.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Passenger seats
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
                    style: GoogleFonts.inter(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
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
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (_selectedSeats.isNotEmpty)
                            Text(
                              'Seats: ${(_selectedSeats.toList()..sort()).join(', ')}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '\$${NumberFormat('#,##0.00').format(totalPrice)}',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _selectedSeats.isEmpty ? null : _proceedToCheckout,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Proceed to Checkout'),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
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
      textColor = AppTheme.textTertiary;
    } else if (isSelected) {
      bgColor = AppTheme.seatSelected;
      textColor = Colors.white;
    } else {
      bgColor = AppTheme.seatAvailable;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => _toggleSeat(seatNumber),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            '$seatNumber',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
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
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
