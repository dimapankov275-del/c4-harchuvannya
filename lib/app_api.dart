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
      response = await _sendAppsScriptRequest(jsonEncode(body));
    } on ApiException {
      rethrow;
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

  /// Google Apps Script ContentService intentionally returns a redirect to a
  /// one-time script.googleusercontent.com URL. Some native HTTP clients do
  /// not automatically follow a POST -> 302 -> GET redirect, so handle it
  /// explicitly here.
  Future<http.Response> _sendAppsScriptRequest(String encodedBody) async {
    final client = http.Client();
    try {
      var uri = Uri.parse(endpoint);
      var method = 'POST';

      for (var redirectCount = 0; redirectCount < 6; redirectCount++) {
        final request = http.Request(method, uri)
          ..followRedirects = false
          ..headers['Accept'] = 'application/json';

        if (method == 'POST') {
          request.headers['Content-Type'] = 'application/json; charset=utf-8';
          request.body = encodedBody;
        }

        final streamed = await client.send(request).timeout(const Duration(seconds: 20));
        final response = await http.Response.fromStream(streamed);

        if (!_isRedirect(response.statusCode)) return response;

        final location = response.headers['location'];
        if (location == null || location.isEmpty) return response;

        final next = uri.resolve(location);
        final host = next.host.toLowerCase();
        if (host == 'accounts.google.com' || host.endsWith('.accounts.google.com')) {
          throw ApiException(
            'Apps Script вимагає вхід у Google. У Deploy → Manage deployments '
            'перевірте, що Web app має доступ «Anyone».',
          );
        }

        uri = next;

        // Apps Script ContentService uses 302 to hand the already-generated
        // response to script.googleusercontent.com. The redirected request
        // must be a GET. 307/308, if ever returned, preserve the POST method.
        if (response.statusCode == 301 ||
            response.statusCode == 302 ||
            response.statusCode == 303) {
          method = 'GET';
        }
      }

      throw ApiException('Сервер зробив забагато перенаправлень.');
    } finally {
      client.close();
    }
  }

  bool _isRedirect(int statusCode) =>
      statusCode == 301 ||
      statusCode == 302 ||
      statusCode == 303 ||
      statusCode == 307 ||
      statusCode == 308;
}
