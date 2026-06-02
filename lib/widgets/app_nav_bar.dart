import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_auth_service.dart';
import '../theme.dart';

class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final VoidCallback onLoginTap;
  final VoidCallback onSignUpTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onTripsTap;
  final VoidCallback? onLogoutTap;

  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
    required this.onLoginTap,
    required this.onSignUpTap,
    this.onProfileTap,
    this.onTripsTap,
    this.onLogoutTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuthService();

    return Container(
      height: 64,
      color: AppTheme.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Logo
              GestureDetector(
                onTap: () => onNavTap(0),
                child: Text(
                  'RideShare',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              // Nav items
              _navItem('Ride', 1, currentIndex == 1),
              const SizedBox(width: 4),
              _navItem('Drive', 2, currentIndex == 2),
              const SizedBox(width: 4),
              _navItem('About', 0, currentIndex == 0),
              const Spacer(),
              // Right side
              if (auth.isLoggedIn) ...[
                _navItem('My Trips', 1, false, onTapOverride: onTripsTap),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Account',
                  offset: const Offset(0, 48),
                  onSelected: (value) {
                    switch (value) {
                      case 'trips':
                        onTripsTap?.call();
                        break;
                      case 'profile':
                        onProfileTap?.call();
                        break;
                      case 'logout':
                        onLogoutTap?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'trips',
                      child: ListTile(
                        leading: Icon(Icons.confirmation_number_outlined),
                        title: Text('My Trips'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'profile',
                      child: ListTile(
                        leading: Icon(Icons.person_outline),
                        title: Text('Profile'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Log out'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            auth.currentUser!.name[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          auth.currentUser!.name.split(' ').first,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                TextButton(
                  onPressed: onLoginTap,
                  child: Text(
                    'Log in',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onSignUpTap,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    'Sign up',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(String label, int index, bool isActive, {VoidCallback? onTapOverride}) {
    return InkWell(
      onTap: onTapOverride ?? () => onNavTap(index),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
