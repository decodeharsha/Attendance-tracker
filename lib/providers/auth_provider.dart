import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;

  Future<void> login(String id, String password, String role) async {
    try {
      final data = await ApiService().login(id, password, role);
      _user = User.fromJson(data['user']);
      _token = data['token'];
      // Store token in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      notifyListeners();
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      _user = null;
      _token = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
      // Handle error gracefully, e.g., notify user or retry
    }
  }

  Future<void> refreshUser() async {
    try {
      print('Refreshing user data...');
      final data = await ApiService().getCurrentUser();
      print('Received user data: $data');
      
      if (data['user'] == null) {
        throw Exception('Invalid user data received');
      }
      
      _user = User.fromJson(data['user']);
      print('User data refreshed successfully: ${_user?.id}');
      notifyListeners();
    } catch (e) {
      print('Refresh user error: $e');
      if (e.toString().contains('Authentication failed') || 
          e.toString().contains('token not found')) {
        // Clear user data if authentication failed
        _user = null;
        _token = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        notifyListeners();
      }
      rethrow;
    }
  }
}