import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/detection_provider.dart';

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

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
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

        setState(() {
          _isVideoInitialized = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Video loaded. Tap "Process Video" to start detection',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processVideo() async {
    if (_videoController == null || !_isVideoInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _totalFramesProcessed = 0;
      _totalDetections = 0;
      _processingStatus = 'Initializing...';
    });

    try {
      final duration = _videoController!.value.duration;
      final durationInSeconds = duration.inSeconds;

      // Process 1 frame per second
      final totalFrames = durationInSeconds;

      for (int i = 0; i < totalFrames; i++) {
        if (!_isProcessing) break; // User cancelled

        setState(() {
          _processingStatus = 'Processing frame ${i + 1}/$totalFrames...';
        });

        // Seek to specific position
        await _videoController!.seekTo(Duration(seconds: i));
        await Future.delayed(
          const Duration(milliseconds: 200),
        ); // Wait for frame

        // Capture current frame
        // Note: This is a simplified version. In production, you'd need
        // a proper frame extraction mechanism or use a plugin

        setState(() {
          _totalFramesProcessed = i + 1;
        });
      }

      setState(() {
        _isProcessing = false;
        _processingStatus = 'Processing complete!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Processed $_totalFramesProcessed frames with $_totalDetections detections',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _processingStatus = 'Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopProcessing() {
    setState(() {
      _isProcessing = false;
      _processingStatus = 'Processing stopped by user';
    });
  }

  void _reset() {
    _videoController?.dispose();
    _videoController = null;

    setState(() {
      _videoFile = null;
      _isVideoInitialized = false;
      _isProcessing = false;
      _totalFramesProcessed = 0;
      _totalDetections = 0;
      _processingStatus = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Video Detection',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_videoFile != null)
            IconButton(
              icon: const Icon(Icons.refresh),
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
                  color: Colors.grey.shade100,
                  child: Center(child: _buildVideoPreview()),
                ),
              ),

              // Statistics Section
              if (_totalFramesProcessed > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Frames',
                        _totalFramesProcessed.toString(),
                        Icons.video_library,
                        Colors.blue,
                      ),
                      _buildStatItem(
                        'Detections',
                        _totalDetections.toString(),
                        Icons.search,
                        Colors.green,
                      ),
                      _buildStatItem(
                        'Avg/Frame',
                        _totalFramesProcessed > 0
                            ? (_totalDetections / _totalFramesProcessed)
                                  .toStringAsFixed(1)
                            : '0',
                        Icons.analytics,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),

              // Status & Control Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
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
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            if (_isProcessing)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            if (_isProcessing) const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _processingStatus,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
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
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            icon: const Icon(Icons.video_library),
                            label: const Text('Pick Video'),
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
                                  ? Colors.red
                                  : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            icon: Icon(
                              _isProcessing ? Icons.stop : Icons.play_arrow,
                            ),
                            label: Text(
                              _isProcessing ? 'Stop' : 'Process Video',
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
          Icon(Icons.video_library, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No video selected',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Pick Video" to select a video',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      );
    }

    if (!_isVideoInitialized) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading video...'),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        children: [
          VideoPlayer(_videoController!),

          // Playback controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
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
                        playedColor: Colors.orange,
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
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
