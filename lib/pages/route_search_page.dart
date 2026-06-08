import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/route_model.dart';
import '../services/firestore_data_service.dart';
import '../theme.dart';
import 'seat_selection_page.dart';

class RouteSearchPage extends StatelessWidget {
  final String origin;
  final String destination;
  final DateTime date;
  final String? pickupAddress;
  final String? dropoffAddress;

  const RouteSearchPage({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
    this.pickupAddress,
    this.dropoffAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('$origin → $destination'),
      ),
      body: FutureBuilder<List<RouteModel>>(
        future: FirestoreDataService().searchRoutes(origin, destination, date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final routes = snapshot.data ?? [];
          return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + results count header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(date),
                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      if (pickupAddress != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'From: $pickupAddress',
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (dropoffAddress != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'To: $dropoffAddress',
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (routes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${routes.length} ride${routes.length != 1 ? 's' : ''} available',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                          ),
                        ),
                    ],
                  ),
                ),
                // Sort pills
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sort, size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text('Earliest', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          Expanded(
            child: routes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.search_off_outlined, size: 48, color: AppTheme.textTertiary),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No rides found',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try different cities or dates',
                          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      return _RouteCard(
                        route: routes[index],
                        pickupAddress: pickupAddress,
                        dropoffAddress: dropoffAddress,
                      );
                    },
                  ),
          ),
            ],
          );
        },
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteModel route;
  final String? pickupAddress;
  final String? dropoffAddress;

  const _RouteCard({
    required this.route,
    this.pickupAddress,
    this.dropoffAddress,
  });

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
                    builder: (_) => SeatSelectionPage(
                      route: route,
                      pickupAddress: pickupAddress,
                      dropoffAddress: dropoffAddress,
                    ),
                  ),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Visual timeline route header
              Row(
                children: [
                  // Origin column with dot
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          departureFormat.format(route.departureTime),
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                route.origin,
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Duration pill in center
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDuration(route.duration),
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  // Destination column with dot
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          departureFormat.format(arrivalTime),
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                route.destination,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(color: AppTheme.primaryDark, shape: BoxShape.circle),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Connecting line
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(height: 1, color: AppTheme.borderColor),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),

              // Driver preview + seats + price row
              Row(
                children: [
                  // Driver preview
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car_outlined, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${route.availableSeats} seat${route.availableSeats != 1 ? 's' : ''} left',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${NumberFormat('#,##0.00').format(route.pricePerSeat)}',
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                  ),
                  Text('/seat', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textTertiary)),
                ],
              ),

              const SizedBox(height: 16),

              // Select Seats button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: route.availableSeats > 0
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SeatSelectionPage(
                                route: route,
                                pickupAddress: pickupAddress,
                                dropoffAddress: dropoffAddress,
                              ),
                            ),
                          )
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(route.availableSeats > 0 ? 'Select seats' : 'Sold out'),
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
