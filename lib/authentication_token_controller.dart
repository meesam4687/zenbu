import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';

  static Future<void> saveTokens({required String accessToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
  }
}
