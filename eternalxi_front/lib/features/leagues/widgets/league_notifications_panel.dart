import 'package:eternal_xi/app/localization/league_l10n.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:eternal_xi/data/models/user_notification_item.dart';
import 'package:eternal_xi/features/leagues/controller/league_notifications_controller.dart';
import 'package:eternal_xi/features/leagues/utils/league_notification_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeagueNotificationsPanel extends StatelessWidget {
  const LeagueNotificationsPanel({
    super.key,
    required this.leagueId,
    required this.idUsuario,
  });

  final int leagueId;
  final int idUsuario;

  static Future<void> show(
    BuildContext context, {
    required int leagueId,
    required int idUsuario,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => ChangeNotifierProvider(
        create: (_) => LeagueNotificationsController(
          userApiService: context.read(),
          idUsuario: idUsuario,
          idLiga: leagueId,
        )..load(),
        child: LeagueNotificationsPanel(
          leagueId: leagueId,
          idUsuario: idUsuario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final theme = Theme.of(context);
    final controller = context.watch<LeagueNotificationsController>();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ll.notificationsTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.xiTextPrimary,
                      ),
                    ),
                  ),
                  if (controller.unreadCount > 0)
                    TextButton(
                      onPressed: controller.markAllRead,
                      child: Text(ll.markAllNotificationsRead),
                    ),
                ],
              ),
            ),
            Expanded(
              child: controller.loading && controller.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : controller.error != null && controller.items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: context.xiTextPrimary),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonalIcon(
                              onPressed: controller.loading
                                  ? null
                                  : controller.load,
                              icon: const Icon(Icons.refresh),
                              label: Text(context.l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    )
                  : controller.items.isEmpty
                  ? Center(
                      child: Text(
                        ll.notificationsEmpty,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: context.xiTextPrimary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: controller.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = controller.items[index];
                        return _NotificationTile(
                          item: item,
                          leagueId: leagueId,
                          idUsuario: idUsuario,
                          onOpen: () async {
                            await controller.markRead(item);
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop();
                            await handleLeagueNotificationTap(
                              context: context,
                              notification: item,
                              leagueId: leagueId,
                              idUsuario: idUsuario,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.leagueId,
    required this.idUsuario,
    required this.onOpen,
  });

  final UserNotificationItem item;
  final int leagueId;
  final int idUsuario;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ll = context.leagueL10n;
    final theme = Theme.of(context);
    final showAction = notificationHasAction(item);
    final playerUrl = resolveNotificationPlayerImageUrl(item);
    final actorUrl = resolveNotificationActorImageUrl(item);

    return Material(
      color: item.leida
          ? context.xiCardSurface
          : context.xiCardSurface.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: showAction ? onOpen : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarStack(playerUrl: playerUrl, actorUrl: actorUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.titulo,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.xiTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.mensaje,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.xiTextPrimary,
                      ),
                    ),
                    if (item.precio != null &&
                        item.precio! > 0 &&
                        !notificationMessageAlreadyShowsPrice(item.mensaje)) ...[
                      const SizedBox(height: 4),
                      Text(
                        LeagueMoneyFormat.money(item.precio!.toDouble()),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.xiTextPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (showAction)
                FilledButton.tonal(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(ll.notificationViewAction),
                )
              else if (!item.leida)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({this.playerUrl, this.actorUrl});

  final String? playerUrl;
  final String? actorUrl;

  @override
  Widget build(BuildContext context) {
    if (actorUrl == null) {
      return _RoundAvatar(url: playerUrl, fallback: Icons.person);
    }
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 4,
            child: _RoundAvatar(
              url: playerUrl,
              fallback: Icons.sports_soccer,
              size: 36,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.xiBackground, width: 2),
              ),
              child: _RoundAvatar(
                url: actorUrl,
                fallback: Icons.person,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAvatar extends StatelessWidget {
  const _RoundAvatar({
    required this.url,
    required this.fallback,
    this.size = 44,
  });

  final String? url;
  final IconData fallback;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: context.xiChipBackground,
        child: Icon(
          fallback,
          size: size * 0.45,
          color: context.xiTextPrimary,
        ),
      );
    }
    return ClipOval(
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: size / 2,
          backgroundColor: context.xiChipBackground,
          child: Icon(
            fallback,
            size: size * 0.45,
            color: context.xiTextPrimary,
          ),
        ),
      ),
    );
  }
}
