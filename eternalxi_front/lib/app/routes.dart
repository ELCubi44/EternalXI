class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const verifyEmailRequest = '/verify-email/request';
  static const verifyEmailConfirm = '/verify-email/confirm';
  static const register = '/register';
  static const passwordResetRequest = '/password-reset/request';
  static const passwordResetConfirm = '/password-reset/confirm';
  static const home = '/home';
  static const mode = '/mode';
  static const clash = '/clash';
  static const clashCards = '/clash/cards';
  static const clashTeam7v7 = '/clash/team/7v7';
  static const clashInventory = '/clash/inventory';
  static const clashStory = '/clash/story';

  static String clashStoryLevel(String levelId) =>
      '/clash/story/level/$levelId';

  static String clashStoryLevelPrepare(String levelId) =>
      '/clash/story/level/$levelId/prepare';

  static String clashMatch(String levelId) => '/clash/match/$levelId';

  static String clashCardDetail(String cardId) => '/clash/cards/$cardId';

  static const profile = '/profile';
  static const changeEmailRequest = '/profile/change-email';
  static const changeEmailConfirm = '/profile/change-email/confirm';
  static const changeNicknameRequest = '/profile/change-nickname';
  static const changeNicknameConfirm = '/profile/change-nickname/confirm';
  static const deleteAccountConfirm = '/profile/delete-account/confirm';
  static const tokensShop = '/profile/tokens-shop';

  /// Recompensas; opcionalmente abre una liga concreta (`GET summary` al entrar).
  static String rewardsShop({int? idLiga}) {
    if (idLiga != null && idLiga > 0) {
      return '$tokensShop?idLiga=$idLiga';
    }
    return tokensShop;
  }

  static const leagues = '/leagues';
  static const leaguesCreate = '/leagues/create';
  static const leaguesJoin = '/leagues/join';

  /// Abre la shell de liga. [idUsuario] fuerza el usuario (query); si es null, usa sesión.
  static String leagueDetail(int idLiga, {int? idUsuario}) {
    if (idUsuario != null && idUsuario > 0) {
      return '/leagues/$idLiga?idUsuario=$idUsuario';
    }
    return '/leagues/$idLiga';
  }
}
