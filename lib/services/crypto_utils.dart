import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoAES {
  static (Uint8List, Uint8List) deriveKeyAndIV(
    String passphrase,
    Uint8List salt,
  ) {
    final passwordBytes = utf8.encode(passphrase);
    var concatenatedHashes = Uint8List(0);
    var currentHash = Uint8List(0);

    while (concatenatedHashes.length < 48) {
      final dataToHash = Uint8List.fromList(currentHash + passwordBytes + salt);
      currentHash = Uint8List.fromList(md5.convert(dataToHash).bytes);
      concatenatedHashes = Uint8List.fromList(concatenatedHashes + currentHash);
    }

    return (
      concatenatedHashes.sublist(0, 32),
      concatenatedHashes.sublist(32, 48),
    );
  }

  static String encryptAESCryptoJS(String plainText, String passphrase) {
    try {
      final random = Random.secure();
      final salt = Uint8List.fromList(
        List.generate(8, (_) => random.nextInt(256)),
      );

      final (keyBytes, ivBytes) = deriveKeyAndIV(passphrase, salt);
      final key = encrypt.Key(keyBytes);
      final iv = encrypt.IV(ivBytes);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
      );
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      final resultBytes = Uint8List.fromList(
        utf8.encode('Salted__') + salt + encrypted.bytes,
      );
      return base64.encode(resultBytes);
    } catch (_) {
      return '';
    }
  }

  static String decryptAESCryptoJS(String encrypted, String passphrase) {
    try {
      final bytes = base64.decode(encrypted.trim());
      if (bytes.length < 16) return '';

      final prefix = utf8.decode(bytes.sublist(0, 8), allowMalformed: true);
      if (prefix != 'Salted__') return '';

      final salt = bytes.sublist(8, 16);
      final encryptedBytes = bytes.sublist(16);

      final (keyBytes, ivBytes) = deriveKeyAndIV(passphrase, salt);
      final key = encrypt.Key(keyBytes);
      final iv = encrypt.IV(ivBytes);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
      );
      return encrypter.decrypt(encrypt.Encrypted(encryptedBytes), iv: iv);
    } catch (_) {
      return '';
    }
  }

  static String cryptoHandler(
    String text,
    String ivString,
    String keyString,
    bool isEncrypt,
  ) {
    try {
      var keyBytes = utf8.encode(keyString);
      if (keyBytes.length != 16 &&
          keyBytes.length != 24 &&
          keyBytes.length != 32) {
        final newKey = Uint8List(32);
        for (var i = 0; i < min(32, keyBytes.length); i++) {
          newKey[i] = keyBytes[i];
        }
        keyBytes = newKey;
      }

      var ivBytes = utf8.encode(ivString);
      if (ivBytes.length != 16) {
        final newIv = Uint8List(16);
        for (var i = 0; i < min(16, ivBytes.length); i++) {
          newIv[i] = ivBytes[i];
        }
        ivBytes = newIv;
      }

      final key = encrypt.Key(keyBytes);
      final iv = encrypt.IV(ivBytes);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
      );

      if (isEncrypt) {
        return encrypter.encrypt(text, iv: iv).base64;
      } else {
        return encrypter.decrypt(
          encrypt.Encrypted.fromBase64(text.trim()),
          iv: iv,
        );
      }
    } catch (_) {
      return '';
    }
  }
}
