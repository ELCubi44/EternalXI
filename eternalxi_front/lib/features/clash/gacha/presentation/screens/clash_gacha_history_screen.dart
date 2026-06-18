import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_evolution_resolver.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_history_entry.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_pity_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clashGachaHistoryTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.clashGachaHistoryEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.xiTextSecondary,
                  ),
                ),
              ),
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _HistoryEntryCard(entry: _entries[index]);
              },
            ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({required this.entry});

  final ClashGachaHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateText = _formatDateTime(entry.createdAt);
    final pullLabel = switch (entry.pullType) {
      ClashGachaPullType.single => l10n.clashGachaHistoryPullSingle,
      ClashGachaPullType.multi => l10n.clashGachaHistoryPullMulti,
      ClashGachaPullType.dailySingle => l10n.clashGachaHistoryPullDaily,
      ClashGachaPullType.ticketSingle => l10n.clashGachaHistoryPullTicket,
    };

    return Container(
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.xiDivider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            entry.bannerName,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(dateText),
              const SizedBox(height: 2),
              Text(
                entry.pullType == ClashGachaPullType.ticketSingle
                    ? pullLabel
                    : '$pullLabel · ${l10n.clashGachaHistorySpent(entry.spentGems)}',
              ),
              const SizedBox(height: 2),
              Text(
                l10n.clashGachaHistorySummary(
                  entry.results.length,
                  ClashCardEvolutionResolver.rarityLabel(entry.bestRarity),
                ),
              ),
            ],
          ),
          children: [
            for (final item in entry.results) _HistoryResultRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _HistoryResultRow extends StatelessWidget {
  const _HistoryResultRow({required this.item});

  final ClashGachaHistoryResultItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = item.isNew
        ? l10n.clashGachaResultNew
        : item.upgradedRarity
        ? l10n.clashGachaResultUpgraded
        : l10n.clashGachaResultDuplicate;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.xiBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.xiDivider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.cardName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(status),
                Wrap(
                  children: [
                    if (item.wasPity)
                      ClashGachaResultChip(label: l10n.clashGachaPityChip),
                    if (item.wasMultiGuarantee)
                      ClashGachaResultChip(
                        label: l10n.clashGachaMultiGuaranteeChip,
                      ),
                  ],
                ),
              ],
            ),
          ),
          ClashRarityBadge(rarity: item.rarity),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}
