import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/mock_data_service.dart';
import '../theme.dart';
import 'route_search_page.dart';
import 'driver_dashboard_page.dart';
import 'admin_panel_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _dataService = MockDataService();
  String? _selectedOrigin;
  String? _selectedDestination;
  DateTime _selectedDate = DateTime.now();
  int _currentNavIndex = 0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _search() {
    if (_selectedOrigin == null || _selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select origin and destination')),
      );
      return;
    }
    if (_selectedOrigin == _selectedDestination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Origin and destination cannot be the same')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteSearchPage(
          origin: _selectedOrigin!,
          destination: _selectedDestination!,
          date: _selectedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top nav bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    Text(
                      'RideShare',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    _navButton(
                      'Driver',
                      Icons.drive_eta_outlined,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverDashboardPage()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _navButton(
                      'Admin',
                      Icons.settings_outlined,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dotted separator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _dottedLine(),
            ),

            // Hero Section — centered, clean
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    'Share Rides\nAcross Texas.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Book a seat in minutes — fixed routes,\nguaranteed departures, affordable prices.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Search Card — clean, bordered
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find your route',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Origin
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOrigin,
                    decoration: InputDecoration(
                      labelText: 'Origin',
                      prefixIcon: Icon(Icons.circle_outlined, color: AppTheme.primaryColor, size: 18),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                    ),
                    items: _dataService.cities.map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedOrigin = val),
                  ),
                  const SizedBox(height: 14),

                  // Destination
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDestination,
                    decoration: InputDecoration(
                      labelText: 'Destination',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryColor, size: 18),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                    ),
                    items: _dataService.cities.map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedDestination = val),
                  ),
                  const SizedBox(height: 14),

                  // Date
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor, size: 18),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                      ),
                      child: Text(
                        DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                        style: GoogleFonts.inter(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _search,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Search Routes'),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dotted separator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: _dottedLine(),
            ),

            // Features section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'Why RideShare?',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          Icons.schedule_outlined,
                          'Fixed Schedules',
                          'Guaranteed departures.',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFeatureCard(
                          Icons.event_seat_outlined,
                          'Reserve Seats',
                          'Pick your exact seat.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeatureCard(
                          Icons.location_on_outlined,
                          'Live Tracking',
                          'Real-time ride location.',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFeatureCard(
                          Icons.payments_outlined,
                          'Transparent',
                          'No hidden fees.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderColor)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() => _currentNavIndex = index);
            if (index == 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Book a trip to see it here!')),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'My Trips'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dottedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dotCount = (constraints.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dotCount, (index) {
            return Container(
              width: 3,
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
