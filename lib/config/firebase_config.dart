import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  // TODO: Replace with your Firebase project config from
  // https://console.firebase.google.com → Project Settings → Your apps → Web
  static const firebaseOptions = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
  );

  static bool get isConfigured =>
      firebaseOptions.apiKey != 'YOUR_API_KEY';
}
