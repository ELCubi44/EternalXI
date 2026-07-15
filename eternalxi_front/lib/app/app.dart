import 'package:eternal_xi/app/router.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_typography.dart';
import 'package:eternal_xi/core/notifications/push_notification_handler.dart';
import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/profile/controller/user_preferences_controller.dart';
import 'package:eternal_xi/shared/widgets/fantasy_atmosphere_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EternalXiApp extends StatefulWidget {
  const EternalXiApp({super.key});

  @override
  State<EternalXiApp> createState() => _EternalXiAppState();
}

class _EternalXiAppState extends State<EternalXiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockPortraitOrientation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationHandler.instance.initialize(appRouter);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lockPortraitOrientation();
    }
  }

  Future<void> _lockPortraitOrientation() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  static ThemeData get _lightTheme {
    const bg = XiColors.ivoryUniform;
    const surface = XiColors.warmWhite;
    const text = XiColors.nightBlue;
    final scheme = ColorScheme.fromSeed(
      seedColor: XiColors.royalBlue,
      brightness: Brightness.light,
    ).copyWith(
      surface: surface,
      onSurface: text,
      primary: XiColors.royalBlue,
      onPrimary: XiColors.warmWhite,
      secondary: XiColors.royalBlue,
      onSecondary: XiColors.nightBlue,
      error: XiColors.heroRed,
    );
    return XiTypography.sanitizeTheme(ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: XiTypography.family,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      dividerColor: const Color(0xFFD8CEBC),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: XiTypography.family,
          color: text,
          fontSize: 20,
          fontWeight: XiTypography.weight,
          letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD8CEBC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: XiColors.royalBlue, width: 2),
        ),
        hintStyle: const TextStyle(fontFamily: XiTypography.family, color: text, fontSize: 14),
        labelStyle: const TextStyle(fontFamily: XiTypography.family, color: text, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: XiColors.royalBlue,
          foregroundColor: XiColors.warmWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: XiTypography.family, fontSize: 15, fontWeight: XiTypography.weight, letterSpacing: 0.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: XiColors.nightBlue,
        contentTextStyle: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(fontFamily: XiTypography.family, color: text, fontSize: 18, fontWeight: XiTypography.weight),
        contentTextStyle: const TextStyle(fontFamily: XiTypography.family, color: text, fontSize: 14, height: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return XiColors.royalBlue;
          return XiColors.steelGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return XiColors.royalBlue.withValues(alpha: 0.3);
          return const Color(0xFFD8CEBC);
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: XiColors.royalBlue),
      dividerTheme: const DividerThemeData(color: Color(0xFFD8CEBC), thickness: 1),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: XiTypography.family, color: text, fontWeight: XiTypography.weight),
        displayMedium: TextStyle(fontFamily: XiTypography.family, color: text, fontWeight: XiTypography.weight),
        displaySmall: TextStyle(fontFamily: XiTypography.family, color: text, fontWeight: XiTypography.weight),
        headlineLarge: TextStyle(fontFamily: XiTypography.family, color: text, fontWeight: XiTypography.weight),
        headlineMedium: TextStyle(fontFamily: XiTypography.family, color: text, fontWeight: XiTypography.weight),
        headlineSmall: TextStyle(fontFamily: XiTypography.family, color: text, fontWeight: XiTypography.weight),
        titleLarge: TextStyle(fontFamily: XiTypography.family, color: text, fontWeight: XiTypography.weight, fontSize: 20),
        titleMedium: TextStyle(fontFamily: XiTypography.family, color: text, fontWeight: XiTypography.weight, fontSize: 16),
        titleSmall: TextStyle(fontFamily: XiTypography.family, color: text, fontWeight: XiTypography.weight, fontSize: 14),
        bodyLarge: TextStyle(fontFamily: XiTypography.family, color: text, fontSize: 16),
        bodyMedium: TextStyle(fontFamily: XiTypography.family, color: text, fontSize: 14),
        bodySmall: TextStyle(fontFamily: XiTypography.family, color: text, fontSize: 12),
        labelLarge: TextStyle(fontFamily: XiTypography.family, color: text, fontWeight: XiTypography.weight, fontSize: 14),
        labelMedium: TextStyle(fontFamily: XiTypography.family, color: text, fontWeight: XiTypography.weight, fontSize: 12),
        labelSmall: TextStyle(fontFamily: XiTypography.family, color: text, fontWeight: XiTypography.weight, fontSize: 11),
      ),
      iconTheme: const IconThemeData(color: text, size: 22),
    ));
  }

  static ThemeData get _theme {
    const scheme = XiColors.colorScheme;
    return XiTypography.sanitizeTheme(ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: XiTypography.family,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: scheme.surfaceContainer,
      dividerColor: XiColors.divider,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          fontFamily: XiTypography.family,
          color: XiColors.warmWhite,
          fontSize: 20,
          fontWeight: XiTypography.weight,
          letterSpacing: 0.5,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: XiColors.surfaceContainer,
        indicatorColor: XiColors.royalBlue.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: XiTypography.family,
              fontSize: 11,
              fontWeight: XiTypography.weight,
              color: XiColors.royalBlue,
              letterSpacing: 0.3,
            );
          }
          return const TextStyle(
            fontFamily: XiTypography.family,
            fontSize: 11,
            fontWeight: XiTypography.weight,
            color: XiColors.warmWhite,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: XiColors.royalBlue, size: 24);
          }
          return const IconThemeData(color: XiColors.warmWhite, size: 22);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: XiColors.surfaceElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: XiColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: XiColors.royalBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: XiColors.heroRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: XiColors.heroRed, width: 2),
        ),
        hintStyle: const TextStyle(
          fontFamily: XiTypography.family,
          color: XiColors.warmWhite,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: XiTypography.family,
          color: XiColors.warmWhite,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: XiColors.royalBlue,
          foregroundColor: XiColors.warmWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: XiTypography.family,
            fontSize: 15,
            fontWeight: XiTypography.weight,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: XiColors.royalBlue,
          side: const BorderSide(color: XiColors.royalBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: XiTypography.family,
            fontSize: 15,
            fontWeight: XiTypography.weight,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: XiColors.royalBlue,
          textStyle: const TextStyle(
            fontFamily: XiTypography.family,
            fontWeight: XiTypography.weight,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: XiColors.surfaceElevated,
        contentTextStyle: TextStyle(
          fontFamily: XiTypography.family,
          color: XiColors.warmWhite,
          fontSize: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: XiColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontFamily: XiTypography.family,
          color: XiColors.warmWhite,
          fontSize: 18,
          fontWeight: XiTypography.weight,
          letterSpacing: 0.3,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: XiTypography.family,
          color: XiColors.warmWhite,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: XiColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: XiColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: XiColors.royalBlue,
        unselectedLabelColor: XiColors.warmWhite,
        indicatorColor: XiColors.royalBlue,
        labelStyle: TextStyle(
          fontFamily: XiTypography.family,
          fontSize: 13,
          fontWeight: XiTypography.weight,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: XiTypography.family,
          fontSize: 13,
          fontWeight: XiTypography.weight,
        ),
        dividerColor: XiColors.divider,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: XiColors.warmWhite,
        textColor: XiColors.warmWhite,
        tileColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: XiColors.surfaceElevated,
        selectedColor: XiColors.royalBlue.withValues(alpha: 0.35),
        checkmarkColor: XiColors.royalBlue,
        labelStyle: const TextStyle(
          fontFamily: XiTypography.family,
          color: XiColors.warmWhite,
          fontSize: 12,
          fontWeight: XiTypography.weight,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: XiTypography.family,
          color: XiColors.royalBlue,
          fontSize: 12,
          fontWeight: XiTypography.weight,
        ),
        side: const BorderSide(color: XiColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: XiColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: XiColors.divider, width: 0.5),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return XiColors.royalBlue;
            }
            return XiColors.surfaceElevated;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return XiColors.warmWhite;
            }
            return XiColors.warmWhite;
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontFamily: XiTypography.family, fontSize: 12, fontWeight: XiTypography.weight),
          ),
          side: WidgetStateProperty.all(const BorderSide(color: XiColors.divider)),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontWeight: XiTypography.weight),
        displayMedium: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontWeight: XiTypography.weight),
        displaySmall: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontWeight: XiTypography.weight),
        headlineLarge: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontWeight: XiTypography.weight),
        headlineMedium: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontWeight: XiTypography.weight),
        headlineSmall: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontWeight: XiTypography.weight),
        titleLarge: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontWeight: XiTypography.weight, fontSize: 20),
        titleMedium: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontWeight: XiTypography.weight, fontSize: 16),
        titleSmall: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontWeight: XiTypography.weight, fontSize: 14),
        bodyLarge: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontSize: 16),
        bodyMedium: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontSize: 14),
        bodySmall: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontSize: 12),
        labelLarge: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontWeight: XiTypography.weight, fontSize: 14),
        labelMedium: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontWeight: XiTypography.weight, fontSize: 12),
        labelSmall: TextStyle(fontFamily: XiTypography.family, color: XiColors.warmWhite, fontWeight: XiTypography.weight, fontSize: 11),
      ),
      iconTheme: const IconThemeData(color: XiColors.warmWhite, size: 22),
      primaryIconTheme: const IconThemeData(color: XiColors.warmWhite, size: 22),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: XiColors.royalBlue,
        foregroundColor: XiColors.warmWhite,
        elevation: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return XiColors.royalBlue;
          return XiColors.steelGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return XiColors.royalBlue.withValues(alpha: 0.3);
          }
          return XiColors.divider;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: XiColors.royalBlue,
        circularTrackColor: XiColors.divider,
        linearTrackColor: XiColors.divider,
      ),
      dividerTheme: const DividerThemeData(
        color: XiColors.divider,
        thickness: 1,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<UserPreferencesController>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Eternal XI',
      locale: preferences.appLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: AppLocalizations.localeResolutionCallback,
      // Trial: look oscuro negro + fondo atmosferico en toda la app.
      themeMode: ThemeMode.dark,
      theme: _lightTheme,
      darkTheme: _theme,
      routerConfig: appRouter,
      builder: (context, child) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          final router = GoRouter.of(context);
          if (router.canPop()) {
            router.pop();
            return;
          }
          final navigator = Navigator.maybeOf(context);
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
          }
        },
        // Rebuild al navegar: el splash de entrada (dos chicos) no usa el fondo N.
        child: ListenableBuilder(
          listenable: appRouter.routerDelegate,
          builder: (context, _) {
            final matches = appRouter.routerDelegate.currentConfiguration;
            final location =
                matches.isEmpty ? AppRoutes.splash : matches.uri.path;
            final showAtmosphere = location != AppRoutes.splash;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (showAtmosphere) const FantasyAtmosphereBackground(),
                XiTypographyScope(
                  child: child ?? const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
