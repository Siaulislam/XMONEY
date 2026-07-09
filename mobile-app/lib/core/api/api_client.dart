import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'session_manager.dart';

class ApiClient {
  ApiClient(this.session);

  final SessionManager session;
  String _baseUrl = 'http://localhost:8080';
  final _deviceId = const Uuid().v4();

  Future<void> loadConfig() async {
    try {
      final raw = await rootBundle.loadString('assets/config.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _baseUrl = (json['apiBaseUrl'] as String).replaceAll(RegExp(r'/$'), '');
    } catch (_) {}
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<Map<String, dynamic>> get(String path) => _request('GET', path);

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> _request(String method, String path, {Map<String, dynamic>? body}) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Device-Id': _deviceId,
    };
    final token = await session.accessToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';

    http.Response res;
    if (method == 'GET') {
      res = await http.get(_uri(path), headers: headers);
    } else {
      res = await http.post(_uri(path), headers: headers, body: body != null ? jsonEncode(body) : null);
    }

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'message': 'Invalid server response'};
    }

    if (res.statusCode == 401 && !path.contains('/auth/')) {
      final ok = await _refresh();
      if (ok) return _request(method, path, body: body);
    }
    return payload;
  }

  Future<bool> _refresh() async {
    final refresh = await session.refreshToken;
    if (refresh == null) return false;
    final res = await http.post(
      _uri('/v1/auth/refresh'),
      headers: {'Content-Type': 'application/json', 'X-Device-Id': _deviceId},
      body: jsonEncode({'refresh_token': refresh}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      await session.saveTokens(data['data'] as Map<String, dynamic>);
      return true;
    }
    await session.clear();
    return false;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await post('/v1/auth/login', {'email': email, 'password': password});
    if (res['success'] == true) await session.saveTokens(res['data'] as Map<String, dynamic>);
    return res;
  }

  Future<void> logout() async {
    final refresh = await session.refreshToken;
    if (refresh != null) {
      await post('/v1/auth/logout', {'refresh_token': refresh});
    }
    await session.clear();
  }
}
