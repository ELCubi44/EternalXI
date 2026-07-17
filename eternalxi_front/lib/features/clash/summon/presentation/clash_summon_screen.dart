import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/presentation/widgets/clash_section_tile.dart';
import 'package:flutter/material.dart';

/// Invocaciones Clash (contenido pendiente; se irá añadiendo poco a poco).
class ClashSummonScreen extends StatelessWidget {
  const ClashSummonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ClashScreenScaffold(
      title: context.l10n.clashTabSummon,
      children: const [],
    );
  }
}
