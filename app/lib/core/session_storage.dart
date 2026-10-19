import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'milestone.accessToken';

final sessionStorageProvider = Provider<SessionStorage>((ref) => SessionStorage(const FlutterSecureStorage()));

class SessionStorage {
  SessionStorage(this._storage);
  final FlutterSecureStorage _storage;

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<void> clear() => _storage.delete(key: _tokenKey);
}
