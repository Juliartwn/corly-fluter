import 'detection.dart';

/// Model untuk complete detection result dari YOLOv10
class DetectionResult {
  final List<Detection> detections; // List semua deteksi bleaching
  final int inferenceTimeMs; // Waktu inference dalam milliseconds
  final int imageWidth; // Lebar gambar original
  final int imageHeight; // Tinggi gambar original
  final DateTime timestamp; // Timestamp deteksi

  DetectionResult({
    required this.detections,
    required this.inferenceTimeMs,
    required this.imageWidth,
    required this.imageHeight,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Get jumlah bleaching yang terdeteksi
  int get bleachingCount => detections.length;

  /// Get average confidence score
  double get averageConfidence {
    if (detections.isEmpty) return 0.0;
    final sum = detections.fold<double>(
      0.0,
      (sum, detection) => sum + detection.confidence,
    );
    return sum / detections.length;
  }

  /// Get highest confidence detection
  Detection? get bestDetection {
    if (detections.isEmpty) return null;
    return detections.reduce(
      (best, current) => current.confidence > best.confidence ? current : best,
    );
  }

  /// Get total bleaching area (sum of all bounding boxes)
  double get totalBleachingArea {
    return detections.fold<double>(
      0.0,
      (sum, detection) => sum + detection.area,
    );
  }

  /// Get bleaching coverage percentage (relative to image size)
  double get bleachingCoveragePercent {
    if (imageWidth == 0 || imageHeight == 0) return 0.0;
    final imageArea = imageWidth * imageHeight;
    return (totalBleachingArea / imageArea) * 100;
  }

  /// Check if any bleaching detected
  bool get hasBleaching => detections.isNotEmpty;

  /// Get inference FPS
  double get fps {
    if (inferenceTimeMs == 0) return 0.0;
    return 1000.0 / inferenceTimeMs;
  }

  /// Convert to Map untuk export
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'bleaching_count': bleachingCount,
      'average_confidence': averageConfidence,
      'total_area': totalBleachingArea,
      'coverage_percent': bleachingCoveragePercent,
      'inference_time_ms': inferenceTimeMs,
      'fps': fps,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'detections': detections.map((d) => d.toMap()).toList(),
    };
  }

  /// Generate summary text
  String getSummary() {
    if (!hasBleaching) {
      return 'No bleaching detected';
    }

    return '''
Bleaching Detection Summary:
- Detected: $bleachingCount area(s)
- Average Confidence: ${(averageConfidence * 100).toStringAsFixed(1)}%
- Coverage: ${bleachingCoveragePercent.toStringAsFixed(2)}%
- Inference Time: ${inferenceTimeMs}ms (${fps.toStringAsFixed(1)} FPS)
''';
  }

  /// Convert to CSV format
  String toCsv() {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
      'timestamp,bleaching_count,avg_confidence,coverage_percent,inference_ms,fps',
    );

    // Summary row
    buffer.writeln(
      '${timestamp.toIso8601String()},$bleachingCount,'
      '${averageConfidence.toStringAsFixed(3)},'
      '${bleachingCoveragePercent.toStringAsFixed(2)},'
      '$inferenceTimeMs,${fps.toStringAsFixed(2)}',
    );

    // Detections header
    buffer.writeln('\nlabel,confidence,x,y,width,height');

    // Detection rows
    for (final detection in detections) {
      buffer.writeln(detection.toCsvRow());
    }

    return buffer.toString();
  }

  @override
  String toString() {
    return 'DetectionResult(bleaching: $bleachingCount, '
        'avgConf: ${averageConfidence.toStringAsFixed(2)}, '
        'time: ${inferenceTimeMs}ms)';
  }
}
