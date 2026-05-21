import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// ── Error types ───────────────────────────────────────────────────────────────

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;
    String? errorCode;
    String message;

    if (data is Map<String, dynamic>) {
      errorCode = data['errorCode']?.toString() ?? data['code']?.toString();
      message = data['userMessage']?.toString() ??
          data['message']?.toString() ??
          data['error']?.toString() ??
          error.message ??
          'Request failed ($statusCode)';
    } else {
      message = error.message ?? 'Request failed ($statusCode)';
    }

    return ApiException(
      message: message.trim(),
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }

  final String message;
  final int? statusCode;
  final String? errorCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Returns a user-facing error message from any thrown object.
String userFacingErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException) return ApiException.fromDio(error).message;
  final msg = error.toString();
  const prefixes = ['Exception: ', 'StateError: ', 'Error: '];
  for (final p in prefixes) {
    if (msg.startsWith(p)) return msg.substring(p.length);
  }
  return msg;
}

/// Returns the HTTP status code if [error] is a Dio or API error.
int? apiHttpStatus(Object error) {
  if (error is ApiException) return error.statusCode;
  if (error is DioException) return error.response?.statusCode;
  return null;
}

/// Logs the error in debug mode.
void debugLogApiIssue(Object error, {required String operation, StackTrace? stackTrace}) {
  if (kDebugMode) {
    debugPrint('[$operation] ${userFacingErrorMessage(error)}');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
  }
}

/// Throws [ApiException] if [data] indicates an API-level failure.
void throwIfApiFailurePayload(dynamic data, {int? httpStatus}) {
  if (data is! Map) return;
  final map = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data);
  final success = map['success'];
  if (success == false) {
    final message = map['userMessage']?.toString() ??
        map['message']?.toString() ??
        map['error']?.toString() ??
        'Request failed';
    throw ApiException(
      message: message.trim(),
      statusCode: httpStatus,
      errorCode: map['errorCode']?.toString(),
    );
  }
}
