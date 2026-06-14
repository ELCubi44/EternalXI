import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

/// Retrato básico o placeholder con iniciales cuando no hay imagen real.
class ClashCardPortrait extends StatelessWidget {
  const ClashCardPortrait({
    required this.name,
    required this.imagePath,
    this.height,
    this.borderRadius = 14,
    super.key,
  });

  final String name;
  final String imagePath;
  final double? height;
  final double borderRadius;

  static bool isPlaceholder(String path) {
    final normalized = path.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'placeholder' ||
        normalized.startsWith('clash://placeholder');
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final usePlaceholder = isPlaceholder(imagePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.xiCardElevated,
              XiColors.navyBlue.withValues(
                alpha: context.isXiDark ? 0.55 : 0.12,
              ),
            ],
          ),
          border: Border.all(color: context.xiDivider),
        ),
        child: usePlaceholder
            ? _PlaceholderContent(initials: _initials)
            : Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _PlaceholderContent(initials: _initials),
              ),
      ),
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_rounded,
            size: 36,
            color: context.xiTextSecondary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 8),
          Text(
            initials,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.xiTextPrimary.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
