import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage_type.dart';
import 'package:eternal_xi/features/clash/events/presentation/controllers/clash_character_events_controller.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_detail_header.dart';
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
  String? _featuredCardName;
  String? _featuredCardRarity;

  @override
  void initState() {
    super.initState();
    _controller = ClashCharacterEventsController(
      repository: context.read<ClashCharacterEventsRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.openEvent(widget.eventId);
      await _resolveFeaturedCard();
    });
  }

  Future<void> _resolveFeaturedCard() async {
    final cardId = _controller.activeEvent?.featuredCardId;
    if (cardId == null) {
      return;
    }
    ClashCardsRepository? cardsRepo;
    try {
      cardsRepo = context.read<ClashCardsRepository>();
    } catch (_) {
      if (mounted) {
        setState(() => _featuredCardName = cardId);
      }
      return;
    }
    final entry = await cardsRepo.findById(cardId);
    if (!mounted) {
      return;
    }
    setState(() {
      _featuredCardName = entry?.name ?? cardId;
      _featuredCardRarity = entry?.effectiveRarity.name.toUpperCase();
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
          appBar: AppBar(title: Text(l10n.clashEventsTitle)),
          body: RefreshIndicator(
            onRefresh: () async {
              await _controller.openEvent(widget.eventId);
              await _resolveFeaturedCard();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                ClashEventDetailHeader(
                  event: event,
                  completedStages: completed,
                  featuredCardName: _featuredCardName,
                  featuredCardRarity: _featuredCardRarity,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.clashEventsStagesTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ..._controller.stageProgress.asMap().entries.map(
                  (entry) => ClashEventStageCard(
                    stageNumber: entry.key + 1,
                    progress: entry.value,
                    onPrimaryAction: entry.value.canPlay
                        ? () => _openStage(entry.value)
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
