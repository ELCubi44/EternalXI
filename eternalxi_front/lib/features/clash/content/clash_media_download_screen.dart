import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_typography.dart';
import 'package:eternal_xi/features/clash/content/clash_content_manifest.dart';
import 'package:eternal_xi/features/clash/content/clash_media_pack_service.dart';
import 'package:eternal_xi/features/clash/content/player_image_cache.dart';
import 'package:eternal_xi/shared/widgets/xi_brand_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Solo se muestra si falta descargar fotos Clash; si ya estù listo, redirige sin UI.
class ClashMediaDownloadScreen extends StatefulWidget {
  const ClashMediaDownloadScreen({super.key});

  @override
  State<ClashMediaDownloadScreen> createState() =>
      _ClashMediaDownloadScreenState();
}

enum _Phase { redirecting, prompt, downloading, error }

class _ClashMediaDownloadScreenState extends State<ClashMediaDownloadScreen> {
  final _service = ClashMediaPackService();
  ClashContentDownloadProgress? _progress;
  String? _error;
  _Phase _phase = _Phase.redirecting;
  int _pendingBytes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    await PlayerImageCache.instance.playersDirectory();
    final info = await _service.pendingDownloadInfo();
    if (!mounted) return;

    if (!info.needsDownload) {
      context.go(AppRoutes.clash);
      return;
    }

    setState(() {
      _phase = _Phase.prompt;
      _pendingBytes = info.pendingBytes;
    });
  }

  Future<void> _download() async {
    setState(() {
      _phase = _Phase.downloading;
      _error = null;
    });

    final result = await _service.ensureMediaPack(
      onProgress: (p) {
        if (!mounted) return;
        setState(() => _progress = p);
      },
    );
    if (!mounted) return;
    if (result.success) {
      context.go(AppRoutes.clash);
      return;
    }
    setState(() {
      _phase = _Phase.error;
      _error = result.errorMessage ?? 'Error de descarga';
    });
  }

  String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Sin flash de "Preparando Clash" si ya estù todo descargado.
    if (_phase == _Phase.redirecting) {
      return const Scaffold(
        backgroundColor: XiColors.nightBlue,
        body: SizedBox.expand(),
      );
    }

    final progress = _progress;
    final fraction = progress?.fraction ?? 0.0;
    final mb = progress?.mbLabel ?? '0.0 / 0.0 MB';

    return Scaffold(
      backgroundColor: XiColors.nightBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 28),
              const XiBrandWordmark(fontSize: 34),
              const Spacer(),
              Text(
                _phase == _Phase.prompt
                    ? l10n.clashMediaPromptTitle
                    : l10n.clashMediaDownloadTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 22,
                  color: Colors.white,
                  height: 1.25,
                ).lumiareNative,
              ),
              const SizedBox(height: 12),
              Text(
                _phase == _Phase.prompt
                    ? l10n.clashMediaPromptBody(_mb(_pendingBytes))
                    : l10n.clashMediaDownloadSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 28),
              if (_phase == _Phase.prompt) ...[
                FilledButton(
                  onPressed: _download,
                  style: FilledButton.styleFrom(
                    backgroundColor: XiColors.techCyan,
                    foregroundColor: XiColors.nightBlue,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(l10n.contentDownloadAccept),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.go(AppRoutes.splash),
                  child: Text(
                    l10n.contentDownloadLater,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _phase == _Phase.error
                        ? 0
                        : fraction.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    color: XiColors.techCyan,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  mb,
                  style: TextStyle(
                    fontFamily: 'Lumiare',
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (_phase == _Phase.error) ...[
                  const SizedBox(height: 18),
                  Text(
                    _error ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 13,
                      color: Colors.orangeAccent.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _download,
                    child: Text(l10n.clashMediaDownloadRetry),
                  ),
                ],
              ],
              const Spacer(flex: 2),
              if (_phase != _Phase.prompt)
                TextButton(
                  onPressed: () => context.go(AppRoutes.splash),
                  child: Text(
                    l10n.profileBackToTitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
