# Corly - Coral Bleaching Detection App

Aplikasi mobile berbasis Flutter untuk deteksi bleaching pada terumbu karang menggunakan YOLOv10.

## 📱 Fitur Utama

1. **Image Detection**
   - Upload foto terumbu karang dari galeri atau kamera
   - Deteksi otomatis area bleaching dengan YOLOv10
   - Tampilkan bounding box dengan label dan confidence score
   - Statistik deteksi: jumlah bleaching, confidence rata-rata, area coverage

2. **Video Detection**
   - Upload video rekaman bawah air dari galeri
   - Proses frame-by-frame detection (setiap 2 detik)
   - Real-time bounding box overlay saat playback
   - Statistik: total frames, total detections, average detections per frame

## 🏗️ Arsitektur

Aplikasi menggunakan **Clean Architecture Pattern** dengan **Provider** untuk state management:

```
lib/
├── core/                    # Core utilities dan constants
│   ├── constants/
│   │   └── app_constants.dart   # Konfigurasi app (model size, threshold, dll)
│   └── utils/               # Helper functions
├── data/                    # Data layer
│   ├── datasources/
│   │   └── tflite_detector.dart # YOLOv10 TFLite detector
│   ├── models/
│   │   ├── detection.dart        # Detection box model
│   │   └── detection_result.dart # Detection result dengan statistik
│   └── repositories/
│       └── detection_repository.dart # Repository pattern
├── presentation/            # Presentation layer
│   ├── screens/
│   │   ├── home_screen.dart           # Main menu
│   │   ├── image_detection_screen.dart # Image detection UI
│   │   └── video_detection_screen.dart # Video detection UI
│   └── widgets/
│       └── bounding_box_painter.dart  # Custom painter untuk bounding boxes
├── providers/               # State management
│   └── detection_provider.dart        # Provider untuk detection state
└── main.dart                # Entry point
```

## 🚀 Setup & Installation

### Prerequisites

- Flutter SDK: >=3.11.0
- Android SDK: minSdk 24
- Dart SDK: >=3.11.0

### 1. Clone & Install Dependencies

```bash
cd corly
flutter pub get
```

### 2. Setup Model

Letakkan file model di `assets/models/`:

- `best.tflite` - YOLOv10 model (14.6 MB)
- `labels.txt` - Class labels (1 line: "bleaching")

Format model:

- Input: `[1, 640, 640, 3]` (RGB image)
- Output: `[1, 300, 6]` (detections dengan format [x1, y1, x2, y2, confidence, class_id])

### 3. Run App

```bash
flutter run
```

## 📊 Model Configuration

- **Model**: YOLOv10 (NMS-free architecture)
- **Input Size**: 640×640 pixels
- **Model Format**: TensorFlow Lite (.tflite)
- **Model Size**: 14.6 MB
- **Output Format**: `[x1, y1, x2, y2, confidence, class_id]` (normalized 0-1)
- **Confidence Threshold**: 0.5
- **Max Detections**: 300

### YOLOv10 Advantages:

- ✅ **NMS-free** - Tidak perlu Non-Maximum Suppression post-processing
- ✅ **Faster inference** - Lebih cepat dibanding YOLO v8/v9
- ✅ **Better accuracy** - Dual label assignments untuk prediksi lebih akurat
- ✅ **Mobile optimized** - Efisien untuk mobile devices

## 🎯 Detection Flow

### Image Detection

1. User pilih foto dari galeri atau ambil dengan kamera
2. Image di-decode dan ukuran asli disimpan untuk scaling
3. Image di-preprocess (resize 640x640, normalize)
4. Run inference dengan YOLOv10 TFLite
5. Post-process output: filter by confidence, scale coordinates
6. Tampilkan image dengan bounding box overlay
7. Hitung statistik: count, avg confidence, coverage %

### Video Detection

1. User pilih video dari galeri
2. Extract frame setiap 2 detik (optimasi performa)
3. Generate thumbnail untuk setiap timestamp
4. Run detection pada setiap frame
5. Simpan hasil deteksi per timestamp
6. User dapat play video dengan bounding box real-time overlay
7. Tampilkan statistik total frames dan detections

## 📦 Dependencies

### Core

- `tflite_flutter: ^0.10.4` - TensorFlow Lite runtime
- `provider: ^6.1.1` - State management

### Media Processing

- `image_picker: ^1.0.7` - Pick images/videos
- `video_player: ^2.8.2` - Video playback
- `video_thumbnail: ^0.5.3` - Video frame extraction
- `camera: ^0.10.5+9` - Camera access
- `image: ^4.1.7` - Image processing

### Storage

- `path_provider: ^2.1.2` - File paths
- `permission_handler: ^11.2.0` - Permissions

## 📝 Class Labels

- `bleaching` - Terumbu karang bleaching (merah)

## 📱 Device Requirements

- **OS**: Android 7.0+ (API Level 24+)
- **RAM**: Minimal 4GB
- **Storage**: ~100MB untuk app + model

## 🔐 Permissions

- `READ_EXTERNAL_STORAGE` - Upload foto/video
- `WRITE_EXTERNAL_STORAGE` - Simpan hasil
- `READ_MEDIA_IMAGES/VIDEO` - Android 13+
- `CAMERA` - Ambil foto langsung

## 📖 Development Status

✅ **COMPLETED**

- [x] Project setup & configuration
- [x] Dependencies installed & configured
- [x] TFLite model integration (YOLOv10)
- [x] Data models & repository pattern
- [x] State management with Provider
- [x] Image Detection screen
  - [x] Pick from gallery
  - [x] Take photo with camera
  - [x] Bounding box overlay
  - [x] Detection statistics
- [x] Video Detection screen
  - [x] Pick from gallery
  - [x] Frame-by-frame processing (every 2 seconds)
  - [x] Real-time bounding box overlay during playback
  - [x] Detection statistics per timestamp
- [x] Bounding box rendering with CustomPaint
- [x] Performance optimization
  - [x] Frame interval optimization (2 seconds)
  - [x] Thumbnail quality optimization (75%)
  - [x] UI yielding to prevent frame drops

## 🎯 Future Enhancements

- [ ] Export annotated images/videos
- [ ] CSV report generation
- [ ] Multiple model support
- [ ] Batch processing
- [ ] Cloud storage integration

## 👨‍💻 Author

Research project untuk deteksi coral bleaching menggunakan YOLOv10.

---

**Note**: Model `.tflite` tidak disertakan di repository. Silakan convert model YOLOv10 Anda sendiri atau hubungi author.
