import 'package:eternal_xi/app/router_auth.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/auth/screens/confirm_email_verification_screen.dart';
import 'package:eternal_xi/features/auth/screens/confirm_password_reset_screen.dart';
import 'package:eternal_xi/features/auth/screens/login_screen.dart';
import 'package:eternal_xi/features/auth/screens/register_screen.dart';
import 'package:eternal_xi/features/auth/screens/request_email_verification_screen.dart';
import 'package:eternal_xi/features/auth/screens/request_password_reset_screen.dart';
import 'package:eternal_xi/features/auth/controller/auth_controller.dart';
import 'package:eternal_xi/features/auth/screens/splash_screen.dart';
import 'package:eternal_xi/features/clash/cards/presentation/screens/clash_card_collection_screen.dart';
import 'package:eternal_xi/features/clash/cards/presentation/screens/clash_card_detail_screen.dart';
import 'package:eternal_xi/features/clash/presentation/clash_navigation_controller.dart';
import 'package:eternal_xi/features/clash/presentation/clash_shell_screen.dart';
import 'package:eternal_xi/features/clash/presentation/clash_tab_host.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/screens/clash_gacha_history_screen.dart';
import 'package:eternal_xi/features/clash/inventory/presentation/screens/clash_inventory_screen.dart';
import 'package:eternal_xi/features/clash/achievements/presentation/screens/clash_achievements_screen.dart';
import 'package:eternal_xi/features/clash/missions/presentation/screens/clash_daily_missions_screen.dart';
import 'package:eternal_xi/features/clash/match/presentation/screens/clash_match_prepare_screen.dart';
import 'package:eternal_xi/features/clash/match/presentation/screens/clash_match_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_level_reader_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_map_screen.dart';
import 'package:eternal_xi/features/clash/team/presentation/screens/clash_lineup_7v7_screen.dart';
import 'package:eternal_xi/features/leagues/screens/create_league_screen.dart';
import 'package:eternal_xi/features/leagues/screens/join_league_screen.dart';
import 'package:eternal_xi/features/leagues/shell/league_shell_screen.dart';
import 'package:eternal_xi/features/leagues/screens/my_leagues_screen.dart';
import 'package:eternal_xi/features/mode/screens/mode_selection_screen.dart';
import 'package:eternal_xi/features/profile/screens/confirm_change_email_screen.dart';
import 'package:eternal_xi/features/profile/screens/confirm_account_deletion_screen.dart';
import 'package:eternal_xi/features/profile/screens/confirm_change_nickname_screen.dart';
import 'package:eternal_xi/features/profile/screens/edit_profile_screen.dart';
import 'package:eternal_xi/features/profile/screens/request_change_email_screen.dart';
import 'package:eternal_xi/features/profile/screens/request_change_nickname_screen.dart';
import 'package:eternal_xi/features/rewards/presentation/screens/rewards_hub_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) =>
          LoginScreen(prefilledCorreo: state.uri.queryParameters['correo']),
    ),
    GoRoute(
      path: AppRoutes.verifyEmailRequest,
      builder: (context, state) => const RequestEmailVerificationScreen(),
    ),
    GoRoute(
      path: AppRoutes.verifyEmailConfirm,
      builder: (context, state) => ConfirmEmailVerificationScreen(
        prefilledCorreo: state.uri.queryParameters['correo'],
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) =>
          RegisterScreen(prefilledCorreo: state.uri.queryParameters['correo']),
    ),
    GoRoute(
      path: AppRoutes.passwordResetRequest,
      builder: (context, state) => const RequestPasswordResetScreen(),
    ),
    GoRoute(
      path: AppRoutes.passwordResetConfirm,
      builder: (context, state) => ConfirmPasswordResetScreen(
        prefilledCorreo: state.uri.queryParameters['correo'],
      ),
    ),
    GoRoute(
      path: AppRoutes.home,
      redirect: (context, state) => AppRoutes.leagues,
    ),
    GoRoute(
      path: AppRoutes.mode,
      redirect: redirectIfUnauthenticated,
      builder: (context, state) => const ModeSelectionScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return ChangeNotifierProvider(
          create: (_) => ClashNavigationController(),
          child: ClashShellScreen(body: child),
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.clash,
          redirect: redirectIfUnauthenticated,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ClashTabHost()),
          routes: [
            GoRoute(
              path: 'story',
              builder: (context, state) => const ClashStoryMapScreen(),
              routes: [
                GoRoute(
                  path: 'level/:levelId',
                  builder: (context, state) => ClashStoryLevelReaderScreen(
                    levelId: state.pathParameters['levelId'] ?? '',
                  ),
                  routes: [
                    GoRoute(
                      path: 'prepare',
                      builder: (context, state) => ClashMatchPrepareScreen(
                        levelId: state.pathParameters['levelId'] ?? '',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: 'match/:levelId',
              builder: (context, state) => ClashMatchScreen(
                levelId: state.pathParameters['levelId'] ?? '',
              ),
            ),
            GoRoute(
              path: 'team/7v7',
              builder: (context, state) => const ClashLineup7v7Screen(),
            ),
            GoRoute(
              path: 'inventory',
              builder: (context, state) => const ClashInventoryScreen(),
            ),
            GoRoute(
              path: 'missions',
              builder: (context, state) => const ClashDailyMissionsScreen(),
            ),
            GoRoute(
              path: 'achievements',
              builder: (context, state) => const ClashAchievementsScreen(),
            ),
            GoRoute(
              path: 'summon/history',
              builder: (context, state) => const ClashGachaHistoryScreen(),
            ),
            GoRoute(
              path: 'cards',
              builder: (context, state) => const ClashCardCollectionScreen(),
              routes: [
                GoRoute(
                  path: ':cardId',
                  builder: (context, state) => ClashCardDetailScreen(
                    cardId: state.pathParameters['cardId'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.leagues,
      builder: (context, state) => const MyLeaguesScreen(),
      routes: [
        GoRoute(
          path: 'create',
          builder: (context, state) => const CreateLeagueScreen(),
        ),
        GoRoute(
          path: 'join',
          builder: (context, state) => const JoinLeagueScreen(),
        ),
        GoRoute(
          path: ':leagueId',
          builder: (context, state) {
            final raw = state.pathParameters['leagueId'] ?? '';
            final id = int.tryParse(raw) ?? 0;
            final idUsuarioRaw = state.uri.queryParameters['idUsuario'];
            final idUsuario = idUsuarioRaw != null
                ? int.tryParse(idUsuarioRaw)
                : null;
            return LeagueShellScreen(leagueId: id, idUsuario: idUsuario);
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const EditProfileScreen(),
      routes: [
        GoRoute(
          path: 'change-email',
          builder: (context, state) => RequestChangeEmailScreen(
            correoActual: context.read<AuthController>().currentUser?.correo,
          ),
          routes: [
            GoRoute(
              path: 'confirm',
              builder: (context, state) => ConfirmChangeEmailScreen(
                prefilledCorreo: state.uri.queryParameters['correo'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'delete-account/confirm',
          builder: (context, state) => const ConfirmAccountDeletionScreen(),
        ),
        GoRoute(
          path: 'change-nickname',
          builder: (context, state) => RequestChangeNicknameScreen(
            nicknameActual: context
                .read<AuthController>()
                .currentUser
                ?.nickname,
          ),
          routes: [
            GoRoute(
              path: 'confirm',
              builder: (context, state) => ConfirmChangeNicknameScreen(
                prefilledNickname: state.uri.queryParameters['nickname'],
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.tokensShop,
      builder: (context, state) {
        final raw = state.uri.queryParameters['idLiga'];
        final id = int.tryParse(raw ?? '') ?? 0;
        return RewardsHubScreen(initialLeagueId: id > 0 ? id : null);
      },
    ),
  ],
);
