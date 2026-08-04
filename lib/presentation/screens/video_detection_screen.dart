import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../../providers/detection_provider.dart';
import '../../data/models/detection.dart';
import '../../theme/colors.dart';
import '../../theme/toast.dart';
import '../widgets/bounding_box_painter.dart';

class VideoDetectionScreen extends StatefulWidget {
  const VideoDetectionScreen({super.key});

  @override
  State<VideoDetectionScreen> createState() => _VideoDetectionScreenState();
}

class _VideoDetectionScreenState extends State<VideoDetectionScreen> {
  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isProcessing = false;
  bool _isVideoInitialized = false;
  int _totalFramesProcessed = 0;
  int _totalDetections = 0;
  String _processingStatus = '';

  static const int _frameMatchToleranceMs = 500;

  // Map untuk menyimpan deteksi per timestamp (dalam milidetik)
  final Map<int, List<Detection>> _detectionsByTimestamp = {};
  final Map<int, Size> _imageSizeByTimestamp = {};

  // Current detections untuk ditampilkan
  List<Detection>? _currentDetections;
  Size? _currentImageSize;

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoPositionChanged);
    _videoController?.dispose();
    super.dispose();
  }

  int? _getMatchingFrameTimestamp(int currentPositionMs) {
    if (_detectionsByTimestamp.isEmpty) {
      return null;
    }

    final exactMatch = _detectionsByTimestamp.keys.firstWhere(
      (timestamp) => timestamp == currentPositionMs,
      orElse: () => -1,
    );

    if (exactMatch != -1) {
      return exactMatch;
    }

    final timestamps = _detectionsByTimestamp.keys.toList()..sort();
    for (final timestamp in timestamps) {
      if ((timestamp - currentPositionMs).abs() <= _frameMatchToleranceMs) {
        return timestamp;
      }
    }

    return null;
  }

  void _onVideoPositionChanged() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    final currentPositionMs = _videoController!.value.position.inMilliseconds;
    final matchingTimestamp = _getMatchingFrameTimestamp(currentPositionMs);
    final detections = matchingTimestamp != null
        ? _detectionsByTimestamp[matchingTimestamp]
        : null;
    final imageSize = matchingTimestamp != null
        ? _imageSizeByTimestamp[matchingTimestamp]
        : null;

    if (mounted) {
      setState(() {
        _currentDetections = detections;
        _currentImageSize = imageSize;
      });
    }
  }

  void _showSnack(
    String message, {
    CorlyToastType type = CorlyToastType.success,
  }) {
    if (!mounted) return;
    CorlyToast.show(context, message: message, type: type);
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        setState(() {
          _videoFile = File(video.path);
          _isVideoInitialized = false;
          _totalFramesProcessed = 0;
          _totalDetections = 0;
          _processingStatus = '';
        });

        // Initialize video player
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(_videoFile!);

        await _videoController!.initialize();

        // Add listener untuk track video position
        _videoController!.addListener(_onVideoPositionChanged);

        setState(() {
          _isVideoInitialized = true;
        });

        _showSnack(
          'Video loaded. Tap "Process Video" to start detection',
          type: CorlyToastType.success,
        );
      }
    } catch (e) {
      _showSnack('Error loading video: $e', type: CorlyToastType.error);
    }
  }

  Future<void> _processVideo() async {
    if (_videoController == null || !_isVideoInitialized) {
      _showSnack('Please select a video first', type: CorlyToastType.warning);
      return;
    }

    setState(() {
      _isProcessing = true;
      _totalFramesProcessed = 0;
      _totalDetections = 0;
      _processingStatus = 'Initializing...';
    });

    final provider = context.read<DetectionProvider>();

    try {
      final duration = _videoController!.value.duration;
      final durationInSeconds = duration.inSeconds;

      // Process 1 frame setiap 2 detik untuk performa lebih baik
      final frameInterval = 2; // detik
      final totalFrames = (durationInSeconds / frameInterval).ceil();

      // Get temp directory untuk simpan thumbnails
      final tempDir = await getTemporaryDirectory();

      for (int i = 0; i < totalFrames; i++) {
        if (!_isProcessing) break; // User cancelled

        final timeMs = i * frameInterval * 1000; // Convert to milliseconds

        setState(() {
          _processingStatus = 'Extracting frame ${i + 1}/$totalFrames...';
        });

        // Yield to UI thread
        await Future.delayed(const Duration(milliseconds: 50));

        // Generate thumbnail at specific timestamp
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: _videoFile!.path,
          thumbnailPath: tempDir.path,
          imageFormat: ImageFormat.PNG,
          timeMs: timeMs,
          quality: 75, // Reduce quality untuk performa lebih baik
        );

        if (thumbnailPath == null || !_isProcessing) {
          continue;
        }

        setState(() {
          _processingStatus = 'Analyzing frame ${i + 1}/$totalFrames...';
        });

        // Yield to UI thread
        await Future.delayed(const Duration(milliseconds: 50));

        // Load thumbnail as image
        final thumbnailFile = File(thumbnailPath);
        final bytes = await thumbnailFile.readAsBytes();
        final image = img.decodeImage(bytes);

        if (image == null) {
          continue;
        }

        // Run detection
        await provider.detectFromImage(image);

        // Simpan detection results dengan timestamp yang sesuai frame yang diproses
        final timestamp = timeMs;
        final detectionCount = provider.detections.length;

        if (detectionCount > 0) {
          _detectionsByTimestamp[timestamp] = List.from(provider.detections);
          _imageSizeByTimestamp[timestamp] = Size(
            image.width.toDouble(),
            image.height.toDouble(),
          );
        }

        setState(() {
          _totalFramesProcessed = i + 1;
          _totalDetections += detectionCount;
        });

        // Clean up thumbnail file
        try {
          await thumbnailFile.delete();
        } catch (_) {}
      }

      setState(() {
        _isProcessing = false;
        _processingStatus =
            'Processing complete! Found $_totalDetections bleaching detections in $_totalFramesProcessed frames.';
      });

      _showSnack(
        'Processed $_totalFramesProcessed frames\nFound $_totalDetections bleaching detections',
        type: CorlyToastType.success,
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _processingStatus = 'Error: $e';
      });

      _showSnack('Error processing video: $e', type: CorlyToastType.error);
    }
  }

  void _stopProcessing() {
    setState(() {
      _isProcessing = false;
      _processingStatus = 'Processing stopped by user';
    });
  }

  void _reset() {
    _videoController?.removeListener(_onVideoPositionChanged);
    _videoController?.dispose();
    _videoController = null;

    setState(() {
      _videoFile = null;
      _isVideoInitialized = false;
      _isProcessing = false;
      _totalFramesProcessed = 0;
      _totalDetections = 0;
      _processingStatus = '';
      _detectionsByTimestamp.clear();
      _imageSizeByTimestamp.clear();
      _currentDetections = null;
      _currentImageSize = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CorlyColors.background,
      appBar: AppBar(
        title: const Text(
          'Video Detection',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: CorlyColors.tealDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_videoFile != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _isProcessing ? null : _reset,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: Consumer<DetectionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Video Preview Section
              Expanded(
                child: Container(
                  color: CorlyColors.background,
                  child: Center(child: _buildVideoPreview()),
                ),
              ),

              // Statistics Section
              if (_totalFramesProcessed > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.all(16),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Frames',
                        _totalFramesProcessed.toString(),
                        Icons.video_library_outlined,
                        CorlyColors.teal,
                      ),
                      _buildStatItem(
                        'Detections',
                        _totalDetections.toString(),
                        Icons.search_rounded,
                        CorlyColors.tealDark,
                      ),
                      _buildStatItem(
                        'Avg/Frame',
                        _totalFramesProcessed > 0
                            ? (_totalDetections / _totalFramesProcessed)
                                  .toStringAsFixed(1)
                            : '0',
                        Icons.analytics_outlined,
                        CorlyColors.tealDark,
                      ),
                    ],
                  ),
                ),

              // Status & Control Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: BoxDecoration(
                  color: CorlyColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Text
                    if (_processingStatus.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            if (_isProcessing)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: CorlyColors.teal,
                                ),
                              ),
                            if (_isProcessing) const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _processingStatus,
                                style: const TextStyle(
                                  color: CorlyColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Control Buttons
                    Row(
                      children: [
                        // Pick Video Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _pickVideo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CorlyColors.teal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.video_library_outlined),
                            label: const Text(
                              'Pick Video',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Process/Stop Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _videoFile == null
                                ? null
                                : _isProcessing
                                ? _stopProcessing
                                : _processVideo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isProcessing
                                  ? Colors.red.shade600
                                  : CorlyColors.tealDark,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: Icon(
                              _isProcessing
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            label: Text(
                              _isProcessing ? 'Stop' : 'Process Video',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoFile == null) {
      return Column(
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
              Icons.video_library_outlined,
              size: 64,
              color: CorlyColors.teal.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No video selected',
            style: TextStyle(
              fontSize: 17,
              color: CorlyColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Pick Video" to select a video',
            style: TextStyle(fontSize: 14, color: CorlyColors.textSecondary),
          ),
        ],
      );
    }

    if (!_isVideoInitialized) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: CorlyColors.coral),
          SizedBox(height: 16),
          Text(
            'Loading video...',
            style: TextStyle(color: CorlyColors.textSecondary),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(_videoController!),

              // Bounding box overlay
              if (_currentDetections != null && _currentImageSize != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: BoundingBoxPainter(
                      detections: _currentDetections!,
                      imageSize: _currentImageSize!,
                    ),
                  ),
                ),

              // Playback controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: VideoProgressIndicator(
                          _videoController!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: CorlyColors.teal,
                            backgroundColor: Colors.white38,
                          ),
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
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CorlyColors.textPrimary,
          ),
        ),
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
}
