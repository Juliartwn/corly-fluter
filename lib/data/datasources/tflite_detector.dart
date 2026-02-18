import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../core/constants.dart';
import '../models/detection.dart';
import '../models/detection_result.dart';

/// TFLite Detector untuk YOLOv10 Coral Bleaching Detection
///
/// YOLOv10 Features:
/// - NMS-free architecture dengan dual label assignments
/// - Consistent matching metric untuk prediksi yang lebih akurat
/// - Lebih efisien untuk real-time detection
class TFLiteDetector {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize detector dengan load model dan labels
  Future<void> initialize() async {
    try {
      // Load model
      _interpreter = await _loadModel();

      // Load labels
      _labels = await _loadLabels();

      _isInitialized = true;
      debugPrint('✓ TFLite Detector initialized successfully');
      debugPrint(
        '  Model input shape: ${_interpreter?.getInputTensor(0).shape}',
      );
      debugPrint(
        '  Model output shape: ${_interpreter?.getOutputTensor(0).shape}',
      );
      debugPrint('  Labels: $_labels');
    } catch (e) {
      debugPrint('✗ Error initializing TFLite Detector: $e');
      rethrow;
    }
  }

  /// Load TFLite model
  Future<Interpreter> _loadModel() async {
    try {
      // Load model dari assets
      final interpreterOptions = InterpreterOptions()
        ..threads = AppConstants.numThreads;

      // Tambah delegate untuk optimasi (opsional)
      // if (Platform.isAndroid) {
      //   interpreterOptions.addDelegate(GpuDelegateV2());
      // }

      final interpreter = await Interpreter.fromAsset(
        AppConstants.modelPath,
        options: interpreterOptions,
      );

      return interpreter;
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }
  }

  /// Load labels dari file
  Future<List<String>> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString(AppConstants.labelsPath);
      return labelData.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      throw Exception('Failed to load labels: $e');
    }
  }

  /// Detect bleaching dari image file
  Future<DetectionResult> detectFromFile(File imageFile) async {
    if (!_isInitialized) {
      throw Exception('Detector not initialized. Call initialize() first.');
    }

    // Load dan decode image
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    return await detectFromImage(image);
  }

  /// Detect bleaching dari image bytes
  Future<DetectionResult> detectFromBytes(Uint8List bytes) async {
    if (!_isInitialized) {
      throw Exception('Detector not initialized. Call initialize() first.');
    }

    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    return await detectFromImage(image);
  }

  /// Detect bleaching dari image object
  Future<DetectionResult> detectFromImage(img.Image image) async {
    if (!_isInitialized) {
      throw Exception('Detector not initialized. Call initialize() first.');
    }

    final stopwatch = Stopwatch()..start();

    // 1. Preprocess image
    final inputTensor = _preprocessImage(image);

    // 2. Run inference
    final output = _runInference(inputTensor);

    // 3. Postprocess output
    final detections = _postprocessOutput(output, image.width, image.height);

    stopwatch.stop();

    return DetectionResult(
      detections: detections,
      inferenceTimeMs: stopwatch.elapsedMilliseconds,
      imageWidth: image.width,
      imageHeight: image.height,
    );
  }

  /// Preprocess image untuk model input
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // Resize ke model input size (640x640)
    final resizedImage = img.copyResize(
      image,
      width: AppConstants.modelInputSize,
      height: AppConstants.modelInputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to normalized float array [1, 640, 640, 3]
    final inputTensor = List.generate(
      1,
      (_) => List.generate(
        AppConstants.modelInputSize,
        (y) => List.generate(AppConstants.modelInputSize, (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            pixel.r / 255.0, // Normalize R channel
            pixel.g / 255.0, // Normalize G channel
            pixel.b / 255.0, // Normalize B channel
          ];
        }),
      ),
    );

    return inputTensor;
  }

  /// Run inference
  List<dynamic> _runInference(List<List<List<List<double>>>> input) {
    // Get actual output shape from model
    // YOLOv10 output shape biasanya [1, num_detections, 6]
    // dimana 6 = [x_center, y_center, width, height, confidence, class_id]
    final outputShape = _interpreter!.getOutputTensor(0).shape;

    // Allocate output dengan shape yang benar
    final outputBuffer = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List.filled(outputShape[2], 0.0),
      ),
    );

    // Run inference
    _interpreter!.run(input, outputBuffer);

    return outputBuffer;
  }

  /// Postprocess output dengan confidence filtering
  /// YOLOv10 sudah NMS-free, hanya perlu filter by confidence threshold
  List<Detection> _postprocessOutput(
    List<dynamic> output,
    int originalWidth,
    int originalHeight,
  ) {
    final detections = <Detection>[];

    // Parse output
    // output shape: [1, num_detections, 6]
    final predictions = output[0] as List;

    for (final pred in predictions) {
      final predList = pred as List;

      // Extract detection data
      final confidence = predList[4] as double;

      // Filter by confidence threshold
      if (confidence < AppConstants.confidenceThreshold) {
        continue;
      }

      // YOLOv10 output format: [x1, y1, x2, y2, confidence, class_id]
      // Dalam normalized coordinates (0-1)
      final x1Norm = predList[0] as double;
      final y1Norm = predList[1] as double;
      final x2Norm = predList[2] as double;
      final y2Norm = predList[3] as double;
      final classId = predList.length > 5 ? (predList[5] as double).toInt() : 0;

      // Get label
      final label = _labels != null && classId < _labels!.length
          ? _labels![classId]
          : 'bleaching';

      // Scale normalized coordinates (0-1) ke pixel coordinates
      final left = x1Norm * originalWidth;
      final top = y1Norm * originalHeight;
      final right = x2Norm * originalWidth;
      final bottom = y2Norm * originalHeight;

      // Clamp ke image bounds
      final clampedLeft = left.clamp(0.0, originalWidth.toDouble());
      final clampedTop = top.clamp(0.0, originalHeight.toDouble());
      final clampedRight = right.clamp(0.0, originalWidth.toDouble());
      final clampedBottom = bottom.clamp(0.0, originalHeight.toDouble());

      final detection = Detection(
        boundingBox: Rect.fromLTRB(
          clampedLeft,
          clampedTop,
          clampedRight,
          clampedBottom,
        ),
        confidence: confidence,
        label: label,
        classId: classId,
      );

      detections.add(detection);
    }

    // YOLOv10 is NMS-free - no need for post-processing NMS
    // Model already outputs clean predictions with dual label assignments
    return detections;
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _isInitialized = false;
    debugPrint('✓ TFLite Detector disposed');
  }
}
