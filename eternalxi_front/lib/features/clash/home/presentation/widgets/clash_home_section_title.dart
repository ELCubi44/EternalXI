import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:flutter/material.dart';

/// Título de sección en Inicio Clash (Fase 35).
class ClashHomeSectionTitle extends StatelessWidget {
  const ClashHomeSectionTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: context.xiTextSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
