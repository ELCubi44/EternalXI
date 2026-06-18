import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_repository.dart';
import 'package:eternal_xi/features/clash/news/presentation/controllers/clash_news_controller.dart';
import 'package:eternal_xi/features/clash/news/presentation/widgets/clash_news_card.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_empty_state_card.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_progress_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClashNewsScreen extends StatefulWidget {
  const ClashNewsScreen({super.key});

  @override
  State<ClashNewsScreen> createState() => _ClashNewsScreenState();
}

class _ClashNewsScreenState extends State<ClashNewsScreen> {
  late final ClashNewsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClashNewsController(
      repository: context.read<ClashNewsRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.openScreen(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markAllAsRead() async {
    await _controller.markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isLoading =
            _controller.state == ClashNewsLoadState.loading &&
            _controller.entries.isEmpty;
        final filtered = _controller.filteredEntries;
        final unread = _controller.summary.unreadCount;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.clashNewsTitle)),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      ClashProgressSummaryCard(
                        lines: [
                          unread == 0
                              ? l10n.clashNewsHomeAllCaughtUp
                              : l10n.clashNewsUnreadSummary(unread),
                        ],
                        action: unread > 0
                            ? SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonal(
                                  onPressed: _markAllAsRead,
                                  child: Text(l10n.clashNewsMarkAllRead),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ClashNewsFilter.values.map((filter) {
                            final selected = _controller.filter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(clashNewsFilterLabel(filter, l10n)),
                                selected: selected,
                                onSelected: (_) =>
                                    _controller.setFilter(filter),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        ClashEmptyStateCard(
                          message: l10n.clashNewsEmptyFilter,
                          icon: Icons.newspaper_outlined,
                        )
                      else
                        ...filtered.map((entry) {
                          return ClashNewsCard(
                            key: ValueKey(entry.item.id),
                            entry: entry,
                            expanded:
                                _controller.expandedNewsId == entry.item.id,
                            typeLabel: clashNewsTypeLabel(
                              entry.item.type,
                              l10n,
                            ),
                            onTap: () =>
                                _controller.toggleExpanded(entry.item.id),
                          );
                        }),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
