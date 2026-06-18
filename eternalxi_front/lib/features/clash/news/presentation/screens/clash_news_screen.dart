import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_repository.dart';
import 'package:eternal_xi/features/clash/news/presentation/controllers/clash_news_controller.dart';
import 'package:eternal_xi/features/clash/news/presentation/widgets/clash_news_card.dart';
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
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isLoading =
            _controller.state == ClashNewsLoadState.loading &&
            _controller.entries.isEmpty;
        final filtered = _controller.filteredEntries;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.clashNewsTitle),
            actions: [
              TextButton(
                onPressed: _controller.summary.unreadCount == 0
                    ? null
                    : _markAllAsRead,
                child: Text(l10n.clashNewsMarkAllRead),
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
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
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              l10n.clashNewsEmptyFilter,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: context.xiTextSecondary,
                              ),
                            ),
                          ),
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
