import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_history_entry.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_history_entry_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClashGachaHistoryScreen extends StatefulWidget {
  const ClashGachaHistoryScreen({super.key});

  @override
  State<ClashGachaHistoryScreen> createState() =>
      _ClashGachaHistoryScreenState();
}

class _ClashGachaHistoryScreenState extends State<ClashGachaHistoryScreen> {
  List<ClashGachaHistoryEntry> _entries = const [];
  bool _loading = true;
  ClashGachaPullType? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final entries = await context.read<ClashGachaRepository>().loadHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  List<ClashGachaHistoryEntry> get _visibleEntries {
    if (_filter == null) {
      return _entries;
    }
    return _entries.where((entry) => entry.pullType == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visible = _visibleEntries;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clashGachaHistoryTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_entries.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      l10n.clashGachaHistoryTotal(_entries.length),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: l10n.clashGachaHistoryFilterAll,
                          selected: _filter == null,
                          onSelected: () => setState(() => _filter = null),
                        ),
                        _FilterChip(
                          label: l10n.clashGachaHistoryFilterSingle,
                          selected: _filter == ClashGachaPullType.single,
                          onSelected: () => setState(
                            () => _filter = ClashGachaPullType.single,
                          ),
                        ),
                        _FilterChip(
                          label: l10n.clashGachaHistoryFilterMulti,
                          selected: _filter == ClashGachaPullType.multi,
                          onSelected: () => setState(
                            () => _filter = ClashGachaPullType.multi,
                          ),
                        ),
                        _FilterChip(
                          label: l10n.clashGachaHistoryFilterDaily,
                          selected: _filter == ClashGachaPullType.dailySingle,
                          onSelected: () => setState(
                            () => _filter = ClashGachaPullType.dailySingle,
                          ),
                        ),
                        _FilterChip(
                          label: l10n.clashGachaHistoryFilterTicket,
                          selected: _filter == ClashGachaPullType.ticketSingle,
                          onSelected: () => setState(
                            () => _filter = ClashGachaPullType.ticketSingle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: _entries.isEmpty
                      ? _EmptyState(message: l10n.clashGachaHistoryEmpty)
                      : visible.isEmpty
                      ? _EmptyState(
                          message: l10n.clashGachaHistoryEmpty,
                          icon: Icons.filter_alt_off_rounded,
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: visible.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return ClashGachaHistoryEntryCard(
                              entry: visible[index],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.icon = Icons.history_rounded});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.xiTextSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: context.xiTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
