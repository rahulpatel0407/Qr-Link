# QRLink — Offline File Transfer via Animated QR Codes

QRLink is a Flutter mobile application that transfers files between two devices without Internet, Bluetooth, Wi-Fi, NFC, or USB. It works by displaying animated QR codes on one device's screen and scanning them with the other device's camera. The app includes compression, optional AES-256 encryption, integrity verification, and AI-powered optimization for reliable transfers.

## How It Works

The transfer pipeline consists of 12 steps across sender and receiver:

1. **File Selection** — User picks any file from their device (documents, images, PDFs, APKs, etc.)
2. **Compression** — File is compressed using GZip to minimize transfer size (runs in background isolate)
3. **Encryption (Optional)** — If enabled, file is encrypted with AES-256-GCM using a user-provided passphrase with PBKDF2 key derivation (200,000 iterations)
4. **SHA-256 Hash** — A SHA-256 hash of the complete file is computed for end-to-end integrity verification
5. **Chunking** — Compressed/encrypted bytes are split into fixed-size chunks (configurable 200–2000 bytes)
6. **Packet Building** — Each chunk is wrapped in a binary packet with: chunk ID, total chunks, CRC32 checksum, SHA-256 hash (chunk 0 only), flags, and payload
7. **QR Frame Generation** — Each packet is base64url-encoded and prepared as QR code data
8. **Animated Display** — QR frames are displayed as a looping animation at configurable FPS (5–30)
9. **Camera Scanning** — Receiver's camera continuously scans the animated QR stream using ML Kit
10. **Packet Validation** — Each decoded frame is base64url-decoded, parsed, and CRC32-verified; corrupt packets are discarded
11. **Reassembly & Verification** — Once all chunks are received, they're assembled in order and SHA-256 is verified against the hash embedded in chunk 0
12. **Decryption & Save** — File is decrypted (if encrypted), decompressed, and saved to device storage

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        QRLink Architecture                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  SENDER DEVICE                    RECEIVER DEVICE                │
│  ┌──────────────┐                ┌──────────────┐                │
│  │ Select File   │                │ Camera Scan   │                │
│  │      ↓        │                │      ↓        │                │
│  │ Compress      │                │ Decode QR     │                │
│  │      ↓        │                │      ↓        │                │
│  │ Encrypt?      │                │ Validate CRC  │                │
│  │      ↓        │                │      ↓        │                │
│  │ SHA-256 Hash  │                │ Store Chunk   │                │
│  │      ↓        │  ┌──────────┐ │      ↓        │                │
│  │ Split Chunks  │  │ Animated │ │ All received? │                │
│  │      ↓        │  │ QR Codes │ │      ↓        │                │
│  │ Build Packets │──│ ■■■■■■■■ │─│ Reassemble    │                │
│  │      ↓        │  │ Display  │ │      ↓        │                │
│  │ Base64url     │  └──────────┘ │ Verify SHA256 │                │
│  │      ↓        │                │      ↓        │                │
│  │ QR Frames     │                │ Decrypt?      │                │
│  │      ↓        │                │      ↓        │                │
│  │ Animate Loop  │                │ Decompress    │                │
│  └──────────────┘                │      ↓        │                │
│                                   │ Save File     │                │
│                                   └──────────────┘                │
│                                                                   │
│  ── AI Optimization Layer ──────────────────────────────────     │
│  • Blur Detection (Laplacian Variance)                           │
│  • Adaptive QR Density (auto-adjust version/EC)                  │
│  • Low-Light Enhancement (CLAHE)                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
qrlink/
├── lib/
│   ├── main.dart                         # App entry point
│   ├── app.dart                          # MaterialApp, theme, routes
│   ├── core/
│   │   ├── models/
│   │   │   ├── packet.dart               # Binary packet protocol
│   │   │   ├── transfer_session.dart     # Session metadata
│   │   │   └── transfer_result.dart      # Transfer statistics
│   │   ├── services/
│   │   │   ├── compression_service.dart  # GZip compression
│   │   │   ├── encryption_service.dart   # AES-256-GCM
│   │   │   ├── chunker_service.dart      # Split/reassemble
│   │   │   ├── qr_generator_service.dart # QR frame generation
│   │   │   ├── qr_decoder_service.dart   # QR frame decoding
│   │   │   ├── integrity_service.dart    # SHA-256 + CRC32
│   │   │   └── storage_service.dart      # File I/O + SQLite
│   │   ├── ai/
│   │   │   ├── blur_detector.dart        # Laplacian variance
│   │   │   ├── adaptive_density.dart     # Auto QR density
│   │   │   └── low_light_enhancer.dart   # Pure Dart CLAHE
│   │   └── utils/
│   │       ├── binary_utils.dart         # Binary data helpers
│   │       ├── base64url.dart            # Base64URL codec
│   │       └── constants.dart            # App-wide constants
│   ├── features/
│   │   ├── home/
│   │   │   └── home_screen.dart          # Send/Receive mode selector
│   │   ├── sender/
│   │   │   ├── sender_screen.dart        # Sender orchestration
│   │   │   ├── sender_controller.dart    # Riverpod state management
│   │   │   ├── file_picker_widget.dart   # File selection UI
│   │   │   └── qr_display_widget.dart    # Animated QR engine
│   │   ├── receiver/
│   │   │   ├── receiver_screen.dart      # Receiver orchestration
│   │   │   ├── receiver_controller.dart  # Riverpod state management
│   │   │   ├── camera_viewfinder.dart    # Camera + overlay
│   │   │   └── chunk_grid_widget.dart    # Visual chunk progress
│   │   ├── result/
│   │   │   ├── transfer_result_screen.dart
│   │   │   └── file_action_bar.dart      # Save/Share/Open
│   │   ├── history/
│   │   │   └── history_screen.dart       # Transfer history
│   │   └── settings/
│   │       └── settings_screen.dart      # All configuration
│   └── theme/
│       ├── app_theme.dart                # Dark space-tech theme
│       └── app_colors.dart               # Color palette
├── test/
│   └── unit/
│       ├── packet_test.dart
│       ├── chunker_test.dart
│       ├── compression_test.dart
│       ├── encryption_test.dart
│       └── integrity_test.dart
├── pubspec.yaml
└── README.md
```

## Getting Started

### Prerequisites
- Flutter SDK >= 3.16.0
- Dart SDK >= 3.0.0
- Android Studio (for Android development)
- An Android device or emulator

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd qrlink

# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Or build debug APK
flutter build apk --debug
```

## Running Tests

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/unit/packet_test.dart
flutter test test/unit/chunker_test.dart
flutter test test/unit/compression_test.dart
flutter test test/unit/encryption_test.dart
flutter test test/unit/integrity_test.dart

# Run with verbose output
flutter test --reporter expanded
```

## Configuration

All settings are configurable through the in-app Settings screen:

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Chunk Size | 1000 bytes | 200–2000 | Bytes per QR frame payload |
| FPS | 15 | 5, 10, 15, 20, 30 | QR animation frame rate |
| Compression | Auto (GZip) | GZip, Auto | Compression algorithm |
| Error Correction | M (15%) | L, M, Q, H | QR error correction level |
| Blur Detection | ON | ON/OFF | Laplacian variance blur check |
| Adaptive Density | ON | ON/OFF | Auto-adjust QR version |
| Low-Light Mode | ON | ON/OFF | CLAHE enhancement |
| Retransmit Timeout | 3 sec | 1–10 sec | Missing chunk timeout |
| Brightness Lock | ON | ON/OFF | Max brightness during transfer |
| History Retention | 30 days | 7, 30, Forever | Transfer log retention |

### Advanced: Chunk Size vs QR Version

The effective data per QR frame depends on the QR version and error correction level:

| QR Version | EC Level L | EC Level M | EC Level Q | EC Level H |
|------------|-----------|-----------|-----------|-----------|
| 10 | 346 B | 271 B | 191 B | 152 B |
| 15 | 664 B | 523 B | 371 B | 286 B |
| 20 | 1091 B | 858 B | 608 B | 468 B |
| 25 | 1628 B | 1292 B | 915 B | 704 B |
| 30 | 2188 B | 1732 B | 1228 B | 946 B |
| 40 | 2953 B | 2331 B | 1663 B | 1273 B |

## Performance Benchmarks

Measured on modern smartphones (Pixel 7 / Galaxy S23) in good lighting:

| File Type | Size | Chunks (1KB) | Est. Time (15 FPS) | Throughput |
|-----------|------|-------------|---------------------|------------|
| Text file | 1 KB | 1 | Instant | — |
| Small image | 100 KB | ~100 | 10–20 s | ~8 KB/s |
| Document | 500 KB | ~500 | 50–100 s | ~8 KB/s |
| Photo (compressed) | 1 MB | ~1000 | 2–4 min | ~6 KB/s |
| PDF | 5 MB | ~5000 | 10–20 min | ~6 KB/s |

> **Note:** Real-world throughput is typically **5–25 KB/s** depending on:
> - Device camera quality and processing speed
> - Lighting conditions
> - Distance and angle between devices
> - QR code density (version) and error correction level
> - The app uses adaptive density to automatically optimize for your conditions

## Binary Packet Protocol

Each chunk is wrapped in a 41-byte header:

```
Offset  Size    Field
──────  ──────  ─────────────────────────────
0       2 B     Chunk ID (big-endian uint16)
2       2 B     Total Chunks (big-endian uint16)
4       4 B     CRC32 checksum (big-endian uint32)
8       32 B    SHA-256 of original file (non-zero in chunk 0 only)
40      1 B     Flags byte:
                  bit 0: encrypted (0=no, 1=yes)
                  bit 1: isLast (0=no, 1=yes)
                  bits 2-7: compression type (0=none, 1=gzip, 2=brotli, 3=zstd)
41      N B     Chunk payload data
```

## Encryption Details

When encryption is enabled:
- **Algorithm:** AES-256-GCM (authenticated encryption)
- **Key Derivation:** PBKDF2 with SHA-256, 200,000 iterations
- **Salt:** 16 bytes (random, unique per encryption)
- **Nonce/IV:** 12 bytes (random, unique per encryption)
- **Output format:** `[16B salt][12B nonce][ciphertext + 16B GCM auth tag]`

## Known Limitations

1. **Throughput:** Real-world transfer speed is 5–25 KB/s (not 100–500 KB/s) due to camera decode latency and QR density limits
2. **File Size:** Practical limit is ~5 MB due to the number of QR frames required; larger files take prohibitively long
3. **Max Chunks:** 65,535 chunks maximum (uint16 limit). At 1KB chunk size, max file is ~64 MB
4. **Lighting:** Poor lighting significantly reduces decode success rate. The CLAHE enhancement helps but can't fully compensate
5. **Camera Quality:** Older or budget phones may struggle with dense QR codes. The adaptive density feature helps
6. **iOS Build:** Requires macOS + Xcode. The code is cross-platform Flutter but Windows can only build Android APKs
7. **Zstd Compression:** Not available due to lack of stable Flutter FFI package; GZip is used as the primary compressor
8. **Selective Retransmit:** The back-channel (receiver shows missing-chunks QR) requires manual coordination between users
9. **No Resume:** If the app is closed mid-transfer, progress is lost. Resume support is a future enhancement
10. **Single Session:** Only one transfer session at a time per app instance

## Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.16+ / Dart 3.0+ |
| QR Generation | qr_flutter |
| QR Scanning | mobile_scanner (ML Kit / Apple Vision) |
| Compression | GZip (dart:io) |
| Encryption | AES-256-GCM via cryptography package |
| Hashing | SHA-256 + CRC32 via crypto package |
| State | Riverpod |
| Database | SQLite via sqflite |
| AI - Blur | Laplacian Variance (pure Dart) |
| AI - Density | Adaptive version/EC controller |
| AI - Light | CLAHE (pure Dart) |
| Charts | fl_chart |
| Animations | flutter_animate |

## Future Enhancements

- **Multi-device broadcast:** One sender, multiple receivers simultaneously
- **Resume support:** Save transfer state and resume after app restart
- **Fountain codes:** Use Luby Transform or Raptor codes for rateless erasure coding
- **Cross-platform:** Desktop sender (Windows/macOS/Linux) for larger screens
- **Hybrid methods:** Combine QR with ultrasonic audio for higher throughput
- **Camera-to-camera:** Both devices scan each other for bidirectional transfers
- **QR optimization:** Custom visual codes beyond standard QR for higher density
- **Zstd support:** When a stable Flutter FFI package is available

## License

MIT License — see LICENSE file for details.
