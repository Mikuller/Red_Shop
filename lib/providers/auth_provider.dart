import 'package:flutter/material.dart';
import 'package:red_shop/models/models.dart';
import 'package:red_shop/services/auth_service.dart';

class ShopAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _userModel;
  bool _isBusy = false;

  UserModel? get userModel => _userModel;
  bool get isBusy => _isBusy;
  bool get isOwner => _userModel?.role == UserRole.owner;

  void setUser(UserModel? user) {
    final previous = _userModel;
    final changed =
        previous?.uid != user?.uid ||
        previous?.active != user?.active ||
        previous?.role != user?.role ||
        previous?.name != user?.name;

    if (!changed) {
      return;
    }

    _userModel = user;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _runBusy(() async {
      await _authService.signIn(email, password);
    });
  }

  Future<void> registerInitialOwner({
    required String name,
    required String email,
    required String password,
  }) async {
    await _runBusy(() async {
      await _authService.registerInitialOwner(
        name: name,
        email: email,
        password: password,
      );
    });
  }

  Future<void> logout() async {
    await _runBusy(() async {
      await _authService.signOut();
      _userModel = null;
    }, notifyAfter: true);
  }

  Future<void> _runBusy(
    Future<void> Function() action, {
    bool notifyAfter = false,
  }) async {
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isBusy = false;
      if (notifyAfter) {
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }
}
