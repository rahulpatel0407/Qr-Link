import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

class QRGeneratorService {
  /// Generates base64url encoded frames from raw packet bytes
  List<String> generateFrames(List<Uint8List> packets) {
    return packets.map((packet) => base64UrlEncode(packet)).toList();
  }

  /// Generates base64url encoded frames from raw packet bytes in a background isolate
  Future<List<String>> generateFramesAsync(List<Uint8List> packets) async {
    return await Isolate.run(() => QRGeneratorService().generateFrames(packets));
  }

  /// Reorders frames by moving missing chunks to the front
  List<String> reorderForRetransmit(List<String> frames, Set<int> missingChunkIds) {
    final List<String> missing = [];
    final List<String> rest = [];
    
    for (int i = 0; i < frames.length; i++) {
      if (missingChunkIds.contains(i)) {
        missing.add(frames[i]);
      } else {
        rest.add(frames[i]);
      }
    }
    
    return [...missing, ...rest];
  }

  /// Returns frame at index with wrapping (modulo)
  String getFrameData(List<String> frames, int index) {
    if (frames.isEmpty) return '';
    return frames[index % frames.length];
  }

  /// Estimates recommended QR version based on base64url encoded length (EC Level M)
  int estimateQrVersion(int dataLength) {
    // Alphanumeric capacity table for EC Level M, versions 1 to 40
    const List<int> capacities = [
      20, 38, 61, 90, 122, 154, 195, 238, 282, 331,
      382, 439, 499, 553, 618, 686, 755, 826, 901, 977,
      1056, 1140, 1228, 1318, 1413, 1509, 1611, 1713, 1818, 1927,
      2039, 2154, 2271, 2391, 2513, 2639, 2769, 2899, 3034, 3173
    ];
    
    for (int i = 0; i < capacities.length; i++) {
      if (dataLength <= capacities[i]) {
        return i + 1; // QR versions are 1-indexed
      }
    }
    return 40; // Max version
  }
}
