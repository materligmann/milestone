import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/session_storage.dart';
import 'auth_models.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthUnknown();

  Dio get _dio => ref.read(dioProvider);

  /// Reads the stored token and checks it against the API.
  Future<void> restore() async {
    final token = await ref.read(sessionStorageProvider).readToken();
    if (token == null) {
      state = const AuthSignedOut();
      return;
    }
    ref.read(tokenProvider.notifier).set(token);
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/me');
      state = AuthSignedIn(User.fromJson(res.data!));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await signOut();
      } else {
        // Offline: trust the stored token until the API says otherwise.
        state = AuthSignedIn(const User(id: '', email: '', name: ''));
      }
    }
  }

  Future<void> signIn({required String email, required String password}) =>
      _authenticate('/auth/login', {'email': email.trim(), 'password': password});

  Future<void> register({required String name, required String email, required String password}) =>
      _authenticate('/auth/register', {'name': name.trim(), 'email': email.trim(), 'password': password});

  Future<void> _authenticate(String path, Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(path, data: body);
    final token = res.data!['accessToken'] as String;
    ref.read(tokenProvider.notifier).set(token);
    await ref.read(sessionStorageProvider).writeToken(token);
    state = AuthSignedIn(User.fromJson(res.data!['user'] as Map<String, dynamic>));
  }

  Future<void> signOut() async {
    ref.read(tokenProvider.notifier).set(null);
    await ref.read(sessionStorageProvider).clear();
    state = const AuthSignedOut();
  }
}
