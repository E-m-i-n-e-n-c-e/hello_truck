import 'package:dio/dio.dart';

class APIException extends DioException {
  final String userMessage;
  final Duration? retryAfter;

  APIException({
    required this.userMessage,
    required super.requestOptions,
    this.retryAfter,
    super.response,
  }) : super(message: userMessage);

  /// Factory constructor to create APIException from DioException
  factory APIException.fromDioException(DioException error) {
    if (error.response?.statusCode == 429) {
      final retryAfterHeader = error.response?.headers['retry-after']?.first;
      final seconds = retryAfterHeader != null
          ? int.tryParse(retryAfterHeader)
          : 60;
      return APIException(
        userMessage:
            'Too many attempts. Please wait $seconds seconds before trying again.',
        requestOptions: error.requestOptions,
        retryAfter: Duration(seconds: seconds ?? 60),
        response: error.response,
      );
    }

    final statusCode = error.response?.statusCode;
    String message;

    switch (statusCode) {
      case 400:
        message = _extractErrorMessage(error) ?? 'Invalid request';
        break;
      case 401:
        message = 'Unauthorized. Please sign in again.';
        break;
      case 403:
        message = 'You do not have permission to perform this action.';
        break;
      case 404:
        message = 'Resource not found.';
        break;
      case 500:
      case 501:
      case 502:
      case 503:
        message = 'Server error. Please try again later.';
        break;
      case null:
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          message =
              'Connection timeout. Please check your internet connection.';
        } else if (error.type == DioExceptionType.connectionError) {
          message = 'No internet connection.';
        } else {
          message = 'An unexpected error occurred. Please try again.';
        }
        break;
      default:
        message = _extractErrorMessage(error) ?? 'An unexpected error occurred';
    }

    return APIException(
      userMessage: message,
      requestOptions: error.requestOptions,
      response: error.response,
    );
  }

  /// Helper method to extract error message from response data
  static String? _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data == null) return null;

    if (data is Map) {
      if (data['message'] is String) {
        return data['message'];
      } else if (data['message'][0] is String) {
        return data['message'][0];
      } else if (data['error'] is String) {
        return data['error'];
      }
    } else if (data is String) {
      return data;
    }

    return null;
  }

  @override
  String toString() => userMessage;
}
