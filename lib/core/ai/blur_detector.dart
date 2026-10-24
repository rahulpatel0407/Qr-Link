import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

class BlurResult {
  final bool isBlurry;
  final double variance;
  final String recommendation;

  BlurResult({
    required this.isBlurry,
    required this.variance,
    required this.recommendation,
  });
}

class BlurDetector {
  Future<BlurResult> analyzeAsync(Uint8List imageBytes, int width, int height) async {
    return await Isolate.run(() => isBlurry(imageBytes, width, height));
  }

  BlurResult isBlurry(Uint8List imageBytes, int width, int height, {double threshold = 100.0}) {
    final double variance = computeLaplacianVariance(imageBytes, width, height);
    final bool blurry = variance < threshold;
    
    String recommendation = 'Image is sharp';
    if (blurry) {
      recommendation = 'Hold camera steady and ensure good lighting';
    } else if (variance < threshold * 1.5) {
      recommendation = 'Image is slightly soft, try to hold still';
    }

    return BlurResult(
      isBlurry: blurry,
      variance: variance,
      recommendation: recommendation,
    );
  }

  double computeLaplacianVariance(Uint8List grayscaleBytes, int width, int height) {
    if (width < 3 || height < 3) return 0.0;
    
    final List<int> laplacians = [];
    double sum = 0.0;
    
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final int center = grayscaleBytes[y * width + x];
        final int top = grayscaleBytes[(y - 1) * width + x];
        final int bottom = grayscaleBytes[(y + 1) * width + x];
        final int left = grayscaleBytes[y * width + (x - 1)];
        final int right = grayscaleBytes[y * width + (x + 1)];
        
        // Laplacian kernel: [[0,1,0],[1,-4,1],[0,1,0]]
        final int laplacian = -4 * center + top + bottom + left + right;
        laplacians.add(laplacian);
        sum += laplacian;
      }
    }
    
    if (laplacians.isEmpty) return 0.0;
    
    final double mean = sum / laplacians.length;
    double sqSum = 0.0;
    
    for (final int value in laplacians) {
      final double diff = value - mean;
      sqSum += diff * diff;
    }
    
    return sqSum / laplacians.length;
  }
}
