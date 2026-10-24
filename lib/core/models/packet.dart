import 'dart:convert';
import 'dart:typed_data';

enum CompressionType {
  none(0),
  gzip(1),
  brotli(2),
  zstd(3);

  final int value;
  const CompressionType(this.value);

  static CompressionType fromInt(int value) {
    return CompressionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CompressionType.none,
    );
  }
}

class PacketFlags {
  final bool encrypted;
  final bool isLast;
  final CompressionType compressionType;

  const PacketFlags({
    required this.encrypted,
    required this.isLast,
    required this.compressionType,
  });

  int toByte() {
    int byte = 0;
    if (encrypted) byte |= 1;
    if (isLast) byte |= 2;
    byte |= (compressionType.value << 2);
    return byte;
  }

  factory PacketFlags.fromByte(int byte) {
    return PacketFlags(
      encrypted: (byte & 1) != 0,
      isLast: (byte & 2) != 0,
      compressionType: CompressionType.fromInt((byte >> 2) & 0x3F),
    );
  }
}

class Packet {
  final int chunkId;
  final int totalChunks;
  final int crc32;
  final Uint8List fileSha256;
  final PacketFlags flags;
  final String sessionId;
  final Uint8List payload;

  Packet({
    required this.chunkId,
    required this.totalChunks,
    required this.crc32,
    required this.fileSha256,
    required this.flags,
    required this.sessionId,
    required this.payload,
  }) {
    if (fileSha256.length != 32) {
      throw ArgumentError('fileSha256 must be exactly 32 bytes');
    }
  }

  /// Convenience factory with direct parameters (matches common usage pattern)
  static Packet build({
    required int chunkId,
    required int totalChunks,
    required Uint8List payload,
    required Uint8List fileSha256,
    bool encrypted = false,
    bool isLast = false,
    CompressionType compressionType = CompressionType.none,
    String sessionId = '',
    PacketFlags? flags,
  }) {
    final packetFlags = flags ?? PacketFlags(
      encrypted: encrypted,
      isLast: isLast,
      compressionType: compressionType,
    );
    final computedCrc32 = computeCrc32(payload);
    
    return Packet(
      chunkId: chunkId,
      totalChunks: totalChunks,
      crc32: computedCrc32,
      fileSha256: fileSha256,
      flags: packetFlags,
      sessionId: sessionId,
      payload: payload,
    );
  }

  Uint8List toBytes() {
    final bytes = BytesBuilder();
    final header = ByteData(41);
    
    header.setUint16(0, chunkId, Endian.big);
    header.setUint16(2, totalChunks, Endian.big);
    header.setUint32(4, crc32, Endian.big);
    
    for (int i = 0; i < 32; i++) {
      header.setUint8(8 + i, fileSha256[i]);
    }
    
    header.setUint8(40, flags.toByte());
    
    bytes.add(header.buffer.asUint8List());
    bytes.add(payload);
    
    return bytes.toBytes();
  }

  /// Parse raw bytes into a Packet. Returns null if CRC32 validation fails
  /// or data is too small/corrupt.
  static Packet? parse(Uint8List raw, {String sessionId = ''}) {
    if (raw.length < 41) {
      return null;
    }

    final header = ByteData.sublistView(raw, 0, 41);
    final chunkId = header.getUint16(0, Endian.big);
    final totalChunks = header.getUint16(2, Endian.big);
    final crc32 = header.getUint32(4, Endian.big);
    
    final fileSha256 = Uint8List.fromList(raw.sublist(8, 40));
    final flags = PacketFlags.fromByte(header.getUint8(40));
    
    final payload = Uint8List.fromList(raw.sublist(41));
    
    // Validate CRC32 — reject corrupt packets silently
    final computedCrc32 = computeCrc32(payload);
    if (computedCrc32 != crc32) {
      return null;
    }

    return Packet(
      chunkId: chunkId,
      totalChunks: totalChunks,
      crc32: crc32,
      fileSha256: fileSha256,
      flags: flags,
      sessionId: sessionId,
      payload: payload,
    );
  }
  
  String toBase64Url() {
    return base64Url.encode(toBytes()).replaceAll('=', '');
  }
  
  /// Parse from base64url string. Returns null if data is corrupt.
  static Packet? fromBase64Url(String b64url, {String sessionId = ''}) {
    try {
      String padded = b64url;
      final remainder = padded.length % 4;
      if (remainder > 0) {
        padded += '=' * (4 - remainder);
      }
      return Packet.parse(base64Url.decode(padded), sessionId: sessionId);
    } catch (_) {
      return null;
    }
  }
}

int computeCrc32(Uint8List data) {
  final crcTable = _generateCrc32Table();
  int crc = 0xFFFFFFFF;
  for (int i = 0; i < data.length; i++) {
    crc = (crc >> 8) ^ crcTable[(crc ^ data[i]) & 0xFF];
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

List<int> _generateCrc32Table() {
  final table = List<int>.filled(256, 0);
  for (int i = 0; i < 256; i++) {
    int crc = i;
    for (int j = 0; j < 8; j++) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
    table[i] = crc & 0xFFFFFFFF;
  }
  return table;
}
