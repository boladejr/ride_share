import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/route_model.dart';
import '../services/mock_data_service.dart';
import '../theme.dart';
import 'seat_selection_page.dart';

class RouteSearchPage extends StatelessWidget {
  final String origin;
  final String destination;
  final DateTime date;

  const RouteSearchPage({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = MockDataService();
    final routes = dataService.searchRoutes(origin, destination, date);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('$origin → $destination'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              DateFormat('EEEE, MMMM d, yyyy').format(date),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          Expanded(
            child: routes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_outlined, size: 64, color: AppTheme.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'No routes found',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try different cities or dates',
                          style: GoogleFonts.inter(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      return _RouteCard(route: routes[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteModel route;

  const _RouteCard({required this.route});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final departureFormat = DateFormat('hh:mm a');
    final arrivalTime = route.departureTime.add(route.duration);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: route.availableSeats > 0
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeatSelectionPage(route: route),
                  ),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Route header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.origin,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          departureFormat.format(route.departureTime),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Icon(Icons.arrow_forward, color: AppTheme.textTertiary, size: 18),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDuration(route.duration),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          route.destination,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          departureFormat.format(arrivalTime),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: AppTheme.borderColor),
              ),

              // Bottom row
              Row(
                children: [
                  // Seats available
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_seat_outlined, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${route.availableSeats} seat${route.availableSeats != 1 ? 's' : ''} left',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Price
                  Text(
                    '\$${NumberFormat('#,##0.00').format(route.pricePerSeat)}',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  Text(
                    '/seat',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Select Seats button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: route.availableSeats > 0
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SeatSelectionPage(route: route),
                            ),
                          )
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(route.availableSeats > 0 ? 'Select Seats' : 'Sold Out'),
                      if (route.availableSeats > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
