import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class FirebaseAuthService extends ChangeNotifier {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final AuthService _mockAuth = AuthService();
  fb.FirebaseAuth? _firebaseAuth;
  FirebaseFirestore? _firestore;
  UserModel? _currentUser;

  bool get _useFirebase => FirebaseConfig.isConfigured;

  UserModel? get currentUser => _useFirebase ? _currentUser : _mockAuth.currentUser;
  bool get isLoggedIn => _useFirebase ? _currentUser != null : _mockAuth.isLoggedIn;
  bool get isDriver => currentUser?.role == UserRole.driver;

  void _initFirebase() {
    _firebaseAuth ??= fb.FirebaseAuth.instance;
    _firestore ??= FirebaseFirestore.instance;
  }

  Future<bool> login(String email, String password) async {
    if (!_useFirebase) {
      final result = _mockAuth.login(email, password);
      notifyListeners();
      return result;
    }

    _initFirebase();
    try {
      final credential = await _firebaseAuth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _loadUserProfile(credential.user!.uid);
        notifyListeners();
        return true;
      }
      return false;
    } on fb.FirebaseAuthException {
      return false;
    }
  }

  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? address,
  }) async {
    if (!_useFirebase) {
      final user = _mockAuth.signUp(
        name: name,
        email: email,
        phone: phone,
        role: role,
        address: address,
      );
      notifyListeners();
      return user;
    }

    _initFirebase();
    try {
      final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) return null;

      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        address: address,
        createdAt: DateTime.now(),
      );

      await _firestore!.collection('users').doc(user.id).set({
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'role': user.role == UserRole.driver ? 'driver' : 'rider',
        'address': user.address,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _currentUser = user;
      notifyListeners();
      return user;
    } on fb.FirebaseAuthException {
      return null;
    }
  }

  Future<void> logout() async {
    if (!_useFirebase) {
      _mockAuth.logout();
      notifyListeners();
      return;
    }

    _initFirebase();
    await _firebaseAuth!.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
    bool clearAddress = false,
  }) async {
    if (!_useFirebase) {
      _mockAuth.updateProfile(
        name: name,
        phone: phone,
        address: address,
        clearAddress: clearAddress,
      );
      notifyListeners();
      return;
    }

    if (_currentUser == null) return;
    _initFirebase();

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (clearAddress) {
      updates['address'] = null;
    } else if (address != null) {
      updates['address'] = address;
    }

    await _firestore!.collection('users').doc(_currentUser!.id).update(updates);

    _currentUser = UserModel(
      id: _currentUser!.id,
      name: name ?? _currentUser!.name,
      email: _currentUser!.email,
      phone: phone ?? _currentUser!.phone,
      role: _currentUser!.role,
      profileImageUrl: _currentUser!.profileImageUrl,
      address: clearAddress ? null : (address ?? _currentUser!.address),
      createdAt: _currentUser!.createdAt,
    );
    notifyListeners();
  }

  Future<void> _loadUserProfile(String uid) async {
    final doc = await _firestore!.collection('users').doc(uid).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    _currentUser = UserModel(
      id: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] == 'driver' ? UserRole.driver : UserRole.rider,
      address: data['address'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Future<void> checkCurrentUser() async {
    if (!_useFirebase) return;
    _initFirebase();
    final user = _firebaseAuth!.currentUser;
    if (user != null) {
      await _loadUserProfile(user.uid);
      notifyListeners();
    }
  }
}
