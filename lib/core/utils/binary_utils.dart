import 'dart:typed_data';

/// Utilities for binary data manipulation
class BinaryUtils {
  BinaryUtils._();

  /// Write a 16-bit unsigned integer in big-endian format
  static void writeUint16BE(ByteData data, int offset, int value) {
    data.setUint16(offset, value, Endian.big);
  }

  /// Read a 16-bit unsigned integer in big-endian format
  static int readUint16BE(ByteData data, int offset) {
    return data.getUint16(offset, Endian.big);
  }

  /// Write a 32-bit unsigned integer in big-endian format
  static void writeUint32BE(ByteData data, int offset, int value) {
    data.setUint32(offset, value, Endian.big);
  }

  /// Read a 32-bit unsigned integer in big-endian format
  static int readUint32BE(ByteData data, int offset) {
    return data.getUint32(offset, Endian.big);
  }

  /// Concatenate multiple Uint8Lists into one
  static Uint8List concat(List<Uint8List> parts) {
    final totalLength = parts.fold<int>(0, (sum, p) => sum + p.length);
    final result = Uint8List(totalLength);
    int offset = 0;
    for (final part in parts) {
      result.setRange(offset, offset + part.length, part);
      offset += part.length;
    }
    return result;
  }

  /// Extract a slice from a Uint8List
  static Uint8List slice(Uint8List data, int start, [int? end]) {
    end ??= data.length;
    return Uint8List.fromList(data.sublist(start, end));
  }

  /// Convert Uint8List to hex string
  static String toHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Convert hex string to Uint8List
  static Uint8List fromHex(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  /// Compare two Uint8Lists for equality in constant time
  /// (prevents timing attacks on hash comparisons)
  static bool constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Create a Uint8List of zeros
  static Uint8List zeros(int length) {
    return Uint8List(length);
  }

  /// Format bytes to human-readable size
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
