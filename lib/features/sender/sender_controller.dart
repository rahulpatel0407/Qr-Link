import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../../core/models/packet.dart';
import '../../core/services/compression_service.dart';
import '../../core/services/encryption_service.dart';
import '../../core/services/chunker_service.dart';
import '../../core/services/integrity_service.dart';
import '../../core/services/qr_generator_service.dart';
import '../../core/utils/binary_utils.dart';

enum SenderStatus {
  idle,
  selecting,
  compressing,
  encrypting,
  chunking,
  generating,
  transmitting,
  complete,
}

class SenderState {
  final File? selectedFile;
  final String? fileName;
  final int fileSize;
  final Uint8List? fileBytes;
  final Uint8List? compressedBytes;
  final int compressedSize;
  final Uint8List? encryptedBytes;
  final bool encrypted;
  final String? passphrase;
  final String compressionAlgorithm;
  final List<Uint8List> chunks;
  final List<String> qrFrames;
  final int currentFrameIndex;
  final int totalChunks;
  final String sessionId;
  final int fps;
  final bool isLooping;
  final bool isPaused;
  final SenderStatus status;
  final double progress;
  final String sha256Hash;
  final String? errorMessage;

  SenderState({
    this.selectedFile,
    this.fileName,
    this.fileSize = 0,
    this.fileBytes,
    this.compressedBytes,
    this.compressedSize = 0,
    this.encryptedBytes,
    this.encrypted = false,
    this.passphrase,
    this.compressionAlgorithm = 'Auto',
    this.chunks = const [],
    this.qrFrames = const [],
    this.currentFrameIndex = 0,
    this.totalChunks = 0,
    this.sessionId = '',
    this.fps = 15,
    this.isLooping = true,
    this.isPaused = false,
    this.status = SenderStatus.idle,
    this.progress = 0.0,
    this.sha256Hash = '',
    this.errorMessage,
  });

  SenderState copyWith({
    File? selectedFile,
    String? fileName,
    int? fileSize,
    Uint8List? fileBytes,
    Uint8List? compressedBytes,
    int? compressedSize,
    Uint8List? encryptedBytes,
    bool? encrypted,
    String? passphrase,
    String? compressionAlgorithm,
    List<Uint8List>? chunks,
    List<String>? qrFrames,
    int? currentFrameIndex,
    int? totalChunks,
    String? sessionId,
    int? fps,
    bool? isLooping,
    bool? isPaused,
    SenderStatus? status,
    double? progress,
    String? sha256Hash,
    String? errorMessage,
  }) {
    return SenderState(
      selectedFile: selectedFile ?? this.selectedFile,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileBytes: fileBytes ?? this.fileBytes,
      compressedBytes: compressedBytes ?? this.compressedBytes,
      compressedSize: compressedSize ?? this.compressedSize,
      encryptedBytes: encryptedBytes ?? this.encryptedBytes,
      encrypted: encrypted ?? this.encrypted,
      passphrase: passphrase ?? this.passphrase,
      compressionAlgorithm: compressionAlgorithm ?? this.compressionAlgorithm,
      chunks: chunks ?? this.chunks,
      qrFrames: qrFrames ?? this.qrFrames,
      currentFrameIndex: currentFrameIndex ?? this.currentFrameIndex,
      totalChunks: totalChunks ?? this.totalChunks,
      sessionId: sessionId ?? this.sessionId,
      fps: fps ?? this.fps,
      isLooping: isLooping ?? this.isLooping,
      isPaused: isPaused ?? this.isPaused,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Human-readable compressed size display
  String get compressedSizeDisplay => BinaryUtils.formatSize(compressedSize);
  String get fileSizeDisplay => BinaryUtils.formatSize(fileSize);

  /// Compression ratio as a percentage
  double get compressionRatio =>
      fileSize > 0 ? (1.0 - compressedSize / fileSize) * 100 : 0;
}

class SenderController extends StateNotifier<SenderState> {
  SenderController()
      : super(SenderState(
            sessionId: const Uuid().v4().substring(0, 8).toUpperCase()));

  final _compressionService = CompressionService();
  final _encryptionService = EncryptionService();
  final _chunkerService = ChunkerService();

  /// Pick a file from device storage
  Future<void> selectFile() async {
    state = state.copyWith(status: SenderStatus.selecting);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        final path = file.path;

        Uint8List fileBytes;
        if (bytes != null) {
          fileBytes = bytes;
        } else if (path != null) {
          fileBytes = await File(path).readAsBytes();
        } else {
          throw Exception('Could not read file data');
        }

        state = state.copyWith(
          selectedFile: path != null ? File(path) : null,
          fileName: file.name,
          fileSize: fileBytes.length,
          fileBytes: fileBytes,
          status: SenderStatus.idle,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(status: SenderStatus.idle);
      }
    } catch (e) {
      state = state.copyWith(
        status: SenderStatus.idle,
        errorMessage: 'File selection failed: $e',
      );
    }
  }

  /// Full transfer pipeline: compress → encrypt → SHA-256 → chunk → build packets → generate frames
  Future<void> startTransfer({
    String? passphrase,
    bool encrypt = false,
    int chunkSize = 1000,
  }) async {
    if (state.fileBytes == null) return;

    try {
      state = state.copyWith(
        encrypted: encrypt,
        passphrase: passphrase,
        sessionId: const Uuid().v4().substring(0, 8).toUpperCase(),
        errorMessage: null,
      );

      // Step 1: Compress
      await _compress();

      // Step 2: Encrypt (optional)
      Uint8List dataToChunk;
      if (encrypt && passphrase != null && passphrase.isNotEmpty) {
        await _encrypt(passphrase);
        dataToChunk = state.encryptedBytes!;
      } else {
        state = state.copyWith(encryptedBytes: state.compressedBytes);
        dataToChunk = state.compressedBytes!;
      }

      // Step 3: Compute SHA-256 of the data that will be chunked
      state = state.copyWith(progress: 0.5);
      final sha256Hash = IntegrityService.computeSha256Hex(dataToChunk);
      final sha256Bytes = IntegrityService.computeSha256(dataToChunk);
      state = state.copyWith(sha256Hash: sha256Hash);

      // Step 4: Split into chunks
      await _chunk(dataToChunk, chunkSize);

      // Step 5: Build packets and generate QR frames
      await _buildPacketsAndGenerateFrames(sha256Bytes);

      state = state.copyWith(
        status: SenderStatus.transmitting,
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        status: SenderStatus.idle,
        errorMessage: 'Transfer failed: $e',
      );
    }
  }

  Future<void> _compress() async {
    state = state.copyWith(status: SenderStatus.compressing, progress: 0.1);

    final algo = state.compressionAlgorithm == 'GZip'
        ? CompressionAlgorithm.gzip
        : CompressionAlgorithm.auto;

    final result = await _compressionService.compress(state.fileBytes!, algo);

    state = state.copyWith(
      compressedBytes: result.bytes,
      compressedSize: result.compressedSize,
      progress: 0.3,
    );
  }

  Future<void> _encrypt(String passphrase) async {
    state = state.copyWith(status: SenderStatus.encrypting, progress: 0.4);
    final encrypted =
        await _encryptionService.encrypt(state.compressedBytes!, passphrase);
    state = state.copyWith(encryptedBytes: encrypted);
  }

  Future<void> _chunk(Uint8List data, int chunkSize) async {
    state = state.copyWith(status: SenderStatus.chunking, progress: 0.6);
    final chunks = _chunkerService.splitIntoChunks(data, chunkSize: chunkSize);
    state = state.copyWith(chunks: chunks, totalChunks: chunks.length);
  }

  Future<void> _buildPacketsAndGenerateFrames(Uint8List fileSha256) async {
    state = state.copyWith(status: SenderStatus.generating, progress: 0.8);

    final List<Uint8List> packetBytes = [];
    for (int i = 0; i < state.chunks.length; i++) {
      final packet = Packet.build(
        chunkId: i,
        totalChunks: state.chunks.length,
        payload: state.chunks[i],
        fileSha256: i == 0 ? fileSha256 : Uint8List(32), // SHA-256 only in chunk 0
        encrypted: state.encrypted,
        isLast: i == state.chunks.length - 1,
        compressionType: CompressionType.gzip,
        sessionId: state.sessionId,
      );
      packetBytes.add(packet.toBytes());
    }

    // Generate base64url frames
    final generator = QRGeneratorService();
    final frames = generator.generateFrames(packetBytes);

    state = state.copyWith(qrFrames: frames);
  }

  /// Advance to next QR frame (called by display timer)
  void advanceFrame() {
    if (state.isPaused || state.qrFrames.isEmpty) return;

    int nextIndex = state.currentFrameIndex + 1;
    if (nextIndex >= state.qrFrames.length) {
      if (state.isLooping) {
        nextIndex = 0;
      } else {
        state = state.copyWith(status: SenderStatus.complete);
        return;
      }
    }
    state = state.copyWith(currentFrameIndex: nextIndex);
  }

  void pause() => state = state.copyWith(isPaused: true);
  void resume() => state = state.copyWith(isPaused: false);
  void setFps(int fps) => state = state.copyWith(fps: fps);
  void setLooping(bool looping) => state = state.copyWith(isLooping: looping);

  void setCompressionAlgorithm(String algo) =>
      state = state.copyWith(compressionAlgorithm: algo);

  /// Reorder frames to prioritize missing chunks for retransmission
  void handleRetransmitRequest(Set<int> missingChunks) {
    if (state.qrFrames.isEmpty || missingChunks.isEmpty) return;

    final generator = QRGeneratorService();
    final reordered =
        generator.reorderForRetransmit(state.qrFrames, missingChunks);

    state = state.copyWith(
      qrFrames: reordered,
      currentFrameIndex: 0,
    );
  }

  void reset() {
    state = SenderState(
      sessionId: const Uuid().v4().substring(0, 8).toUpperCase(),
    );
  }
}

final senderControllerProvider =
    StateNotifierProvider<SenderController, SenderState>((ref) {
  return SenderController();
});
