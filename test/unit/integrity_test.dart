import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrlink/core/services/integrity_service.dart';
import 'package:qrlink/core/utils/binary_utils.dart';

void main() {
  group('SHA-256', () {
    test('SHA-256 matches for valid reassembly', () {
      final data = Uint8List.fromList(
        'QRLink transfer integrity test data — complete and unmodified.'
            .codeUnits,
      );

      final hash = IntegrityService.computeSha256(data);
      final verified = IntegrityService.verifyIntegrity(data, hash);

      expect(verified, isTrue);
    });

    test('SHA-256 fails when one byte is flipped', () {
      final data = Uint8List.fromList(
        'QRLink transfer integrity test data — complete and unmodified.'
            .codeUnits,
      );

      final hash = IntegrityService.computeSha256(data);

      // Flip one byte
      final corrupted = Uint8List.fromList(data);
      corrupted[10] = corrupted[10] ^ 0xFF;

      final verified = IntegrityService.verifyIntegrity(corrupted, hash);
      expect(verified, isFalse);
    });

    test('SHA-256 produces 32-byte hash', () {
      final data = Uint8List.fromList([1, 2, 3]);
      final hash = IntegrityService.computeSha256(data);

      expect(hash.length, equals(32));
    });

    test('SHA-256 hex is 64 characters', () {
      final data = Uint8List.fromList([1, 2, 3]);
      final hex = IntegrityService.computeSha256Hex(data);

      expect(hex.length, equals(64));
      // Should only contain hex characters
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hex), isTrue);
    });

    test('SHA-256 is deterministic', () {
      final data = Uint8List.fromList(
        'Deterministic hash test'.codeUnits,
      );

      final hash1 = IntegrityService.computeSha256(data);
      final hash2 = IntegrityService.computeSha256(data);

      expect(hash1, equals(hash2));
    });

    test('different data produces different SHA-256', () {
      final data1 = Uint8List.fromList('Data A'.codeUnits);
      final data2 = Uint8List.fromList('Data B'.codeUnits);

      final hash1 = IntegrityService.computeSha256(data1);
      final hash2 = IntegrityService.computeSha256(data2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('empty data produces valid SHA-256', () {
      final data = Uint8List(0);
      final hash = IntegrityService.computeSha256(data);

      expect(hash.length, equals(32));
      // SHA-256 of empty string is a known constant
      final hex = IntegrityService.computeSha256Hex(data);
      expect(
        hex,
        equals(
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        ),
      );
    });
  });

  group('CRC32', () {
    test('CRC32 matches for identical data', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);

      final crc1 = IntegrityService.computeCrc32(data);
      final crc2 = IntegrityService.computeCrc32(data);

      expect(crc1, equals(crc2));
    });

    test('CRC32 fails for modified data', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      final crc = IntegrityService.computeCrc32(data);

      final modified = Uint8List.fromList([1, 2, 3, 4, 6]);
      final verified = IntegrityService.verifyCrc32(modified, crc);

      expect(verified, isFalse);
    });

    test('CRC32 verifies correctly for valid data', () {
      final data = Uint8List.fromList(
        'CRC32 test string for QRLink'.codeUnits,
      );
      final crc = IntegrityService.computeCrc32(data);
      final verified = IntegrityService.verifyCrc32(data, crc);

      expect(verified, isTrue);
    });
  });

  group('Constant-time comparison', () {
    test('constant-time comparison is used for hash verification', () {
      final data = Uint8List.fromList('test'.codeUnits);
      final hash = IntegrityService.computeSha256(data);

      // Verify same hash passes
      expect(BinaryUtils.constantTimeEquals(hash, hash), isTrue);

      // Verify different hash fails
      final differentHash = Uint8List.fromList(hash);
      differentHash[0] ^= 1;
      expect(
        BinaryUtils.constantTimeEquals(hash, differentHash),
        isFalse,
      );
    });

    test('constant-time equals with different lengths returns false', () {
      final a = Uint8List.fromList([1, 2, 3]);
      final b = Uint8List.fromList([1, 2, 3, 4]);

      expect(BinaryUtils.constantTimeEquals(a, b), isFalse);
    });

    test('constant-time equals with empty arrays', () {
      final a = Uint8List(0);
      final b = Uint8List(0);

      expect(BinaryUtils.constantTimeEquals(a, b), isTrue);
    });

    test('constant-time equals catches single bit difference', () {
      final a = Uint8List.fromList([0xFF, 0xFF, 0xFF]);
      final b = Uint8List.fromList([0xFF, 0xFE, 0xFF]);

      expect(BinaryUtils.constantTimeEquals(a, b), isFalse);
    });
  });
}
