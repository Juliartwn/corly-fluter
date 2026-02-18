import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/detection_provider.dart';
import '../widgets/bounding_box_painter.dart';

class ImageDetectionScreen extends StatefulWidget {
  const ImageDetectionScreen({super.key});

  @override
  State<ImageDetectionScreen> createState() => _ImageDetectionScreenState();
}

class _ImageDetectionScreenState extends State<ImageDetectionScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  /// Pick image dari gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick image dari camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error mengambil foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show pilihan sumber gambar
  Future<void> _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Pilih dari Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Batal'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Jalankan deteksi
  Future<void> _runDetection() async {
    if (_selectedImage == null) return;

    final provider = context.read<DetectionProvider>();
    await provider.detectFromImageFile(_selectedImage!);

    if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Reset state
  void _reset() {
    setState(() {
      _selectedImage = null;
    });
    context.read<DetectionProvider>().reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Gambar'),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: Consumer<DetectionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Area gambar
              Expanded(
                child: _selectedImage == null
                    ? _buildEmptyState()
                    : _buildImageWithDetections(provider),
              ),

              // Statistics (jika ada hasil)
              if (provider.hasResult) _buildStatistics(provider),

              // Action buttons
              _buildActionButtons(provider),
            ],
          );
        },
      ),
    );
  }

  /// Empty state ketika belum ada gambar
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada gambar dipilih',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih gambar untuk mulai deteksi',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Gambar dengan bounding boxes
  Widget _buildImageWithDetections(DetectionProvider provider) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image
          Image.file(_selectedImage!, fit: BoxFit.contain),

          // Bounding boxes overlay
          if (provider.hasResult)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    painter: BoundingBoxPainter(
                      detections: provider.currentResult!.detections,
                      imageSize: Size(
                        provider.currentResult!.imageWidth.toDouble(),
                        provider.currentResult!.imageHeight.toDouble(),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Loading overlay
          if (provider.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Memproses deteksi...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Statistics panel
  Widget _buildStatistics(DetectionProvider provider) {
    final result = provider.currentResult!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Deteksi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Terdeteksi',
                '${result.bleachingCount}',
                Colors.blue,
              ),
              _buildStatItem(
                'Confidence',
                '${(result.averageConfidence * 100).toStringAsFixed(1)}%',
                Colors.green,
              ),
              _buildStatItem(
                'Waktu',
                '${result.inferenceTimeMs}ms',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stat item widget
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  /// Action buttons
  Widget _buildActionButtons(DetectionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_selectedImage == null)
            // Tombol pilih gambar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _showImageSourceOptions,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text(
                  'Pilih Gambar',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          else if (!provider.hasResult)
            // Tombol detect
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _runDetection,
                icon: const Icon(Icons.search),
                label: const Text(
                  'Deteksi Bleaching',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          else
            // Tombol setelah deteksi
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _showImageSourceOptions,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Gambar Lain'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _runDetection,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Deteksi Ulang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
