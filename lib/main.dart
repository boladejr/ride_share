import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_config.dart';
import 'services/firebase_auth_service.dart';
import 'theme.dart';
import 'pages/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (FirebaseConfig.isConfigured) {
    await Firebase.initializeApp(options: FirebaseConfig.firebaseOptions);
    await FirebaseAuthService().checkCurrentUser();
  }

  runApp(const RideShareApp());
}

class RideShareApp extends StatelessWidget {
  const RideShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideShare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}
