import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrlink/core/services/compression_service.dart';

void main() {
  late CompressionService compressor;

  setUp(() {
    compressor = CompressionService();
  });

  group('GZip compression', () {
    test('gzip round-trip produces identical output', () async {
      final original = Uint8List.fromList(
        'Hello, World! This is a test of the QRLink compression service. '
                'Repeated content helps compression: AAAAAAAAABBBBBBBBCCCCCCCC'
            .codeUnits,
      );

      final compressed = await compressor.compress(
        original,
        CompressionAlgorithm.gzip,
      );
      final decompressed = await compressor.decompress(
        compressed.bytes,
        CompressionAlgorithm.gzip,
      );

      expect(decompressed, equals(original));
    });

    test('gzip compresses text meaningfully', () async {
      // Highly compressible text
      final original = Uint8List.fromList(
        ('A' * 10000).codeUnits,
      );

      final compressed = await compressor.compress(
        original,
        CompressionAlgorithm.gzip,
      );

      // Repeated characters should compress to far less than original
      expect(compressed.bytes.length, lessThan(original.length));
      expect(compressed.ratio, greaterThan(0.5)); // at least 50% compression
    });

    test('gzip handles empty input', () async {
      final original = Uint8List(0);

      final compressed = await compressor.compress(
        original,
        CompressionAlgorithm.gzip,
      );
      final decompressed = await compressor.decompress(
        compressed.bytes,
        CompressionAlgorithm.gzip,
      );

      expect(decompressed, equals(original));
    });

    test('gzip handles single byte', () async {
      final original = Uint8List.fromList([42]);

      final compressed = await compressor.compress(
        original,
        CompressionAlgorithm.gzip,
      );
      final decompressed = await compressor.decompress(
        compressed.bytes,
        CompressionAlgorithm.gzip,
      );

      expect(decompressed, equals(original));
    });

    test('gzip handles binary data', () async {
      final original = Uint8List.fromList(
        List.generate(5000, (i) => i % 256),
      );

      final compressed = await compressor.compress(
        original,
        CompressionAlgorithm.gzip,
      );
      final decompressed = await compressor.decompress(
        compressed.bytes,
        CompressionAlgorithm.gzip,
      );

      expect(decompressed, equals(original));
    });
  });

  group('CompressedData', () {
    test('ratio is calculated correctly', () async {
      final original = Uint8List.fromList(
        ('QRLink file transfer ' * 100).codeUnits,
      );

      final compressed = await compressor.compress(
        original,
        CompressionAlgorithm.gzip,
      );

      expect(compressed.originalSize, equals(original.length));
      expect(compressed.compressedSize, equals(compressed.bytes.length));
      expect(
        compressed.ratio,
        closeTo(
          1 - (compressed.compressedSize / compressed.originalSize),
          0.01,
        ),
      );
    });

    test('algorithm field is set correctly', () async {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);

      final gzipResult = await compressor.compress(
        data,
        CompressionAlgorithm.gzip,
      );
      expect(gzipResult.algorithm, equals(CompressionAlgorithm.gzip));
    });
  });

  group('Auto compression', () {
    test('auto selects best algorithm', () async {
      final original = Uint8List.fromList(
        ('The quick brown fox jumps over the lazy dog. ' * 50).codeUnits,
      );

      final result = await compressor.compress(
        original,
        CompressionAlgorithm.auto,
      );

      // Auto should produce valid compressed data
      expect(result.bytes, isNotEmpty);
      expect(result.compressedSize, lessThan(result.originalSize));
    });
  });

  group('Large file handling', () {
    test('handles 1MB file', () async {
      final original = Uint8List.fromList(
        List.generate(1024 * 1024, (i) => (i * 37 + 13) % 256),
      );

      final compressed = await compressor.compress(
        original,
        CompressionAlgorithm.gzip,
      );
      final decompressed = await compressor.decompress(
        compressed.bytes,
        CompressionAlgorithm.gzip,
      );

      expect(decompressed.length, equals(original.length));
      expect(decompressed, equals(original));
    });
  });
}
