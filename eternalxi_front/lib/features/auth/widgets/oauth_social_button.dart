import 'package:flutter/material.dart';

/// Logotipo multicolor de Google (paths oficiales del icono Sign in with Google).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _viewBox = 48.0;

  static final _red = Path()
    ..moveTo(24, 9.5)
    ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
    ..lineTo(40.06, 6.25)
    ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
    ..cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22)
    ..lineTo(10.54, 19.41)
    ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5)
    ..close();

  static final _blue = Path()
    ..moveTo(46.98, 24.55)
    ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20)
    ..lineTo(24, 20)
    ..lineTo(24, 29.02)
    ..lineTo(36.94, 29.02)
    ..cubicTo(36.38, 31.97, 34.7, 34.47, 32.16, 36.14)
    ..lineTo(39.89, 42.15)
    ..cubicTo(44.4, 37.99, 46.98, 31.87, 46.98, 24.55)
    ..close();

  static final _yellow = Path()
    ..moveTo(10.53, 28.59)
    ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24)
    ..cubicTo(9.77, 22.4, 10.04, 20.86, 10.53, 19.41)
    ..lineTo(2.55, 13.22)
    ..cubicTo(0.92, 16.46, 0, 20.12, 0, 24)
    ..cubicTo(0, 27.88, 0.92, 31.54, 2.56, 34.78)
    ..lineTo(10.53, 28.59)
    ..close();

  static final _green = Path()
    ..moveTo(24, 48)
    ..cubicTo(30.48, 48, 35.93, 45.87, 39.89, 42.19)
    ..lineTo(32.16, 36.18)
    ..cubicTo(30.01, 37.63, 27.24, 38.48, 24, 38.48)
    ..cubicTo(17.74, 38.48, 12.43, 34.26, 10.53, 28.57)
    ..lineTo(2.55, 34.76)
    ..cubicTo(6.51, 42.62, 14.62, 48, 24, 48)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _viewBox;
    canvas.save();
    canvas.scale(scale);
    void fill(Color color, Path path) {
      canvas.drawPath(path, Paint()..color = color);
    }

    fill(const Color(0xFFEA4335), _red);
    fill(const Color(0xFF4285F4), _blue);
    fill(const Color(0xFFFBBC05), _yellow);
    fill(const Color(0xFF34A853), _green);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Manzana estilo Sign in with Apple.
class AppleLogo extends StatelessWidget {
  const AppleLogo({super.key, this.size = 22, this.color = Colors.black});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppleLogoPainter(color: color),
      ),
    );
  }
}

class _AppleLogoPainter extends CustomPainter {
  _AppleLogoPainter({required this.color});

  final Color color;

  static const _viewBox = 24.0;

  static Path _applePath() {
    final path = Path()
      ..moveTo(12.152, 6.896)
      ..cubicTo(11.204, 6.896, 9.737, 5.818, 8.192, 5.856)
      ..cubicTo(6.152, 5.883, 4.282, 7.039, 3.231, 8.87)
      ..cubicTo(1.114, 12.545, 2.685, 17.973, 4.75, 20.96)
      ..cubicTo(5.763, 22.414, 6.958, 24.05, 8.543, 23.999)
      ..cubicTo(10.063, 23.934, 10.633, 23.012, 12.478, 23.012)
      ..cubicTo(14.309, 23.012, 14.828, 23.999, 16.438, 23.96)
      ..cubicTo(18.075, 23.934, 19.114, 22.48, 20.114, 21.012)
      ..cubicTo(21.27, 19.324, 21.75, 17.687, 21.776, 17.597)
      ..cubicTo(21.737, 17.584, 18.594, 16.376, 18.556, 12.74)
      ..cubicTo(18.53, 9.7, 21.036, 8.246, 21.153, 8.181)
      ..cubicTo(19.724, 6.091, 17.53, 5.857, 16.763, 5.805)
      ..cubicTo(14.763, 5.649, 13.088, 6.895, 12.153, 6.895)
      ..close()
      ..moveTo(15.53, 3.83)
      ..cubicTo(16.373, 2.818, 16.93, 1.403, 16.775, 0)
      ..cubicTo(15.568, 0.052, 14.113, 0.805, 13.243, 1.818)
      ..cubicTo(12.463, 2.714, 11.789, 4.156, 11.97, 5.532)
      ..cubicTo(13.308, 5.636, 14.685, 4.844, 15.529, 3.831)
      ..close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final scale = size.width / _viewBox;
    canvas.save();
    canvas.scale(scale);
    canvas.drawPath(_applePath(), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AppleLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Burbujas circulares para inicio de sesion (Google + Apple).
class OAuthLoginBubbles extends StatelessWidget {
  const OAuthLoginBubbles({
    super.key,
    required this.onGoogle,
    required this.onApple,
    this.isLoading = false,
    this.showApple = true,
  });

  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final bool isLoading;
  final bool showApple;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _OAuthBubble(
          onPressed: isLoading ? null : onGoogle,
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFDADCE0),
          child: const GoogleLogo(size: 26),
        ),
        if (showApple) ...[
          const SizedBox(width: 20),
          _OAuthBubble(
            onPressed: isLoading ? null : onApple,
            backgroundColor: isDark ? Colors.white : Colors.black,
            borderColor: isDark ? Colors.white : Colors.black,
            child: AppleLogo(
              size: 24,
              color: isDark ? Colors.black : Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}

class _OAuthBubble extends StatelessWidget {
  const _OAuthBubble({
    required this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: CircleBorder(side: BorderSide(color: borderColor, width: 1)),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 58,
          height: 58,
          child: Center(child: child),
        ),
      ),
    );
  }
}

enum OAuthSocialVariant { google, apple }

/// Boton de vincular con branding oficial.
class OAuthLinkButton extends StatelessWidget {
  const OAuthLinkButton({
    super.key,
    required this.variant,
    required this.label,
    required this.onPressed,
    this.linked = false,
    this.linkedLabel,
    this.isLoading = false,
  });

  final OAuthSocialVariant variant;
  final String label;
  final String? linkedLabel;
  final VoidCallback? onPressed;
  final bool linked;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (linked) {
      return _LinkedProviderRow(
        variant: variant,
        label: linkedLabel ?? label,
      );
    }

    final isGoogle = variant == OAuthSocialVariant.google;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color background;
    final Color foreground;
    final Color border;
    final Widget logo;

    if (isGoogle) {
      background = Colors.white;
      foreground = const Color(0xFF1F1F1F);
      border = const Color(0xFFDADCE0);
      logo = const GoogleLogo(size: 20);
    } else {
      background = isDark ? Colors.white : Colors.black;
      foreground = isDark ? Colors.black : Colors.white;
      border = isDark ? Colors.white24 : Colors.black;
      logo = AppleLogo(size: 18, color: foreground);
    }

    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  logo,
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      color: foreground,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LinkedProviderRow extends StatelessWidget {
  const _LinkedProviderRow({
    required this.variant,
    required this.label,
  });

  final OAuthSocialVariant variant;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isGoogle = variant == OAuthSocialVariant.google;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF1F1F1F);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF34A853).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF34A853).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          if (isGoogle)
            const GoogleLogo(size: 20)
          else
            const AppleLogo(size: 18, color: Color(0xFF1F1F1F)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Lumiare',
                fontSize: 14,
                color: fg,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF34A853),
            size: 22,
          ),
        ],
      ),
    );
  }
}
