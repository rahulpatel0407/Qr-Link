import 'transfer_session.dart';

class TransferResult {
  final TransferSession session;
  final int originalSize;
  final int compressedSize;
  final Duration transferDuration;
  final int chunksTotal;
  final int chunksReceived;
  final double avgThroughputKBps;
  final double peakThroughputKBps;
  final double compressionRatio;
  final bool sha256Verified;
  final String sha256Hash;
  final String? savedFilePath;

  TransferResult({
    required this.session,
    required this.originalSize,
    required this.compressedSize,
    required this.transferDuration,
    required this.chunksTotal,
    required this.chunksReceived,
    required this.avgThroughputKBps,
    required this.peakThroughputKBps,
    required this.compressionRatio,
    required this.sha256Verified,
    required this.sha256Hash,
    this.savedFilePath,
  });

  double get compressionPercentage {
    if (originalSize == 0) return 0.0;
    return (1.0 - (compressedSize / originalSize)) * 100.0;
  }

  static String formattedSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size.truncateToDouble() == size ? 0 : 2)} ${suffixes[i]}';
  }

  Map<String, dynamic> toMap() {
    return {
      'session': session.toMap(),
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'transferDuration': transferDuration.inMilliseconds,
      'chunksTotal': chunksTotal,
      'chunksReceived': chunksReceived,
      'avgThroughputKBps': avgThroughputKBps,
      'peakThroughputKBps': peakThroughputKBps,
      'compressionRatio': compressionRatio,
      'sha256Verified': sha256Verified ? 1 : 0,
      'sha256Hash': sha256Hash,
      'savedFilePath': savedFilePath,
    };
  }

  factory TransferResult.fromMap(Map<String, dynamic> map) {
    return TransferResult(
      session: TransferSession.fromMap(map['session'] as Map<String, dynamic>),
      originalSize: map['originalSize'] as int,
      compressedSize: map['compressedSize'] as int,
      transferDuration: Duration(milliseconds: map['transferDuration'] as int),
      chunksTotal: map['chunksTotal'] as int,
      chunksReceived: map['chunksReceived'] as int,
      avgThroughputKBps: map['avgThroughputKBps'] as double,
      peakThroughputKBps: map['peakThroughputKBps'] as double,
      compressionRatio: map['compressionRatio'] as double,
      sha256Verified: (map['sha256Verified'] as int) == 1,
      sha256Hash: map['sha256Hash'] as String,
      savedFilePath: map['savedFilePath'] as String?,
    );
  }
}
