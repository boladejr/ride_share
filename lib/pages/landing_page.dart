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

  void _quickSearch(String origin, String destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteSearchPage(
          origin: origin,
          destination: destination,
          date: DateTime.now(),
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
            // Nav bar
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
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverDashboardPage())),
                    ),
                    const SizedBox(width: 8),
                    _navButton(
                      'Admin',
                      Icons.settings_outlined,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelPage())),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Hero Section with pill badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car_outlined, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'Intercity rideshare across Texas',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Get between cities\nby car \u2014 affordably.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.primaryDark, height: 1.15),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Book a seat in a shared car. Fixed routes,\nguaranteed departures, starting at \$25/seat.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textSecondary, height: 1.6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Search Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Find your route', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOrigin,
                    decoration: InputDecoration(
                      labelText: 'Where are you leaving from?',
                      prefixIcon: Icon(Icons.circle_outlined, color: AppTheme.primaryColor, size: 16),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                    ),
                    items: _dataService.cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                    onChanged: (val) => setState(() => _selectedOrigin = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDestination,
                    decoration: InputDecoration(
                      labelText: 'Where are you going?',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryColor, size: 16),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                    ),
                    items: _dataService.cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                    onChanged: (val) => setState(() => _selectedDestination = val),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Select date',
                        prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor, size: 16),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                      ),
                      child: Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate), style: GoogleFonts.inter(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _search,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Text('View prices'), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18)],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Text('500+ seats booked and counting', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary, fontWeight: FontWeight.w500)),

            const SizedBox(height: 40),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _statItem('6', 'Texas cities'),
                  _statDivider(),
                  _statItem('3', 'seats per car'),
                  _statDivider(),
                  _statItem('\$25', 'starting price'),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // How it works section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              color: AppTheme.surfaceColor,
              child: Column(
                children: [
                  Text('How it works', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                  const SizedBox(height: 8),
                  Text('Book a seat in three simple steps', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 28),
                  _howItWorksStep('1', 'Search', 'Pick your origin, destination, and travel date.', Icons.search_outlined),
                  const SizedBox(height: 16),
                  _howItWorksStep('2', 'Select & Pay', 'Choose your seat and pay securely with card.', Icons.event_seat_outlined),
                  const SizedBox(height: 16),
                  _howItWorksStep('3', 'Ride', 'Get your pickup point and track your driver live.', Icons.directions_car_outlined),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Popular Routes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Popular routes', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                  const SizedBox(height: 6),
                  Text('Most booked routes this week', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 18),
                  _popularRouteCard('Austin', 'San Antonio', '\$25', '1h 30m'),
                  const SizedBox(height: 10),
                  _popularRouteCard('Austin', 'Houston', '\$35', '2h 45m'),
                  const SizedBox(height: 10),
                  _popularRouteCard('Dallas', 'Austin', '\$40', '3h 15m'),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Trust / Safety section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text('Why riders choose us', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: _trustCard(Icons.verified_user_outlined, 'Verified drivers', 'Background-checked and reviewed.')),
                    const SizedBox(width: 12),
                    Expanded(child: _trustCard(Icons.schedule_outlined, 'Fixed schedules', 'Guaranteed departure times.')),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _trustCard(Icons.gps_fixed_outlined, 'Live tracking', 'Real-time driver location.')),
                    const SizedBox(width: 12),
                    Expanded(child: _trustCard(Icons.payments_outlined, 'No hidden fees', 'Pay per seat, all-in price.')),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Testimonials
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              color: AppTheme.surfaceColor,
              child: Column(
                children: [
                  Text('What riders are saying', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                  const SizedBox(height: 24),
                  _testimonialCard('"Super easy to book and the driver was on time. Way better than the bus."', 'Sarah M.', 'Austin to San Antonio'),
                  const SizedBox(height: 12),
                  _testimonialCard('"Affordable, comfortable, and I didn\'t have to drive. Will use again."', 'James R.', 'Houston to Austin'),
                  const SizedBox(height: 12),
                  _testimonialCard('"The live tracking feature gave me peace of mind. Great service!"', 'Maria L.', 'Dallas to San Antonio'),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Final CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: AppTheme.primaryDark, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Text('Ready to ride?', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('Book your seat today and travel for less.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scroll up to search for routes!'))),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryDark),
                        child: const Text('Search routes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

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
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.borderColor))),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() => _currentNavIndex = index);
            if (index == 1) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book a trip to see it here!')));
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
        decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 40, color: AppTheme.borderColor);

  Widget _howItWorksStep(String number, String title, String desc, IconData icon) {
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
          Icon(icon, color: AppTheme.textTertiary, size: 22),
        ],
      ),
    );
  }

  Widget _popularRouteCard(String from, String to, String price, String duration) {
    return InkWell(
      onTap: () => _quickSearch(from, to),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderColor)),
        child: Row(
          children: [
            Column(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
              Container(width: 1, height: 20, color: AppTheme.borderColor),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryDark, shape: BoxShape.circle)),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(from, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
                const SizedBox(height: 6),
                Text(to, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(price, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
              Text(duration, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary)),
            ]),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _trustCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _testimonialCard(String quote, String name, String route) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(quote, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.primaryDark, height: 1.5, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(name[0], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
            ),
            const SizedBox(width: 8),
            Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
            const SizedBox(width: 8),
            Text(route, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiary)),
          ]),
        ],
      ),
    );
  }
}
