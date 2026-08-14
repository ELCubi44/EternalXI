import 'package:eternal_xi/app/page_transitions.dart';
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
import 'package:eternal_xi/features/clash/help/presentation/screens/clash_help_screen.dart';
import 'package:eternal_xi/features/clash/help/presentation/screens/clash_help_topic_screen.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/screens/clash_gacha_history_screen.dart';
import 'package:eternal_xi/features/clash/debug/presentation/clash_debug_screen.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/presentation/clash_reward_history_screen.dart';
import 'package:eternal_xi/features/clash/inventory/presentation/screens/clash_inventory_screen.dart';
import 'package:eternal_xi/features/clash/achievements/presentation/screens/clash_achievements_screen.dart';
import 'package:eternal_xi/features/clash/news/presentation/screens/clash_news_screen.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/screens/clash_gifts_screen.dart';
import 'package:eternal_xi/features/clash/challenges/presentation/controllers/clash_chain_trial_controller.dart';
import 'package:eternal_xi/features/clash/challenges/presentation/screens/clash_chain_match_screen.dart';
import 'package:eternal_xi/features/clash/challenges/presentation/screens/clash_trial_detail_screen.dart';
import 'package:eternal_xi/features/clash/challenges/presentation/screens/clash_trial_prepare_screen.dart';
import 'package:eternal_xi/features/clash/challenges/presentation/screens/clash_trials_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_events_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_detail_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_story_stage_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_match_prepare_screen.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_match_screen.dart';
import 'package:eternal_xi/features/clash/missions/presentation/screens/clash_weekly_missions_screen.dart';
import 'package:eternal_xi/features/clash/missions/presentation/screens/clash_daily_missions_screen.dart';
import 'package:eternal_xi/features/clash/decisive_moments/presentation/controllers/clash_decisive_moments_controller.dart';
import 'package:eternal_xi/features/clash/decisive_moments/presentation/screens/clash_decisive_moments_screen.dart';
import 'package:eternal_xi/features/clash/match/presentation/screens/clash_match_prepare_screen.dart';
import 'package:eternal_xi/features/clash/match/presentation/screens/clash_match_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_level_reader_screen.dart';
import 'package:eternal_xi/features/clash/story/presentation/screens/clash_story_map_screen.dart';
import 'package:eternal_xi/features/clash/team/presentation/screens/clash_lineup_7v7_screen.dart';
import 'package:eternal_xi/features/clash/content/clash_media_download_screen.dart';
import 'package:eternal_xi/features/profile/screens/confirm_change_email_screen.dart';
import 'package:eternal_xi/features/profile/screens/confirm_account_deletion_screen.dart';
import 'package:eternal_xi/features/profile/screens/confirm_change_nickname_screen.dart';
import 'package:eternal_xi/features/profile/screens/edit_profile_screen.dart';
import 'package:eternal_xi/features/profile/screens/friends_screen.dart';
import 'package:eternal_xi/features/profile/screens/public_user_profile_screen.dart';
import 'package:eternal_xi/features/legal/screens/legal_document_screen.dart';
import 'package:eternal_xi/features/legal/screens/legal_hub_screen.dart';
import 'package:eternal_xi/features/profile/screens/request_change_email_screen.dart';
import 'package:eternal_xi/features/profile/screens/request_change_nickname_screen.dart';
import 'package:eternal_xi/features/rewards/presentation/screens/rewards_hub_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    fadeGoRoute(
      path: AppRoutes.splash,
      duration: const Duration(milliseconds: 480),
      builder: (context, state) => const SplashScreen(),
    ),
    fadeGoRoute(
      path: AppRoutes.login,
      builder: (context, state) =>
          LoginScreen(prefilledCorreo: state.uri.queryParameters['correo']),
    ),
    fadeGoRoute(
      path: AppRoutes.legalHub,
      builder: (context, state) => const LegalHubScreen(),
      routes: [
        fadeGoRoute(
          path: ':docType',
          builder: (context, state) {
            final typeName = state.pathParameters['docType'] ?? 'terms';
            final type = LegalDocumentType.values.firstWhere(
              (t) => t.name == typeName,
              orElse: () => LegalDocumentType.terms,
            );
            return LegalDocumentScreen(type: type);
          },
        ),
      ],
    ),
    fadeGoRoute(
      path: AppRoutes.verifyEmailRequest,
      builder: (context, state) => const RequestEmailVerificationScreen(),
    ),
    fadeGoRoute(
      path: AppRoutes.verifyEmailConfirm,
      builder: (context, state) => ConfirmEmailVerificationScreen(
        prefilledCorreo: state.uri.queryParameters['correo'],
      ),
    ),
    fadeGoRoute(
      path: AppRoutes.register,
      builder: (context, state) =>
          RegisterScreen(prefilledCorreo: state.uri.queryParameters['correo']),
    ),
    fadeGoRoute(
      path: AppRoutes.passwordResetRequest,
      builder: (context, state) => const RequestPasswordResetScreen(),
    ),
    fadeGoRoute(
      path: AppRoutes.passwordResetConfirm,
      builder: (context, state) => ConfirmPasswordResetScreen(
        prefilledCorreo: state.uri.queryParameters['correo'],
      ),
    ),
    GoRoute(
      path: AppRoutes.home,
      redirect: (context, state) => AppRoutes.clash,
    ),
    GoRoute(
      path: '/mode',
      redirect: (context, state) => AppRoutes.clash,
    ),
    GoRoute(
      path: '/leagues',
      redirect: (context, state) => AppRoutes.clash,
    ),
    fadeGoRoute(
      path: AppRoutes.clashPrepare,
      redirect: redirectIfUnauthenticated,
      builder: (context, state) => const ClashMediaDownloadScreen(),
    ),
    // Subrutas Clash son hermanas de `/clash` (no hijas): si el hub vive en el
    // pageBuilder del padre, go_router nunca muestra story/inventory/etc.
    ShellRoute(
      redirect: redirectIfUnauthenticated,
      builder: (context, state, child) {
        return ChangeNotifierProvider(
          create: (_) => ClashNavigationController(),
          child: ClashShellScreen(body: child),
        );
      },
      routes: [
        fadeGoRoute(
          path: AppRoutes.clash,
          builder: (context, state) => const ClashTabHost(),
        ),
        fadeGoRoute(
          path: AppRoutes.clashStory,
          builder: (context, state) => const ClashStoryMapScreen(),
          routes: [
            fadeGoRoute(
              path: 'level/:levelId',
              builder: (context, state) => ClashStoryLevelReaderScreen(
                levelId: state.pathParameters['levelId'] ?? '',
              ),
              routes: [
                fadeGoRoute(
                  path: 'prepare',
                  builder: (context, state) => ClashMatchPrepareScreen(
                    levelId: state.pathParameters['levelId'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
        fadeGoRoute(
          path: '/clash/match/:levelId',
          builder: (context, state) => ClashMatchScreen(
            levelId: state.pathParameters['levelId'] ?? '',
          ),
        ),
        fadeGoRoute(
          path: '/clash/decisive/:levelId',
          builder: (context, state) => ClashDecisiveMomentsScreen(
            levelId: state.pathParameters['levelId'] ?? '',
          ),
        ),
        fadeGoRoute(
          path: AppRoutes.clashTeam7v7,
          builder: (context, state) => const ClashLineup7v7Screen(),
        ),
        fadeGoRoute(
          path: AppRoutes.clashInventory,
          builder: (context, state) => const ClashInventoryScreen(),
        ),
        fadeGoRoute(
          path: AppRoutes.clashMissions,
          builder: (context, state) => const ClashDailyMissionsScreen(),
        ),
        fadeGoRoute(
          path: AppRoutes.clashWeeklyMissions,
          builder: (context, state) => const ClashWeeklyMissionsScreen(),
        ),
        fadeGoRoute(
          path: AppRoutes.clashAchievements,
          builder: (context, state) => const ClashAchievementsScreen(),
        ),
        fadeGoRoute(
          path: AppRoutes.clashNews,
          builder: (context, state) => const ClashNewsScreen(),
        ),
        fadeGoRoute(
          path: AppRoutes.clashGifts,
          builder: (context, state) => const ClashGiftsScreen(),
        ),
        fadeGoRoute(
          path: AppRoutes.clashTrials,
          builder: (context, state) => const ClashTrialsScreen(),
          routes: [
            fadeGoRoute(
              path: ':trialId',
              builder: (context, state) => ClashTrialDetailScreen(
                trialId: state.pathParameters['trialId'] ?? '',
              ),
              routes: [
                fadeGoRoute(
                  path: 'floor/:floorId/prepare',
                  builder: (context, state) => ClashTrialPrepareScreen(
                    trialId: state.pathParameters['trialId'] ?? '',
                    floorId: state.pathParameters['floorId'] ?? '',
                  ),
                ),
                fadeGoRoute(
                  path: 'floor/:floorId/match',
                  builder: (context, state) => ClashChainMatchScreen(
                    trialId: state.pathParameters['trialId'] ?? '',
                    floorId: state.pathParameters['floorId'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
        fadeGoRoute(
          path: AppRoutes.clashEvents,
          builder: (context, state) => const ClashEventsScreen(),
          routes: [
            fadeGoRoute(
              path: ':eventId',
              builder: (context, state) => ClashEventDetailScreen(
                eventId: state.pathParameters['eventId'] ?? '',
              ),
              routes: [
                fadeGoRoute(
                  path: 'stage/:stageId',
                  builder: (context, state) => ClashEventStoryStageScreen(
                    eventId: state.pathParameters['eventId'] ?? '',
                    stageId: state.pathParameters['stageId'] ?? '',
                  ),
                  routes: [
                    fadeGoRoute(
                      path: 'prepare',
                      builder: (context, state) => ClashEventMatchPrepareScreen(
                        eventId: state.pathParameters['eventId'] ?? '',
                        stageId: state.pathParameters['stageId'] ?? '',
                      ),
                    ),
                    fadeGoRoute(
                      path: 'match',
                      builder: (context, state) => ClashEventMatchScreen(
                        eventId: state.pathParameters['eventId'] ?? '',
                        stageId: state.pathParameters['stageId'] ?? '',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        fadeGoRoute(
          path: AppRoutes.clashHelp,
          builder: (context, state) => const ClashHelpScreen(),
          routes: [
            fadeGoRoute(
              path: ':topicId',
              builder: (context, state) => ClashHelpTopicScreen(
                topicId: state.pathParameters['topicId'] ?? '',
              ),
            ),
          ],
        ),
        fadeGoRoute(
          path: AppRoutes.clashSummonHistory,
          builder: (context, state) => const ClashGachaHistoryScreen(),
        ),
        fadeGoRoute(
          path: AppRoutes.clashRewardHistory,
          builder: (context, state) => const ClashRewardHistoryScreen(),
        ),
        fadeGoRoute(
          path: AppRoutes.clashDebug,
          builder: (context, state) => const ClashDebugScreen(),
        ),
        fadeGoRoute(
          path: AppRoutes.clashCards,
          builder: (context, state) => const ClashCardCollectionScreen(),
          routes: [
            fadeGoRoute(
              path: ':cardId',
              builder: (context, state) => ClashCardDetailScreen(
                cardId: state.pathParameters['cardId'] ?? '',
              ),
            ),
          ],
        ),
      ],
    ),
    fadeGoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const EditProfileScreen(),
      routes: [
        fadeGoRoute(
          path: 'change-email',
          builder: (context, state) => RequestChangeEmailScreen(
            correoActual: context.read<AuthController>().currentUser?.correo,
          ),
          routes: [
            fadeGoRoute(
              path: 'confirm',
              builder: (context, state) => ConfirmChangeEmailScreen(
                prefilledCorreo: state.uri.queryParameters['correo'],
              ),
            ),
          ],
        ),
        fadeGoRoute(
          path: 'delete-account/confirm',
          builder: (context, state) => const ConfirmAccountDeletionScreen(),
        ),
        fadeGoRoute(
          path: 'change-nickname',
          builder: (context, state) => RequestChangeNicknameScreen(
            nicknameActual: context
                .read<AuthController>()
                .currentUser
                ?.nickname,
          ),
          routes: [
            fadeGoRoute(
              path: 'confirm',
              builder: (context, state) => ConfirmChangeNicknameScreen(
                prefilledNickname: state.uri.queryParameters['nickname'],
              ),
            ),
          ],
        ),
        fadeGoRoute(
          path: 'friends',
          builder: (context, state) => const FriendsScreen(),
        ),
        fadeGoRoute(
          path: 'users/:userId',
          builder: (context, state) {
            final raw = state.pathParameters['userId'] ?? '';
            final userId = int.tryParse(raw) ?? 0;
            return PublicUserProfileScreen(userId: userId);
          },
        ),
      ],
    ),
    fadeGoRoute(
      path: AppRoutes.tokensShop,
      builder: (context, state) {
        final raw = state.uri.queryParameters['idLiga'];
        final id = int.tryParse(raw ?? '') ?? 0;
        return RewardsHubScreen(initialLeagueId: id > 0 ? id : null);
      },
    ),
  ],
);
