import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pass_option.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_math.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> showClashMatchPassSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final match = context.watch<ClashMatchController>();
      final options = match.passOptions;
      final l10n = context.l10n;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.clashMatchPassSheetTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(),
              ),
              const SizedBox(height: 12),
              if (options.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l10n.clashMatchPassSheetEmpty,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _PassOptionTile(option: options[index]);
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _PassOptionTile extends StatelessWidget {
  const _PassOptionTile({required this.option});

  final MatchPassOption option;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final match = context.read<ClashMatchController>();
    final risk = MatchPossessionMath.possessionRiskForPass(
      option.successPercent,
    );

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          match.passTo(option.targetIndex);
          Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  option.targetName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.targetName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.targetPosition.displayNameEs,
                      style: theme.textTheme.bodySmall?.copyWith(
                        ),
                    ),
                    Text(
                      option.approximateZone.labelEs(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.xiTextSecondary,
                      ),
                    ),
                    Text(
                      l10n.clashMatchPassOptionPower(option.targetPower),
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.clashMatchPassRiskLabel(risk),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: risk >= 50
                            ? Colors.orange
                            : context.xiTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      l10n.clashMatchPassPercent(option.successPercent),
                      style: theme.textTheme.labelLarge?.copyWith(
                        ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FilledButton.tonal(
                    onPressed: () {
                      match.passTo(option.targetIndex);
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(l10n.clashMatchActionPass),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
