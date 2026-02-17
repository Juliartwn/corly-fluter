import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../datasources/tflite_detector.dart';
import '../models/detection_result.dart';

/// Repository interface untuk coral bleaching detection
abstract class DetectionRepository {
  Future<void> initialize();
  Future<DetectionResult> detectFromFile(File imageFile);
  Future<DetectionResult> detectFromBytes(Uint8List bytes);
  Future<DetectionResult> detectFromImage(img.Image image);
  void dispose();
  bool get isInitialized;
}

/// Implementation dari DetectionRepository menggunakan TFLite
class DetectionRepositoryImpl implements DetectionRepository {
  final TFLiteDetector _detector;

  DetectionRepositoryImpl(this._detector);

  @override
  bool get isInitialized => _detector.isInitialized;

  @override
  Future<void> initialize() async {
    try {
      await _detector.initialize();
    } catch (e) {
      throw Exception('Failed to initialize detection repository: $e');
    }
  }

  @override
  Future<DetectionResult> detectFromFile(File imageFile) async {
    try {
      return await _detector.detectFromFile(imageFile);
    } catch (e) {
      throw Exception('Detection from file failed: $e');
    }
  }

  @override
  Future<DetectionResult> detectFromBytes(Uint8List bytes) async {
    try {
      return await _detector.detectFromBytes(bytes);
    } catch (e) {
      throw Exception('Detection from bytes failed: $e');
    }
  }

  @override
  Future<DetectionResult> detectFromImage(img.Image image) async {
    try {
      return await _detector.detectFromImage(image);
    } catch (e) {
      throw Exception('Detection from image failed: $e');
    }
  }

  @override
  void dispose() {
    _detector.dispose();
  }
}
