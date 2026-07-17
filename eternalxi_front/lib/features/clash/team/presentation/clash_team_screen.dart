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
            fontSize: 17,
            height: 1.15,
          ),
          onTap: () => context.push(AppRoutes.clashCards),
        ),
      ],
    );
  }
}

/// Entrada Equipo: pastilla compacta con icono y texto alineados dentro.
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                XiColors.techCyan.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.42),
              ],
            ),
            border: Border.all(
              color: XiColors.techCyan.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: XiColors.techCyan.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: XiColors.classicGold.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    iconAsset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
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
