import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_section_tile.dart';
import 'package:eternal_xi/features/clash/story/presentation/clash_story_gate.dart';
import 'package:flutter/material.dart';

class ClashSummonScreen extends StatelessWidget {
  const ClashSummonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locked = !ClashStoryGate.isTeamUnlocked(context);

    VoidCallback? lockedTap() =>
        locked ? () => ClashStoryGate.showSummonLockedSnackBar(context) : null;

    return ClashScreenScaffold(
      title: l10n.clashTabSummon,
      children: [
        ClashSectionTile(
          icon: Icons.view_carousel_rounded,
          title: l10n.clashSummonBanners,
          onTap: lockedTap(),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.looks_one_rounded,
          title: l10n.clashSummonSingle,
          onTap: lockedTap(),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.filter_9_plus_rounded,
          title: l10n.clashSummonMulti,
          onTap: lockedTap(),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.history_rounded,
          title: l10n.clashSummonHistory,
          onTap: lockedTap(),
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.percent_rounded,
          title: l10n.clashSummonRates,
          onTap: lockedTap(),
        ),
      ],
    );
  }
}
