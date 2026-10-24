import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrlink/core/services/encryption_service.dart';

void main() {
  late EncryptionService encryption;

  setUp(() {
    encryption = EncryptionService();
  });

  group('AES-256-GCM Encryption', () {
    test('encrypt → decrypt with correct passphrase', () async {
      final plaintext = Uint8List.fromList(
        'Secret QRLink transfer data — confidential!'.codeUnits,
      );
      const passphrase = 'MyStrongPassphrase123!';

      final encrypted = await encryption.encrypt(plaintext, passphrase);
      final decrypted = await encryption.decrypt(encrypted, passphrase);

      expect(decrypted, equals(plaintext));
    });

    test('wrong passphrase throws DecryptionException', () async {
      final plaintext = Uint8List.fromList(
        'Top secret message'.codeUnits,
      );

      final encrypted = await encryption.encrypt(plaintext, 'correct-pass');

      expect(
        () async => await encryption.decrypt(encrypted, 'wrong-pass'),
        throwsA(isA<DecryptionException>()),
      );
    });

    test('DecryptionException has correct message', () async {
      final plaintext = Uint8List.fromList([1, 2, 3]);

      final encrypted = await encryption.encrypt(plaintext, 'pass123');

      try {
        await encryption.decrypt(encrypted, 'wrongpass');
        fail('Should have thrown DecryptionException');
      } on DecryptionException catch (e) {
        expect(e.message, contains('wrong passphrase'));
      }
    });

    test('salt and IV are unique per encryption call', () async {
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);
      const passphrase = 'test-pass';

      final encrypted1 = await encryption.encrypt(plaintext, passphrase);
      final encrypted2 = await encryption.encrypt(plaintext, passphrase);

      // Salt is first 16 bytes
      final salt1 = encrypted1.sublist(0, 16);
      final salt2 = encrypted2.sublist(0, 16);

      // IV is bytes 16-28
      final iv1 = encrypted1.sublist(16, 28);
      final iv2 = encrypted2.sublist(16, 28);

      // Salt and IV should be different each time
      expect(salt1, isNot(equals(salt2)));
      expect(iv1, isNot(equals(iv2)));

      // But both should still decrypt correctly
      final decrypted1 = await encryption.decrypt(encrypted1, passphrase);
      final decrypted2 = await encryption.decrypt(encrypted2, passphrase);

      expect(decrypted1, equals(plaintext));
      expect(decrypted2, equals(plaintext));
    });

    test('encrypted output is longer than plaintext', () async {
      final plaintext = Uint8List.fromList(
        List.generate(100, (i) => i % 256),
      );

      final encrypted = await encryption.encrypt(plaintext, 'pass');

      // Should be: 16 (salt) + 12 (nonce) + 100 (data) + 16 (GCM tag) = 144
      expect(encrypted.length, greaterThan(plaintext.length));
      expect(encrypted.length, greaterThanOrEqualTo(plaintext.length + 28));
    });

    test('handles empty plaintext', () async {
      final plaintext = Uint8List(0);
      const passphrase = 'empty-test';

      final encrypted = await encryption.encrypt(plaintext, passphrase);
      final decrypted = await encryption.decrypt(encrypted, passphrase);

      expect(decrypted, equals(plaintext));
    });

    test('handles large plaintext (1MB)', () async {
      final plaintext = Uint8List.fromList(
        List.generate(1024 * 1024, (i) => (i * 7 + 3) % 256),
      );
      const passphrase = 'large-file-pass';

      final encrypted = await encryption.encrypt(plaintext, passphrase);
      final decrypted = await encryption.decrypt(encrypted, passphrase);

      expect(decrypted.length, equals(plaintext.length));
      expect(decrypted, equals(plaintext));
    });

    test('handles unicode passphrase', () async {
      final plaintext = Uint8List.fromList([1, 2, 3]);
      const passphrase = '密码🔐αβγ';

      final encrypted = await encryption.encrypt(plaintext, passphrase);
      final decrypted = await encryption.decrypt(encrypted, passphrase);

      expect(decrypted, equals(plaintext));
    });

    test('tampered ciphertext fails decryption', () async {
      final plaintext = Uint8List.fromList(
        'Integrity test data'.codeUnits,
      );
      const passphrase = 'integrity-pass';

      final encrypted = await encryption.encrypt(plaintext, passphrase);

      // Tamper with the ciphertext (after salt + nonce, in the encrypted data area)
      if (encrypted.length > 30) {
        encrypted[30] = encrypted[30] ^ 0xFF;
      }

      expect(
        () async => await encryption.decrypt(encrypted, passphrase),
        throwsA(isA<DecryptionException>()),
      );
    });
  });
}
