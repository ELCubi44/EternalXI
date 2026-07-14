import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppPrimaryButton extends StatefulWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  bool get _disabled => widget.isLoading || widget.onPressed == null;

  void _onDown(TapDownDetails _) {
    if (!_disabled) _pressCtrl.forward();
  }

  void _onUp(TapUpDetails _) {
    if (!_disabled) {
      _pressCtrl.reverse();
      widget.onPressed?.call();
    }
  }

  void _onCancel() {
    if (!_disabled) _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: GestureDetector(
        onTapDown: _disabled ? null : _onDown,
        onTapUp: _disabled ? null : _onUp,
        onTapCancel: _disabled ? null : _onCancel,
        child: AnimatedOpacity(
          opacity: _disabled ? 0.45 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: _disabled
                  ? const LinearGradient(
                      colors: [XiColors.navyBlue, XiColors.navyBlue],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2F62D8),
                        XiColors.royalBlue,
                        Color(0xFF1A3A9A),
                      ],
                    ),
              boxShadow: _disabled
                  ? []
                  : [
                      BoxShadow(
                        color: XiColors.royalBlue.withValues(alpha: 0.38),
                        blurRadius: 16,
                        spreadRadius: -2,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: XiColors.warmWhite,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontFamily: 'Lumiare',
                          color: XiColors.warmWhite,
                          fontSize: 15,
                          letterSpacing: 0.6,
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
