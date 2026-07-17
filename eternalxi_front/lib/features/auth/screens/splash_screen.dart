import 'dart:math' as math;

import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_typography.dart';
import 'package:eternal_xi/shared/widgets/xi_brand_wordmark.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/auth/widgets/app_settings_sheet.dart';
import 'package:eternal_xi/features/clash/content/clash_content_download_service.dart';
import 'package:eternal_xi/features/clash/content/clash_content_manifest.dart';
import 'package:eternal_xi/features/clash/content/player_image_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const splashArtAsset = 'assets/app/splash_loading.png';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _dotsCtrl;
  late final AnimationController _pulseCtrl;

  bool _sessionReady = false;
  bool _hasSession = false;
  bool _contentReady = false;
  bool _contentFailed = false;
  bool _awaitingDownloadConsent = false;
  int _pendingContentBytes = 0;
  ClashContentDownloadProgress? _downloadProgress;

  final _contentDownload = ClashContentDownloadService();

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: XiColors.nightBlue,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthController>();
      final hasSession =
          auth.currentUser != null || await auth.restoreSession();
      if (!mounted) return;
      setState(() {
        _sessionReady = true;
        _hasSession = hasSession;
      });
      await _prepareClashContent();
      // Precalienta la ruta de caché de fotos por si Fantasy/Clash ya tienen pack.
      await PlayerImageCache.instance.playersDirectory();
    });
  }

  Future<void> _prepareClashContent() async {
    try {
      final needs = await _contentDownload.needsDownload();
      if (!mounted) return;
      if (!needs) {
        await _downloadClashContent();
        return;
      }
      final manifest = await _contentDownload.loadManifest();
      if (!mounted) return;
      setState(() {
        _awaitingDownloadConsent = true;
        _pendingContentBytes = manifest.cardsBytes;
        _contentReady = false;
        _contentFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _contentReady = false;
        _contentFailed = true;
      });
    }
  }

  Future<void> _downloadClashContent() async {
    setState(() {
      _awaitingDownloadConsent = false;
      _contentFailed = false;
      _downloadProgress = null;
    });
    try {
      final result = await _contentDownload.ensureContent(
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _downloadProgress = progress);
        },
      );
      if (!mounted) return;
      setState(() {
        _contentReady = result.success;
        _contentFailed = !result.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _contentReady = false;
        _contentFailed = true;
      });
    }
  }

  Future<void> _skipContentDownload() async {
    setState(() {
      _awaitingDownloadConsent = false;
      _downloadProgress = null;
    });
    final result = await _contentDownload.useBundledForNow(
      onProgress: (progress) {
        if (!mounted) return;
        setState(() => _downloadProgress = progress);
      },
    );
    if (!mounted) return;
    setState(() {
      _contentReady = result.success;
      _contentFailed = !result.success;
    });
  }

  @override
  void dispose() {
    _dotsCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _enter() {
    if (!_sessionReady || !_contentReady) return;
    context.go(_hasSession ? AppRoutes.mode : AppRoutes.login);
  }

  void _openSettings() => AppSettingsSheet.show(context);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final auth = context.watch<AuthController>();
    final nickname = auth.currentUser?.nickname.trim();
    final sessionName = (nickname != null && nickname.isNotEmpty)
        ? nickname
        : null;

    // Fondo opaco para tapar el estadio N global; solo se ve el arte de entrada.
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _sessionReady &&
                _contentReady &&
                !_awaitingDownloadConsent
            ? _enter
            : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF000000)),
            Image.asset(
              SplashScreen.splashArtAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.52, 0.72, 1.0],
                  colors: [
                    Color(0x1A000000),
                    Colors.transparent,
                    Color(0x99000000),
                    Color(0xE6000000),
                  ],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black38,
                  foregroundColor: XiColors.warmWhite,
                ),
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_rounded),
                tooltip: l10n.splashSettingsTitle,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 28 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    XiBrandWordmark(
                      uppercase: false,
                      fontSize: 34,
                      color: XiColors.warmWhite,
                      letterSpacing: 1.2,
                      textAlign: TextAlign.center,
                      shadows: const [
                        Shadow(
                          color: Color(0xCC101B35),
                          blurRadius: 16,
                          offset: Offset(0, 3),
                        ),
                        Shadow(
                          color: Color(0x66D9A441),
                          blurRadius: 20,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 72,
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            XiColors.classicGold,
                            XiColors.techCyan,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_awaitingDownloadConsent)
                      Column(
                        children: [
                          Text(
                            l10n.splashContentPromptTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 15,
                              color: XiColors.warmWhite.withValues(alpha: 0.95),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.splashContentPromptBody(
                              (_pendingContentBytes / (1024 * 1024))
                                  .toStringAsFixed(1),
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 13,
                              height: 1.4,
                              color: XiColors.warmWhite.withValues(alpha: 0.78),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _downloadClashContent,
                            style: FilledButton.styleFrom(
                              backgroundColor: XiColors.techCyan,
                              foregroundColor: XiColors.nightBlue,
                            ),
                            child: Text(l10n.contentDownloadAccept),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _skipContentDownload,
                            child: Text(
                              l10n.contentDownloadLater,
                              style: TextStyle(
                                color:
                                    XiColors.warmWhite.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (!_sessionReady || !_contentReady)
                      Column(
                        children: [
                          Text(
                            l10n.splashDownloadingContent,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 14,
                              color: XiColors.warmWhite.withValues(alpha: 0.92),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_downloadProgress != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _downloadProgress!.fraction > 0
                                    ? _downloadProgress!.fraction
                                    : null,
                                minHeight: 6,
                                backgroundColor:
                                    XiColors.royalBlue.withValues(alpha: 0.35),
                                color: XiColors.techCyan,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _downloadProgress!.mbLabel,
                              style: TextStyle(
                                fontFamily: 'Lumiare',
                                fontSize: 13,
                                color: XiColors.techCyan.withValues(alpha: 0.95),
                              ),
                            ),
                          ] else
                            AnimatedBuilder(
                              animation: _dotsCtrl,
                              builder: (_, _) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(3, (i) {
                                    final phase =
                                        (_dotsCtrl.value - i * 0.22) % 1.0;
                                    final v = math
                                        .sin(phase * math.pi)
                                        .clamp(0.0, 1.0);
                                    return Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color.lerp(
                                          XiColors.royalBlue
                                              .withValues(alpha: 0.35),
                                          XiColors.techCyan,
                                          v,
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          if (_contentFailed) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Error de descarga. Reintenta cerrando la app.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Lumiare',
                                fontSize: 12,
                                color: XiColors.classicGold.withValues(
                                  alpha: 0.95,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _downloadClashContent,
                              child: Text(l10n.clashMediaDownloadRetry),
                            ),
                          ],
                        ],
                      )
                    else ...[
                      if (_hasSession) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: XiColors.techCyan.withValues(alpha: 0.95),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.splashSessionActive,
                              style: TextStyle(
                                fontFamily: 'Lumiare',
                                fontSize: 13,
                                color: XiColors.techCyan.withValues(alpha: 0.95),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        if (sessionName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            sessionName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Lumiare',
                              fontSize: 17,
                              color: XiColors.classicGold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) {
                          final scale = 0.96 + (_pulseCtrl.value * 0.04);
                          return Transform.scale(
                            scale: scale,
                            child: Text(
                              l10n.splashTapToEnter,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Lumiare',
                                fontSize: 15,
                                color: XiColors.warmWhite,
                                letterSpacing: 1.2,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
