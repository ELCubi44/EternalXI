import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Diálogo al salir de la alineación con cambios sin guardar.
Future<T?> showUnsavedLineupDialog<T>(BuildContext context) {
  return showDialog<T>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final l10n = ctx.l10n;
      return AlertDialog(
        title: Text(l10n.unsavedLineupTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.unsavedLineupBody,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: Text(l10n.save),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              child: Text(l10n.exitWithoutSaving),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'stay'),
              child: Text(l10n.stayHere),
            ),
          ],
        ),
      );
    },
  );
}

enum UnsavedLineupChoice { save, discardAndLeave, stay }

UnsavedLineupChoice? parseUnsavedLineupChoice(String? value) {
  return switch (value) {
    'save' => UnsavedLineupChoice.save,
    'discard' => UnsavedLineupChoice.discardAndLeave,
    'stay' => UnsavedLineupChoice.stay,
    _ => null,
  };
}
