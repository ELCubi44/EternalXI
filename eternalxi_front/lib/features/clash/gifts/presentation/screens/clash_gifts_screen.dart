import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/controllers/clash_gifts_controller.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/widgets/clash_gift_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClashGiftsScreen extends StatefulWidget {
  const ClashGiftsScreen({super.key});

  @override
  State<ClashGiftsScreen> createState() => _ClashGiftsScreenState();
}

class _ClashGiftsScreenState extends State<ClashGiftsScreen> {
  late final ClashGiftsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClashGiftsController(
      repository: context.read<ClashGiftsRepository>(),
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

  Future<void> _claimGift(String giftId) async {
    final l10n = context.l10n;
    final result = await _controller.claimGift(giftId);
    if (!mounted) {
      return;
    }
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.clashGiftsClaimSuccess),
        ),
      );
    }
  }

  Future<void> _claimAll() async {
    final l10n = context.l10n;
    final results = await _controller.claimAllPending();
    if (!mounted) {
      return;
    }
    final claimed = results.where((item) => item.success).length;
    if (claimed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.clashGiftsClaimSuccess),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final summary = _controller.summary;
        final isClaiming = _controller.state == ClashGiftsLoadState.claiming;
        final isLoading =
            _controller.state == ClashGiftsLoadState.loading &&
            _controller.entries.isEmpty;
        final entries = _controller.entries;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.clashGiftsTitle)),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        l10n.clashGiftsPendingSummary(summary.pendingCount),
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.clashGiftsClaimedSummary(
                          summary.claimedCount,
                          summary.totalGifts,
                        ),
                        style: theme.textTheme.labelLarge,
                      ),
                      if (summary.pendingCount == 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.clashGiftsEmptyPending,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.xiTextSecondary,
                          ),
                        ),
                      ],
                      if (summary.pendingCount > 0) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: isClaiming ? null : _claimAll,
                            child: Text(l10n.clashGiftsClaimAll),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              l10n.clashGiftsEmptyPending,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: context.xiTextSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        ...entries.map(
                          (entry) => ClashGiftCard(
                            key: ValueKey(entry.gift.id),
                            entry: entry,
                            isClaiming: isClaiming,
                            onClaim: entry.canClaim
                                ? () => _claimGift(entry.gift.id)
                                : null,
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
