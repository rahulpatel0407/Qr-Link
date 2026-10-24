import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrlink/core/models/packet.dart';

void main() {
  group('Packet', () {
    test('packet round-trip: build → parse → verify CRC32', () {
      final payload = Uint8List.fromList(
        List.generate(100, (i) => i % 256),
      );
      final sha256 = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        sha256[i] = (i * 7 + 3) % 256;
      }

      final packet = Packet.build(
        chunkId: 5,
        totalChunks: 48,
        payload: payload,
        fileSha256: sha256,
        encrypted: false,
        isLast: false,
        compressionType: CompressionType.gzip,
      );

      final bytes = packet.toBytes();
      final parsed = Packet.parse(bytes);

      expect(parsed, isNotNull);
      expect(parsed!.chunkId, equals(5));
      expect(parsed.totalChunks, equals(48));
      expect(parsed.payload, equals(payload));
      expect(parsed.flags.encrypted, isFalse);
      expect(parsed.flags.isLast, isFalse);
      expect(parsed.flags.compressionType, equals(CompressionType.gzip));
    });

    test('chunk 0 contains SHA-256 hash', () {
      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
      final sha256 = Uint8List.fromList(
        List.generate(32, (i) => (i * 13 + 7) % 256),
      );

      final packet = Packet.build(
        chunkId: 0,
        totalChunks: 10,
        payload: payload,
        fileSha256: sha256,
        encrypted: true,
        isLast: false,
        compressionType: CompressionType.none,
      );

      final parsed = Packet.parse(packet.toBytes());
      expect(parsed, isNotNull);
      expect(parsed!.chunkId, equals(0));
      expect(parsed.fileSha256, equals(sha256));
    });

    test('non-zero chunk has zero SHA-256', () {
      final payload = Uint8List.fromList([10, 20, 30]);
      final zeroSha = Uint8List(32); // all zeros

      final packet = Packet.build(
        chunkId: 5,
        totalChunks: 10,
        payload: payload,
        fileSha256: zeroSha,
        encrypted: false,
        isLast: false,
        compressionType: CompressionType.gzip,
      );

      final parsed = Packet.parse(packet.toBytes());
      expect(parsed, isNotNull);
      expect(parsed!.fileSha256, equals(zeroSha));
    });

    test('flags encode/decode compression type correctly', () {
      for (final ct in CompressionType.values) {
        final flags = PacketFlags(
          encrypted: true,
          isLast: true,
          compressionType: ct,
        );

        final byte = flags.toByte();
        final decoded = PacketFlags.fromByte(byte);

        expect(decoded.encrypted, isTrue);
        expect(decoded.isLast, isTrue);
        expect(decoded.compressionType, equals(ct));
      }
    });

    test('flags encode all combinations correctly', () {
      for (final encrypted in [true, false]) {
        for (final isLast in [true, false]) {
          for (final ct in CompressionType.values) {
            final flags = PacketFlags(
              encrypted: encrypted,
              isLast: isLast,
              compressionType: ct,
            );

            final byte = flags.toByte();
            final decoded = PacketFlags.fromByte(byte);

            expect(decoded.encrypted, equals(encrypted));
            expect(decoded.isLast, equals(isLast));
            expect(decoded.compressionType, equals(ct));
          }
        }
      }
    });

    test('corrupt payload fails CRC32', () {
      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
      final sha256 = Uint8List(32);

      final packet = Packet.build(
        chunkId: 0,
        totalChunks: 1,
        payload: payload,
        fileSha256: sha256,
        encrypted: false,
        isLast: true,
        compressionType: CompressionType.none,
      );

      final bytes = packet.toBytes();
      // Corrupt one byte in the payload area (after 41-byte header)
      bytes[42] = bytes[42] ^ 0xFF;

      final parsed = Packet.parse(bytes);
      // Parse should return null because CRC32 won't match
      expect(parsed, isNull);
    });

    test('base64url round-trip', () {
      final payload = Uint8List.fromList(
        List.generate(200, (i) => i % 256),
      );
      final sha256 = Uint8List(32);

      final packet = Packet.build(
        chunkId: 12,
        totalChunks: 100,
        payload: payload,
        fileSha256: sha256,
        encrypted: false,
        isLast: false,
        compressionType: CompressionType.gzip,
      );

      final encoded = packet.toBase64Url();
      final decoded = Packet.fromBase64Url(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.chunkId, equals(12));
      expect(decoded.totalChunks, equals(100));
      expect(decoded.payload, equals(payload));
    });

    test('isLast flag set on last chunk', () {
      final payload = Uint8List.fromList([99]);
      final sha256 = Uint8List(32);

      final packet = Packet.build(
        chunkId: 47,
        totalChunks: 48,
        payload: payload,
        fileSha256: sha256,
        encrypted: false,
        isLast: true,
        compressionType: CompressionType.none,
      );

      final parsed = Packet.parse(packet.toBytes());
      expect(parsed!.flags.isLast, isTrue);
    });
  });

  group('CRC32', () {
    test('computes consistent CRC32', () {
      final data = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"
      final crc1 = computeCrc32(data);
      final crc2 = computeCrc32(data);
      expect(crc1, equals(crc2));
    });

    test('different data produces different CRC32', () {
      final data1 = Uint8List.fromList([1, 2, 3]);
      final data2 = Uint8List.fromList([1, 2, 4]);
      expect(computeCrc32(data1), isNot(equals(computeCrc32(data2))));
    });

    test('empty data produces valid CRC32', () {
      final data = Uint8List(0);
      final crc = computeCrc32(data);
      expect(crc, isA<int>());
    });
  });
}
