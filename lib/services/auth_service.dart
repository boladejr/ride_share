import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isDriver => _currentUser?.role == UserRole.driver;

  final List<UserModel> _registeredUsers = [
    UserModel(
      id: 'user_1',
      name: 'Sarah Mitchell',
      email: 'sarah@example.com',
      phone: '+1 (512) 555-0101',
      role: UserRole.rider,
      address: '1200 Barton Springs Rd, Austin, TX 78704',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    UserModel(
      id: 'driver_1',
      name: 'Carlos Rivera',
      email: 'carlos@rideshare.com',
      phone: '+1 (512) 555-0147',
      role: UserRole.driver,
      address: '800 Brazos St, Austin, TX 78701',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
  ];

  List<UserModel> get registeredUsers => List.unmodifiable(_registeredUsers);

  bool login(String email, String password) {
    try {
      final user = _registeredUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  UserModel signUp({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    String? address,
  }) {
    final user = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: role,
      address: address,
      createdAt: DateTime.now(),
    );
    _registeredUsers.add(user);
    _currentUser = user;
    notifyListeners();
    return user;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? phone,
    String? address,
    bool clearAddress = false,
  }) {
    if (_currentUser == null) return;
    final current = _currentUser!;
    _currentUser = UserModel(
      id: current.id,
      name: name ?? current.name,
      email: current.email,
      phone: phone ?? current.phone,
      role: current.role,
      profileImageUrl: current.profileImageUrl,
      address: clearAddress ? null : (address ?? current.address),
      createdAt: current.createdAt,
    );
    final index = _registeredUsers.indexWhere((u) => u.id == _currentUser!.id);
    if (index != -1) {
      _registeredUsers[index] = _currentUser!;
    }
    notifyListeners();
  }
}
