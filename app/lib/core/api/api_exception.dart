import 'package:dio/dio.dart';

/// Every failure of an HTTP call surfaces as one of these subclasses.
///
/// [message] is always safe to show to the user.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  /// True when the failure means "the backend could not be reached or is
  /// down", which is when repositories may fall back to the offline cache.
  bool get allowsCacheFallback => false;

  /// Converts a dio failure into the matching [ApiException].
  factory ApiException.fromDio(DioException error) {
    final Response<dynamic>? response = error.response;
    if (response != null && response.statusCode != null) {
      return ApiException.fromResponse(response.statusCode!, response.data);
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const NetworkException(
        'The server is taking too long to respond. Please try again.',
      ),
      DioExceptionType.cancel => const UnexpectedApiException(
        'The request was cancelled.',
      ),
      _ => const NetworkException(),
    };
  }

  /// Converts an HTTP error status and its decoded JSON body.
  factory ApiException.fromResponse(int statusCode, Object? body) {
    final String? serverMessage = _serverMessage(body);
    return switch (statusCode) {
      401 => UnauthorizedException(
        serverMessage == null || serverMessage == 'Unauthenticated.'
            ? UnauthorizedException.sessionExpiredMessage
            : serverMessage,
      ),
      404 => const NotFoundException(),
      422 => ValidationException(
        serverMessage ?? 'Please check the highlighted fields.',
        _fieldErrors(body),
      ),
      429 => const RateLimitedException(),
      >= 500 => ServerException(statusCode),
      _ => UnexpectedApiException(
        serverMessage ?? 'Something went wrong. Please try again.',
      ),
    };
  }

  static String? _serverMessage(Object? body) {
    if (body is Map && body['message'] is String) {
      final String message = (body['message'] as String).trim();
      return message.isEmpty ? null : message;
    }
    return null;
  }

  static Map<String, List<String>> _fieldErrors(Object? body) {
    final Map<String, List<String>> result = <String, List<String>>{};
    if (body is Map && body['errors'] is Map) {
      (body['errors'] as Map).forEach((Object? field, Object? messages) {
        if (field is String && messages is List) {
          result[field] = messages.whereType<String>().toList();
        } else if (field is String && messages is String) {
          result[field] = <String>[messages];
        }
      });
    }
    return result;
  }

  @override
  String toString() => '$runtimeType: $message';
}

/// No connection, DNS failure, or timeout.
final class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        "Can't reach StudentOS right now. Check your internet connection "
        'and try again.',
  ]);

  @override
  bool get allowsCacheFallback => true;
}

/// 401: wrong credentials on login, or an expired/invalid session elsewhere.
final class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = sessionExpiredMessage]);

  static const String sessionExpiredMessage =
      'Your session has expired. Please log in again.';
}

/// 422: the server rejected one or more fields.
final class ValidationException extends ApiException {
  const ValidationException(super.message, this.fieldErrors);

  /// Field name → messages, exactly as returned in the `errors` object.
  final Map<String, List<String>> fieldErrors;

  /// First message for [field], or null when that field is valid.
  String? errorFor(String field) {
    final List<String>? messages = fieldErrors[field];
    return messages == null || messages.isEmpty ? null : messages.first;
  }
}

/// 404: the record does not exist (or belongs to someone else).
final class NotFoundException extends ApiException {
  const NotFoundException([
    super.message = "We couldn't find that item. It may have been deleted.",
  ]);
}

/// 429: too many requests.
final class RateLimitedException extends ApiException {
  const RateLimitedException([
    super.message = 'Too many attempts. Please wait a minute and try again.',
  ]);
}

/// 5xx: the backend failed or is unavailable.
final class ServerException extends ApiException {
  const ServerException(
    this.statusCode, [
    super.message =
        'StudentOS is having trouble right now. Please try again in a '
        'moment.',
  ]);

  final int statusCode;

  @override
  bool get allowsCacheFallback => true;
}

/// Anything else (unexpected status code, malformed response).
final class UnexpectedApiException extends ApiException {
  const UnexpectedApiException([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
