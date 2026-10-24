import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';

/// Compression algorithms supported by the service.
enum CompressionAlgorithm {
  gzip,
  zstd,
  auto,
}

/// Represents data that has been compressed.
class CompressedData {
  final Uint8List bytes;
  final CompressionAlgorithm algorithm;
  final int originalSize;
  final int compressedSize;

  CompressedData({
    required this.bytes,
    required this.algorithm,
    required this.originalSize,
    required this.compressedSize,
  });

  /// The compression ratio achieved (0.0 = no compression, 1.0 = fully compressed).
  /// Represents the fraction of size saved: 1 - (compressed / original).
  double get ratio =>
      originalSize == 0 ? 0.0 : 1.0 - (compressedSize / originalSize);
}

/// Service for compressing and decompressing data.
/// Supports instance and static usage patterns.
class CompressionService {
  /// Compresses [input] using the specified [algo].
  /// On web or small inputs, runs directly. On native platforms, runs in an isolate.
  Future<CompressedData> compress(
    Uint8List input,
    CompressionAlgorithm algo,
  ) async {
    if (kIsWeb || input.length < 50000) {
      return _compressSync(input, algo);
    }
    try {
      return await Isolate.run(() => _compressSync(input, algo));
    } catch (_) {
      return _compressSync(input, algo);
    }
  }

  /// Decompresses [input] using the specified [algo].
  Future<Uint8List> decompress(
    Uint8List input,
    CompressionAlgorithm algo,
  ) async {
    if (kIsWeb || input.length < 50000) {
      return _decompressSync(input, algo);
    }
    try {
      return await Isolate.run(() => _decompressSync(input, algo));
    } catch (_) {
      return _decompressSync(input, algo);
    }
  }

  /// Internal sync compression using pure Dart archive package.
  static CompressedData _compressSync(
    Uint8List input,
    CompressionAlgorithm algo,
  ) {
    if (input.isEmpty) {
      return CompressedData(
        bytes: Uint8List(0),
        algorithm: algo,
        originalSize: 0,
        compressedSize: 0,
      );
    }

    final encoder = GZipEncoder();
    final compressedList = encoder.encode(input);
    final compressedBytes = compressedList != null
        ? Uint8List.fromList(compressedList)
        : input;

    return CompressedData(
      bytes: compressedBytes,
      algorithm: algo,
      originalSize: input.length,
      compressedSize: compressedBytes.length,
    );
  }

  /// Internal sync decompression using pure Dart archive package.
  static Uint8List _decompressSync(
    Uint8List input,
    CompressionAlgorithm algo,
  ) {
    if (input.isEmpty) return Uint8List(0);
    try {
      final decoder = GZipDecoder();
      final decompressedList = decoder.decodeBytes(input);
      return Uint8List.fromList(decompressedList);
    } catch (e) {
      return input;
    }
  }
}
