import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_reward_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_stage_detail_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashEventStoryStageScreen extends StatefulWidget {
  const ClashEventStoryStageScreen({
    required this.eventId,
    required this.stageId,
    super.key,
  });

  final String eventId;
  final String stageId;

  @override
  State<ClashEventStoryStageScreen> createState() =>
      _ClashEventStoryStageScreenState();
}

class _ClashEventStoryStageScreenState
    extends State<ClashEventStoryStageScreen> {
  ClashCharacterEvent? _event;
  ClashCharacterEventStage? _stage;
  ClashCharacterEventStageProgress? _progress;
  var _loading = true;
  var _completing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<ClashCharacterEventsRepository>();
    final event = await repo.findEventById(widget.eventId);
    final stage = await repo.findStage(widget.eventId, widget.stageId);
    final progressList = await repo.fetchStageProgress(widget.eventId);
    ClashCharacterEventStageProgress? progress;
    for (final item in progressList) {
      if (item.stage.id == widget.stageId) {
        progress = item;
        break;
      }
    }
    if (mounted) {
      setState(() {
        _event = event;
        _stage = stage;
        _progress = progress;
        _loading = false;
      });
    }
  }

  Future<void> _complete() async {
    if (_completing) {
      return;
    }
    setState(() => _completing = true);
    final repo = context.read<ClashCharacterEventsRepository>();
    final result = await repo.completeStoryStage(
      eventId: widget.eventId,
      stageId: widget.stageId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _completing = false);
    if (result == null) {
      return;
    }
    if (result.rewardsGranted.isEmpty) {
      context.pop();
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Provider<ClashCharacterEventsRepository>.value(
          value: repo,
          child: ClashEventRewardScreen(
            eventId: widget.eventId,
            stageId: widget.stageId,
          ),
        ),
      ),
    );
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stage = _stage;
    final event = _event;
    final progress = _progress;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (stage == null || event == null || progress == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.clashEventsTitle)),
        body: Center(child: Text(l10n.clashEventsStageNotFound)),
      );
    }

    final isCompleted = progress.clearCount > 0;
    final narrative = stage.storyText.isNotEmpty
        ? stage.storyText
        : l10n.clashEventsStoryPlaceholder;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clashEventsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          ClashEventStageDetailHeader(
            eventTitle: event.title,
            stage: stage,
            status: progress.status,
            clearCount: progress.clearCount,
            firstClearClaimed: isCompleted,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.xiCardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.xiDivider),
            ),
            child: Text(
              narrative,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: context.xiTextSecondary,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isCompleted) ...[
            OutlinedButton(
              onPressed: () =>
                  context.go(AppRoutes.clashEventDetail(widget.eventId)),
              child: Text(l10n.clashEventsBack),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _completing ? null : _complete,
              child: _completing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.clashEventsStageReadAgain),
            ),
          ] else
            FilledButton(
              onPressed: _completing ? null : _complete,
              child: _completing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.clashEventsStoryComplete),
            ),
        ],
      ),
    );
  }
}
