import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/detection_provider.dart';
import '../../theme/colors.dart';
import '../../theme/toast.dart';
import 'image_detection_screen.dart';
import 'video_detection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
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
          CorlyToast.success(context, 'Model initialized successfully');
        }
      } catch (e) {
        if (mounted) {
          CorlyToast.error(context, 'Failed to initialize: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DetectionProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: CorlyColors.background,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Corly',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.3,
                color: Colors.white,
              ),
            ),
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CorlyColors.tealDark,
                  CorlyColors.teal,
                  CorlyColors.background,
                ],
                stops: [0.0, 0.28, 0.55],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),

                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.22),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ==== Title ====
                    const Text(
                      'Coral Bleaching Detection',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Powered by YOLOv10',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),
                    _buildStatusBadge(provider),

                    const SizedBox(height: 36),

                    _buildFeatureCard(
                      context,
                      icon: Icons.image_outlined,
                      title: 'Image Detection',
                      subtitle: 'Upload foto terumbu karang',
                      gradient: const [Color(0xFF1AA6B7), Color(0xFF0E7C86)],
                      enabled: provider.isInitialized && !provider.isLoading,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ImageDetectionScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildFeatureCard(
                      context,
                      icon: Icons.video_camera_back_outlined,
                      title: 'Video Detection',
                      subtitle: 'Upload video bawah air',
                      gradient: const [Color(0xFF5FD1D9), Color(0xFF1AA6B7)],
                      enabled: provider.isInitialized && !provider.isLoading,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VideoDetectionScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(DetectionProvider provider) {
    IconData icon;
    Color color;
    String text;

    switch (provider.state) {
      case DetectionState.initializing:
        icon = Icons.hourglass_top_rounded;
        color = Colors.amber.shade200;
        text = 'Initializing Model...';
        break;

      case DetectionState.error:
        icon = Icons.error_outline_rounded;
        color = Colors.red.shade200;
        text = 'Initialization Failed';
        break;

      case DetectionState.idle:
      case DetectionState.success:
        if (provider.isInitialized) {
          icon = Icons.check_circle_rounded;
          color = Colors.greenAccent.shade100;
          text = 'Ready to Use';
        } else {
          icon = Icons.pending_outlined;
          color = Colors.white70;
          text = 'Waiting...';
        }
        break;

      default:
        icon = Icons.info_outline_rounded;
        color = Colors.white70;
        text = 'Processing...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: CorlyColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: CorlyColors.tealDark.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
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
                          fontWeight: FontWeight.w700,
                          color: CorlyColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CorlyColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CorlyColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: CorlyColors.teal,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
