import 'dart:typed_data';

/// Service for splitting data into chunks and reassembling them.
class ChunkerService {
  /// Splits [data] into chunks of maximum [chunkSize] bytes.
  List<Uint8List> splitIntoChunks(Uint8List data, {int chunkSize = 1000}) {
    final List<Uint8List> chunks = [];
    int offset = 0;
    while (offset < data.length) {
      final end = (offset + chunkSize < data.length) ? offset + chunkSize : data.length;
      chunks.add(Uint8List.fromList(data.sublist(offset, end)));
      offset += chunkSize;
    }
    return chunks;
  }

  /// Reassembles [chunks] into a single Uint8List.
  /// Returns null if any chunks from 0 to [totalChunks] - 1 are missing.
  Uint8List? reassembleChunks(Map<int, Uint8List> chunks, int totalChunks) {
    if (chunks.length != totalChunks) return null;

    final bb = BytesBuilder();
    for (int i = 0; i < totalChunks; i++) {
      final chunk = chunks[i];
      if (chunk == null) return null;
      bb.add(chunk);
    }
    return bb.toBytes();
  }

  /// Returns a set of missing chunk IDs.
  Set<int> getMissingChunks(Set<int> received, int totalChunks) {
    final missing = <int>{};
    for (int i = 0; i < totalChunks; i++) {
      if (!received.contains(i)) {
        missing.add(i);
      }
    }
    return missing;
  }

  /// Encodes [missing] chunk IDs into a compact bitfield.
  /// 1 bit per chunk, 1 = missing, 0 = received.
  Uint8List encodeMissingChunksBitfield(Set<int> missing, int totalChunks) {
    final int byteLength = (totalChunks + 7) ~/ 8;
    final Uint8List bitfield = Uint8List(byteLength);

    for (int i = 0; i < totalChunks; i++) {
      if (missing.contains(i)) {
        final int byteIndex = i ~/ 8;
        final int bitIndex = i % 8;
        bitfield[byteIndex] |= (1 << bitIndex);
      }
    }
    return bitfield;
  }

  /// Decodes a [bitfield] into a set of missing chunk IDs.
  Set<int> decodeMissingChunksBitfield(Uint8List bitfield, int totalChunks) {
    final missing = <int>{};
    for (int i = 0; i < totalChunks; i++) {
      final int byteIndex = i ~/ 8;
      final int bitIndex = i % 8;
      
      if (byteIndex < bitfield.length) {
        if ((bitfield[byteIndex] & (1 << bitIndex)) != 0) {
          missing.add(i);
        }
      }
    }
    return missing;
  }
}
