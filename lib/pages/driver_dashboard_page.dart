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
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Driver',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
              padding: const EdgeInsets.all(20),
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      driver.name[0],
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.name,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          driver.email,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Payout',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                      Text(
                        '\$${NumberFormat('#,##0.00').format(driver.totalPayout)}',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Assigned Routes
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Assigned Routes (${assignedRoutes.length})',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            if (assignedRoutes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No routes assigned yet'),
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
                final payoutPerRun = takenSeats * route.pricePerSeat * 0.7; // 70% driver share
                final tripStatus = _dataService.getTripStatus(route.id);
                final isAccepted = _acceptedRuns.contains(route.id);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _statusBadge(tripStatus),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Details grid
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _infoChip(
                              Icons.schedule,
                              DateFormat('EEE, MMM d • hh:mm a')
                                  .format(route.departureTime),
                            ),
                            _infoChip(
                              Icons.people,
                              '$passengerCount passengers',
                            ),
                            _infoChip(
                              Icons.location_on,
                              route.pickupPoint,
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        // Payout and actions
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payout',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '\$${NumberFormat('#,##0.00').format(payoutPerRun)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  '70% of $takenSeats seats',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),

                            // Accept Run button or Status Toggle
                            if (!isAccepted &&
                                tripStatus == TripStatus.notStarted)
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _acceptedRuns.add(route.id);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Run accepted: ${route.origin} → ${route.destination}',
                                      ),
                                      backgroundColor: AppTheme.successColor,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Accept Run'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successColor,
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
                              ),
                            ),
                            tilePadding: EdgeInsets.zero,
                            children: bookings.map((b) {
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.person, size: 20),
                                title: Text(
                                  b.riderName,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                subtitle: Text(
                                  'Seats: ${b.seatNumbers.join(", ")}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  b.pickupPoint,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
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
          icon: Icon(Icons.schedule, size: 14),
        ),
        ButtonSegment(
          value: TripStatus.inProgress,
          label: Text('In Progress', style: TextStyle(fontSize: 10)),
          icon: Icon(Icons.directions_car, size: 14),
        ),
        ButtonSegment(
          value: TripStatus.completed,
          label: Text('Done', style: TextStyle(fontSize: 10)),
          icon: Icon(Icons.check_circle, size: 14),
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
        color = AppTheme.seatSelected;
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
