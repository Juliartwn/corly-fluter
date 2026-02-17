import 'dart:ui';

/// Model untuk single detection result (bounding box + metadata)
class Detection {
  final Rect boundingBox; // Koordinat bounding box
  final double confidence; // Confidence score (0.0 - 1.0)
  final String label; // Class label ('bleaching')
  final int classId; // Class ID (0 untuk bleaching)

  Detection({
    required this.boundingBox,
    required this.confidence,
    required this.label,
    required this.classId,
  });

  /// Convert normalized coordinates (0-1) to pixel coordinates
  factory Detection.fromNormalized({
    required double x,
    required double y,
    required double width,
    required double height,
    required double confidence,
    required String label,
    required int classId,
    required int imageWidth,
    required int imageHeight,
  }) {
    // Convert from center coordinates to top-left coordinates
    final left = (x - width / 2) * imageWidth;
    final top = (y - height / 2) * imageHeight;
    final right = (x + width / 2) * imageWidth;
    final bottom = (y + height / 2) * imageHeight;

    return Detection(
      boundingBox: Rect.fromLTRB(left, top, right, bottom),
      confidence: confidence,
      label: label,
      classId: classId,
    );
  }

  /// Create from YOLO output format [x_center, y_center, width, height, confidence, class_id]
  factory Detection.fromYoloOutput({
    required List<double> output,
    required int imageWidth,
    required int imageHeight,
    required String label,
  }) {
    return Detection.fromNormalized(
      x: output[0],
      y: output[1],
      width: output[2],
      height: output[3],
      confidence: output[4],
      label: label,
      classId: output.length > 5 ? output[5].toInt() : 0,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  /// Get bounding box area
  double get area => boundingBox.width * boundingBox.height;

  /// Get center point
  Offset get center => boundingBox.center;

  /// Convert to Map untuk export
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'confidence': confidence,
      'x': boundingBox.left,
      'y': boundingBox.top,
      'width': boundingBox.width,
      'height': boundingBox.height,
      'class_id': classId,
    };
  }

  /// Convert to CSV row
  String toCsvRow() {
    return '$label,${confidence.toStringAsFixed(3)},'
        '${boundingBox.left.toStringAsFixed(1)},'
        '${boundingBox.top.toStringAsFixed(1)},'
        '${boundingBox.width.toStringAsFixed(1)},'
        '${boundingBox.height.toStringAsFixed(1)}';
  }

  @override
  String toString() {
    return 'Detection(label: $label, confidence: ${confidence.toStringAsFixed(2)}, '
        'bbox: ${boundingBox.toString()})';
  }
}
