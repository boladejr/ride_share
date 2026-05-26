import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class RidesharePage extends StatelessWidget {
  final VoidCallback onRideTap;
  final VoidCallback onDriveTap;

  const RidesharePage({
    super.key,
    required this.onRideTap,
    required this.onDriveTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 28),
            color: AppTheme.surfaceColor,
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
                const SizedBox(height: 24),
                Text(
                  'Get between cities\nby car \u2014 affordably.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: AppTheme.primaryDark, height: 1.15),
                ),
                const SizedBox(height: 16),
                Text(
                  'Book a seat in a shared car. Fixed routes, guaranteed\ndepartures, starting at \$25/seat.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: onRideTap,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Text('Book a ride'), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18)],
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: onDriveTap,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      ),
                      child: const Text('Drive with us'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _statItem('6+', 'Texas cities'),
                _statDivider(),
                _statItem('3', 'seats per car'),
                _statDivider(),
                _statItem('\$25', 'starting price'),
                _statDivider(),
                _statItem('500+', 'trips completed'),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // How it works
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            color: Colors.white,
            child: Column(
              children: [
                Text('How it works', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                const SizedBox(height: 8),
                Text('Book a seat in three simple steps', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 32),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    children: [
                      _howItWorksStep('1', 'Search your route', 'Enter your pickup address, destination, and travel date. We\'ll find available rides on your route.', Icons.search_outlined),
                      const SizedBox(height: 16),
                      _howItWorksStep('2', 'Select & Pay', 'Choose your seat and pay securely. Get instant confirmation with your pickup details.', Icons.event_seat_outlined),
                      const SizedBox(height: 16),
                      _howItWorksStep('3', 'Ride', 'Meet at your pickup point and enjoy a comfortable ride to your destination.', Icons.directions_car_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Popular Routes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Popular routes', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                const SizedBox(height: 6),
                Text('Most booked routes this week', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 20),
                _popularRouteCard('Austin', 'San Antonio', '\$25', '1h 30m'),
                const SizedBox(height: 10),
                _popularRouteCard('Austin', 'Houston', '\$35', '2h 45m'),
                const SizedBox(height: 10),
                _popularRouteCard('Dallas', 'Austin', '\$40', '3h 15m'),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Trust / Safety
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text('Why riders choose us', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                const SizedBox(height: 28),
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

          const SizedBox(height: 48),

          // Testimonials
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            color: AppTheme.surfaceColor,
            child: Column(
              children: [
                Text('What riders are saying', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                const SizedBox(height: 28),
                _testimonialCard('"Super easy to book and the driver was on time. Way better than the bus."', 'Sarah M.', 'Austin to San Antonio'),
                const SizedBox(height: 12),
                _testimonialCard('"Affordable, comfortable, and I didn\'t have to drive. Will use again."', 'James R.', 'Houston to Austin'),
                const SizedBox(height: 12),
                _testimonialCard('"The live tracking feature gave me peace of mind. Great service!"', 'Maria L.', 'Dallas to San Antonio'),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Final CTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: AppTheme.primaryDark, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Text('Ready to ride?', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Book your seat today and travel for less.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onRideTap,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryDark),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text('Search routes'),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(number, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryColor))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
              ],
            ),
          ),
          Icon(icon, color: AppTheme.textTertiary, size: 24),
        ],
      ),
    );
  }

  Widget _popularRouteCard(String from, String to, String price, String duration) {
    return Container(
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
    );
  }

  Widget _trustCard(IconData icon, String title, String subtitle) {
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
