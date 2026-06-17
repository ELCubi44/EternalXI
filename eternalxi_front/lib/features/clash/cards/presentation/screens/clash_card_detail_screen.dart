import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_table.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_portrait.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashCardDetailScreen extends StatefulWidget {
  const ClashCardDetailScreen({required this.cardId, super.key});

  final String cardId;

  @override
  State<ClashCardDetailScreen> createState() => _ClashCardDetailScreenState();
}

class _ClashCardDetailScreenState extends State<ClashCardDetailScreen> {
  ClashCardCatalogEntry? _entry;
  bool _loading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCard());
  }

  Future<void> _loadCard() async {
    final controller = context.read<ClashCardsController>();
    final collection = context.read<ClashPlayerCollectionRepository>();
    if (controller.state == ClashCardsLoadState.idle) {
      await controller.load();
    }
    final entry = await controller.findCard(widget.cardId);
    if (!mounted) {
      return;
    }
    setState(() {
      _entry = entry == null ? null : collection.enrichEntry(entry);
      _notFound = entry == null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notFound || _entry == null) {
      return _ErrorState(message: l10n.clashCardNotFound);
    }

    final entry = _entry!;
    final card = entry.card;
    final technique = card.superTechniques.isNotEmpty
        ? card.superTechniques.first
        : null;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                entry.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.xiTextPrimary,
                ),
              ),
            ),
            ClashRarityBadge(rarity: card.rarity),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            final portrait = ClashCardPortrait(
              name: entry.name,
              imagePath: card.basicPortraitPath,
              height: wide ? 320 : 260,
              borderRadius: 18,
            );

            final info = _InfoPanel(entry: entry);

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: portrait),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        info,
                        const SizedBox(height: 12),
                        _XpPanel(entry: entry),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                portrait,
                const SizedBox(height: 16),
                info,
                const SizedBox(height: 12),
                _XpPanel(entry: entry),
              ],
            );
          },
        ),
        if (technique != null) ...[
          const SizedBox(height: 20),
          _TechniquePanel(technique: technique),
        ],
        const SizedBox(height: 16),
        ClashSectionTile(
          icon: Icons.trending_up_rounded,
          title: l10n.clashActionUpgrade,
          onTap: () => _showComingSoon(context),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.upgrade_rounded,
          title: l10n.clashActionEvolve,
          onTap: () => _showComingSoon(context),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.account_tree_rounded,
          title: l10n.clashActionTree,
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.l10n.clashComingSoon),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: context.xiTextSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.pop(),
              child: Text(context.l10n.clashBack),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.entry});

  final ClashCardCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final card = entry.card;
    final stats = entry.displayStats;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetaRow(label: l10n.clashCardTeam, value: entry.team),
          _MetaRow(
            label: l10n.clashCardPosition,
            value: card.position.displayNameEs,
          ),
          _MetaRow(label: l10n.clashCardStyle, value: card.style.displayNameEs),
          _MetaRow(
            label: l10n.clashCardLevel,
            value: '${entry.displayLevel} / ${card.rarity.maxLevel}',
          ),
          _MetaRow(label: l10n.clashCardPower, value: '${entry.power}'),
          const SizedBox(height: 12),
          Text(
            l10n.clashCardStats,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _StatRow(label: l10n.clashStatSave, value: stats.save),
          _StatRow(label: l10n.clashStatDefense, value: stats.defense),
          _StatRow(label: l10n.clashStatPass, value: stats.pass),
          _StatRow(label: l10n.clashStatDribble, value: stats.dribble),
          _StatRow(label: l10n.clashStatShot, value: stats.shot),
          _StatRow(label: l10n.clashStatPt, value: stats.techniquePoints),
          _StatRow(label: l10n.clashStatStamina, value: stats.stamina),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary.withValues(alpha: 0.85),
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _XpPanel extends StatelessWidget {
  const _XpPanel({required this.entry});

  final ClashCardCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final card = entry.card;
    final progress = entry.progress;
    final currentXp = progress?.currentExperience ?? 0;

    if (entry.isMaxLevel) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.xiCardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.xiDivider),
        ),
        child: Text(
          l10n.clashCardMaxLevel,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.xiTextSecondary,
          ),
        ),
      );
    }

    final needed =
        entry.xpToNextLevel ??
        ClashCardXpTable.xpToNextLevel(entry.displayLevel, card.rarity);
    final ratio = needed <= 0 ? 0.0 : (currentXp / needed).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.clashCardXpTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: context.xiChipBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clashCardXpProgress(currentXp, needed),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechniquePanel extends StatelessWidget {
  const _TechniquePanel({required this.technique});

  final ClashSuperTechnique technique;

  static String _typeLabel(ClashTechniqueType type) => switch (type) {
    ClashTechniqueType.save => 'Parada',
    ClashTechniqueType.defense => 'Defensa',
    ClashTechniqueType.dribble => 'Regate',
    ClashTechniqueType.shot => 'Tiro',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.clashTechniqueSection,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            technique.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(technique.description),
          const SizedBox(height: 10),
          _MetaRow(
            label: l10n.clashTechniqueType,
            value: _typeLabel(technique.type),
          ),
          _MetaRow(
            label: l10n.clashCardStyle,
            value: technique.style.displayNameEs,
          ),
          _MetaRow(
            label: l10n.clashTechniquePower,
            value: '${technique.effectivePower}',
          ),
          _MetaRow(
            label: l10n.clashTechniquePtCost,
            value: '${technique.ptCost}',
          ),
          _MetaRow(
            label: l10n.clashTechniqueLevel,
            value: technique.level.name.toUpperCase(),
          ),
        ],
      ),
    );
  }
}
