import 'package:flutter/material.dart';
import '../widgets/app_nav_bar.dart';
import 'rideshare_page.dart';
import 'ride_page.dart';
import 'drive_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentPageIndex = 0; // 0=Rideshare, 1=Ride, 2=Drive

  void _navigateTo(int index) {
    setState(() => _currentPageIndex = index);
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(
          onSuccess: () {
            Navigator.pop(context);
            setState(() {});
          },
          onSignUpTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SignUpPage(
                  onSuccess: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  onLoginTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginPage(
                          onSuccess: () {
                            Navigator.pop(context);
                            setState(() {});
                          },
                          onSignUpTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpPage(
          onSuccess: () {
            Navigator.pop(context);
            setState(() {});
          },
          onLoginTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LoginPage(
                  onSuccess: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  onSignUpTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          onLogout: () {
            Navigator.pop(context);
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppNavBar(
            currentIndex: _currentPageIndex,
            onNavTap: _navigateTo,
            onLoginTap: _openLogin,
            onSignUpTap: _openSignUp,
            onProfileTap: _openProfile,
          ),
          Expanded(
            child: _buildPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_currentPageIndex) {
      case 1:
        return const RidePage();
      case 2:
        return DrivePage(onSignUpTap: _openSignUp);
      case 0:
      default:
        return RidesharePage(
          onRideTap: () => _navigateTo(1),
          onDriveTap: () => _navigateTo(2),
        );
    }
  }
}
