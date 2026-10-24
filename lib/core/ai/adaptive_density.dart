enum DensityLevel {
  low(15, 'Q'),
  normal(25, 'M'),
  high(35, 'M'),
  max(40, 'L');

  final int version;
  final String errorCorrection;

  const DensityLevel(this.version, this.errorCorrection);
}

class DensityAdjustment {
  final DateTime timestamp;
  final DensityLevel fromLevel;
  final DensityLevel toLevel;
  final double successRate;
  final String reason;

  DensityAdjustment({
    required this.timestamp,
    required this.fromLevel,
    required this.toLevel,
    required this.successRate,
    required this.reason,
  });
}

class AdaptiveDensityController {
  DensityLevel currentLevel = DensityLevel.normal;
  final List<double> rollingSuccessRates = [];
  final List<DensityAdjustment> adjustmentLog = [];

  void recordDecodeResult(bool success) {
    rollingSuccessRates.add(success ? 1.0 : 0.0);
    if (rollingSuccessRates.length > 30) {
      rollingSuccessRates.removeAt(0);
    }
  }

  DensityAdjustment? evaluate() {
    if (rollingSuccessRates.isEmpty) return null;
    
    double sum = 0.0;
    for (final double rate in rollingSuccessRates) {
      sum += rate;
    }
    final double avg = sum / rollingSuccessRates.length;

    if (avg < 0.80 && currentLevel.index > 0) {
      final DensityLevel newLevel = DensityLevel.values[currentLevel.index - 1];
      final adjustment = DensityAdjustment(
        timestamp: DateTime.now(),
        fromLevel: currentLevel,
        toLevel: newLevel,
        successRate: avg,
        reason: 'Success rate below 80% ($avg)',
      );
      currentLevel = newLevel;
      adjustmentLog.add(adjustment);
      rollingSuccessRates.clear(); // Reset window after adjustment
      return adjustment;
    }
    
    if (avg > 0.95 && currentLevel.index < DensityLevel.values.length - 1) {
      // Suggest increase but don't auto-apply (returning adjustment doesn't mutate currentLevel)
      return DensityAdjustment(
        timestamp: DateTime.now(),
        fromLevel: currentLevel,
        toLevel: DensityLevel.values[currentLevel.index + 1],
        successRate: avg,
        reason: 'Success rate high ($avg), could increase density',
      );
    }
    
    return null;
  }

  int getRecommendedVersion() {
    return currentLevel.version;
  }

  String getRecommendedErrorCorrection() {
    return currentLevel.errorCorrection;
  }

  void reset() {
    currentLevel = DensityLevel.normal;
    rollingSuccessRates.clear();
    adjustmentLog.clear();
  }
}
