/// QRLink application constants
class AppConstants {
  AppConstants._();

  // ── App Identity ──
  static const String appName = 'QRLink';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Offline File Transfer via Animated QR Codes';

  // ── Chunking Defaults ──
  static const int defaultChunkSize = 1000; // bytes
  static const int minChunkSize = 200;
  static const int maxChunkSize = 2000;

  // ── QR Code ──
  static const int defaultQrVersion = 25; // balanced decode reliability
  static const int maxQrVersion = 40;
  static const int minQrVersion = 10;
  static const String defaultErrorCorrection = 'M';

  // QR Version capacities in binary mode at EC level M (bytes)
  static const Map<int, int> qrVersionCapacityM = {
    10: 271,
    15: 523,
    20: 858,
    25: 1292,
    30: 1732,
    35: 2038,
    40: 2331,
  };

  // QR Version capacities at EC level L (bytes)
  static const Map<int, int> qrVersionCapacityL = {
    10: 346,
    15: 664,
    20: 1091,
    25: 1628,
    30: 2188,
    35: 2573,
    40: 2953,
  };

  // ── FPS ──
  static const int defaultFps = 15;
  static const List<int> fpsOptions = [5, 10, 15, 20, 30];

  // ── Packet Header ──
  static const int packetHeaderSize = 41; // 2+2+4+32+1
  static const int sha256Size = 32;
  static const int sessionIdLength = 8;

  // ── Encryption ──
  static const int pbkdf2Iterations = 200000;
  static const int saltLength = 16;
  static const int nonceLength = 12;
  static const int aesKeyLength = 32; // 256 bits

  // ── Transfer ──
  static const int retransmitTimeoutSeconds = 3;
  static const int minRetransmitTimeout = 1;
  static const int maxRetransmitTimeout = 10;
  static const int framePreBufferCount = 10;

  // ── AI / Optimization ──
  static const double blurThreshold = 100.0;
  static const double lowDensityThreshold = 0.80;
  static const double highDensityThreshold = 0.95;
  static const int lowLightBrightnessThreshold = 50; // out of 255

  // ── CLAHE ──
  static const int claheTileGridX = 8;
  static const int claheTileGridY = 8;
  static const double claheClipLimit = 2.0;

  // ── History ──
  static const int defaultRetentionDays = 30;
  static const List<int> retentionOptions = [7, 30, -1]; // -1 = forever

  // ── Database ──
  static const String dbName = 'qrlink.db';
  static const int dbVersion = 1;
  static const String tableHistory = 'transfer_history';

  // ── Performance ──
  static const int speedGraphWindowSeconds = 30;
  static const int chunkGridMaxCells = 200; // switch to heatmap above this
}
