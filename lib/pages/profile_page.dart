import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_data_service.dart';
import '../models/user_model.dart';
import '../theme.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;
  final bool scrollToBookings;

  const ProfilePage({super.key, required this.onLogout, this.scrollToBookings = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuthService();
  final _firestoreService = FirestoreDataService();
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  final _scrollController = ScrollController();
  final _bookingsKey = GlobalKey();

  List<Map<String, dynamic>> _bookings = [];
  bool _loadingBookings = true;
  StreamSubscription? _bookingsSub;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser!;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone);
    _addressController = TextEditingController(text: user.address ?? '');
    _loadBookings();
  }

  void _maybeScrollToBookings() {
    if (!widget.scrollToBookings) return;
    final ctx = _bookingsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Subscribe to the rider's bookings so My Trips updates in real time (e.g.
  /// the status badge advances Confirmed → Picked up → Completed as the driver
  /// taps, with no manual refresh).
  void _loadBookings() {
    final user = _auth.currentUser;
    if (user == null) return;
    _bookingsSub?.cancel();
    _bookingsSub = _firestoreService.userBookingsStream(user.id).listen(
      (bookings) {
        if (!mounted) return;
        setState(() {
          _bookings = bookings;
          _loadingBookings = false;
        });
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _maybeScrollToBookings());
      },
      onError: (_) {
        if (mounted) setState(() => _loadingBookings = false);
      },
    );
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _auth.updateProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      clearAddress: _addressController.text.isEmpty,
    );
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: Text('RideShare', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              color: AppTheme.surfaceColor,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user.name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.role == UserRole.driver ? 'Driver' : 'Rider',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Profile details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Profile details', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
                          TextButton(
                            onPressed: () {
                              if (_isEditing) {
                                _save();
                              } else {
                                setState(() => _isEditing = true);
                              }
                            },
                            child: Text(
                              _isEditing ? 'Save' : 'Edit',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_isEditing) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline, size: 18)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.phone_outlined, size: 18)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Home address', prefixIcon: Icon(Icons.home_outlined, size: 18)),
                        ),
                      ] else ...[
                        _profileRow(Icons.email_outlined, 'Email', user.email),
                        const SizedBox(height: 14),
                        _profileRow(Icons.phone_outlined, 'Phone', user.phone),
                        const SizedBox(height: 14),
                        _profileRow(Icons.home_outlined, 'Address', user.address ?? 'Not set'),
                        const SizedBox(height: 14),
                        _profileRow(Icons.badge_outlined, 'Role', user.role == UserRole.driver ? 'Driver' : 'Rider'),
                        const SizedBox(height: 14),
                        _profileRow(Icons.calendar_today_outlined, 'Member since', _formatDate(user.createdAt)),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // My Bookings section
            Padding(
              key: _bookingsKey,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  padding: const EdgeInsets.all(24),
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
                          Icon(Icons.confirmation_number_outlined, size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text('My Bookings', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_loadingBookings)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_bookings.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Icon(Icons.directions_car_outlined, size: 40, color: AppTheme.textTertiary),
                                const SizedBox(height: 12),
                                Text(
                                  'No bookings yet',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Book a ride to see it here',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...(_bookings.map((booking) => _bookingCard(booking))),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Log out'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> booking) {
    final origin = booking['origin'] ?? '';
    final destination = booking['destination'] ?? '';
    final status = booking['status'] ?? 'confirmed';
    final totalPrice = (booking['totalPrice'] as num?)?.toDouble() ?? 0;
    final seats = booking['seats'] as int? ?? 0;
    final seatNumbers = booking['seatNumbers'] as List<dynamic>?;
    final createdAt = booking['createdAt'];
    final pickupAddress = booking['pickupAddress'] as String?;
    final dropoffAddress = booking['dropoffAddress'] as String?;
    final driverName = booking['assignedDriverName'] as String?;

    DateTime? bookingDate;
    if (createdAt != null) {
      try {
        bookingDate = createdAt.toDate();
      } catch (_) {}
    }

    final String statusLabel;
    final Color statusColor;
    switch (status) {
      case 'in_progress':
        statusLabel = 'Picked up';
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusLabel = 'Completed';
        statusColor = AppTheme.textSecondary;
        break;
      case 'cancelled':
        statusLabel = 'Cancelled';
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusLabel = 'Confirmed';
        statusColor = AppTheme.successColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  origin.isNotEmpty && destination.isNotEmpty
                      ? '$origin  \u2192  $destination'
                      : 'Ride Booking',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (seats > 0) ...[
                Icon(Icons.event_seat_outlined, size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 4),
                Text(
                  seatNumbers != null
                      ? 'Seats ${seatNumbers.join(', ')}'
                      : '$seats seat${seats != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 16),
              ],
              if (totalPrice > 0) ...[
                Icon(Icons.attach_money, size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 2),
                Text(
                  NumberFormat('#,##0.00').format(totalPrice),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
                ),
              ],
            ],
          ),
          if (pickupAddress != null && pickupAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    pickupAddress,
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (dropoffAddress != null && dropoffAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dropoffAddress,
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (driverName != null && driverName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'Driver: $driverName',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ],
          if (bookingDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy \u2022 h:mm a').format(bookingDate),
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textTertiary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiary)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primaryDark)),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
