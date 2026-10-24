import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrlink/core/services/chunker_service.dart';

void main() {
  late ChunkerService chunker;

  setUp(() {
    chunker = ChunkerService();
  });

  group('splitIntoChunks', () {
    test('file splits into correct number of chunks', () {
      final data = Uint8List.fromList(List.generate(2500, (i) => i % 256));
      final chunks = chunker.splitIntoChunks(data, chunkSize: 1000);

      // 2500 / 1000 = 2 full + 1 partial = 3 chunks
      expect(chunks.length, equals(3));
      expect(chunks[0].length, equals(1000));
      expect(chunks[1].length, equals(1000));
      expect(chunks[2].length, equals(500));
    });

    test('exact multiple produces no partial chunk', () {
      final data = Uint8List.fromList(List.generate(2000, (i) => i % 256));
      final chunks = chunker.splitIntoChunks(data, chunkSize: 1000);

      expect(chunks.length, equals(2));
      expect(chunks[0].length, equals(1000));
      expect(chunks[1].length, equals(1000));
    });

    test('data smaller than chunk size produces single chunk', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      final chunks = chunker.splitIntoChunks(data, chunkSize: 1000);

      expect(chunks.length, equals(1));
      expect(chunks[0], equals(data));
    });

    test('single byte produces single chunk', () {
      final data = Uint8List.fromList([42]);
      final chunks = chunker.splitIntoChunks(data, chunkSize: 500);

      expect(chunks.length, equals(1));
      expect(chunks[0].length, equals(1));
      expect(chunks[0][0], equals(42));
    });

    test('custom chunk size works', () {
      final data = Uint8List.fromList(List.generate(1000, (i) => i % 256));
      final chunks = chunker.splitIntoChunks(data, chunkSize: 200);

      expect(chunks.length, equals(5));
      for (final chunk in chunks) {
        expect(chunk.length, equals(200));
      }
    });
  });

  group('reassembleChunks', () {
    test('reassembled bytes match original exactly', () {
      final original = Uint8List.fromList(
        List.generate(2500, (i) => (i * 7 + 3) % 256),
      );
      final chunks = chunker.splitIntoChunks(original, chunkSize: 1000);

      final chunkMap = <int, Uint8List>{};
      for (int i = 0; i < chunks.length; i++) {
        chunkMap[i] = chunks[i];
      }

      final reassembled = chunker.reassembleChunks(chunkMap, chunks.length);

      expect(reassembled, isNotNull);
      expect(reassembled!.length, equals(original.length));
      expect(reassembled, equals(original));
    });

    test('missing chunk causes incomplete reassembly', () {
      final data = Uint8List.fromList(List.generate(3000, (i) => i % 256));
      final chunks = chunker.splitIntoChunks(data, chunkSize: 1000);

      final chunkMap = <int, Uint8List>{};
      for (int i = 0; i < chunks.length; i++) {
        if (i != 1) {
          // Skip chunk 1
          chunkMap[i] = chunks[i];
        }
      }

      final reassembled = chunker.reassembleChunks(chunkMap, chunks.length);
      expect(reassembled, isNull); // Should return null for incomplete
    });

    test('out-of-order chunks reassemble correctly', () {
      final original = Uint8List.fromList(
        List.generate(3000, (i) => (i * 11 + 5) % 256),
      );
      final chunks = chunker.splitIntoChunks(original, chunkSize: 1000);

      // Add in reverse order
      final chunkMap = <int, Uint8List>{};
      for (int i = chunks.length - 1; i >= 0; i--) {
        chunkMap[i] = chunks[i];
      }

      final reassembled = chunker.reassembleChunks(chunkMap, chunks.length);

      expect(reassembled, isNotNull);
      expect(reassembled, equals(original));
    });
  });

  group('getMissingChunks', () {
    test('identifies all missing chunks', () {
      final received = <int>{0, 2, 4};
      final missing = chunker.getMissingChunks(received, 6);

      expect(missing, equals({1, 3, 5}));
    });

    test('no missing chunks when all received', () {
      final received = <int>{0, 1, 2, 3, 4};
      final missing = chunker.getMissingChunks(received, 5);

      expect(missing, isEmpty);
    });

    test('all chunks missing when none received', () {
      final received = <int>{};
      final missing = chunker.getMissingChunks(received, 3);

      expect(missing, equals({0, 1, 2}));
    });
  });

  group('bitfield encoding', () {
    test('missing chunks bitfield round-trip', () {
      final missing = <int>{1, 3, 7, 15};
      final totalChunks = 20;

      final bitfield = chunker.encodeMissingChunksBitfield(
        missing,
        totalChunks,
      );
      final decoded = chunker.decodeMissingChunksBitfield(
        bitfield,
        totalChunks,
      );

      expect(decoded, equals(missing));
    });

    test('empty missing set produces all-zero bitfield', () {
      final missing = <int>{};
      final totalChunks = 16;

      final bitfield = chunker.encodeMissingChunksBitfield(
        missing,
        totalChunks,
      );
      final decoded = chunker.decodeMissingChunksBitfield(
        bitfield,
        totalChunks,
      );

      expect(decoded, isEmpty);
    });

    test('all chunks missing produces all-one bitfield', () {
      final totalChunks = 8;
      final missing = Set<int>.from(List.generate(totalChunks, (i) => i));

      final bitfield = chunker.encodeMissingChunksBitfield(
        missing,
        totalChunks,
      );
      final decoded = chunker.decodeMissingChunksBitfield(
        bitfield,
        totalChunks,
      );

      expect(decoded, equals(missing));
    });
  });
}
