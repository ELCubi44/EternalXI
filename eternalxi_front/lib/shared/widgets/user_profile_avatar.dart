import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:flutter/material.dart';

/// Avatar de usuario con resolucion fiable de foto de perfil.
class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({
    required this.userId,
    this.photoPath,
    this.nickname,
    this.size = 40,
    this.ringColor,
    this.onTap,
    super.key,
  });

  final int userId;
  final String? photoPath;
  final String? nickname;
  final double size;
  final Color? ringColor;
  final VoidCallback? onTap;

  String? get _photoUrl {
    final fromApi = LeagueAssetUrls.buildBackendImageUrl(photoPath);
    if (fromApi != null) return fromApi;
    if (userId > 0) {
      return ApiConstants.userProfilePhotoUrl(userId, cacheBuster: userId);
    }
    return null;
  }

  String get _initial {
    final nick = nickname?.trim() ?? '';
    if (nick.isEmpty) return '?';
    return nick.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ring = ringColor ?? XiColors.classicGold;
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring.withValues(alpha: 0.55), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: _photoUrl != null
          ? Image.network(
              _photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(ring),
            )
          : _fallback(ring),
    );

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }

  Widget _fallback(Color ring) {
    return ColoredBox(
      color: ring.withValues(alpha: 0.14),
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
            fontFamily: 'Lumiare',
            fontSize: size * 0.38,
            color: ring,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
