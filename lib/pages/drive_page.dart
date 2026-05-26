import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../theme.dart';

class DrivePage extends StatefulWidget {
  final VoidCallback onSignUpTap;

  const DrivePage({super.key, required this.onSignUpTap});

  @override
  State<DrivePage> createState() => _DrivePageState();
}

class _DrivePageState extends State<DrivePage> {
  final _auth = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _licenseController = TextEditingController();
  bool _submitted = false;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  void _submitApplication() {
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
    _auth.signUp(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      role: UserRole.driver,
    );

    setState(() => _submitted = true);
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
                      Scrollable.ensureVisible(
                        context,
                        duration: const Duration(milliseconds: 500),
                      );
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
            _buildAlreadyDriverState()
          else
            _buildApplicationForm(),

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

  Widget _buildAlreadyDriverState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.verified_outlined, color: AppTheme.primaryColor, size: 40),
            const SizedBox(height: 16),
            Text('You\'re already a driver!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
            const SizedBox(height: 8),
            Text(
              'Visit your dashboard to manage routes and trips.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
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
