import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;

  String? get token => _token;

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    _token = token;
    notifyListeners(); // Notifica os 'ouvintes' que o estado mudou
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _token = null;
    notifyListeners();
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    _token = await _storage.read(key: 'auth_token');
    return _token;
  }
}