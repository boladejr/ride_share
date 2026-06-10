import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_data_service.dart';
import '../models/user_model.dart';
import '../theme.dart';

class DrivePage extends StatefulWidget {
  final VoidCallback onSignUpTap;

  const DrivePage({super.key, required this.onSignUpTap});

  @override
  State<DrivePage> createState() => _DrivePageState();
}

class _DrivePageState extends State<DrivePage> {
  final _auth = FirebaseAuthService();
  final _dataService = FirestoreDataService();
  List<Map<String, dynamic>>? _pending;
  List<Map<String, dynamic>>? _assigned;
  bool _loadingPending = false;
  final Set<String> _claiming = {};
  final Set<String> _updatingStatus = {};
  StreamSubscription? _pendingSub;
  StreamSubscription? _assignedSub;
  final GlobalKey _formKey = GlobalKey();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _licenseController = TextEditingController();
  bool _submitted = false;
  bool _agreeTerms = false;

  @override
  void initState() {
    super.initState();
    if (_auth.isLoggedIn && _auth.isDriver) {
      _subscribeFeeds();
    }
  }

  /// Subscribe to the live driver feeds (assigned rides + open claim queue) so
  /// the Drive page updates in real time as rides are booked, assigned, claimed
  /// or advanced — no manual refresh needed.
  void _subscribeFeeds() {
    setState(() => _loadingPending = true);
    _pendingSub?.cancel();
    _assignedSub?.cancel();
    _pendingSub = _dataService.pendingAssignmentsStream().listen((items) {
      if (!mounted) return;
      setState(() {
        _pending = items;
        _loadingPending = false;
      });
    });
    _assignedSub = _dataService
        .assignedRidesStream(_auth.currentUser?.id ?? '')
        .listen((mine) {
      if (!mounted) return;
      setState(() => _assigned = mine);
    });
  }

  Future<void> _claim(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    setState(() => _claiming.add(id));
    final ok = await _dataService.claimAssignment(
      assignmentId: id,
      bookingDocId: item['bookingDocId'] as String? ?? '',
      driverId: _auth.currentUser?.id ?? '',
      driverName: _auth.currentUser?.name ?? 'Driver',
    );
    if (!mounted) return;
    setState(() => _claiming.remove(id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Ride claimed — it\'s now assigned to you.'
            : 'That ride was already claimed by another driver.'),
      ),
    );
    // Live streams refresh the lists automatically.
  }

  Future<void> _updateStatus(Map<String, dynamic> item, String status) async {
    final id = item['id'] as String;
    setState(() => _updatingStatus.add(id));
    final ok = await _dataService.updateTripStatus(
      bookingDocId: id,
      driverId: _auth.currentUser?.id ?? '',
      status: status,
    );
    if (!mounted) return;
    setState(() => _updatingStatus.remove(id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (status == 'completed'
                ? 'Trip completed.'
                : 'Marked as picked up.')
            : 'Could not update the trip. Please try again.'),
      ),
    );
    // Live streams refresh the lists automatically.
  }

  @override
  void dispose() {
    _pendingSub?.cancel();
    _assignedSub?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _vehicleController.text.isEmpty ||
        _licenseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms')),
      );
      return;
    }

    // Sign up as driver
    await _auth.signUp(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: 'driver123',
      role: UserRole.driver,
    );

    // Add the new driver to the active assignment pool immediately so they can
    // start being matched to rides (no approval step).
    await _dataService.saveDriverApplication(
      userId: _auth.currentUser?.id ?? '',
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      vehicleInfo: _vehicleController.text,
      licenseNumber: _licenseController.text,
    );

    if (!mounted) return;
    setState(() => _submitted = true);
    // They're now an active driver — start their live feeds.
    if (_auth.isLoggedIn && _auth.isDriver) {
      _subscribeFeeds();
    }

    // Retroactively pull in any already-pending rides headed their way.
    final matched = await _dataService.retroMatchDriver(
      driverId: _auth.currentUser?.id ?? '',
      driverName: _auth.currentUser?.name ?? 'Driver',
    );
    if (mounted && matched > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'You were matched with $matched pending ride${matched != 1 ? 's' : ''}.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 28),
            color: AppTheme.primaryDark,
            child: Column(
              children: [
                Text(
                  'Drive with RideShare',
                  style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
                ),
                const SizedBox(height: 12),
                Text(
                  'Earn money on your own schedule. Drive between\nTexas cities and keep more of your earnings.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.white70, height: 1.6),
                ),
                const SizedBox(height: 28),
                if (!_auth.isLoggedIn && !_submitted)
                  ElevatedButton(
                    onPressed: () {
                      final ctx = _formKey.currentContext;
                      if (ctx != null) {
                        Scrollable.ensureVisible(
                          ctx,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          alignment: 0.05,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Apply to drive'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Earnings highlights
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text('Why drive with us?', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                const SizedBox(height: 28),
                Row(children: [
                  Expanded(child: _benefitCard(Icons.attach_money, 'Great earnings', 'Earn \$25\u2013\$50 per trip. Average drivers make \$800+/week.')),
                  const SizedBox(width: 12),
                  Expanded(child: _benefitCard(Icons.schedule_outlined, 'Flexible schedule', 'Choose when you drive. Pick routes that work for you.')),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _benefitCard(Icons.route_outlined, 'Fixed routes', 'No random pickups. Drive set routes between cities.')),
                  const SizedBox(width: 12),
                  Expanded(child: _benefitCard(Icons.shield_outlined, 'Insurance covered', 'Full ride insurance for you and your passengers.')),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // How to start
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
            color: AppTheme.surfaceColor,
            child: Column(
              children: [
                Text('How to get started', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                const SizedBox(height: 28),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      _stepCard('1', 'Apply online', 'Fill out the application below with your details and vehicle information.'),
                      const SizedBox(height: 12),
                      _stepCard('2', 'Background check', 'We verify your driving record and run a background check.'),
                      const SizedBox(height: 12),
                      _stepCard('3', 'Get approved', 'Once approved, start accepting rides and earning money.'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Application Form or Success
          if (_submitted)
            _buildSuccessState()
          else if (_auth.isLoggedIn && _auth.isDriver)
            _buildDriverDashboard()
          else
            KeyedSubtree(key: _formKey, child: _buildApplicationForm()),

          const SizedBox(height: 48),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 12),
                Text('\u00a9 2026 RideShare. All rights reserved.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: AppTheme.successColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Application submitted!', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
            const SizedBox(height: 8),
            Text(
              'We\'ll review your application and get back to you within 24\u201348 hours.\nYou\'re now logged in as a driver.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverDashboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.verified_outlined,
                      color: AppTheme.primaryColor, size: 40),
                  const SizedBox(height: 16),
                  Text('You\'re already a driver!',
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark)),
                  const SizedBox(height: 8),
                  Text(
                    'Claim rides that need a driver below.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildAssignedSection(),
            _buildPendingQueue(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedSection() {
    final rides = _assigned ?? [];
    if (rides.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Your assigned rides',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark)),
        const SizedBox(height: 8),
        ...rides.map(_assignedCard),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _assignedCard(Map<String, dynamic> item) {
    final origin = item['origin'] ?? '';
    final destination = item['destination'] ?? '';
    final pickup = item['pickupAddress'] as String?;
    final dropoff = item['dropoffAddress'] as String?;
    final seats = item['seats'] as int? ?? 0;
    final price = (item['totalPrice'] as num?)?.toDouble() ?? 0;
    final rider = item['riderName'] as String?;
    final departure = (item['departureTime'] as dynamic)?.toDate() as DateTime?;
    final id = item['id'] as String;
    final status = (item['status'] as String?) ?? 'confirmed';
    final busy = _updatingStatus.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: Colors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$origin  \u2192  $destination',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark)),
              ),
              _statusBadge(status),
            ],
          ),
          if (rider != null && rider.isNotEmpty) ...[
            const SizedBox(height: 10),
            _riderRow(rider),
          ],
          if (departure != null) ...[
            const SizedBox(height: 8),
            _infoLine(Icons.schedule_outlined,
                DateFormat('EEE, MMM d \u00b7 hh:mm a').format(departure)),
          ],
          if (pickup != null && pickup.isNotEmpty)
            _infoLine(Icons.location_on_outlined, pickup),
          if (dropoff != null && dropoff.isNotEmpty)
            _infoLine(Icons.flag_outlined, dropoff),
          _infoLine(Icons.event_seat_outlined,
              '$seats seat${seats != 1 ? 's' : ''}  \u00b7  \$${price.toStringAsFixed(2)}'),
          _lifecycleAction(item, status, busy),
        ],
      ),
    );
  }

  /// Picked-up / completed buttons (or a done note) for an assigned ride.
  Widget _lifecycleAction(Map<String, dynamic> item, String status, bool busy) {
    if (status == 'completed') {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
            const SizedBox(width: 6),
            Text('Trip completed',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700)),
          ],
        ),
      );
    }
    final isPickedUp = status == 'in_progress';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: busy
              ? null
              : () => _updateStatus(
                  item, isPickedUp ? 'completed' : 'in_progress'),
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(isPickedUp
                  ? Icons.flag_outlined
                  : Icons.directions_car_outlined),
          label: Text(isPickedUp ? 'Mark completed' : 'Mark picked up'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  /// Small coloured pill reflecting the booking's lifecycle status.
  Widget _statusBadge(String status) {
    late final String label;
    late final MaterialColor color;
    switch (status) {
      case 'in_progress':
        label = 'Picked up';
        color = Colors.blue;
        break;
      case 'completed':
        label = 'Completed';
        color = Colors.grey;
        break;
      default:
        label = 'Assigned to you';
        color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.shade800)),
    );
  }

  /// Prominent "who you're picking up" row for the driver.
  Widget _riderRow(String rider) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          child: Icon(Icons.person, size: 16, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rider',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textTertiary)),
              Text(rider,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingQueue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Rides needing a driver',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark)),
            ),
            IconButton(
              onPressed: _loadingPending ? null : _subscribeFeeds,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              color: AppTheme.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingPending)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_pending == null || _pending!.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined,
                    color: AppTheme.textTertiary, size: 32),
                const SizedBox(height: 12),
                Text('No rides need a driver right now.',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          )
        else
          ..._pending!.map(_pendingCard),
      ],
    );
  }

  Widget _pendingCard(Map<String, dynamic> item) {
    final origin = item['origin'] ?? '';
    final destination = item['destination'] ?? '';
    final pickup = item['pickupAddress'] as String?;
    final dropoff = item['dropoffAddress'] as String?;
    final seats = item['seats'] as int? ?? 0;
    final price = (item['totalPrice'] as num?)?.toDouble() ?? 0;
    final rider = item['riderName'] as String?;
    final departure = (item['departureTime'] as dynamic)?.toDate() as DateTime?;
    final id = item['id'] as String;
    final claiming = _claiming.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: Colors.orange, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$origin  \u2192  $destination',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Needs driver',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800)),
              ),
            ],
          ),
          if (departure != null) ...[
            const SizedBox(height: 8),
            _infoLine(Icons.schedule_outlined,
                DateFormat('EEE, MMM d \u00b7 hh:mm a').format(departure)),
          ],
          if (pickup != null && pickup.isNotEmpty)
            _infoLine(Icons.location_on_outlined, pickup),
          if (dropoff != null && dropoff.isNotEmpty)
            _infoLine(Icons.flag_outlined, dropoff),
          _infoLine(Icons.event_seat_outlined,
              '$seats seat${seats != 1 ? 's' : ''}  \u00b7  \$${price.toStringAsFixed(2)}'),
          if (rider != null && rider.isNotEmpty) ...[
            const SizedBox(height: 10),
            _riderRow(rider),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: claiming ? null : () => _claim(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: claiming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Claim this ride'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Driver application', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
              const SizedBox(height: 6),
              Text('Fill out the form to get started', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 24),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _vehicleController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle (year, make, model)',
                  prefixIcon: Icon(Icons.directions_car_outlined, size: 18),
                  hintText: 'e.g. 2022 Toyota Camry',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'Driver\'s license number',
                  prefixIcon: Icon(Icons.badge_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Checkbox(
                    value: _agreeTerms,
                    onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                    activeColor: AppTheme.primaryColor,
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the terms of service and driver agreement',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitApplication,
                  child: const Text('Submit application'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefitCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _stepCard(String number, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(number, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryColor))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
