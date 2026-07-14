import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback_message.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_list.dart';
import 'package:flutter/material.dart';

/// Cuerpo compartido de feedback de recompensas (Fase 59).
class ClashRewardFeedbackBody extends StatelessWidget {
  const ClashRewardFeedbackBody({required this.message, super.key});

  final ClashRewardFeedbackMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warningColor = message.kind == ClashRewardFeedbackKind.partial
        ? Colors.orange.shade800
        : theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.title,
          style: theme.textTheme.titleLarge?.copyWith(
            ),
        ),
        if (message.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            message.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: message.kind == ClashRewardFeedbackKind.success
                  ? context.xiTextSecondary
                  : warningColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        if (message.hasItems) ...[
          const SizedBox(height: 16),
          ClashRewardList(
            items: message.items,
            layout: ClashRewardListLayout.column,
          ),
        ],
      ],
    );
  }
}

Future<void> showClashRewardFeedbackSheet(
  BuildContext context,
  ClashRewardFeedbackMessage message,
) async {
  final l10n = context.l10n;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClashRewardFeedbackBody(message: message),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(l10n.clashRewardFeedbackAccept),
              ),
            ],
          ),
        ),
      );
    },
  );
}
