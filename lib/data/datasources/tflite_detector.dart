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
    final inputShape = _interpreter!.getInputTensor(0).shape;

    if (inputShape.length != 4) {
      throw Exception(
        'Unsupported model input shape: $inputShape. Expected 4D tensor.',
      );
    }

    final batchSize = inputShape[0];
    final inputChannels = inputShape[1];
    final inputHeight = inputShape[2];
    final inputWidth = inputShape[3];

    if (batchSize != 1 ||
        inputHeight <= 0 ||
        inputWidth <= 0 ||
        inputChannels <= 0) {
      throw Exception('Invalid model input shape: $inputShape');
    }

    debugPrint(
      '  Preprocessing image to ${inputWidth}x${inputHeight}x$inputChannels',
    );

    // Resize ke ukuran input model yang sebenarnya
    final resizedImage = img.copyResize(
      image,
      width: inputWidth,
      height: inputHeight,
      interpolation: img.Interpolation.linear,
    );

    // Convert to normalized float array [1, C, H, W]
    final inputTensor = List.generate(
      1,
      (_) => List.generate(inputChannels, (channel) {
        return List.generate(inputHeight, (y) {
          return List.generate(inputWidth, (x) {
            final pixel = resizedImage.getPixel(x, y);

            if (inputChannels == 1) {
              return (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) /
                  255.0;
            }

            if (inputChannels == 3) {
              switch (channel) {
                case 0:
                  return pixel.r / 255.0;
                case 1:
                  return pixel.g / 255.0;
                case 2:
                  return pixel.b / 255.0;
                default:
                  throw Exception(
                    'Unsupported channel index $channel for shape $inputShape',
                  );
              }
            }

            if (inputChannels == 4) {
              switch (channel) {
                case 0:
                  return pixel.r / 255.0;
                case 1:
                  return pixel.g / 255.0;
                case 2:
                  return pixel.b / 255.0;
                case 3:
                  return 1.0;
                default:
                  throw Exception(
                    'Unsupported channel index $channel for shape $inputShape',
                  );
              }
            }

            throw Exception(
              'Unsupported channel count in model input shape: $inputShape',
            );
          });
        });
      }),
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
    // prefer format: [x1, y1, x2, y2, confidence, class_id]
    // fallback: [x_center, y_center, width, height, confidence, class_id]
    final predictions = output[0] as List;

    for (final pred in predictions) {
      final predList = pred as List;

      // Extract detection data
      final confidence = (predList[4] as num).toDouble();

      // Filter by confidence threshold
      if (confidence < AppConstants.confidenceThreshold) {
        continue;
      }

      final x1Raw = (predList[0] as num).toDouble();
      final y1Raw = (predList[1] as num).toDouble();
      final x2Raw = (predList[2] as num).toDouble();
      final y2Raw = (predList[3] as num).toDouble();
      final classId = predList.length > 5 ? (predList[5] as num).toInt() : 0;

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final modelInputWidth = inputShape[3].toDouble();
      final modelInputHeight = inputShape[2].toDouble();

      // Some exports emit normalized boxes, others emit boxes in model-input pixels.
      // Prefer corner format because it matches the exported YOLOv10 output used here.
      final x1Norm = x1Raw > 1.5 ? x1Raw / modelInputWidth : x1Raw;
      final y1Norm = y1Raw > 1.5 ? y1Raw / modelInputHeight : y1Raw;
      final x2Norm = x2Raw > 1.5 ? x2Raw / modelInputWidth : x2Raw;
      final y2Norm = y2Raw > 1.5 ? y2Raw / modelInputHeight : y2Raw;

      final x1LooksLikeCorner = x2Norm > x1Norm && y2Norm > y1Norm;

      // Get label
      final label = _labels != null && classId < _labels!.length
          ? _labels![classId]
          : 'bleaching';

      double left;
      double top;
      double right;
      double bottom;

      if (x1LooksLikeCorner) {
        left = x1Norm * originalWidth;
        top = y1Norm * originalHeight;
        right = x2Norm * originalWidth;
        bottom = y2Norm * originalHeight;
      } else {
        final xCenterNorm = x1Norm;
        final yCenterNorm = y1Norm;
        final widthNorm = x2Norm;
        final heightNorm = y2Norm;

        left = (xCenterNorm - widthNorm / 2) * originalWidth;
        top = (yCenterNorm - heightNorm / 2) * originalHeight;
        right = (xCenterNorm + widthNorm / 2) * originalWidth;
        bottom = (yCenterNorm + heightNorm / 2) * originalHeight;
      }

      // Clamp ke image bounds
      final clampedLeft = left.clamp(0.0, originalWidth.toDouble());
      final clampedTop = top.clamp(0.0, originalHeight.toDouble());
      final clampedRight = right.clamp(0.0, originalWidth.toDouble());
      final clampedBottom = bottom.clamp(0.0, originalHeight.toDouble());

      if (clampedRight <= clampedLeft || clampedBottom <= clampedTop) {
        continue;
      }

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
