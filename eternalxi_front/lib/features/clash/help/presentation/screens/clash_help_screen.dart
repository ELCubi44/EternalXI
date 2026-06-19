import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_repository.dart';
import 'package:eternal_xi/features/clash/help/domain/clash_help_topic.dart';
import 'package:eternal_xi/features/clash/help/presentation/controllers/clash_help_controller.dart';
import 'package:eternal_xi/features/clash/help/presentation/widgets/clash_help_labels.dart';
import 'package:eternal_xi/features/clash/help/presentation/widgets/clash_help_quick_tip_card.dart';
import 'package:eternal_xi/features/clash/help/presentation/widgets/clash_help_topic_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashHelpScreen extends StatefulWidget {
  const ClashHelpScreen({super.key});

  @override
  State<ClashHelpScreen> createState() => _ClashHelpScreenState();
}

class _ClashHelpScreenState extends State<ClashHelpScreen> {
  late final ClashHelpController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ClashHelpController(
      repository: context.read<ClashHelpRepository>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isLoading =
            _controller.state == ClashHelpLoadState.loading &&
            _controller.topics.isEmpty;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.clashHelpTitle)),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    const ClashHelpQuickTipCard(),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.clashHelpSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: _controller.setQuery,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CategoryChip(
                          label: l10n.clashHelpCategoryAll,
                          selected: _controller.category == null,
                          onTap: () => _controller.setCategory(null),
                        ),
                        ...ClashHelpCategory.values.map(
                          (category) => _CategoryChip(
                            label: clashHelpCategoryLabel(category, l10n),
                            selected: _controller.category == category,
                            onTap: () => _controller.setCategory(category),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_controller.topics.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            l10n.clashHelpNoResults,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      )
                    else
                      ..._controller.topics.map(
                        (topic) => ClashHelpTopicCard(
                          topic: topic,
                          onRead: () =>
                              context.push(AppRoutes.clashHelpTopic(topic.id)),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
