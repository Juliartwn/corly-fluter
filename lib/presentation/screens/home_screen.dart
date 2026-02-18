import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/detection_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize model saat pertama kali buka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeModel();
    });
  }

  Future<void> _initializeModel() async {
    final provider = context.read<DetectionProvider>();

    if (!provider.isInitialized) {
      try {
        await provider.initialize();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Model initialized successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✗ Failed to initialize: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DetectionProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Corly - Coral Bleaching Detection',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.water_drop,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Coral Bleaching Detection',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Powered by YOLOv10',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 48),

                  // Feature Buttons
                  _buildFeatureButton(
                    context,
                    icon: Icons.image,
                    title: 'Image Detection',
                    subtitle: 'Upload foto terumbu karang',
                    color: Colors.green,
                    enabled: provider.isInitialized && !provider.isLoading,
                    onTap: () {
                      // TODO: Navigate to Image Detection Screen
                      _showComingSoon(context, 'Image Detection');
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildFeatureButton(
                    context,
                    icon: Icons.video_library,
                    title: 'Video Detection',
                    subtitle: 'Upload video bawah air',
                    color: Colors.orange,
                    enabled: false, // Coming soon
                    onTap: () {
                      _showComingSoon(context, 'Video Detection');
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildFeatureButton(
                    context,
                    icon: Icons.camera_alt,
                    title: 'Real-Time Detection',
                    subtitle: 'Deteksi langsung dengan kamera',
                    color: Colors.red,
                    enabled: false, // Coming soon
                    onTap: () {
                      _showComingSoon(context, 'Real-Time Detection');
                    },
                  ),

                  const SizedBox(height: 48),

                  // Status Badge - Dynamic
                  _buildStatusBadge(provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(DetectionProvider provider) {
    IconData icon;
    Color bgColor;
    Color borderColor;
    Color textColor;
    String text;

    switch (provider.state) {
      case DetectionState.initializing:
        icon = Icons.hourglass_empty;
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade200;
        textColor = Colors.orange.shade700;
        text = 'Initializing Model...';
        break;

      case DetectionState.error:
        icon = Icons.error;
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        textColor = Colors.red.shade700;
        text = 'Initialization Failed';
        break;

      case DetectionState.idle:
      case DetectionState.success:
        if (provider.isInitialized) {
          icon = Icons.check_circle;
          bgColor = Colors.green.shade50;
          borderColor = Colors.green.shade200;
          textColor = Colors.green.shade700;
          text = 'Ready to Use';
        } else {
          icon = Icons.pending;
          bgColor = Colors.grey.shade50;
          borderColor = Colors.grey.shade200;
          textColor = Colors.grey.shade700;
          text = 'Waiting...';
        }
        break;

      default:
        icon = Icons.info;
        bgColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade200;
        textColor = Colors.blue.shade700;
        text = 'Processing...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue,
      ),
    );
  }
}
