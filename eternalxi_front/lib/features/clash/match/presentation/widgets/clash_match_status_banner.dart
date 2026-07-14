import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_status_messages.dart';
import 'package:flutter/material.dart';

/// Banner contextual del estado del partido (Fase 15).
class ClashMatchStatusBanner extends StatelessWidget {
  const ClashMatchStatusBanner({required this.state, super.key});

  final MatchState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final messages = ClashMatchStatusMessages.banner(l10n, state);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            messages.primary,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              ),
          ),
          if (messages.secondary != null) ...[
            const SizedBox(height: 4),
            Text(
              messages.secondary!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
