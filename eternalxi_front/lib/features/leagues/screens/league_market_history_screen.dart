import 'package:eternal_xi/data/models/league_market_history_entry.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/features/leagues/widgets/league_market_history_bubble.dart';
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
  List<LeagueMarketHistoryEntry> _entries = const [];

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
      final rows = await api.getMarketHistory(
        leagueId: widget.leagueId,
        userId: widget.userId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = rows;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = (widget.leagueName ?? '').trim().isNotEmpty
        ? 'Movimientos recientes de ${widget.leagueName!.trim()}'
        : 'Movimientos recientes de la liga';
    return Scaffold(
      appBar: AppBar(title: const Text('Historial del mercado')),
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
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _ErrorState(error: _error!, onRetry: _load)
            else if (_entries.isEmpty)
              const _EmptyState()
            else
              ..._entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LeagueMarketHistoryBubble(entry: entry),
                ),
              ),
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
            'Aún no hay movimientos de mercado.',
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
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
