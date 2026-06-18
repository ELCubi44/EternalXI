import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_reward_screen.dart';
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
  ClashCharacterEventStage? _stage;
  var _loading = true;
  var _completing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<ClashCharacterEventsRepository>();
    final stage = await repo.findStage(widget.eventId, widget.stageId);
    if (mounted) {
      setState(() {
        _stage = stage;
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

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (stage == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.clashEventsTitle)),
        body: Center(child: Text(l10n.clashEventsStageNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(stage.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            stage.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            stage.storyText.isNotEmpty
                ? stage.storyText
                : l10n.clashEventsStoryPlaceholder,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.xiTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.clashEventsFirstClear,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _rewardText(context, stage.firstClearRewards),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
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

  String _rewardText(BuildContext context, ClashCharacterEventReward reward) {
    final l10n = context.l10n;
    if (reward.isEmpty) {
      return '—';
    }
    final parts = <String>[];
    if (reward.coins > 0) {
      parts.add(l10n.clashAchievementsRewardCoins(reward.coins));
    }
    if (reward.gems > 0) {
      parts.add(l10n.clashAchievementsRewardGems(reward.gems));
    }
    if (reward.expMaterial != null) {
      parts.add(
        l10n.clashShopGrantLine(
          reward.expMaterial!.id,
          reward.expMaterial!.quantity,
        ),
      );
    }
    if (reward.featuredCardId != null) {
      parts.add(reward.featuredCardId!);
    }
    return parts.join(' · ');
  }
}
