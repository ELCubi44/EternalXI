import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Mensajes de bloqueo progresivo ligados al prólogo de historia.
class ClashStoryGate {
  static bool isTeamUnlocked(BuildContext context) {
    return context.read<ClashStoryController>().clashTeamUnlocked;
  }

  static void showTeamLockedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.l10n.clashStoryGateTeam),
      ),
    );
  }

  static void showSummonLockedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.l10n.clashStoryGateSummon),
      ),
    );
  }

  static void showEventsLockedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.l10n.clashStoryGateEvents),
      ),
    );
  }
}
