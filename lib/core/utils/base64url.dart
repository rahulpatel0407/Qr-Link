import 'dart:convert';
import 'dart:typed_data';

/// Base64URL encoding/decoding utilities for QR data transport
class Base64Url {
  Base64Url._();

  /// Encode bytes to base64url string (no padding)
  static String encode(Uint8List bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Decode base64url string (with or without padding) to bytes
  static Uint8List decode(String encoded) {
    // Add padding if necessary
    String padded = encoded;
    final remainder = padded.length % 4;
    if (remainder > 0) {
      padded += '=' * (4 - remainder);
    }
    return base64Url.decode(padded);
  }

  /// Check if a string is valid base64url
  static bool isValid(String data) {
    try {
      decode(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Calculate the encoded length for a given byte count
  static int encodedLength(int byteCount) {
    // base64url: 4 chars per 3 bytes, rounded up, minus padding
    return ((byteCount + 2) ~/ 3) * 4;
  }

  /// Calculate the decoded byte count for a given encoded string length
  static int decodedLength(int encodedLength) {
    return (encodedLength * 3) ~/ 4;
  }
}
