import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage_type.dart';
import 'package:eternal_xi/features/clash/events/presentation/controllers/clash_character_events_controller.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_stage_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashEventDetailScreen extends StatefulWidget {
  const ClashEventDetailScreen({required this.eventId, super.key});

  final String eventId;

  @override
  State<ClashEventDetailScreen> createState() => _ClashEventDetailScreenState();
}

class _ClashEventDetailScreenState extends State<ClashEventDetailScreen> {
  late final ClashCharacterEventsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClashCharacterEventsController(
      repository: context.read<ClashCharacterEventsRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.openEvent(widget.eventId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openStage(ClashCharacterEventStageProgress progress) {
    final stage = progress.stage;
    if (!progress.canPlay) {
      return;
    }
    if (stage.type == ClashCharacterEventStageType.story) {
      context.push(AppRoutes.clashEventStoryStage(widget.eventId, stage.id));
      return;
    }
    context.push(AppRoutes.clashEventStagePrepare(widget.eventId, stage.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final event = _controller.activeEvent;
        if (_controller.state == ClashCharacterEventsLoadState.loading &&
            event == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (event == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.clashEventsTitle)),
            body: Center(child: Text(l10n.clashEventsNotFound)),
          );
        }

        final completed = _controller.stageProgress
            .where(
              (item) => item.status == ClashCharacterEventStageStatus.completed,
            )
            .length;

        return Scaffold(
          appBar: AppBar(title: Text(event.title)),
          body: RefreshIndicator(
            onRefresh: () => _controller.openEvent(widget.eventId),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  event.characterName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.xiTextSecondary,
                    height: 1.45,
                  ),
                ),
                if (event.featuredCardId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.clashEventsFeaturedCard(event.featuredCardId!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.xiTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  l10n.clashEventsProgress(completed, event.stages.length),
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.clashEventsStagesTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ..._controller.stageProgress.map(
                  (progress) => ClashEventStageCard(
                    progress: progress,
                    onPrimaryAction: progress.canPlay
                        ? () => _openStage(progress)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
