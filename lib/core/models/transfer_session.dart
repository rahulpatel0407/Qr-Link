import 'dart:math';
import 'packet.dart';

enum TransferStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled
}

class TransferSession {
  final String sessionId;
  final String fileName;
  final int fileSize;
  final int compressedSize;
  final int totalChunks;
  final CompressionType compressionType;
  final bool encrypted;
  final String fileSha256;
  final DateTime startTime;
  final DateTime? endTime;
  final TransferStatus status;

  TransferSession({
    required this.sessionId,
    required this.fileName,
    required this.fileSize,
    required this.compressedSize,
    required this.totalChunks,
    required this.compressionType,
    required this.encrypted,
    required this.fileSha256,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  double get throughputKBps {
    final millis = duration.inMilliseconds;
    if (millis == 0) return 0.0;
    final totalBytes = compressedSize > 0 ? compressedSize : fileSize;
    return (totalBytes / 1024.0) / (millis / 1000.0);
  }

  static String generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(4, (i) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'fileName': fileName,
      'fileSize': fileSize,
      'compressedSize': compressedSize,
      'totalChunks': totalChunks,
      'compressionType': compressionType.value,
      'encrypted': encrypted ? 1 : 0,
      'fileSha256': fileSha256,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.name,
    };
  }

  factory TransferSession.fromMap(Map<String, dynamic> map) {
    return TransferSession(
      sessionId: map['sessionId'] as String,
      fileName: map['fileName'] as String,
      fileSize: map['fileSize'] as int,
      compressedSize: map['compressedSize'] as int,
      totalChunks: map['totalChunks'] as int,
      compressionType: CompressionType.fromInt(map['compressionType'] as int),
      encrypted: (map['encrypted'] as int) == 1,
      fileSha256: map['fileSha256'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      status: TransferStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransferStatus.pending,
      ),
    );
  }
}
