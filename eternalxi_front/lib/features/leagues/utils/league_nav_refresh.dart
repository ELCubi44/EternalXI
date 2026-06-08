import 'package:flutter/material.dart';

/// Tras volver de una ruta apilada, ejecuta [refresh] si el contexto sigue montado.
Future<void> leagueAfterPush(
  BuildContext context,
  Future<void> navigation,
  Future<void> Function() refresh,
) async {
  await navigation;
  if (!context.mounted) {
    return;
  }
  await refresh();
}
