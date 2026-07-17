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

/// Primera entrada a Clash: descarga fotos de jugadores con progreso en MB.
class ClashMediaDownloadScreen extends StatefulWidget {
  const ClashMediaDownloadScreen({super.key});

  @override
  State<ClashMediaDownloadScreen> createState() =>
      _ClashMediaDownloadScreenState();
}

class _ClashMediaDownloadScreenState extends State<ClashMediaDownloadScreen> {
  final _service = ClashMediaPackService();
  ClashContentDownloadProgress? _progress;
  String? _error;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_running) return;
    setState(() {
      _running = true;
      _error = null;
    });

    // Prefetch dir so localFileIfReady works in Clash/Fantasy UI.
    await PlayerImageCache.instance.playersDirectory();

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
      _running = false;
      _error = result.errorMessage ?? 'Error de descarga';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                l10n.clashMediaDownloadTitle,
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
                l10n.clashMediaDownloadSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lumiare',
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 36),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _error != null ? 0 : fraction.clamp(0.0, 1.0),
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
              if (_error != null) ...[
                const SizedBox(height: 18),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lumiare',
                    fontSize: 13,
                    color: Colors.orangeAccent.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _start,
                  child: Text(l10n.clashMediaDownloadRetry),
                ),
              ],
              const Spacer(flex: 2),
              TextButton(
                onPressed: () => context.go(AppRoutes.mode),
                child: Text(
                  l10n.backToModeSelection,
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
