import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/presentation/controllers/clash_cards_controller.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_error.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_ticket.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/controllers/clash_gacha_controller.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_action_button.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_banner_card.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_pity_card.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  Future<void> _pull(ClashGachaPullType type, {String? ticketId}) async {
    final outcome = ticketId == null
        ? await _controller.pull(type)
        : await _controller.pullWithTicket(ticketId);
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
    if (outcome.error == ClashGachaPullError.noTickets) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.clashGachaNoTickets),
        ),
      );
      return;
    }
    if (outcome.result != null) {
      await context.read<ClashCardsController>().reloadOwnedCards();
      if (!mounted) {
        return;
      }
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

  final Future<void> Function(ClashGachaPullType type, {String? ticketId})
  onPull;

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
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.clashTabSummon,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.clashSummonHistory),
              child: Text(l10n.clashSummonHistory),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.xiChipBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.xiDivider),
          ),
          child: Text(
            l10n.clashGachaLocalDisclaimer,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _WalletCard(
          gems: controller.walletGems,
          tickets: controller.totalTicketCount,
        ),
        const SizedBox(height: 16),
        ClashGachaBannerCard(
          banner: banner,
          rates: controller.rates,
          pityState: controller.pityState,
          dailyAvailable: controller.dailyAvailable,
        ),
        if (controller.pityState != null) ...[
          const SizedBox(height: 12),
          ClashGachaPityCard(pityState: controller.pityState!),
        ],
        const SizedBox(height: 20),
        ClashGachaActionButton(
          label: l10n.clashGachaSingleButton(banner.singleCost),
          loading: pulling,
          onPressed: !pulling && controller.canAffordSingle
              ? () => onPull(ClashGachaPullType.single)
              : null,
          subtitle: !controller.canAffordSingle && !pulling
              ? l10n.clashGachaButtonDisabledGems
              : null,
        ),
        const SizedBox(height: 10),
        ClashGachaActionButton(
          label: l10n.clashGachaMultiButton(
            banner.multiCost,
            banner.multiCount,
          ),
          style: ClashGachaActionStyle.tonal,
          loading: pulling,
          onPressed: !pulling && controller.canAffordMulti
              ? () => onPull(ClashGachaPullType.multi)
              : null,
          subtitle: !controller.canAffordMulti && !pulling
              ? l10n.clashGachaButtonDisabledGems
              : null,
        ),
        if (banner.dailyDiscountAvailable) ...[
          const SizedBox(height: 10),
          ClashGachaActionButton(
            label: controller.dailyAvailable
                ? l10n.clashGachaDailyButton(banner.dailyDiscountCost)
                : l10n.clashGachaDailyUsed,
            style: ClashGachaActionStyle.outlined,
            icon: Icons.today_rounded,
            loading: pulling,
            onPressed: !pulling && controller.canAffordDaily
                ? () => onPull(ClashGachaPullType.dailySingle)
                : null,
            subtitle: !controller.dailyAvailable
                ? l10n.clashGachaButtonDisabledDaily
                : (!controller.canAffordDaily && !pulling
                      ? l10n.clashGachaButtonDisabledGems
                      : null),
          ),
        ],
        if (controller.compatibleTickets.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.clashGachaTicketsAvailable,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final entry in controller.compatibleTickets) ...[
            _TicketUseButton(
              entry: entry,
              pulling: pulling,
              onUse: () => onPull(
                ClashGachaPullType.ticketSingle,
                ticketId: entry.ticket.id,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.gems, required this.tickets});

  final int gems;
  final int tickets;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Row(
        children: [
          Icon(Icons.diamond_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.clashGachaWalletGems(gems),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(
            Icons.confirmation_number_rounded,
            color: theme.colorScheme.tertiary,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.clashGachaWalletTickets(tickets),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketUseButton extends StatelessWidget {
  const _TicketUseButton({
    required this.entry,
    required this.pulling,
    required this.onUse,
  });

  final ClashGachaTicketInventoryEntry entry;
  final bool pulling;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = !pulling && entry.quantity > 0;

    return ClashGachaActionButton(
      label: l10n.clashGachaUseTicketButton(entry.quantity),
      style: ClashGachaActionStyle.outlined,
      icon: Icons.confirmation_number_rounded,
      loading: pulling,
      onPressed: enabled ? onUse : null,
      subtitle: enabled ? null : l10n.clashGachaButtonDisabledTickets,
    );
  }
}
