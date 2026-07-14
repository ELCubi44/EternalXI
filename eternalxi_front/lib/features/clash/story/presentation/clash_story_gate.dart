import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Mensajes de bloqueo progresivo (modo Cadena XI ya no depende del proxlogo).
class ClashStoryGate {
  static bool isTeamUnlocked(BuildContext context) => true;

  static bool isSummonUnlocked(BuildContext context) => true;

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
