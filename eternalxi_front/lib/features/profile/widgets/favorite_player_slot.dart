import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/data/models/user_public_profile.dart';
import 'package:flutter/material.dart';

/// Silueta o foto del jugador favorito (p. ej. a la derecha del avatar de perfil).
class FavoritePlayerSlot extends StatelessWidget {
  const FavoritePlayerSlot({
    super.key,
    required this.loading,
    required this.favorite,
    this.onTap,
    this.showAddPlaceholder = true,
  });

  final bool loading;
  final UserPublicFavoritePlayer? favorite;
  final VoidCallback? onTap;
  final bool showAddPlaceholder;

  static const double size = 80;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = favorite?.photoUrl?.isNotEmpty == true;

    if (!loading && !hasPhoto && !showAddPlaceholder) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: size,
        child: Center(
          child: loading
              ? const SizedBox(
                  width: size,
                  height: size,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : hasPhoto
              ? Image.network(
                  favorite!.photoUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _emptySlot(context),
                )
              : _emptySlot(context),
        ),
      ),
    );
  }

  Widget _emptySlot(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.xiTextSecondary.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.person_rounded,
            size: 34,
            color: context.xiTextSecondary.withValues(alpha: 0.55),
          ),
          if (showAddPlaceholder)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: context.xiCardSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.xiTextSecondary.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 16,
                color: context.xiTextSecondary.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }
}
