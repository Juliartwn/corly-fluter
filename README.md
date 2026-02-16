# Corly - Coral Bleaching Detection App

Aplikasi mobile berbasis Flutter untuk deteksi bleaching pada terumbu karang menggunakan YOLOv10.

## 📱 Fitur Utama

1. **Upload & Deteksi dari Foto**
   - Unggah foto terumbu karang dari galeri
   - Deteksi otomatis area bleaching
   - Tampilkan bounding box dengan confidence score

2. **Upload & Deteksi dari Video**
   - Unggah video rekaman bawah air
   - Proses frame-by-frame detection
   - Simpan sebagai annotated video

3. **Real-Time Detection**
   - Deteksi langsung menggunakan kamera
   - Real-time bounding box overlay
   - Target 10 FPS dengan minimal 4GB RAM

## 🏗️ Arsitektur

Aplikasi menggunakan **Clean Architecture Pattern**:

```
lib/
├── core/                    # Core utilities dan constants
│   ├── constants.dart       # Konfigurasi app
│   └── utils/               # Helper functions
├── data/                    # Data layer
│   ├── datasources/         # TFLite detector
│   ├── models/              # Data models
│   └── repositories/        # Repository implementations
├── presentation/            # Presentation layer
│   ├── screens/             # UI screens
│   └── widgets/             # Reusable widgets
└── providers/               # State management (Provider)
```

## 🚀 Setup & Installation

### Prerequisites

- Flutter SDK: >=3.11.0
- Android SDK: minSdk 24
- RAM minimal: 4GB (untuk device testing)

### 1. Clone & Install Dependencies

```bash
cd corly
flutter pub get
```

### 2. Setup Model

Letakkan file model di `assets/models/`:

- `yolov10_coral_bleaching.tflite` (model YOLOv10 yang sudah dikonversi)
- `labels.txt` (sudah tersedia)

Lihat `assets/models/README.md` untuk panduan konversi model.

### 3. Run App

```bash
flutter run
```

## 📊 Model Configuration

- **Input Size**: 640×640 pixels
- **Model Format**: TensorFlow Lite (.tflite)
- **Quantization**: Optimized untuk mobile
- **Confidence Threshold**: 0.5
- **IoU Threshold**: 0.45 (NMS)
- **Max Inference Time**: 500ms per frame
- **Target FPS**: 10 FPS (real-time)

## 🔧 Performance Optimization

1. **Model Quantization** - Mengurangi ukuran model
2. **Input Resizing** - 640×640 pixels
3. **Frame Skipping** - Skip 2 frames untuk performa
4. **Isolate Computation** - Inference di background thread

## 📦 Dependencies

### Core

- `tflite_flutter: ^0.10.4` - TensorFlow Lite runtime
- `provider: ^6.1.1` - State management

### Media Processing

- `image_picker: ^1.0.7` - Pick images/videos
- `video_player: ^2.8.2` - Video playback
- `camera: ^0.10.5+9` - Camera access
- `image: ^4.1.7` - Image processing

### Storage & Export

- `path_provider: ^2.1.2` - File paths
- `csv: ^6.0.0` - Export to CSV
- `permission_handler: ^11.2.0` - Permissions

## 📝 Class Labels

- `healthy_coral` - Terumbu karang sehat (hijau)
- `bleached_coral` - Terumbu karang bleaching (merah)

## 🎨 Export Features

- Annotated images dengan bounding boxes
- Annotated videos
- CSV reports dengan statistik deteksi

## 📱 Device Requirements

- **OS**: Android 7.0+ (API Level 24+)
- **RAM**: Minimal 4GB
- **Storage**: ~100MB untuk app + model
- **Camera**: Optional (untuk real-time detection)

## 🔐 Permissions

- `CAMERA` - Real-time detection
- `READ_EXTERNAL_STORAGE` - Upload foto/video
- `WRITE_EXTERNAL_STORAGE` - Simpan hasil
- `READ_MEDIA_IMAGES/VIDEO` - Android 13+

## 📖 Development Status

✅ **Setup & Configuration** - COMPLETED

- [x] Dependencies installed
- [x] Project structure created
- [x] Constants configured
- [x] Android permissions setup
- [x] TFLite configuration

⏳ **Next Steps** (Coming soon):

- [ ] Data models & repository
- [ ] TFLite detector implementation
- [ ] State management with Provider
- [ ] UI screens & widgets
- [ ] Testing & optimization

## 👨‍💻 Author

Research project untuk deteksi coral bleaching menggunakan YOLOv10.

---

**Note**: Model `.tflite` tidak disertakan di repository. Silakan convert model YOLOv10 Anda sendiri atau hubungi author.
