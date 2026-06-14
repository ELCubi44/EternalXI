import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:eternal_xi/features/clash/team/presentation/widgets/clash_lineup_card_picker_sheet.dart';
import 'package:eternal_xi/features/clash/team/presentation/widgets/clash_lineup_field_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashLineup7v7Screen extends StatefulWidget {
  const ClashLineup7v7Screen({super.key});

  @override
  State<ClashLineup7v7Screen> createState() => _ClashLineup7v7ScreenState();
}

class _ClashLineup7v7ScreenState extends State<ClashLineup7v7Screen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<ClashLineupsController>();
      if (controller.state == ClashLineupsLoadState.idle) {
        await controller.load();
      }
    });
  }

  Future<void> _renameLineup(ClashLineupsController controller) async {
    final lineup = controller.selectedLineup;
    if (lineup == null) {
      return;
    }

    final l10n = context.l10n;
    final nameController = TextEditingController(text: lineup.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.clashLineupRenameTitle),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.clashLineupRenameHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.clashBack),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, nameController.text.trim()),
              child: Text(l10n.clashLineupRenameSave),
            ),
          ],
        );
      },
    );
    nameController.dispose();

    if (newName != null && newName.isNotEmpty) {
      await controller.renameSelectedLineup(newName);
    }
  }

  Future<void> _openPicker(
    ClashLineupsController controller,
    ClashPosition slot,
  ) async {
    await showClashLineupCardPicker(
      context: context,
      controller: controller,
      slot: slot,
      onSelected: (cardId) => controller.assignCard(slot: slot, cardId: cardId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashLineupsController>();

    if (controller.state == ClashLineupsLoadState.loading ||
        controller.state == ClashLineupsLoadState.idle) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.state == ClashLineupsLoadState.error) {
      return Center(
        child: Text(controller.errorMessage ?? l10n.clashLineupLoadError),
      );
    }

    final lineup = controller.selectedLineup;
    if (lineup == null) {
      return Center(child: Text(l10n.clashLineupLoadError));
    }

    final totalPower = controller.totalPower(lineup);
    final missing = lineup.missingPositions;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.go(AppRoutes.clash),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                l10n.clashTeamLineup7,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.xiTextPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _renameLineup(controller),
              icon: const Icon(Icons.edit_rounded),
              tooltip: l10n.clashLineupRenameTitle,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: List.generate(controller.lineups.length, (index) {
            final item = controller.lineups[index];
            final label = item.isActive ? '${item.name} ★' : item.name;
            return ButtonSegment<int>(value: index, label: Text(label));
          }),
          selected: {controller.selectedIndex},
          onSelectionChanged: (selection) {
            controller.selectLineupIndex(selection.first);
          },
        ),
        const SizedBox(height: 16),
        ClashLineupFieldView(
          lineup: lineup,
          controller: controller,
          onSlotTap: (slot) => _openPicker(controller, slot),
        ),
        const SizedBox(height: 16),
        _StatusCard(
          isComplete: lineup.isComplete,
          totalPower: totalPower,
          missing: missing,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: lineup.isActive ? null : controller.setSelectedAsActive,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: Text(l10n.clashLineupSetActive),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.isComplete,
    required this.totalPower,
    required this.missing,
  });

  final bool isComplete;
  final int totalPower;
  final List<ClashPosition> missing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.clashLineupTotalPower}: $totalPower',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isComplete ? l10n.clashLineupComplete : l10n.clashLineupIncomplete,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isComplete ? Colors.green : theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!isComplete) ...[
            const SizedBox(height: 8),
            Text(l10n.clashLineupMissingTitle),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: missing
                  .map(
                    (position) => Chip(
                      label: Text(position.displayNameEs),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
