import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'session_events.dart';

/// The single HTTP entry point of the app. It talks only to the gateway.
///
/// Every method returns the decoded JSON body (`Map`, `List`, or `null` for
/// an empty 204 response) and throws an [ApiException] on any failure.
/// Nothing is logged: no tokens, no bodies.
class ApiClient {
  ApiClient({
    required Future<String?> Function() readToken,
    required void Function() onUnauthorized,
    String baseUrl = AppConfig.apiBaseUrl,
    HttpClientAdapter? httpClientAdapter,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: AppConfig.connectTimeout,
           sendTimeout: AppConfig.receiveTimeout,
           receiveTimeout: AppConfig.receiveTimeout,
           contentType: Headers.jsonContentType,
           responseType: ResponseType.json,
           headers: <String, String>{'Accept': Headers.jsonContentType},
         ),
       ) {
    if (httpClientAdapter != null) {
      _dio.httpClientAdapter = httpClientAdapter;
    }
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra[_authenticatedKey] == true) {
            final String? token = await readToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              options.extra[_tokenSentKey] = true;
            }
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final bool tokenWasSent =
              error.requestOptions.extra[_tokenSentKey] == true;
          if (error.response?.statusCode == 401 && tokenWasSent) {
            onUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  static const String _authenticatedKey = 'authenticated';
  static const String _tokenSentKey = 'tokenSent';

  final Dio _dio;

  /// `GET [path]`. [path] is the full public path, e.g. `/api/notes`.
  Future<Object?> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) {
    return _send('GET', path, query: query, authenticated: authenticated);
  }

  Future<Object?> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  Future<Object?> put(String path, {Object? body, bool authenticated = true}) {
    return _send('PUT', path, body: body, authenticated: authenticated);
  }

  Future<Object?> delete(String path, {bool authenticated = true}) {
    return _send('DELETE', path, authenticated: authenticated);
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    required bool authenticated,
  }) async {
    try {
      final Response<dynamic> response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          extra: <String, dynamic>{_authenticatedKey: authenticated},
        ),
      );
      final Object? data = response.data;
      return data is String && data.isEmpty ? null : data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final TokenStorage tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    readToken: tokenStorage.read,
    onUnauthorized: () =>
        ref.read(unauthorizedSignalProvider.notifier).notify(),
  );
});
