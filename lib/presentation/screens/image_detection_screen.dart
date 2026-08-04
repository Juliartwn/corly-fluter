import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../../providers/detection_provider.dart';
import '../../theme/colors.dart';
import '../../theme/toast.dart';
import '../widgets/bounding_box_painter.dart';

class ImageDetectionScreen extends StatefulWidget {
  const ImageDetectionScreen({super.key});

  @override
  State<ImageDetectionScreen> createState() => _ImageDetectionScreenState();
}

class _ImageDetectionScreenState extends State<ImageDetectionScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Size? _imageSize; // Store actual image dimensions

  /// Pick image dari gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        final file = File(image.path);

        // Load image to get dimensions
        final bytes = await file.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        if (decodedImage != null) {
          setState(() {
            _selectedImage = file;
            _imageSize = Size(
              decodedImage.width.toDouble(),
              decodedImage.height.toDouble(),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error memilih gambar: $e', isError: true);
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
        final file = File(image.path);

        // Load image to get dimensions
        final bytes = await file.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        if (decodedImage != null) {
          setState(() {
            _selectedImage = file;
            _imageSize = Size(
              decodedImage.width.toDouble(),
              decodedImage.height.toDouble(),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error mengambil foto: $e', isError: true);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (isError) {
      CorlyToast.error(context, message);
    } else {
      CorlyToast.success(context, message);
    }
  }

  /// Show pilihan sumber gambar
  Future<void> _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              _sheetTile(
                icon: Icons.photo_library_outlined,
                iconColor: CorlyColors.teal,
                label: 'Pilih dari Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              _sheetTile(
                icon: Icons.camera_alt_outlined,
                iconColor: CorlyColors.coral,
                label: 'Ambil Foto',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              _sheetTile(
                icon: Icons.cancel_outlined,
                iconColor: Colors.grey.shade500,
                label: 'Batal',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }

  /// Jalankan deteksi
  Future<void> _runDetection() async {
    if (_selectedImage == null) return;

    final provider = context.read<DetectionProvider>();
    await provider.detectFromImageFile(_selectedImage!);

    if (mounted && provider.errorMessage != null) {
      _showSnack(provider.errorMessage!, isError: true);
    }
  }

  /// Reset state
  void _reset() {
    setState(() {
      _selectedImage = null;
      _imageSize = null;
    });
    context.read<DetectionProvider>().reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CorlyColors.background,
      appBar: AppBar(
        title: const Text(
          'Deteksi Gambar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: CorlyColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
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
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: CorlyColors.teal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 64,
              color: CorlyColors.teal.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada gambar dipilih',
            style: TextStyle(
              fontSize: 17,
              color: CorlyColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih gambar untuk mulai deteksi',
            style: TextStyle(fontSize: 14, color: CorlyColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Gambar dengan bounding boxes
  Widget _buildImageWithDetections(DetectionProvider provider) {
    // Gunakan aspect ratio dari image yang sudah di-load
    final aspectRatio = _imageSize != null
        ? _imageSize!.width / _imageSize!.height
        : 1.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                Image.file(_selectedImage!, fit: BoxFit.contain),

                // Bounding boxes overlay
                if (provider.hasResult)
                  CustomPaint(
                    painter: BoundingBoxPainter(
                      detections: provider.currentResult!.detections,
                      imageSize: Size(
                        provider.currentResult!.imageWidth.toDouble(),
                        provider.currentResult!.imageHeight.toDouble(),
                      ),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Statistics panel
  Widget _buildStatistics(DetectionProvider provider) {
    final result = provider.currentResult!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CorlyColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: CorlyColors.tealDark.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Deteksi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CorlyColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Terdeteksi',
                '${result.bleachingCount}',
                CorlyColors.teal,
              ),
              _buildStatItem(
                'Confidence',
                '${(result.averageConfidence * 100).toStringAsFixed(1)}%',
                CorlyColors.tealDark,
              ),
              _buildStatItem(
                'Waktu',
                '${result.inferenceTimeMs}ms',
                CorlyColors.coral,
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CorlyColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Action buttons
  Widget _buildActionButtons(DetectionProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          if (_selectedImage == null)
            // Tombol pilih gambar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _showImageSourceOptions,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text(
                  'Pilih Gambar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CorlyColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          else if (!provider.hasResult)
            // Tombol detect
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _runDetection,
                icon: const Icon(Icons.search_rounded),
                label: const Text(
                  'Deteksi Bleaching',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CorlyColors.tealDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          else
            // Tombol setelah deteksi
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _showImageSourceOptions,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Gambar Lain'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CorlyColors.teal,
                        side: const BorderSide(color: CorlyColors.teal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _runDetection,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Deteksi Ulang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CorlyColors.tealDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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