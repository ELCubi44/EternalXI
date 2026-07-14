import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_status_chip.dart';
import 'package:flutter/material.dart';

/// Cabecera del partido 7v7: título, rival, marcador y estado (Fase 46).
class ClashMatchHeader extends StatelessWidget {
  const ClashMatchHeader({
    required this.matchTitle,
    required this.state,
    this.rivalName,
    this.rivalChipLabel,
    super.key,
  });

  final String matchTitle;
  final MatchState state;
  final String? rivalName;
  final String? rivalChipLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final userScore = state.score.user;
    final rivalScore = state.score.rival;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        children: [
          Text(
            matchTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              ),
          ),
          if (rivalName != null && rivalName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l10n.clashMatchHeaderVsRival(rivalName!),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$userScore',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '—',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: context.xiTextSecondary,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Text(
                '$rivalScore',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.clashMatchWinTarget,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              ClashMatchStatusChip(state: state),
              if (rivalChipLabel != null && rivalChipLabel!.isNotEmpty)
                Chip(
                  label: Text(
                    rivalChipLabel!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      ),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
