import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

class LowLightEnhancer {
  final List<int> _brightnessHistory = [];
  
  bool get shouldActivate {
    if (_brightnessHistory.isEmpty) return false;
    double sum = 0;
    for (final b in _brightnessHistory) {
      sum += b;
    }
    return (sum / _brightnessHistory.length) < 50;
  }

  bool isLowLight(Uint8List grayscaleBytes) {
    if (grayscaleBytes.isEmpty) return false;
    double sum = 0;
    for (int i = 0; i < grayscaleBytes.length; i++) {
      sum += grayscaleBytes[i];
    }
    final avg = sum / grayscaleBytes.length;
    _brightnessHistory.add(avg.round());
    if (_brightnessHistory.length > 10) {
      _brightnessHistory.removeAt(0);
    }
    return avg < 50;
  }

  Future<Uint8List> enhanceAsync(
    Uint8List grayscaleBytes,
    int width,
    int height, {
    int tileGridX = 8,
    int tileGridY = 8,
    double clipLimit = 2.0,
  }) async {
    return await Isolate.run(() => enhance(
      grayscaleBytes,
      width,
      height,
      tileGridX: tileGridX,
      tileGridY: tileGridY,
      clipLimit: clipLimit,
    ));
  }

  Uint8List enhance(
    Uint8List grayscaleBytes,
    int width,
    int height, {
    int tileGridX = 8,
    int tileGridY = 8,
    double clipLimit = 2.0,
  }) {
    if (width == 0 || height == 0) return grayscaleBytes;

    final Uint8List result = Uint8List(grayscaleBytes.length);
    final int tileW = width ~/ tileGridX;
    final int tileH = height ~/ tileGridY;

    if (tileW == 0 || tileH == 0) return grayscaleBytes;

    // Create histograms for each tile
    final List<List<List<int>>> mappings = List.generate(
      tileGridY,
      (ty) => List.generate(
        tileGridX,
        (tx) => List.filled(256, 0),
      ),
    );

    final int tilePixels = tileW * tileH;
    final int clipLimitVal = max(1, (clipLimit * tilePixels / 256.0).round());

    for (int ty = 0; ty < tileGridY; ty++) {
      for (int tx = 0; tx < tileGridX; tx++) {
        final List<int> hist = List.filled(256, 0);
        
        final int startY = ty * tileH;
        final int startX = tx * tileW;
        final int endY = min(startY + tileH, height);
        final int endX = min(startX + tileW, width);

        // Compute histogram
        for (int y = startY; y < endY; y++) {
          for (int x = startX; x < endX; x++) {
            final int pixel = grayscaleBytes[y * width + x];
            hist[pixel]++;
          }
        }

        // Clip histogram and redistribute
        int clipped = 0;
        for (int i = 0; i < 256; i++) {
          if (hist[i] > clipLimitVal) {
            clipped += hist[i] - clipLimitVal;
            hist[i] = clipLimitVal;
          }
        }

        final int redistribute = clipped ~/ 256;
        final int remainder = clipped % 256;
        
        for (int i = 0; i < 256; i++) {
          hist[i] += redistribute;
        }
        
        if (remainder > 0) {
          final int step = 256 ~/ remainder;
          for (int i = 0; i < remainder; i++) {
            hist[i * step]++;
          }
        }

        // Compute CDF mapping
        int sum = 0;
        for (int i = 0; i < 256; i++) {
          sum += hist[i];
          mappings[ty][tx][i] = min(255, (sum * 255) ~/ tilePixels);
        }
      }
    }

    // Bilinear interpolation
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final double txDouble = (x / tileW) - 0.5;
        final double tyDouble = (y / tileH) - 0.5;

        final int tx1 = max(0, txDouble.floor());
        final int tx2 = min(tileGridX - 1, tx1 + 1);
        final int ty1 = max(0, tyDouble.floor());
        final int ty2 = min(tileGridY - 1, ty1 + 1);

        final double xWeight = max(0.0, min(1.0, txDouble - tx1));
        final double yWeight = max(0.0, min(1.0, tyDouble - ty1));

        final int pixel = grayscaleBytes[y * width + x];

        final int val11 = mappings[ty1][tx1][pixel];
        final int val12 = mappings[ty1][tx2][pixel];
        final int val21 = mappings[ty2][tx1][pixel];
        final int val22 = mappings[ty2][tx2][pixel];

        final double valTop = val11 * (1 - xWeight) + val12 * xWeight;
        final double valBottom = val21 * (1 - xWeight) + val22 * xWeight;
        final double finalVal = valTop * (1 - yWeight) + valBottom * yWeight;

        result[y * width + x] = finalVal.round().clamp(0, 255);
      }
    }

    return result;
  }
}
