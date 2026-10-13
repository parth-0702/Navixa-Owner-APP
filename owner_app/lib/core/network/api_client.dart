import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../storage/preferences_service.dart';
import '../storage/secure_storage_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  ApiClient({
    required SecureStorageService secureStorage,
    required PreferencesService preferencesService,
    http.Client? httpClient,
    this.onSessionExpired,
  })  : _secureStorage = secureStorage,
        _preferencesService = preferencesService,
        _client = httpClient ?? http.Client();

  final SecureStorageService _secureStorage;
  final PreferencesService _preferencesService;
  final http.Client _client;
  final void Function()? onSessionExpired;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  String get baseUrl {
    final custom = _preferencesService.getCustomBaseUrl();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return AppConfig.defaultBaseUrl;
  }

  Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final token = await _secureStorage.getAccessToken();
      if (token != null) {
        map['Authorization'] = 'Bearer $token';
      }
    }
    return map;
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams, bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(endpoint, queryParams);
      final headers = await _headers(requiresAuth: requiresAuth);
      return _client.get(uri, headers: headers);
    }, endpoint: endpoint);
  }

  Future<dynamic> post(String endpoint, {dynamic body, bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(endpoint);
      final headers = await _headers(requiresAuth: requiresAuth);
      return _client.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    }, endpoint: endpoint);
  }

  Future<dynamic> put(String endpoint, {dynamic body, bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(endpoint);
      final headers = await _headers(requiresAuth: requiresAuth);
      return _client.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    }, endpoint: endpoint);
  }

  Future<dynamic> patch(String endpoint, {dynamic body, bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(endpoint);
      final headers = await _headers(requiresAuth: requiresAuth);
      return _client.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    }, endpoint: endpoint);
  }

  Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(endpoint);
      final headers = await _headers(requiresAuth: requiresAuth);
      return _client.delete(uri, headers: headers);
    }, endpoint: endpoint);
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$baseUrl$cleanEndpoint';

    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      final filtered = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          filtered[key] = value.toString();
        }
      });
      return uri.replace(queryParameters: filtered);
    }
    return uri;
  }

  Future<dynamic> _sendWithRetry(
    Future<http.Response> Function() requestFn, {
    required String endpoint,
    int retryCount = 0,
  }) async {
    try {
      final response = await requestFn();

      if (response.statusCode == 401 && !endpoint.contains('/auth/login') && !endpoint.contains('/auth/refresh')) {
        if (retryCount == 0) {
          // Attempt automatic token refresh
          final refreshed = await _refreshToken();
          if (refreshed != null) {
            return _sendWithRetry(requestFn, endpoint: endpoint, retryCount: retryCount + 1);
          }
        }
        await _secureStorage.clearTokens();
        onSessionExpired?.call();
        throw const UnauthorizedException();
      }

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }
  }

  Future<String?> _refreshToken() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        _refreshCompleter?.complete(null);
        return null;
      }

      final uri = _buildUri('/auth/refresh');
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final newAccess = data['accessToken']?.toString();
        final newRefresh = data['refreshToken']?.toString() ?? refreshToken;

        if (newAccess != null) {
          await _secureStorage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
          _refreshCompleter?.complete(newAccess);
          return newAccess;
        }
      }

      _refreshCompleter?.complete(null);
      return null;
    } catch (_) {
      _refreshCompleter?.complete(null);
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final errorMessage = (body is Map && body['error'] != null)
        ? body['error'].toString()
        : 'Request failed with status: ${response.statusCode}';

    if (response.statusCode == 401) {
      throw UnauthorizedException(errorMessage);
    } else if (response.statusCode == 403) {
      throw ForbiddenException(errorMessage);
    } else if (response.statusCode == 404) {
      throw NotFoundException(errorMessage);
    } else {
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }
}
