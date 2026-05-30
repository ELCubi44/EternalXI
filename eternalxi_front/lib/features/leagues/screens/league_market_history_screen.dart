import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/data/models/league_activity_event.dart';
import 'package:eternal_xi/data/models/league_market_history_entry.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/utils/league_history_filters.dart';
import 'package:eternal_xi/features/leagues/widgets/league_market_history_bubble.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/league_activity_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeagueMarketHistoryScreen extends StatefulWidget {
  const LeagueMarketHistoryScreen({
    super.key,
    required this.leagueId,
    required this.userId,
    this.leagueName,
  });

  final int leagueId;
  final int userId;
  final String? leagueName;

  @override
  State<LeagueMarketHistoryScreen> createState() =>
      _LeagueMarketHistoryScreenState();
}

class _LeagueMarketHistoryScreenState extends State<LeagueMarketHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<LeagueUnifiedHistoryItem> _items = const [];
  String _filter = LeagueMarketHistoryFilters.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool keepData = false}) async {
    if (!keepData) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }
    try {
      final api = context.read<LeaguesApiService>();
      final results = await Future.wait([
        api.getMarketHistory(leagueId: widget.leagueId, userId: widget.userId),
        api.getLeagueActivity(
          idLiga: widget.leagueId,
          idUsuario: widget.userId,
          limit: 100,
        ),
      ]);
      if (!mounted) {
        return;
      }
      final marketRows = results[0] as List<LeagueMarketHistoryEntry>;
      final activityRows = results[1] as List<LeagueActivityEvent>;
      final kicks = activityRows
          .where((e) => e.tipo.trim().toUpperCase() == 'ADMIN_KICK')
          .toList();

      final merged = <LeagueUnifiedHistoryItem>[
        ...marketRows.map(LeagueUnifiedMarketItem.new),
        ...kicks.map(LeagueUnifiedActivityItem.new),
      ]..sort((a, b) {
        final ad = a.sortDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.sortDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      setState(() {
        _items = merged;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<LeagueUnifiedHistoryItem> get _filteredItems {
    return _items
        .where((item) => leagueMarketHistoryMatchesFilter(item, _filter))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ll = context.leagueL10n;
    final subtitle = (widget.leagueName ?? '').trim().isNotEmpty
        ? ll.historySubtitleNamed(widget.leagueName!.trim())
        : ll.historySubtitleGeneric;
    final filtered = _filteredItems;

    return Scaffold(
      appBar: AppBar(title: Text(ll.marketHistoryTitle)),
      body: RefreshIndicator(
        onRefresh: () => _load(keepData: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          children: [
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in LeagueMarketHistoryFilters.labels.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(entry.value),
                        selected: _filter == entry.key,
                        onSelected: _loading
                            ? null
                            : (_) => setState(() => _filter = entry.key),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _ErrorState(error: _error!, onRetry: _load)
            else if (filtered.isEmpty)
              const _EmptyState()
            else
              ...filtered.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: switch (item) {
                    LeagueUnifiedMarketItem(:final entry) =>
                      LeagueMarketHistoryBubble(entry: entry),
                    LeagueUnifiedActivityItem(:final event) =>
                      LeagueActivityTile(event: event),
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 34,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            context.leagueL10n.noMovementsForFilter,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final Future<void> Function({bool keepData}) onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 34,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}
