import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

enum ClashGachaActionStyle { filled, tonal, outlined }

/// Botón de invocación con coste y motivo de deshabilitado (Fase 38).
class ClashGachaActionButton extends StatelessWidget {
  const ClashGachaActionButton({
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.icon,
    this.loading = false,
    this.style = ClashGachaActionStyle.filled,
    super.key,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onPressed;
  final ClashGachaActionStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOnPressed = loading ? null : onPressed;

    Widget content;
    if (loading) {
      content = SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: style == ClashGachaActionStyle.filled
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.primary,
        ),
      );
    } else if (style == ClashGachaActionStyle.outlined) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
        ],
      );
    }

    return switch (style) {
      ClashGachaActionStyle.filled => FilledButton(
        onPressed: effectiveOnPressed,
        child: content,
      ),
      ClashGachaActionStyle.tonal => FilledButton.tonal(
        onPressed: effectiveOnPressed,
        child: content,
      ),
      ClashGachaActionStyle.outlined => OutlinedButton.icon(
        onPressed: effectiveOnPressed,
        icon: Icon(icon ?? Icons.confirmation_number_rounded),
        label: content,
      ),
    };
  }
}
