import 'dart:typed_data';
import 'dart:isolate';
import 'package:crypto/crypto.dart';

/// Service for checking and verifying data integrity using SHA-256 and CRC32.
class IntegrityService {
  /// Computes SHA-256 hash of the given [data] synchronously.
  static Uint8List computeSha256(Uint8List data) {
    final Digest digest = sha256.convert(data);
    return Uint8List.fromList(digest.bytes);
  }

  /// Computes SHA-256 hash asynchronously in a background isolate.
  static Future<Uint8List> computeSha256Async(Uint8List data) async {
    return await Isolate.run(() {
      final Digest digest = sha256.convert(data);
      return Uint8List.fromList(digest.bytes);
    });
  }

  /// Computes SHA-256 hash of the given [data] and returns it as a hex string.
  static String computeSha256Hex(Uint8List data) {
    final Digest digest = sha256.convert(data);
    return digest.toString();
  }

  /// Async version of computeSha256Hex for large files.
  static Future<String> computeSha256HexAsync(Uint8List data) async {
    return await Isolate.run(() {
      final Digest digest = sha256.convert(data);
      return digest.toString();
    });
  }

  /// Computes a standard CRC32 checksum of the given [data].
  /// Uses the polynomial 0xEDB88320.
  static int computeCrc32(Uint8List data) {
    int crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (int j = 0; j < 8; j++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }

  /// Verifies the integrity of [assembled] data against an [expectedHash].
  /// Uses constant-time comparison to prevent timing attacks.
  static bool verifyIntegrity(Uint8List assembled, Uint8List expectedHash) {
    final Digest digest = sha256.convert(assembled);
    final Uint8List actualHash = Uint8List.fromList(digest.bytes);

    if (actualHash.length != expectedHash.length) {
      return false;
    }

    // Constant-time comparison to prevent timing attacks
    int result = 0;
    for (int i = 0; i < actualHash.length; i++) {
      result |= actualHash[i] ^ expectedHash[i];
    }
    return result == 0;
  }

  /// Async version of verifyIntegrity for large files.
  static Future<bool> verifyIntegrityAsync(
    Uint8List assembled,
    Uint8List expectedHash,
  ) async {
    return await Isolate.run(() {
      return verifyIntegrity(assembled, expectedHash);
    });
  }

  /// Verifies the CRC32 checksum of [data] against an [expectedCrc].
  static bool verifyCrc32(Uint8List data, int expectedCrc) {
    final int actualCrc = computeCrc32(data);
    return actualCrc == expectedCrc;
  }
}
