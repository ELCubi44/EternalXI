import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_section_tile.dart';
import 'package:flutter/material.dart';

class ClashShopScreen extends StatelessWidget {
  const ClashShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ClashScreenScaffold(
      title: l10n.clashTabShop,
      children: [
        ClashSectionTile(icon: Icons.store_rounded, title: l10n.clashShopGame),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.event_available_rounded,
          title: l10n.clashShopEvent,
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.swap_horiz_rounded,
          title: l10n.clashShopExchange,
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.diamond_rounded,
          title: l10n.clashShopGems,
        ),
        const SizedBox(height: 10),
        ClashSectionTile(
          icon: Icons.inventory_2_rounded,
          title: l10n.clashShopPacks,
        ),
      ],
    );
  }
}
