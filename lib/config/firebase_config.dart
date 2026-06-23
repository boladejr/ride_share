import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  // TODO: Replace with your Firebase project config from
  // https://console.firebase.google.com → Project Settings → Your apps → Web
  static const firebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyAtU-_6Kb1szdpNApT5ZgzoQi7O52rjWow',
    appId: '1:79487487715:web:371ca3b204c9784de93fd6',
    messagingSenderId: '79487487715',
    projectId: 'ridetest-63fae',
    authDomain: 'ridetest-63fae.firebaseapp.com',
    storageBucket: 'ridetest-63fae.firebasestorage.app',
    measurementId: 'G-74VDE03YXZ',
  );

  static bool get isConfigured =>
      firebaseOptions.apiKey != 'YOUR_API_KEY';
}
