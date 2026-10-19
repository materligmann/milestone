import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_controller.dart';
import 'config.dart';

/// Holds the bearer token in memory; the auth controller keeps it in sync with secure storage.
final tokenProvider = NotifierProvider<TokenNotifier, String?>(TokenNotifier.new);

class TokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? token) => state = token;
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(tokenProvider);
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) {
        final isAuthRoute = error.requestOptions.path.startsWith('/auth/');
        if (error.response?.statusCode == 401 && !isAuthRoute) {
          ref.read(authControllerProvider.notifier).signOut();
        }
        handler.next(error);
      },
    ),
  );
  return dio;
});

/// Turns a Dio failure into a sentence a person can read.
String describeError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) return message.join('\n');
      return message.toString();
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => 'The server took too long to answer.',
      DioExceptionType.connectionError => 'No connection to the server.',
      _ => 'Something went wrong (${error.response?.statusCode ?? 'network'}).',
    };
  }
  return error.toString();
}
