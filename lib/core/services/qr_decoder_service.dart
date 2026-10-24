import 'dart:convert';
import 'dart:typed_data';
import '../models/packet.dart';

enum ProcessResult {
  newChunk,
  duplicate,
  corrupt,
  sessionChanged
}

class ReceiverState {
  final Map<int, Uint8List> receivedChunks = {};
  int totalChunks = -1;
  String sessionId = '';
  Uint8List? fileSha256;
  final Set<int> missingChunks = {};
  DateTime startTime = DateTime.now();
  DateTime lastReceiveTime = DateTime.now();
  int decodeSuccessCount = 0;
  int decodeFailCount = 0;
}

class QRDecoderService {
  Packet? decodeFrame(String base64UrlData) {
    try {
      final Uint8List bytes = base64Url.decode(base64UrlData);
      final Packet packet = Packet.fromBytes(bytes);
      if (!packet.verifyCrc32()) {
        return null;
      }
      return packet;
    } catch (e) {
      return null;
    }
  }

  ProcessResult processFrame(ReceiverState state, String frameData) {
    final Packet? packet = decodeFrame(frameData);
    if (packet == null) {
      state.decodeFailCount++;
      return ProcessResult.corrupt;
    }

    if (state.sessionId.isNotEmpty && state.sessionId != packet.sessionId) {
      return ProcessResult.sessionChanged;
    }

    state.decodeSuccessCount++;
    state.lastReceiveTime = DateTime.now();

    if (state.sessionId.isEmpty) {
      state.sessionId = packet.sessionId;
      state.totalChunks = packet.totalChunks;
      state.missingChunks.addAll(List.generate(packet.totalChunks, (index) => index));
    }

    if (packet.chunkId == 0 && packet.fileSha256 != null) {
      state.fileSha256 = packet.fileSha256;
    }

    if (state.receivedChunks.containsKey(packet.chunkId)) {
      return ProcessResult.duplicate;
    }

    state.receivedChunks[packet.chunkId] = packet.payload;
    state.missingChunks.remove(packet.chunkId);
    
    return ProcessResult.newChunk;
  }

  bool isComplete(ReceiverState state) {
    return state.totalChunks > 0 && state.receivedChunks.length == state.totalChunks;
  }

  double getProgress(ReceiverState state) {
    if (state.totalChunks <= 0) return 0.0;
    return state.receivedChunks.length / state.totalChunks;
  }

  double getDecodeSuccessRate(ReceiverState state) {
    final int total = state.decodeSuccessCount + state.decodeFailCount;
    if (total == 0) return 1.0;
    return state.decodeSuccessCount / total;
  }

  String? generateMissingChunksQR(ReceiverState state) {
    if (state.missingChunks.isEmpty || state.totalChunks <= 0) return null;
    
    // Simple bitfield: 1 bit per chunk, 1 = missing, 0 = received
    final int byteLength = (state.totalChunks + 7) ~/ 8;
    final Uint8List bitfield = Uint8List(byteLength);
    
    for (int chunkId in state.missingChunks) {
      if (chunkId < state.totalChunks) {
        final int byteIndex = chunkId ~/ 8;
        final int bitIndex = chunkId % 8;
        bitfield[byteIndex] |= (1 << bitIndex);
      }
    }
    
    return base64UrlEncode(bitfield);
  }
}
