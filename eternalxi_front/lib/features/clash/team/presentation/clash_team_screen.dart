import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClashTeamScreen extends StatelessWidget {
  const ClashTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ClashScreenScaffold(
      title: l10n.clashTabTeam,
      children: [
        _TeamSectionBar(
          iconAsset: ClashEpicAssets.teamPersonajesIcon,
          title: l10n.clashTeamCharacters,
          titleStyle: theme.textTheme.titleMedium?.copyWith(
            color: context.xiTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            height: 1.1,
          ),
          onTap: () => context.push(AppRoutes.clashCards),
        ),
      ],
    );
  }
}

/// Fila compacta Equipo: ancho según contenido (icono + texto).
class _TeamSectionBar extends StatelessWidget {
  const _TeamSectionBar({
    required this.iconAsset,
    required this.title,
    required this.onTap,
    this.titleStyle,
  });

  final String iconAsset;
  final String title;
  final VoidCallback onTap;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: XiColors.techCyan.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
              image: const DecorationImage(
                image: AssetImage(ClashEpicAssets.teamSectionBarBg),
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 18, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    iconAsset,
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: titleStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
