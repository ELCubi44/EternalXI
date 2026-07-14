import 'package:flutter/material.dart';

class LeagueStatsListItem {
  const LeagueStatsListItem({
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
}

class LeagueStatsListScreen extends StatelessWidget {
  const LeagueStatsListScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    this.emptyText = 'Aún no hay estadísticas',
  });

  final String title;
  final String? subtitle;
  final List<LeagueStatsListItem> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: CustomScrollView(
        slivers: [
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  emptyText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minLeadingWidth: 30,
                      leading: item.leading,
                      onTap: item.onTap,
                      title: Text(
                        item.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          ),
                      ),
                      subtitle:
                          item.subtitle == null || item.subtitle!.trim().isEmpty
                          ? null
                          : Text(
                              item.subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                      trailing:
                          item.trailing == null || item.trailing!.trim().isEmpty
                          ? null
                          : Text(
                              item.trailing!,
                              style: theme.textTheme.titleSmall?.copyWith(
                                ),
                            ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
