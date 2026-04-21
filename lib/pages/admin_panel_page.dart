import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/route_model.dart';
import '../models/booking_model.dart';
import '../services/mock_data_service.dart';
import '../theme.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dataService = MockDataService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Admin Panel'),
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
                Icon(Icons.admin_panel_settings_outlined,
                    size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Admin',
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.route_outlined, size: 16), text: 'Routes'),
            Tab(icon: Icon(Icons.book_outlined, size: 16), text: 'Bookings'),
            Tab(icon: Icon(Icons.drive_eta_outlined, size: 16), text: 'Drivers'),
            Tab(icon: Icon(Icons.attach_money, size: 16), text: 'Pricing'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats overview cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(child: _statCard('Routes', '${_dataService.routes.length}', Icons.route_outlined, AppTheme.primaryColor)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Bookings', '${_dataService.bookings.length}', Icons.book_outlined, Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Drivers', '${_dataService.drivers.length}', Icons.drive_eta_outlined, AppTheme.successColor)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Revenue', '\$${NumberFormat('#,##0').format(_dataService.bookings.fold<double>(0, (sum, b) => sum + b.totalPrice))}', Icons.attach_money, AppTheme.primaryDark)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRoutesTab(),
                _buildBookingsTab(),
                _buildDriversTab(),
                _buildPricingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== ROUTES TAB =====================
  Widget _buildRoutesTab() {
    final routes = _dataService.routes;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAddRouteDialog(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 18),
                  const SizedBox(width: 8),
                  const Text('Add New Route'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${route.origin} → ${route.destination}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('EEE, MMM d • hh:mm a').format(route.departureTime)} • '
                            '${route.totalSeats} seats • '
                            '\$${NumberFormat('#,##0.00').format(route.pricePerSeat)}/seat',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                      onPressed: () => _showEditRouteDialog(route),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                      onPressed: () => _confirmDeleteRoute(route),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddRouteDialog() {
    final originCtrl = TextEditingController();
    final destCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final seatsCtrl = TextEditingController(text: '3');
    final pickupCtrl = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New Route'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Origin'),
                  items: _dataService.cities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => originCtrl.text = v ?? '',
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Destination'),
                  items: _dataService.cities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => destCtrl.text = v ?? '',
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Departure Time'),
                  subtitle: Text(selectedTime.format(ctx)),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price per Seat (\$)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: seatsCtrl,
                  decoration: const InputDecoration(labelText: 'Passenger Seats'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pickupCtrl,
                  decoration: const InputDecoration(labelText: 'Pickup Point'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (originCtrl.text.isEmpty ||
                    destCtrl.text.isEmpty ||
                    priceCtrl.text.isEmpty) {
                  return;
                }
                final now = DateTime.now();
                final departure = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                final seats = int.tryParse(seatsCtrl.text) ?? 3;
                _dataService.addRoute(RouteModel(
                  id: _dataService.generateRouteId(),
                  origin: originCtrl.text,
                  destination: destCtrl.text,
                  departureTime: departure,
                  duration: const Duration(hours: 3),
                  totalSeats: seats,
                  availableSeats: seats,
                  pricePerSeat: double.tryParse(priceCtrl.text) ?? 0,
                  pickupPoint: pickupCtrl.text.isEmpty
                      ? '${originCtrl.text} Pickup Point'
                      : pickupCtrl.text,
                ));
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRouteDialog(RouteModel route) {
    final priceCtrl =
        TextEditingController(text: route.pricePerSeat.toStringAsFixed(0));
    final seatsCtrl =
        TextEditingController(text: route.totalSeats.toString());
    final pickupCtrl = TextEditingController(text: route.pickupPoint);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit: ${route.origin} → ${route.destination}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price per Seat (\$)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: seatsCtrl,
                decoration: const InputDecoration(labelText: 'Passenger Seats'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pickupCtrl,
                decoration: const InputDecoration(labelText: 'Pickup Point'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _dataService.updateRoute(route.copyWith(
                pricePerSeat: double.tryParse(priceCtrl.text) ?? route.pricePerSeat,
                totalSeats: int.tryParse(seatsCtrl.text) ?? route.totalSeats,
                pickupPoint: pickupCtrl.text,
              ));
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRoute(RouteModel route) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Route?'),
        content: Text(
          'Are you sure you want to delete ${route.origin} → ${route.destination}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _dataService.deleteRoute(route.id);
              setState(() {});
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ===================== BOOKINGS TAB =====================
  Widget _buildBookingsTab() {
    final bookings = _dataService.bookings;
    return bookings.isEmpty
        ? const Center(child: Text('No bookings yet'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.id,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          _paymentBadge(booking.paymentStatus),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _bookingDetail('Rider', booking.riderName),
                      _bookingDetail(
                        'Route',
                        '${booking.origin} → ${booking.destination}',
                      ),
                      _bookingDetail(
                        'Seats',
                        booking.seatNumbers.join(', '),
                      ),
                      _bookingDetail(
                        'Amount',
                        '\$${NumberFormat('#,##0.00').format(booking.totalPrice)}',
                      ),
                      if (booking.paymentStatus == PaymentStatus.paid) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _dataService.cancelBooking(booking.id);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Booking cancelled. Refund initiated via Stripe.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                            icon: const Icon(Icons.cancel, size: 16),
                            label: const Text('Cancel & Refund'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _bookingDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: GoogleFonts.inter(color: AppTheme.textTertiary, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentBadge(PaymentStatus status) {
    Color color;
    String text;
    switch (status) {
      case PaymentStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case PaymentStatus.paid:
        color = AppTheme.successColor;
        text = 'Paid';
        break;
      case PaymentStatus.refunded:
        color = Colors.red;
        text = 'Refunded';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ===================== DRIVERS TAB =====================
  Widget _buildDriversTab() {
    final drivers = _dataService.drivers;
    final routes = _dataService.routes;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driver = drivers[index];
        final driverRoutes = _dataService.getRoutesForDriver(driver.id);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        driver.name[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${driver.phone} • ${driver.email}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${NumberFormat('#,##0.00').format(driver.totalPayout)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          'total payout',
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'Assigned Routes:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                if (driverRoutes.isEmpty)
                  Text(
                    'No routes assigned',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  )
                else
                  ...driverRoutes.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${r.origin} → ${r.destination} @ ${DateFormat('hh:mm a').format(r.departureTime)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Assign route button
                OutlinedButton.icon(
                  onPressed: () {
                    final unassigned = routes
                        .where((r) => r.assignedDriverId == null)
                        .toList();
                    if (unassigned.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No unassigned routes available'),
                        ),
                      );
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Assign Route'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: unassigned
                              .map(
                                (r) => ListTile(
                                  title: Text(
                                    '${r.origin} → ${r.destination}',
                                  ),
                                  subtitle: Text(
                                    DateFormat('hh:mm a')
                                        .format(r.departureTime),
                                  ),
                                  onTap: () {
                                    _dataService.assignDriverToRoute(
                                      driver.id,
                                      r.id,
                                    );
                                    setState(() {});
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${driver.name} assigned to ${r.origin} → ${r.destination}',
                                        ),
                                        backgroundColor: AppTheme.successColor,
                                      ),
                                    );
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Assign Route'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===================== PRICING TAB =====================
  Widget _buildPricingTab() {
    final routes = _dataService.routes;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return Card(
          child: ListTile(
            title: Text(
              '${route.origin} → ${route.destination}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Current: \$${NumberFormat('#,##0.00').format(route.pricePerSeat)}/seat',
              style: const TextStyle(fontSize: 13),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                final priceCtrl = TextEditingController(
                  text: route.pricePerSeat.toStringAsFixed(0),
                );
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Update Price'),
                    content: TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Price per Seat (\$)',
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final newPrice = double.tryParse(priceCtrl.text);
                          if (newPrice != null && newPrice > 0) {
                            _dataService.updateRoute(
                              route.copyWith(pricePerSeat: newPrice),
                            );
                            setState(() {});
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Price updated to \$${NumberFormat('#,##0.00').format(newPrice)}',
                                ),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          }
                        },
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Edit Price'),
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textTertiary)),
        ],
      ),
    );
  }
}
