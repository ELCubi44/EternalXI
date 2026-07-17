import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClashTeamScreen extends StatelessWidget {
  const ClashTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ClashScreenScaffold(
      title: l10n.clashTabTeam,
      children: [
        ClashSectionTile(
          iconAsset: ClashEpicAssets.teamPersonajesIcon,
          title: l10n.clashTeamCharacters,
          onTap: () => context.push(AppRoutes.clashCards),
        ),
      ],
    );
  }
}
