import 'dart:io';

import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/features/clash/content/player_image_cache.dart';
import 'package:flutter/material.dart';

/// Foto de jugador: disco local (pack Clash) si existe; si no, red.
class XiPlayerPhotoImage extends StatelessWidget {
  const XiPlayerPhotoImage({
    super.key,
    required this.playerId,
    this.networkUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final int playerId;
  final String? networkUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    final local = PlayerImageCache.instance.localFileIfReady(playerId);
    if (local != null) {
      return Image.file(
        local,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: errorBuilder,
      );
    }

    return FutureBuilder<File?>(
      future: PlayerImageCache.instance.localFile(playerId),
      builder: (context, snap) {
        final file = snap.data;
        if (file != null) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            errorBuilder: errorBuilder,
          );
        }

        final url = networkUrl ??
            (playerId > 0
                ? LeagueAssetUrls.resolvePlayerPhotoUrl(idJugador: playerId)
                : null);
        if (url == null || url.isEmpty) {
          return errorBuilder?.call(
                context,
                Exception('no photo'),
                StackTrace.current,
              ) ??
              SizedBox(width: width, height: height);
        }

        return Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          errorBuilder: errorBuilder,
          loadingBuilder: loadingBuilder,
        );
      },
    );
  }
}
