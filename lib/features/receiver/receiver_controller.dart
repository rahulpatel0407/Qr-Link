import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/packet.dart';
import '../../core/services/integrity_service.dart';
import '../../core/services/chunker_service.dart';
import '../../core/services/compression_service.dart';
import '../../core/services/encryption_service.dart';
import '../../core/utils/binary_utils.dart';

enum ReceiverStatus {
  waiting,
  scanning,
  receiving,
  reassembling,
  complete,
  error,
}

enum ProcessResult {
  newChunk,
  duplicate,
  corrupt,
  sessionChanged,
}

class ReceiverState {
  final Map<int, Uint8List> receivedChunks;
  final int totalChunks;
  final String sessionId;
  final Uint8List? fileSha256;
  final Set<int> missingChunks;
  final DateTime? startTime;
  final DateTime? lastReceiveTime;
  final bool isComplete;
  final int decodeSuccessCount;
  final int decodeFailCount;
  final List<double> speedHistory;
  final ReceiverStatus status;
  final String? errorMessage;
  final String? fileName;
  final int compressionType;
  final bool encrypted;
  final Uint8List? assembledData;
  final String? savedFilePath;

  ReceiverState({
    this.receivedChunks = const {},
    this.totalChunks = 0,
    this.sessionId = '',
    this.fileSha256,
    this.missingChunks = const {},
    this.startTime,
    this.lastReceiveTime,
    this.isComplete = false,
    this.decodeSuccessCount = 0,
    this.decodeFailCount = 0,
    this.speedHistory = const [],
    this.status = ReceiverStatus.waiting,
    this.errorMessage,
    this.fileName,
    this.compressionType = 0,
    this.encrypted = false,
    this.assembledData,
    this.savedFilePath,
  });

  ReceiverState copyWith({
    Map<int, Uint8List>? receivedChunks,
    int? totalChunks,
    String? sessionId,
    Uint8List? fileSha256,
    Set<int>? missingChunks,
    DateTime? startTime,
    DateTime? lastReceiveTime,
    bool? isComplete,
    int? decodeSuccessCount,
    int? decodeFailCount,
    List<double>? speedHistory,
    ReceiverStatus? status,
    String? errorMessage,
    String? fileName,
    int? compressionType,
    bool? encrypted,
    Uint8List? assembledData,
    String? savedFilePath,
  }) {
    return ReceiverState(
      receivedChunks: receivedChunks ?? this.receivedChunks,
      totalChunks: totalChunks ?? this.totalChunks,
      sessionId: sessionId ?? this.sessionId,
      fileSha256: fileSha256 ?? this.fileSha256,
      missingChunks: missingChunks ?? this.missingChunks,
      startTime: startTime ?? this.startTime,
      lastReceiveTime: lastReceiveTime ?? this.lastReceiveTime,
      isComplete: isComplete ?? this.isComplete,
      decodeSuccessCount: decodeSuccessCount ?? this.decodeSuccessCount,
      decodeFailCount: decodeFailCount ?? this.decodeFailCount,
      speedHistory: speedHistory ?? this.speedHistory,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      fileName: fileName ?? this.fileName,
      compressionType: compressionType ?? this.compressionType,
      encrypted: encrypted ?? this.encrypted,
      assembledData: assembledData ?? this.assembledData,
      savedFilePath: savedFilePath ?? this.savedFilePath,
    );
  }

  /// Progress from 0.0 to 1.0
  double get progress =>
      totalChunks == 0 ? 0.0 : receivedChunks.length / totalChunks;

  /// Percentage string
  String get progressPercent => '${(progress * 100).toStringAsFixed(0)}%';

  /// Decode success rate
  double get decodeSuccessRate {
    final total = decodeSuccessCount + decodeFailCount;
    return total == 0 ? 1.0 : decodeSuccessCount / total;
  }
}

class ReceiverController extends StateNotifier<ReceiverState> {
  ReceiverController() : super(ReceiverState());

  final _chunkerService = ChunkerService();
  int _totalBytesReceived = 0;
  DateTime? _lastSpeedCalcTime;

  /// Process a scanned QR code's raw string data.
  /// Decodes base64url → parses packet → validates CRC32 → stores chunk.
  ProcessResult processScannedData(String rawData) {
    try {
      // Base64url decode → parse packet (includes CRC32 validation)
      final packet = Packet.fromBase64Url(rawData);
      if (packet == null) {
        state = state.copyWith(
          decodeFailCount: state.decodeFailCount + 1,
        );
        return ProcessResult.corrupt;
      }

      // Check for session change (via chunk 0 SHA-256 as session marker)
      if (state.sessionId.isNotEmpty &&
          packet.sessionId.isNotEmpty &&
          packet.sessionId != state.sessionId) {
        // New session detected — reset and start fresh
        reset();
        state = state.copyWith(
          status: ReceiverStatus.receiving,
          sessionId: packet.sessionId,
          startTime: DateTime.now(),
        );
        return ProcessResult.sessionChanged;
      }

      // First packet — initialize state
      if (state.status == ReceiverStatus.waiting ||
          state.status == ReceiverStatus.scanning) {
        state = state.copyWith(
          status: ReceiverStatus.receiving,
          totalChunks: packet.totalChunks,
          sessionId:
              packet.sessionId.isNotEmpty ? packet.sessionId : 'LINKED',
          startTime: DateTime.now(),
          missingChunks:
              Set.from(List.generate(packet.totalChunks, (i) => i)),
          encrypted: packet.flags.encrypted,
          compressionType: packet.flags.compressionType.value,
        );
      }

      // Extract SHA-256 from chunk 0
      if (packet.chunkId == 0) {
        final isNonZero = packet.fileSha256.any((b) => b != 0);
        if (isNonZero) {
          state = state.copyWith(fileSha256: packet.fileSha256);
        }
      }

      // Check for duplicate
      if (state.receivedChunks.containsKey(packet.chunkId)) {
        return ProcessResult.duplicate;
      }

      // Store the chunk
      final newChunks = Map<int, Uint8List>.from(state.receivedChunks)
        ..[packet.chunkId] = packet.payload;
      final newMissing = Set<int>.from(state.missingChunks)
        ..remove(packet.chunkId);

      _totalBytesReceived += packet.payload.length;

      state = state.copyWith(
        receivedChunks: newChunks,
        missingChunks: newMissing,
        decodeSuccessCount: state.decodeSuccessCount + 1,
        lastReceiveTime: DateTime.now(),
      );

      _updateSpeedHistory();

      // Check if transfer is complete
      if (newMissing.isEmpty) {
        state = state.copyWith(
          status: ReceiverStatus.reassembling,
          isComplete: true,
        );
      }

      return ProcessResult.newChunk;
    } catch (e) {
      state = state.copyWith(
        decodeFailCount: state.decodeFailCount + 1,
      );
      return ProcessResult.corrupt;
    }
  }

  /// Update the rolling speed history (KB/s over last 30 seconds)
  void _updateSpeedHistory() {
    final now = DateTime.now();
    if (_lastSpeedCalcTime == null) {
      _lastSpeedCalcTime = now;
      return;
    }

    final elapsed = now.difference(_lastSpeedCalcTime!).inMilliseconds;
    if (elapsed > 500) {
      // Calculate speed every 500ms
      final speedKBps = (_totalBytesReceived / 1024) /
          (now.difference(state.startTime!).inMilliseconds / 1000);

      final history = List<double>.from(state.speedHistory);
      history.add(speedKBps);
      if (history.length > 60) history.removeAt(0); // Keep last 60 readings

      state = state.copyWith(speedHistory: history);
      _lastSpeedCalcTime = now;
    }
  }

  /// Reassemble all received chunks in order.
  /// Returns the assembled byte data or null if incomplete.
  Uint8List? reassemble() {
    final assembled = _chunkerService.reassembleChunks(
      state.receivedChunks,
      state.totalChunks,
    );

    if (assembled == null) {
      state = state.copyWith(
        status: ReceiverStatus.error,
        errorMessage: 'Missing chunks — cannot reassemble',
      );
      return null;
    }

    // Verify SHA-256 integrity
    if (state.fileSha256 != null) {
      final isValid = IntegrityService.verifyIntegrity(
        assembled,
        state.fileSha256!,
      );

      if (!isValid) {
        state = state.copyWith(
          status: ReceiverStatus.error,
          errorMessage:
              'SHA-256 integrity check failed — data may be corrupted',
        );
        return assembled; // Return data anyway, user can retry
      }
    }

    state = state.copyWith(
      status: ReceiverStatus.complete,
      assembledData: assembled,
    );
    return assembled;
  }

  /// Decompress the assembled data
  Future<Uint8List?> decompressAssembled() async {
    if (state.assembledData == null) return null;

    final compressor = CompressionService();
    try {
      return await compressor.decompress(
        state.assembledData!,
        CompressionAlgorithm.gzip,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Decompression failed: $e',
      );
      return null;
    }
  }

  /// Decrypt the assembled data
  Future<Uint8List?> decryptAssembled(String passphrase) async {
    if (state.assembledData == null) return null;

    final encryptor = EncryptionService();
    try {
      return await encryptor.decrypt(state.assembledData!, passphrase);
    } on DecryptionException catch (e) {
      state = state.copyWith(
        errorMessage: e.message,
      );
      return null;
    }
  }

  /// Get progress as 0.0–1.0
  double getProgress() => state.progress;

  /// Get decode success rate as 0.0–1.0
  double getDecodeSuccessRate() => state.decodeSuccessRate;

  /// Estimated time remaining based on current speed
  Duration? getEstimatedTimeRemaining() {
    if (state.speedHistory.isEmpty || state.missingChunks.isEmpty) return null;

    final avgSpeed = state.speedHistory.last; // KB/s
    if (avgSpeed <= 0) return null;

    // Estimate remaining bytes (missing chunks × average chunk size)
    final avgChunkSize = _totalBytesReceived /
        (state.receivedChunks.isEmpty ? 1 : state.receivedChunks.length);
    final remainingBytes = state.missingChunks.length * avgChunkSize;
    final remainingSeconds = remainingBytes / (avgSpeed * 1024);

    return Duration(seconds: remainingSeconds.ceil());
  }

  /// Generate a missing-chunks QR code for selective retransmit
  String? generateMissingChunksQR() {
    if (state.missingChunks.isEmpty) return null;

    final bitfield = _chunkerService.encodeMissingChunksBitfield(
      state.missingChunks,
      state.totalChunks,
    );
    return base64Url.encode(bitfield).replaceAll('=', '');
  }

  void reset() {
    _totalBytesReceived = 0;
    _lastSpeedCalcTime = null;
    state = ReceiverState();
  }
}

final receiverControllerProvider =
    StateNotifierProvider<ReceiverController, ReceiverState>((ref) {
  return ReceiverController();
});
