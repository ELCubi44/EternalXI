import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClashPlaceholderScreen extends StatelessWidget {
  const ClashPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.xiBackground,
      appBar: AppBar(title: Text(l10n.clashPlaceholderTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.bolt_rounded,
                size: 72,
                color: XiColors.techCyan.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.clashPlaceholderTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.xiTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.clashPlaceholderBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.xiTextSecondary.withValues(alpha: 0.9),
                  height: 1.55,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.mode),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(l10n.backToModeSelection),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
