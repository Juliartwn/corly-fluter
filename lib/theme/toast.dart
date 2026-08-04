import 'package:flutter/material.dart';
import 'colors.dart';

enum CorlyToastType { success, error, warning, info }

class CorlyToast {
  CorlyToast._();

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    CorlyToastType type = CorlyToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Hindari tumpuk-tumpuk kalau ada notif lain yang masih tampil
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _CorlyToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismissed: () {
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
          entry.remove();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: CorlyToastType.success);

  static void error(BuildContext context, String message) => show(
        context,
        message: message,
        type: CorlyToastType.error,
        duration: const Duration(seconds: 4),
      );

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: CorlyToastType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: CorlyToastType.info);
}

class _CorlyToastWidget extends StatefulWidget {
  final String message;
  final CorlyToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  const _CorlyToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_CorlyToastWidget> createState() => _CorlyToastWidgetState();
}

class _CorlyToastWidgetState extends State<_CorlyToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    _scheduleDismiss();
  }

  void _scheduleDismiss() {
    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  ({IconData icon, Color color}) _style() {
    switch (widget.type) {
      case CorlyToastType.success:
        return (icon: Icons.check_circle_rounded, color: CorlyColors.tealDark);
      case CorlyToastType.error:
        return (icon: Icons.error_rounded, color: const Color(0xFFE5484D));
      case CorlyToastType.warning:
        return (icon: Icons.warning_rounded, color: const Color(0xFFE8A33D));
      case CorlyToastType.info:
        return (icon: Icons.info_rounded, color: CorlyColors.teal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style();
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPadding > 0 ? 8 : 16, 16, 0),
          child: SlideTransition(
            position: _offset,
            child: FadeTransition(
              opacity: _fade,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () async {
                    await _controller.reverse();
                    widget.onDismissed();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border(
                        left: BorderSide(color: s.color, width: 4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(s.icon, color: s.color, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: CorlyColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}