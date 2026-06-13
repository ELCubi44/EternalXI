import 'dart:math' as math;

import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const splashArtAsset = 'assets/app/splash_loading.png';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotsCtrl;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthController>();
      final hasSession = await auth.restoreSession();
      if (!mounted) return;
      context.go(hasSession ? AppRoutes.mode : AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: XiColors.nightBlue,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                  Color(0x1A101B35),
                  Colors.transparent,
                  Color(0x99101B35),
                  Color(0xE6101B35),
                ],
              ),
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
                  const Text(
                    'Eternal XI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lumiare',
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: XiColors.warmWhite,
                      letterSpacing: 2.5,
                      height: 1.1,
                      shadows: [
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
                  AnimatedBuilder(
                    animation: _dotsCtrl,
                    builder: (_, __) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final phase = (_dotsCtrl.value - i * 0.22) % 1.0;
                          final v = math.sin(phase * math.pi).clamp(0.0, 1.0);
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.lerp(
                                XiColors.royalBlue.withValues(alpha: 0.35),
                                XiColors.techCyan,
                                v,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: XiColors.techCyan.withValues(
                                    alpha: 0.45 * v,
                                  ),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
