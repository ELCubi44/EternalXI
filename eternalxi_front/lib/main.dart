import 'package:eternal_xi/core/localization/app_locale_resolver.dart';
import 'package:eternal_xi/app/app.dart';
import 'package:eternal_xi/core/network/api_client.dart';
import 'package:eternal_xi/core/storage/secure_storage_service.dart';
import 'package:eternal_xi/data/services/auth_api_service.dart';
import 'package:eternal_xi/data/services/leagues_api_service.dart';
import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/data/services/user_progress_api_service.dart';
import 'package:eternal_xi/features/rewards/data/services/rewards_api_service.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/leagues/controller/leagues_controller.dart';
import 'package:eternal_xi/features/profile/controller/account_progress_controller.dart';
import 'package:eternal_xi/features/profile/controller/profile_controller.dart';
import 'package:eternal_xi/features/profile/controller/user_preferences_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  tzdata.initializeTimeZones();

  final apiClient = ApiClient(
    acceptLanguage: AppLocaleResolver.apiLanguageTag(),
  );
  final secureStorageService = SecureStorageService();
  final savedThemeRaw = await secureStorageService.getThemeMode();
  final savedLanguageRaw = await secureStorageService.getLanguageCode();
  final initialThemePreference = UserPreferencesController.themeFromStorage(
    savedThemeRaw,
  );
  final initialLanguagePreference =
      UserPreferencesController.languageFromStorage(savedLanguageRaw);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<SecureStorageService>.value(value: secureStorageService),
        Provider<AuthApiService>(
          create: (context) => AuthApiService(context.read<ApiClient>()),
        ),
        Provider<UserApiService>(
          create: (context) => UserApiService(context.read<ApiClient>()),
        ),
        Provider<UserProgressApiService>(
          create: (context) => UserProgressApiService(context.read<ApiClient>()),
        ),
        Provider<LeaguesApiService>(
          create: (context) => LeaguesApiService(context.read<ApiClient>()),
        ),
        Provider<RewardsApiService>(
          create: (context) => RewardsApiService(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(
            authApiService: context.read<AuthApiService>(),
            secureStorageService: context.read<SecureStorageService>(),
            userApiService: context.read<UserApiService>(),
          ),
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (context) => ProfileController(
            userApiService: context.read<UserApiService>(),
            secureStorageService: context.read<SecureStorageService>(),
          ),
        ),
        ChangeNotifierProvider<AccountProgressController>(
          create: (context) => AccountProgressController(
            progressApiService: context.read<UserProgressApiService>(),
            secureStorageService: context.read<SecureStorageService>(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthController, UserPreferencesController>(
          create: (context) => UserPreferencesController(
            userApiService: context.read<UserApiService>(),
            secureStorageService: context.read<SecureStorageService>(),
            apiClient: context.read<ApiClient>(),
            initialThemeMode: initialThemePreference,
            initialLanguageCode: initialLanguagePreference,
          ),
          update: (context, auth, preferences) {
            final controller =
                preferences ??
                UserPreferencesController(
                  userApiService: context.read<UserApiService>(),
                  secureStorageService: context.read<SecureStorageService>(),
                  apiClient: context.read<ApiClient>(),
                  initialThemeMode: initialThemePreference,
                  initialLanguageCode: initialLanguagePreference,
                );
            controller.syncWithUser(auth.currentUser?.id);
            return controller;
          },
        ),
        ChangeNotifierProvider<LeaguesController>(
          create: (context) => LeaguesController(
            leaguesApiService: context.read<LeaguesApiService>(),
          ),
        ),
      ],
      child: const EternalXiApp(),
    ),
  );
}