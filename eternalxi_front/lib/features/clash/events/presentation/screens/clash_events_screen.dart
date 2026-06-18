import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/presentation/controllers/clash_character_events_controller.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_card.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = ClashCharacterEventsController(
      repository: context.read<ClashCharacterEventsRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.loadEvents(),
    );
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

        return Scaffold(
          appBar: AppBar(title: Text(l10n.clashEventsTitle)),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _controller.loadEvents,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_controller.summaries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text(l10n.clashEventsEmpty)),
                        )
                      else
                        ..._controller.summaries.map(
                          (summary) => ClashEventCard(
                            summary: summary,
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
