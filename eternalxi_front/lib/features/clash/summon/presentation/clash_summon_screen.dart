import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/clash_gacha_panel.dart';
import 'package:eternal_xi/features/clash/story/presentation/clash_story_gate.dart';
import 'package:flutter/material.dart';

class ClashSummonScreen extends StatelessWidget {
  const ClashSummonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locked = !ClashStoryGate.isTeamUnlocked(context);

    if (locked) {
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
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton(
              onPressed: () => ClashStoryGate.showSummonLockedSnackBar(context),
              child: Text(l10n.clashStoryGateSummon),
            ),
          ),
        ],
      );
    }

    return const ClashGachaPanel();
  }
}
