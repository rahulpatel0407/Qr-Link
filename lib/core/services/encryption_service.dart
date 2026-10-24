import 'dart:math';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:cryptography/cryptography.dart';

/// Exception thrown when decryption fails.
class DecryptionException implements Exception {
  final String message;
  DecryptionException([this.message = 'Decryption failed — wrong passphrase']);

  @override
  String toString() => 'DecryptionException: $message';
}

/// Service for encrypting and decrypting data using AES-256-GCM.
class EncryptionService {
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _iterations = 200000;

  /// Encrypts [data] with the provided [passphrase].
  Future<Uint8List> encrypt(Uint8List data, String passphrase) async {
    return await Isolate.run(() async {
      final random = Random.secure();
      final salt = Uint8List(_saltLength);
      for (int i = 0; i < salt.length; i++) {
        salt[i] = random.nextInt(256);
      }

      final nonce = Uint8List(_nonceLength);
      for (int i = 0; i < nonce.length; i++) {
        nonce[i] = random.nextInt(256);
      }

      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: _iterations,
        bits: 256,
      );

      final secretKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(passphrase.codeUnits),
        nonce: salt,
      );

      final algorithm = AesGcm.with256bits();
      final secretBox = await algorithm.encrypt(
        data,
        secretKey: secretKey,
        nonce: nonce,
      );

      final bb = BytesBuilder();
      bb.add(salt);
      bb.add(nonce);
      bb.add(secretBox.cipherText);
      bb.add(secretBox.mac.bytes);

      return bb.toBytes();
    });
  }

  /// Decrypts [encrypted] data with the provided [passphrase].
  Future<Uint8List> decrypt(Uint8List encrypted, String passphrase) async {
    return await Isolate.run(() async {
      try {
        if (encrypted.length < _saltLength + _nonceLength + 16) {
          throw DecryptionException('Invalid encrypted data length');
        }

        final salt = encrypted.sublist(0, _saltLength);
        final nonce = encrypted.sublist(_saltLength, _saltLength + _nonceLength);
        
        // MAC is 16 bytes for AES-256-GCM
        final cipherTextLength = encrypted.length - _saltLength - _nonceLength - 16;
        final cipherTextStart = _saltLength + _nonceLength;
        final cipherText = encrypted.sublist(cipherTextStart, cipherTextStart + cipherTextLength);
        final macBytes = encrypted.sublist(cipherTextStart + cipherTextLength);

        final pbkdf2 = Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: _iterations,
          bits: 256,
        );

        final secretKey = await pbkdf2.deriveKey(
          secretKey: SecretKey(passphrase.codeUnits),
          nonce: salt,
        );

        final algorithm = AesGcm.with256bits();
        final secretBox = SecretBox(
          cipherText,
          nonce: nonce,
          mac: Mac(macBytes),
        );

        final decrypted = await algorithm.decrypt(
          secretBox,
          secretKey: secretKey,
        );

        return Uint8List.fromList(decrypted);
      } catch (e) {
        throw DecryptionException('Decryption failed — wrong passphrase');
      }
    });
  }
}
