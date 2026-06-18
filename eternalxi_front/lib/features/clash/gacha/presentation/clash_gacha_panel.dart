import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_error.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/controllers/clash_gacha_controller.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_banner_card.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClashGachaPanel extends StatefulWidget {
  const ClashGachaPanel({super.key});

  @override
  State<ClashGachaPanel> createState() => _ClashGachaPanelState();
}

class _ClashGachaPanelState extends State<ClashGachaPanel> {
  late final ClashGachaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClashGachaController(
      repository: context.read<ClashGachaRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pull(ClashGachaPullType type) async {
    final outcome = await _controller.pull(type);
    if (!mounted) {
      return;
    }
    final l10n = context.l10n;
    if (outcome.error == ClashGachaPullError.insufficientGems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _controller.walletGems <= 0
                ? l10n.clashGachaEarnGemsHint
                : l10n.clashGachaInsufficientGems,
          ),
        ),
      );
      return;
    }
    if (outcome.error == ClashGachaPullError.dailyAlreadyUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.clashGachaDailyUsed),
        ),
      );
      return;
    }
    if (outcome.result != null) {
      await context.read<ClashCardsController>().reloadOwnedCards();
      await ClashGachaResultSheet.show(context, outcome.result!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ClashGachaController>.value(
      value: _controller,
      child: _ClashGachaBody(onPull: _pull),
    );
  }
}

class _ClashGachaBody extends StatelessWidget {
  const _ClashGachaBody({required this.onPull});

  final Future<void> Function(ClashGachaPullType type) onPull;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashGachaController>();
    final banner = controller.banner;

    if (controller.state == ClashGachaLoadState.loading ||
        controller.state == ClashGachaLoadState.idle) {
      return const Center(child: CircularProgressIndicator());
    }

    if (banner == null) {
      return Center(child: Text(l10n.clashStoryLoadError));
    }

    final pulling = controller.state == ClashGachaLoadState.pulling;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(
          l10n.clashTabSummon,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.clashGachaLocalDisclaimer,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.xiTextSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        _WalletCard(gems: controller.walletGems),
        const SizedBox(height: 16),
        ClashGachaBannerCard(banner: banner, rates: controller.rates),
        const SizedBox(height: 16),
        Text(
          l10n.clashSummonRates,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _RatesCard(rates: controller.rates),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: pulling ? null : () => onPull(ClashGachaPullType.single),
          child: Text(l10n.clashGachaSingleButton(banner.singleCost)),
        ),
        const SizedBox(height: 10),
        FilledButton.tonal(
          onPressed: pulling ? null : () => onPull(ClashGachaPullType.multi),
          child: Text(
            l10n.clashGachaMultiButton(banner.multiCost, banner.multiCount),
          ),
        ),
        const SizedBox(height: 10),
        if (banner.dailyDiscountAvailable)
          OutlinedButton(
            onPressed: pulling || !controller.dailyAvailable
                ? null
                : () => onPull(ClashGachaPullType.dailySingle),
            child: Text(
              controller.dailyAvailable
                  ? l10n.clashGachaDailyButton(banner.dailyDiscountCost)
                  : l10n.clashGachaDailyUsed,
            ),
          ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.gems});

  final int gems;

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
      child: Row(
        children: [
          Icon(
            Icons.diamond_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Text(
            l10n.clashGachaWalletGems(gems),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RatesCard extends StatelessWidget {
  const _RatesCard({required this.rates});

  final ClashGachaRarityRates rates;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        children: [
          _RateRow(label: 'N', value: rates.nPercent),
          _RateRow(label: 'R', value: rates.rPercent),
          _RateRow(label: 'SR', value: rates.srPercent),
          _RateRow(label: 'LR', value: rates.lrPercent),
          _RateRow(label: 'XI', value: rates.xiPercent),
          const SizedBox(height: 8),
          Text(
            l10n.clashGachaMultiGuarantee,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text('$value %')),
        ],
      ),
    );
  }
}
