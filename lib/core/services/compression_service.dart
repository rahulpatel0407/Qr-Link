import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

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
  /// All compression runs in a background isolate to prevent UI jank.
  Future<CompressedData> compress(
    Uint8List input,
    CompressionAlgorithm algo,
  ) async {
    return await Isolate.run(() => _compressSync(input, algo));
  }

  /// Decompresses [input] using the specified [algo].
  Future<Uint8List> decompress(
    Uint8List input,
    CompressionAlgorithm algo,
  ) async {
    return await Isolate.run(() => _decompressSync(input, algo));
  }

  /// Internal sync compression (runs inside isolate).
  static CompressedData _compressSync(
    Uint8List input,
    CompressionAlgorithm algo,
  ) {
    Uint8List compressedBytes;
    CompressionAlgorithm usedAlgo;

    switch (algo) {
      case CompressionAlgorithm.gzip:
        compressedBytes = Uint8List.fromList(gzip.encode(input));
        usedAlgo = CompressionAlgorithm.gzip;
        break;
      case CompressionAlgorithm.zstd:
        // Zstd FFI not bundled — fall back to gzip with a note
        compressedBytes = Uint8List.fromList(gzip.encode(input));
        usedAlgo = CompressionAlgorithm.gzip;
        break;
      case CompressionAlgorithm.auto:
        // Auto: try gzip (only available algo without native FFI)
        compressedBytes = Uint8List.fromList(gzip.encode(input));
        usedAlgo = CompressionAlgorithm.gzip;
        break;
    }

    return CompressedData(
      bytes: compressedBytes,
      algorithm: usedAlgo,
      originalSize: input.length,
      compressedSize: compressedBytes.length,
    );
  }

  /// Internal sync decompression (runs inside isolate).
  static Uint8List _decompressSync(
    Uint8List input,
    CompressionAlgorithm algo,
  ) {
    // All currently supported algorithms use gzip under the hood
    return Uint8List.fromList(gzip.decode(input));
  }
}
