import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:flutter/material.dart';

/// Escudo de equipo circular: URL del API si se informa; si no, asset por id.
class LeagueTeamLogo extends StatelessWidget {
  const LeagueTeamLogo({
    super.key,
    required this.idEquipo,
    this.size = 22,
    this.networkImageUrl,
  });

  final int idEquipo;
  final double size;

  /// `fotoEquipo` u otra URL absoluta del backend (opcional).
  final String? networkImageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final net = LeagueAssetUrls.resolveTeamBadgeUrl(
      idEquipo: idEquipo,
      rawFoto: networkImageUrl,
    );
    if (net != null && net.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            net,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, _, _) => _assetOrFallback(colorScheme),
            loadingBuilder: (context, child, progress) {
              if (progress == null) {
                return child;
              }
              return ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child: SizedBox(
                    width: size * 0.45,
                    height: size * 0.45,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    return _assetOrFallback(colorScheme);
  }

  Widget _assetOrFallback(ColorScheme colorScheme) {
    if (idEquipo <= 0) {
      return _fallback(colorScheme);
    }
    final uri = LeagueAssetUrls.teamBadge(idEquipo).toString();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          uri,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, _, _) => _fallback(colorScheme),
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: SizedBox(
                  width: size * 0.45,
                  height: size * 0.45,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _fallback(ColorScheme colorScheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.shield_outlined,
        size: size * 0.55,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
      ),
    );
  }
}
