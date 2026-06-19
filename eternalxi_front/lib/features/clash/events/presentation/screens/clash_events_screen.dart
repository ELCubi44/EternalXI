import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/presentation/controllers/clash_character_events_controller.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_card.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_events_list_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashEventsScreen extends StatefulWidget {
  const ClashEventsScreen({super.key});

  @override
  State<ClashEventsScreen> createState() => _ClashEventsScreenState();
}

class _ClashEventsScreenState extends State<ClashEventsScreen> {
  late final ClashCharacterEventsController _controller;
  final Map<String, String> _cardNamesById = {};

  @override
  void initState() {
    super.initState();
    _controller = ClashCharacterEventsController(
      repository: context.read<ClashCharacterEventsRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.loadEvents();
      await _resolveFeaturedCardNames();
    });
  }

  Future<void> _resolveFeaturedCardNames() async {
    ClashCardsRepository? cardsRepo;
    try {
      cardsRepo = context.read<ClashCardsRepository>();
    } catch (_) {
      return;
    }
    final names = <String, String>{};
    for (final summary in _controller.summaries) {
      final cardId = summary.event.featuredCardId;
      if (cardId == null) {
        continue;
      }
      final entry = await cardsRepo.findById(cardId);
      names[cardId] = entry?.name ?? cardId;
    }
    if (!mounted) {
      return;
    }
    setState(() => _cardNamesById.addAll(names));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isLoading =
            _controller.state == ClashCharacterEventsLoadState.loading &&
            _controller.summaries.isEmpty;
        final availableCount = _controller.summaries
            .where((summary) => summary.isAvailable)
            .length;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.clashEventsTitle)),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await _controller.loadEvents();
                    await _resolveFeaturedCardNames();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      ClashEventsListHeader(availableCount: availableCount),
                      if (_controller.summaries.isEmpty)
                        _EventsEmptyState(message: l10n.clashEventsEmpty)
                      else
                        ..._controller.summaries.map(
                          (summary) => ClashEventCard(
                            summary: summary,
                            featuredCardName:
                                summary.event.featuredCardId == null
                                ? null
                                : _cardNamesById[summary.event.featuredCardId!],
                            onEnter: () => context.push(
                              AppRoutes.clashEventDetail(summary.event.id),
                            ),
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

class _EventsEmptyState extends StatelessWidget {
  const _EventsEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 56,
            color: context.xiTextSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: context.xiTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
