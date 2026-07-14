import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Campana de notificaciones con badge de pendientes opcional.
class NotificationBellIcon extends StatelessWidget {
  const NotificationBellIcon({
    super.key,
    this.size = 28,
    this.unreadCount = 0,
  });

  static const asset = 'assets/app/notification_bell.png';

  final double size;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final hasBadge = unreadCount > 0;
    final label = unreadCount > 99 ? '99+' : '$unreadCount';
    final badgeMinWidth = label.length > 1 ? 18.0 : 16.0;

    return SizedBox(
      width: size + 6,
      height: size + 4,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          if (hasBadge)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: label.length > 1 ? 3 : 4,
                  vertical: 1,
                ),
                constraints: BoxConstraints(minWidth: badgeMinWidth, minHeight: 15),
                decoration: BoxDecoration(
                  color: XiColors.heroRed,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: XiColors.warmWhite, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Lumiare',
                    fontSize: 8.5,
                    color: XiColors.warmWhite,
                    height: 1.15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
