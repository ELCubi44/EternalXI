import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/presentation/widgets/clash_match_event_tile.dart';
import 'package:flutter/material.dart';

/// Historial reciente de eventos del partido (Fase 46).
class ClashMatchHistoryPanel extends StatelessWidget {
  const ClashMatchHistoryPanel({
    required this.state,
    this.maxEvents = 8,
    super.key,
  });

  final MatchState state;
  final int maxEvents;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final events = state.eventLog.reversed.take(maxEvents).toList();

    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.clashMatchEventLogTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final event in events) ClashMatchEventTile(event: event),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
