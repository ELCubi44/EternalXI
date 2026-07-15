import 'package:eternal_xi/app/routes.dart';
import 'package:go_router/go_router.dart';

abstract final class UserProfileNavigation {
  UserProfileNavigation._();

  static void openPublicProfile(
    dynamic context, {
    required int userId,
    String? nicknameHint,
  }) {
    final path = AppRoutes.publicUserProfile(userId);
    if (context is GoRouter) {
      context.push(path);
      return;
    }
    GoRouter.of(context).push(path);
  }
}
