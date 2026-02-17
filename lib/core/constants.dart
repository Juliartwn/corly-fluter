/// App Constants untuk konfigurasi deteksi coral bleaching
class AppConstants {
  // Model Configuration
  static const String modelPath =
      'assets/models/yolov10_coral_bleaching.tflite';
  static const String labelsPath = 'assets/models/labels.txt';

  // Model Input/Output Configuration
  static const int modelInputSize = 640; // YOLOv10 input size 640x640
  static const int numChannels = 3; // RGB channels
  static const int numThreads = 4; // Number of threads for inference

  // Detection Thresholds
  static const double confidenceThreshold = 0.5; // Minimum confidence score
  // Note: YOLOv10 is NMS-free, no IoU threshold needed

  // Performance Configuration
  static const int maxInferenceTimeMs = 500; // Maximum 500ms per frame
  static const int targetFpsRealtime = 10; // Target 10 FPS for real-time
  static const int frameSkipCount = 2; // Skip frames untuk performa

  // Device Requirements
  static const int minRamGB = 4; // Minimum RAM requirement

  // Class Labels (hanya 1 class: bleaching)
  static const List<String> classLabels = ['bleaching'];

  // Colors for Bounding Boxes
  static const Map<String, int> classColors = {
    'bleaching': 0xFFFF0000, // Red for bleaching detection
  };

  // Export Settings
  static const String exportFolderName = 'CoralDetection';
  static const String csvFileName = 'detection_results.csv';

  // UI Settings
  static const double boundingBoxStrokeWidth = 3.0;
  static const double textFontSize = 14.0;
}
