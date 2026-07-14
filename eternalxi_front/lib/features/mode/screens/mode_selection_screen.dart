import 'package:eternal_xi/core/constants/clash_feature_flags.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().currentUser;
    final nickname = user?.nickname.trim();
    final greeting = (nickname != null && nickname.isNotEmpty)
        ? nickname
        : l10n.appTitle;

    return Scaffold(
      backgroundColor: context.xiBackground,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.xiHeaderGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: context.xiHeaderTitle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.modeSelectionSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.xiTextSecondary.withValues(alpha: 0.85),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  greeting,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: XiColors.royalBlue,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _ModeOptionCard(
                        icon: Icons.emoji_events_rounded,
                        iconColor: XiColors.classicGold,
                        title: l10n.modeFantasyTitle,
                        description: l10n.modeFantasyDescription,
                        actionLabel: l10n.modeFantasyEnter,
                        onTap: () => context.go(AppRoutes.leagues),
                      ),
                      const SizedBox(height: 16),
                      _ModeOptionCard(
                        icon: Icons.bolt_rounded,
                        iconColor: XiColors.techCyan,
                        title: l10n.modeClashTitle,
                        description: l10n.modeClashDescription,
                        actionLabel: ClashFeatureFlags.modeSelectionEnabled
                            ? l10n.modeClashEnter
                            : l10n.clashTeamComingSoonBadge,
                        enabled: ClashFeatureFlags.modeSelectionEnabled,
                        onTap: ClashFeatureFlags.modeSelectionEnabled
                            ? () => context.go(AppRoutes.clash)
                            : null,
                      ),
                    ],
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

class _ModeOptionCard extends StatelessWidget {
  const _ModeOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String actionLabel;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardOpacity = enabled ? 1.0 : 0.72;

    return Opacity(
      opacity: cardOpacity,
      child: Material(
        color: context.xiCardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.xiDivider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: iconColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.xiTextPrimary,
                        ),
                      ),
                    ),
                    if (!enabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.xiChipBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: context.xiDivider),
                        ),
                        child: Text(
                          actionLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.xiTextSecondary,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: context.xiTextSecondary.withValues(alpha: 0.5),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.xiTextSecondary.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: enabled ? onTap : null,
                    child: Text(actionLabel),
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
