import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../services/mock_data_service.dart';
import '../theme.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  final _dataService = MockDataService();
  // Simulating logged-in driver (driver_1 - Carlos Rivera)
  final String _currentDriverId = 'driver_1';
  final Set<String> _acceptedRuns = {};

  @override
  Widget build(BuildContext context) {
    final driver = _dataService.getDriverById(_currentDriverId);
    final assignedRoutes = _dataService.getRoutesForDriver(_currentDriverId);

    if (driver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Dashboard')),
        body: const Center(child: Text('Driver not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_outlined, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Driver',
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver info header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      driver.name[0],
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
                        const SizedBox(height: 2),
                        Text(driver.email, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Earnings summary cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _earningsCard(
                      'Total Earnings',
                      '\$${NumberFormat('#,##0.00').format(driver.totalPayout)}',
                      Icons.account_balance_wallet_outlined,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _earningsCard(
                      'Active Routes',
                      '${assignedRoutes.length}',
                      Icons.route_outlined,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _earningsCard(
                      'Completed',
                      '${assignedRoutes.where((r) => _dataService.getTripStatus(r.id) == TripStatus.completed).length}',
                      Icons.check_circle_outline,
                      AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),

            // Assigned Routes
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Assigned Routes (${assignedRoutes.length})',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
              ),
            ),

            if (assignedRoutes.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No routes assigned yet',
                    style: GoogleFonts.inter(color: AppTheme.textTertiary),
                  ),
                ),
              )
            else
              ...assignedRoutes.map((route) {
                final bookings = _dataService.getBookingsForRoute(route.id);
                final passengerCount = bookings.fold<int>(
                  0,
                  (sum, b) => sum + b.seatNumbers.length,
                );
                final takenSeats = route.totalSeats - route.availableSeats;
                final payoutPerRun = takenSeats * route.pricePerSeat * 0.7;
                final tripStatus = _dataService.getTripStatus(route.id);
                final isAccepted = _acceptedRuns.contains(route.id);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${route.origin} → ${route.destination}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ),
                          _statusBadge(tripStatus),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Details
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _infoChip(
                            Icons.schedule_outlined,
                            DateFormat('EEE, MMM d • hh:mm a')
                                .format(route.departureTime),
                          ),
                          _infoChip(
                            Icons.people_outline,
                            '$passengerCount passengers',
                          ),
                          _infoChip(
                            Icons.location_on_outlined,
                            route.pickupPoint,
                          ),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1, color: AppTheme.borderColor),
                      ),

                      // Payout and actions
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payout',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '\$${NumberFormat('#,##0.00').format(payoutPerRun)}',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                              Text(
                                '70% of $takenSeats seats',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),

                          if (!isAccepted &&
                              tripStatus == TripStatus.notStarted)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _acceptedRuns.add(route.id);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Run accepted: ${route.origin} → ${route.destination}',
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check, size: 16),
                                  const SizedBox(width: 6),
                                  const Text('Accept Run'),
                                ],
                              ),
                            )
                          else if (isAccepted)
                            _buildStatusToggle(route.id, tripStatus),
                        ],
                      ),

                      // Pickup points for passengers
                      if (bookings.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ExpansionTile(
                          title: Text(
                            'Passenger Pickups',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          tilePadding: EdgeInsets.zero,
                          children: bookings.map((b) {
                            return ListTile(
                              dense: true,
                              leading: Icon(Icons.person_outline, size: 18, color: AppTheme.textSecondary),
                              title: Text(
                                b.riderName,
                                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primaryDark),
                              ),
                              subtitle: Text(
                                'Seats: ${b.seatNumbers.join(", ")}',
                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary),
                              ),
                              trailing: Text(
                                b.pickupPoint,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle(String routeId, TripStatus currentStatus) {
    return SegmentedButton<TripStatus>(
      segments: const [
        ButtonSegment(
          value: TripStatus.notStarted,
          label: Text('Not Started', style: TextStyle(fontSize: 10)),
          icon: Icon(Icons.schedule_outlined, size: 14),
        ),
        ButtonSegment(
          value: TripStatus.inProgress,
          label: Text('In Progress', style: TextStyle(fontSize: 10)),
          icon: Icon(Icons.directions_car_outlined, size: 14),
        ),
        ButtonSegment(
          value: TripStatus.completed,
          label: Text('Done', style: TextStyle(fontSize: 10)),
          icon: Icon(Icons.check_circle_outline, size: 14),
        ),
      ],
      selected: {currentStatus},
      onSelectionChanged: (Set<TripStatus> selected) {
        setState(() {
          _dataService.updateTripStatus(routeId, selected.first);
        });
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 10),
        ),
      ),
    );
  }

  Widget _statusBadge(TripStatus status) {
    Color color;
    String text;
    switch (status) {
      case TripStatus.notStarted:
        color = Colors.orange;
        text = 'Not Started';
        break;
      case TripStatus.inProgress:
        color = AppTheme.primaryColor;
        text = 'In Progress';
        break;
      case TripStatus.completed:
        color = AppTheme.successColor;
        text = 'Completed';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _earningsCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiary)),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
