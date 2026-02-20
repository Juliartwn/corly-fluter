import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../data/data.dart';

/// Detection State untuk UI
enum DetectionState {
  idle, // Belum ada deteksi
  initializing, // Loading model
  detecting, // Sedang proses deteksi
  success, // Deteksi berhasil
  error, // Ada error
}

/// Provider untuk manage coral bleaching detection
class DetectionProvider extends ChangeNotifier {
  final DetectionRepository _repository;

  DetectionProvider(this._repository);

  // State
  DetectionState _state = DetectionState.idle;
  DetectionResult? _currentResult;
  String? _errorMessage;
  File? _currentImageFile;

  // Getters
  DetectionState get state => _state;
  DetectionResult? get currentResult => _currentResult;
  String? get errorMessage => _errorMessage;
  File? get currentImageFile => _currentImageFile;
  bool get isInitialized => _repository.isInitialized;
  bool get isLoading =>
      _state == DetectionState.initializing ||
      _state == DetectionState.detecting;
  bool get hasResult =>
      _currentResult != null && _state == DetectionState.success;
  List<Detection> get detections => _currentResult?.detections ?? [];

  /// Initialize TFLite model
  Future<void> initialize() async {
    try {
      _setState(DetectionState.initializing);
      _errorMessage = null;

      await _repository.initialize();

      _setState(DetectionState.idle);
      debugPrint('✓ Detection Provider initialized');
    } catch (e) {
      _errorMessage = 'Failed to initialize model: $e';
      _setState(DetectionState.error);
      debugPrint('✗ Initialization error: $e');
      rethrow;
    }
  }

  /// Detect bleaching dari image file
  Future<void> detectFromImageFile(File imageFile) async {
    try {
      _setState(DetectionState.detecting);
      _errorMessage = null;
      _currentImageFile = imageFile;

      // Check if model initialized
      if (!_repository.isInitialized) {
        throw Exception('Model not initialized. Call initialize() first.');
      }

      debugPrint('→ Starting detection from image: ${imageFile.path}');

      // Run detection
      final result = await _repository.detectFromFile(imageFile);

      // Update state
      _currentResult = result;
      _setState(DetectionState.success);

      debugPrint(
        '✓ Detection complete: ${result.bleachingCount} bleaching detected',
      );
      debugPrint('  Inference time: ${result.inferenceTimeMs}ms');
      debugPrint(
        '  Average confidence: ${(result.averageConfidence * 100).toStringAsFixed(1)}%',
      );
    } catch (e) {
      _errorMessage = 'Detection failed: $e';
      _setState(DetectionState.error);
      debugPrint('✗ Detection error: $e');
      rethrow;
    }
  }

  /// Detect bleaching dari image bytes
  Future<void> detectFromBytes(Uint8List bytes) async {
    try {
      _setState(DetectionState.detecting);
      _errorMessage = null;
      _currentImageFile = null;

      if (!_repository.isInitialized) {
        throw Exception('Model not initialized. Call initialize() first.');
      }

      debugPrint('→ Starting detection from bytes');

      final result = await _repository.detectFromBytes(bytes);

      _currentResult = result;
      _setState(DetectionState.success);

      debugPrint('✓ Detection complete');
    } catch (e) {
      _errorMessage = 'Detection failed: $e';
      _setState(DetectionState.error);
      debugPrint('✗ Detection error: $e');
      rethrow;
    }
  }

  /// Detect bleaching dari Image object
  Future<void> detectFromImage(img.Image image) async {
    try {
      _setState(DetectionState.detecting);
      _errorMessage = null;
      _currentImageFile = null;

      if (!_repository.isInitialized) {
        throw Exception('Model not initialized. Call initialize() first.');
      }

      debugPrint('→ Starting detection from Image object');

      final result = await _repository.detectFromImage(image);

      _currentResult = result;
      _setState(DetectionState.success);

      debugPrint('✓ Detection complete');
    } catch (e) {
      _errorMessage = 'Detection failed: $e';
      _setState(DetectionState.error);
      debugPrint('✗ Detection error: $e');
      rethrow;
    }
  }

  /// Reset detection result
  void reset() {
    _currentResult = null;
    _currentImageFile = null;
    _errorMessage = null;
    _setState(DetectionState.idle);
    debugPrint('✓ Detection reset');
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == DetectionState.error) {
      _setState(DetectionState.idle);
    }
    notifyListeners();
  }

  /// Helper untuk set state dan notify listeners
  void _setState(DetectionState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    debugPrint('✓ Detection Provider disposed');
    super.dispose();
  }
}
