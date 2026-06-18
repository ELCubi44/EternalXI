import 'package:flutter/material.dart';

/// Botón de reclamar con estado loading (Fase 40).
class ClashClaimButton extends StatelessWidget {
  const ClashClaimButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );

    if (!expanded) {
      return Align(alignment: Alignment.centerRight, child: button);
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
