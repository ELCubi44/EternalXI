import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/controllers/clash_gifts_controller.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/widgets/clash_gift_card.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_claim_button.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_empty_state_card.dart';
import 'package:eternal_xi/features/clash/shared/presentation/widgets/clash_progress_summary_card.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback.dart';
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
    final result = await _controller.claimGift(giftId);
    if (!mounted) {
      return;
    }
    ClashRewardFeedback.showGiftClaimFeedback(context, result);
  }

  Future<void> _claimAll() async {
    final results = await _controller.claimAllPending();
    if (!mounted) {
      return;
    }
    ClashRewardFeedback.showGiftBatchClaimFeedback(context, results);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final summary = _controller.summary;
        final isClaiming = _controller.state == ClashGiftsLoadState.claiming;
        final isLoading =
            _controller.state == ClashGiftsLoadState.loading &&
            _controller.entries.isEmpty;
        final entries = _controller.entries;
        final progress = summary.totalGifts == 0
            ? 0.0
            : summary.claimedCount / summary.totalGifts;

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
                      ClashProgressSummaryCard(
                        lines: [
                          l10n.clashGiftsPendingSummary(summary.pendingCount),
                          l10n.clashGiftsClaimedSummary(
                            summary.claimedCount,
                            summary.totalGifts,
                          ),
                        ],
                        progress: progress,
                        action: summary.pendingCount > 0
                            ? ClashClaimButton(
                                label: l10n.clashGiftsClaimAll,
                                loading: isClaiming,
                                onPressed: _claimAll,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      if (entries.isEmpty)
                        ClashEmptyStateCard(
                          message: l10n.clashGiftsEmptyPending,
                          icon: Icons.card_giftcard_outlined,
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
