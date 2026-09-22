import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AppApi {
  AppApi(String endpoint) : endpoint = _normalizeEndpoint(endpoint);

  final String endpoint;
  String token = '';

  static String _normalizeEndpoint(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  bool get configured => endpoint.startsWith('https://script.google.com/') && endpoint.contains('/exec');

  Future<Map<String, dynamic>> login(String login, String password) async {
    final data = await _post(<String, dynamic>{
      'action': 'login',
      'login': login,
      'password': password,
    }, includeToken: false);
    token = data['token']?.toString() ?? '';
    return data;
  }

  Future<Map<String, dynamic>> session() => _post(<String, dynamic>{'action': 'session'});

  Future<Map<String, dynamic>> sync({
    required String fromDate,
    required String toDate,
    List<String>? groups,
  }) {
    return _post(<String, dynamic>{
      'action': 'sync',
      'fromDate': fromDate,
      'toDate': toDate,
      if (groups != null) 'groups': groups,
    });
  }

  Future<Map<String, dynamic>> setStatus({
    required String group,
    required String personName,
    required String date,
    required String meal,
    required String mark,
  }) {
    return _post(<String, dynamic>{
      'action': 'setStatus',
      'group': group,
      'personName': personName,
      'date': date,
      'meal': meal,
      'mark': mark,
    });
  }

  Future<Map<String, dynamic>> calculationPreview({
    required String startDate,
    required String endDate,
  }) {
    return _post(<String, dynamic>{
      'action': 'calculationPreview',
      'startDate': startDate,
      'endDate': endDate,
    });
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _post(<String, dynamic>{
      'action': 'changePassword',
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> logout() async {
    if (token.isEmpty) return;
    try {
      await _post(<String, dynamic>{'action': 'logout'});
    } catch (_) {
      // Logout must still clear the local token if the network is unavailable.
    }
    token = '';
  }

  Future<Map<String, dynamic>> _post(
    Map<String, dynamic> payload, {
    bool includeToken = true,
  }) async {
    if (!configured) {
      throw ApiException('Backend не налаштований. Вставте Apps Script /exec URL.');
    }

    final body = <String, dynamic>{...payload};
    if (includeToken) {
      if (token.isEmpty) throw ApiException('Сесія відсутня. Увійдіть повторно.');
      body['token'] = token;
    }

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(endpoint),
            headers: const <String, String>{'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (error) {
      throw ApiException('Немає зв’язку з сервером: $error');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw ApiException('Сервер повернув некоректну відповідь (HTTP ${response.statusCode}).');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(decoded['error']?.toString() ?? 'HTTP ${response.statusCode}');
    }
    if (decoded['ok'] != true) {
      throw ApiException(decoded['error']?.toString() ?? 'Помилка сервера.');
    }

    final data = decoded['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}
