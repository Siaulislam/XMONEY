import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../l10n/xm_strings.dart';
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

  Map<String, String> _headers({bool auth = true}) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Device-Id': _deviceId,
      'X-Locale': XmStrings.instance.lang,
      'X-Platform': Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'other'),
    };
    return headers;
  }

  Future<Map<String, String>> _authHeaders() async {
    final headers = _headers();
    final token = await session.accessToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<Map<String, dynamic>> get(String path) => _request('GET', path);

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) =>
      _request('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _request('DELETE', path);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool retry = true,
  }) async {
    final headers = await _authHeaders();
    http.Response res;
    final uri = _uri(path);
    switch (method) {
      case 'GET':
        res = await http.get(uri, headers: headers);
        break;
      case 'PUT':
        res = await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: headers);
        break;
      default:
        res = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    }

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'message': 'Invalid server response'};
    }

    if (res.statusCode == 401 && retry && !path.contains('/auth/')) {
      final ok = await _refresh();
      if (ok) return _request(method, path, body: body, retry: false);
    }
    return payload;
  }

  Future<bool> _refresh() async {
    final refresh = await session.refreshToken;
    if (refresh == null) return false;
    final res = await http.post(
      _uri('/v1/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
        'X-Device-Id': _deviceId,
        'X-Locale': XmStrings.instance.lang,
      },
      body: jsonEncode({'refresh_token': refresh}),
    );
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        await session.saveTokens(data['data'] as Map<String, dynamic>);
        return true;
      }
    } catch (_) {}
    await session.clear();
    return false;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) =>
      post('/v1/auth/register', body);

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  }) =>
      post('/v1/auth/verify-otp', {'email': email, 'otp': otp, 'purpose': purpose});

  Future<Map<String, dynamic>> resendOtp({
    required String email,
    required String purpose,
  }) =>
      post('/v1/auth/resend-otp', {'email': email, 'purpose': purpose});

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await post('/v1/auth/login', {'email': email, 'password': password});
    if (res['success'] == true) await session.saveTokens(res['data'] as Map<String, dynamic>);
    return res;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) =>
      post('/v1/auth/forgot-password', {'email': email});

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) =>
      post('/v1/auth/reset-password', {
        'email': email,
        'otp': otp,
        'password': password,
      });

  Future<Map<String, dynamic>> changePassword(String current, String next) =>
      post('/v1/me/change-password', {'current_password': current, 'new_password': next});

  Future<Map<String, dynamic>> uploadKyc({
    required String documentType,
    required File file,
  }) async {
    final token = await session.accessToken;
    final req = http.MultipartRequest('POST', _uri('/v1/kyc/upload'));
    req.headers['Accept'] = 'application/json';
    req.headers['X-Device-Id'] = _deviceId;
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.fields['document_type'] = documentType;
    req.files.add(await http.MultipartFile.fromPath('document', file.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'message': 'Upload failed'};
    }
  }

  Future<void> logout() async {
    final refresh = await session.refreshToken;
    if (refresh != null) {
      await post('/v1/auth/logout', {'refresh_token': refresh});
    }
    await session.clear();
  }
}
