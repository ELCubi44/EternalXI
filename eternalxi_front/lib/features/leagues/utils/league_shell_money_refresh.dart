import 'package:eternal_xi/features/leagues/shell/league_shell_data.dart';
import 'package:flutter/material.dart';

/// Recarga la shell de liga (presupuesto, cabecera, pestañas) tras operaciones con dinero.
Future<void> reloadLeagueShellAfterMoney(BuildContext context) async {
  await LeagueShellData.maybeOf(context)?.reload();
}
