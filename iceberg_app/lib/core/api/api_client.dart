import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://app.iceberglc.com/api/v1',
);

class ApiClient {
  ApiClient._();
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  final _storage = const FlutterSecureStorage();
  late final Dio dio = _buildDio();

  Dio _buildDio() {
    final d = Dio(
      BaseOptions(
        baseUrl: kBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          // 401 → try refresh
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              // Retry original request with new token
              final opts = error.requestOptions;
              final token = await _storage.read(key: 'access_token');
              opts.headers['Authorization'] = 'Bearer $token';
              try {
                final res = await dio.fetch(opts);
                return handler.resolve(res);
              } catch (_) {}
            }
          }
          handler.next(error);
        },
      ),
    );

    return d;
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null) return false;
    try {
      final res = await Dio().post(
        '$kBaseUrl/auth/token/refresh/',
        data: {'refresh': refresh},
      );
      final newAccess = res.data['access'] as String?;
      if (newAccess != null) {
        await _storage.write(key: 'access_token', value: newAccess);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<String?> get accessToken => _storage.read(key: 'access_token');
}
