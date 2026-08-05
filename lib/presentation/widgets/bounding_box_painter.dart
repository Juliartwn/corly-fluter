import 'package:flutter/material.dart';
import '../../data/models/detection.dart';

/// Custom painter untuk menggambar bounding boxes dari hasil deteksi
class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize;

  BoundingBoxPainter({required this.detections, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    // Hitung scale factor dari image size ke display size
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (var detection in detections) {
      final bbox = detection.boundingBox;

      // Scale bounding box coordinates
      final left = bbox.left * scaleX;
      final top = bbox.top * scaleY;
      final width = bbox.width * scaleX;
      final height = bbox.height * scaleY;

      final rect = Rect.fromLTWH(left, top, width, height);

      // Draw bounding box
      final boxPaint = Paint()
        ..color = _getColorForClass(detection.label)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawRect(rect, boxPaint);

      // Draw filled background untuk label
      final labelBgPaint = Paint()
        ..color = _getColorForClass(detection.label).withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      // Buat label text
      final labelText =
          '${detection.label} ${(detection.confidence * 100).toStringAsFixed(1)}%';
      final textSpan = TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      const labelPaddingX = 4.0;
      const labelPaddingY = 3.0;
      final labelWidth = textPainter.width + labelPaddingX * 2;
      final labelHeight = textPainter.height + labelPaddingY * 2;
      final preferredLabelTop = top - labelHeight - 2;
      final labelTopCandidate = preferredLabelTop >= 0
          ? preferredLabelTop
          : top + height + 2;
      final labelTop = labelTopCandidate < 0
          ? 0.0
          : (labelTopCandidate + labelHeight > size.height
                ? (size.height - labelHeight).clamp(0.0, size.height)
                : labelTopCandidate);
      final labelLeft = left < 0
          ? 0.0
          : (left + labelWidth > size.width
                ? (size.width - labelWidth).clamp(0.0, size.width)
                : left);

      // Draw label background
      final labelRect = Rect.fromLTWH(
        labelLeft,
        labelTop,
        labelWidth,
        labelHeight,
      );
      canvas.drawRect(labelRect, labelBgPaint);

      // Draw label text
      textPainter.paint(
        canvas,
        Offset(labelLeft + labelPaddingX, labelTop + labelPaddingY),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageSize != imageSize;
  }

  /// Warna untuk setiap class (untuk coral bleaching hanya 1 class)
  Color _getColorForClass(String label) {
    switch (label.toLowerCase()) {
      case 'bleaching':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
