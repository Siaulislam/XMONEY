import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const _access = 'xm_access';
  static const _refresh = 'xm_refresh';
  static const _user = 'xm_user';

  final _store = const FlutterSecureStorage();

  Future<String?> get accessToken => _store.read(key: _access);
  Future<String?> get refreshToken => _store.read(key: _refresh);

  Future<bool> get isLoggedIn async => (await accessToken) != null;

  Future<void> saveTokens(Map<String, dynamic> data) async {
    if (data['access_token'] != null) await _store.write(key: _access, value: data['access_token'] as String);
    if (data['refresh_token'] != null) await _store.write(key: _refresh, value: data['refresh_token'] as String);
    if (data['user'] != null) await _store.write(key: _user, value: jsonEncode(data['user']));
  }

  Future<void> clear() async {
    await _store.deleteAll();
  }
}
