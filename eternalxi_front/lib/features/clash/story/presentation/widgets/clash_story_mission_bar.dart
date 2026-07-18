import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_status.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_labels.dart';
import 'package:flutter/material.dart';

/// Barra fina de misin (mismo lenguaje visual que Personajes en Equipo).
/// Solo nmero + ttulo; icono libro o batalla en crculo dorado.
class ClashStoryMissionBar extends StatelessWidget {
  const ClashStoryMissionBar({
    required this.level,
    required this.status,
    required this.onTap,
    super.key,
  });

  final ClashStoryLevel level;
  final ClashStoryLevelStatus status;
  final VoidCallback? onTap;

  static const double _barHeight = 42;
  static const double _iconSize = 58;
  static const double _barLeftInset = 22;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = status == ClashStoryLevelStatus.completed;
    final enabled = onTap != null;
    final rowHeight = _iconSize;
    final barTop = (rowHeight - _barHeight) / 2;
    final typeIcon = clashStoryLevelTypeIcon(level.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: SizedBox(
              height: rowHeight,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: _barLeftInset,
                    right: 0,
                    top: barTop,
                    height: _barHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        ClashEpicAssets.teamPersonajesBarBg,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                        alignment: const Alignment(-0.15, 0),
                        errorBuilder: (_, __, ___) => DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xE608101C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: XiColors.techCyan.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: _iconSize,
                      height: _iconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0A1220),
                        border: Border.all(
                          color: XiColors.classicGold.withValues(alpha: 0.7),
                          width: 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        typeIcon,
                        size: 28,
                        color: completed
                            ? const Color(0xFF4ADE80)
                            : XiColors.classicGold,
                      ),
                    ),
                  ),
                  Positioned(
                    left: _iconSize + 8,
                    right: 16,
                    top: barTop,
                    height: _barHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${level.order}.  ${level.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: context.xiTextPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
