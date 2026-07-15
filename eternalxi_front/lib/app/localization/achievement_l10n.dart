class AchievementL10nEntry {
  const AchievementL10nEntry({
    required this.title,
    required this.description,
    required this.information,
  });

  final String title;
  final String description;
  final String information;
}

abstract final class AchievementL10n {
  AchievementL10n._();

  static AchievementL10nEntry? byCode(
    String code, {
    required String localeCode,
  }) {
    final normalized = code.trim().toUpperCase();
    final isEn = localeCode.toLowerCase().startsWith('en');
    final source = isEn ? _en : _es;
    return source[normalized];
  }

  static const Map<String, AchievementL10nEntry> _es = {
    'WIN_LEAGUE_1': AchievementL10nEntry(title: 'Primera corona', description: 'Gana una liga válida', information: 'Termina 1.º en una liga válida para progreso.'),
    'WIN_LEAGUE_3': AchievementL10nEntry(title: 'Tricampeón', description: 'Gana 3 ligas válidas', information: 'Acumula 3 títulos en ligas válidas.'),
    'WIN_LEAGUE_5': AchievementL10nEntry(title: 'Dominador', description: 'Gana 5 ligas válidas', information: 'Acumula 5 campeonatos válidos en tu cuenta.'),
    'GOALS_50': AchievementL10nEntry(title: 'Goleador', description: '50 goles acumulados', information: 'Suma 50 goles con tus jugadores en ligas jugadas.'),
    'GOALS_100': AchievementL10nEntry(title: 'Artillero', description: '100 goles acumulados', information: 'Alcanza 100 goles totales con tu plantilla.'),
    'GOALS_250': AchievementL10nEntry(title: 'Máquina de goles', description: '250 goles acumulados', information: 'Llega a 250 goles con tus jugadores.'),
    'ASSISTS_25': AchievementL10nEntry(title: 'Creador', description: '25 asistencias acumuladas', information: 'Registra 25 asistencias con tus jugadores.'),
    'ASSISTS_100': AchievementL10nEntry(title: 'Maestro del pase', description: '100 asistencias acumuladas', information: 'Acumula 100 asistencias en tu cuenta.'),
    'CLEAN_SHEETS_10': AchievementL10nEntry(title: 'Muralla', description: '10 porterías a cero', information: 'Consigue 10 porterías a cero con tus porteros.'),
    'CLEAN_SHEETS_50': AchievementL10nEntry(title: 'Fortín', description: '50 porterías a cero', information: 'Acumula 50 porterías a cero.'),
    'INJURIES_15': AchievementL10nEntry(title: 'Consultorio', description: '15 lesiones acumuladas', information: 'Tus jugadores suman 15 lesiones en partido.'),
    'SANCTIONS_25': AchievementL10nEntry(title: 'Tarjetero', description: '25 sanciones acumuladas', information: 'Tus jugadores suman 25 tarjetas.'),
    'DAY_POINTS_50': AchievementL10nEntry(title: 'Jornada sólida', description: '50+ pts fantasy en una jornada', information: 'Supera 50 puntos fantasy en una jornada.'),
    'DAY_POINTS_75': AchievementL10nEntry(title: 'Jornada brillante', description: '75+ pts fantasy en una jornada', information: 'Supera 75 puntos fantasy en una jornada.'),
    'DAY_POINTS_100': AchievementL10nEntry(title: 'Jornada épica', description: '100+ pts fantasy en una jornada', information: 'Supera 100 puntos fantasy en una jornada.'),
    'DAY_POINTS_150': AchievementL10nEntry(title: 'Jornada legendaria', description: '150+ pts fantasy en una jornada', information: 'Supera 150 puntos fantasy en una jornada.'),
    'CLAUSE_20M': AchievementL10nEntry(title: 'Clausulazo I', description: 'Cláusula a jugador de 20M+', information: 'Aplica cláusula a un jugador de 20M o más.'),
    'CLAUSE_30M': AchievementL10nEntry(title: 'Clausulazo II', description: 'Cláusula a jugador de 30M+', information: 'Aplica cláusula a un jugador de 30M o más.'),
    'CLAUSE_50M': AchievementL10nEntry(title: 'Clausulazo III', description: 'Cláusula a jugador de 50M+', information: 'Aplica cláusula a un jugador de 50M o más.'),
    'CLAUSE_100M': AchievementL10nEntry(title: 'Clausulazo IV', description: 'Cláusula a jugador de 100M+', information: 'Aplica cláusula a un jugador de 100M o más.'),
    'SHIELD_PLAYER': AchievementL10nEntry(title: 'Blindaje', description: 'Protege a un jugador con carta', information: 'Usa una carta de protección sobre un jugador propio.'),
    'SHIELD_3_ACTIVE': AchievementL10nEntry(title: 'Muralla triple', description: '3 jugadores protegidos a la vez en una liga', information: 'Mantén 3 escudos activos al mismo tiempo.'),
    'SHIELD_5_ACTIVE': AchievementL10nEntry(title: 'Bunker', description: '5 jugadores protegidos a la vez en una liga', information: 'Mantén 5 escudos activos al mismo tiempo.'),
    'SELL_50M': AchievementL10nEntry(title: 'Vendedor I', description: 'Vende por 50M+ (mercado o carta)', information: 'Completa una venta por 50M o más.'),
    'SELL_100M': AchievementL10nEntry(title: 'Vendedor II', description: 'Vende por 100M+', information: 'Completa una venta por 100M o más.'),
    'SELL_150M': AchievementL10nEntry(title: 'Vendedor III', description: 'Vende por 150M+', information: 'Completa una venta por 150M o más.'),
    'SELL_200M': AchievementL10nEntry(title: 'Vendedor IV', description: 'Vende por 200M+', information: 'Completa una venta por 200M o más.'),
    'FINISH_LEAGUE_500': AchievementL10nEntry(title: 'Temporada competida', description: 'Termina liga ida con 500+ pts totales', information: 'Finaliza liga de ida con al menos 500 puntos.'),
    'FINISH_LEAGUE_750': AchievementL10nEntry(title: 'Temporada elite', description: 'Termina liga ida con 750+ pts totales', information: 'Finaliza liga de ida con al menos 750 puntos.'),
    'FINISH_LEAGUE_1000': AchievementL10nEntry(title: 'Temporada mítica', description: 'Termina liga ida con 1000+ pts totales', information: 'Finaliza liga de ida con al menos 1000 puntos.'),
    'PACKS_5': AchievementL10nEntry(title: 'Coleccionista I', description: 'Abre 5 sobres en una liga', information: 'Abre 5 sobres de recompensa en la misma liga.'),
    'PACKS_10': AchievementL10nEntry(title: 'Coleccionista II', description: 'Abre 10 sobres en una liga', information: 'Abre 10 sobres de recompensa en la misma liga.'),
    'PACKS_15': AchievementL10nEntry(title: 'Coleccionista III', description: 'Abre 15 sobres en una liga', information: 'Abre 15 sobres de recompensa en la misma liga.'),
    'PACKS_20': AchievementL10nEntry(title: 'Coleccionista IV', description: 'Abre 20 sobres en una liga', information: 'Abre 20 sobres de recompensa en la misma liga.'),
    'PUSH_WIN_5000': AchievementL10nEntry(title: 'Puja holgada', description: 'Gana subasta por <=5000€ de margen', information: 'Gana una subasta con margen de 5000€ o menos.'),
    'PUSH_WIN_1000': AchievementL10nEntry(title: 'Puja ajustada', description: 'Gana subasta por <=1000€ de margen', information: 'Gana una subasta con margen de 1000€ o menos.'),
    'PUSH_WIN_500': AchievementL10nEntry(title: 'Puja tensa', description: 'Gana subasta por <=500€ de margen', information: 'Gana una subasta con margen de 500€ o menos.'),
    'PUSH_WIN_100': AchievementL10nEntry(title: 'Puja milimétrica', description: 'Gana subasta por <=100€ de margen', information: 'Gana una subasta con margen de 100€ o menos.'),
    'FIRST_LEAGUE': AchievementL10nEntry(title: 'Primer paso', description: 'Completa tu primera liga válida', information: 'Cierra una liga válida, no hace falta ganarla.'),
    'COACH_ROULETTE': AchievementL10nEntry(title: 'Míster con suerte', description: 'Consigue entrenador en la ruleta', information: 'Obtén un entrenador en la ruleta de recompensas.'),
    'FRIEND_1': AchievementL10nEntry(title: 'Primer colega', description: 'Consigue tu primer amigo', information: 'Acepta o confirma tu primera amistad en Eternal XI.'),
    'FRIEND_5': AchievementL10nEntry(title: 'Mano extendida', description: 'Ten 5 amigos', information: 'Acumula 5 amistades confirmadas en tu cuenta.'),
    'FRIEND_15': AchievementL10nEntry(title: 'Capitán social', description: 'Ten 15 amigos', information: 'Llega a 15 amigos confirmados en la plataforma.'),
    'FAVORITE_ROSTER_HALF': AchievementL10nEntry(title: 'Mediatoteca', description: 'Ficha al 50% del catálogo', information: 'Ficha al menos la mitad de los jugadores en ligas terminadas.'),
    'FAVORITE_ROSTER_COMPLETE': AchievementL10nEntry(title: 'Colección total', description: 'Ficha al 100% del catálogo', information: 'Ficha todos los jugadores del catálogo en ligas terminadas.'),
  };

  static const Map<String, AchievementL10nEntry> _en = {
    'WIN_LEAGUE_1': AchievementL10nEntry(title: 'First Crown', description: 'Win one valid league', information: 'Finish first in a league that qualifies for progress.'),
    'WIN_LEAGUE_3': AchievementL10nEntry(title: 'Three-Peat', description: 'Win 3 valid leagues', information: 'Accumulate 3 valid league titles.'),
    'WIN_LEAGUE_5': AchievementL10nEntry(title: 'Dominator', description: 'Win 5 valid leagues', information: 'Accumulate 5 valid league titles.'),
    'GOALS_50': AchievementL10nEntry(title: 'Goal Scorer', description: '50 cumulative goals', information: 'Score 50 goals with your players across leagues.'),
    'GOALS_100': AchievementL10nEntry(title: 'Sharpshooter', description: '100 cumulative goals', information: 'Reach 100 total goals with your squad.'),
    'GOALS_250': AchievementL10nEntry(title: 'Goal Machine', description: '250 cumulative goals', information: 'Reach 250 total goals with your players.'),
    'ASSISTS_25': AchievementL10nEntry(title: 'Playmaker', description: '25 cumulative assists', information: 'Register 25 assists with your players.'),
    'ASSISTS_100': AchievementL10nEntry(title: 'Pass Master', description: '100 cumulative assists', information: 'Accumulate 100 assists on your account.'),
    'CLEAN_SHEETS_10': AchievementL10nEntry(title: 'Wall', description: '10 clean sheets', information: 'Keep 10 clean sheets with your goalkeepers.'),
    'CLEAN_SHEETS_50': AchievementL10nEntry(title: 'Fortress', description: '50 clean sheets', information: 'Accumulate 50 clean sheets.'),
    'INJURIES_15': AchievementL10nEntry(title: 'Infirmary', description: '15 cumulative injuries', information: 'Your players accumulate 15 in-match injuries.'),
    'SANCTIONS_25': AchievementL10nEntry(title: 'Card Collector', description: '25 cumulative sanctions', information: 'Your players accumulate 25 cards.'),
    'DAY_POINTS_50': AchievementL10nEntry(title: 'Solid Matchday', description: '50+ fantasy points in one matchday', information: 'Score at least 50 fantasy points in one matchday.'),
    'DAY_POINTS_75': AchievementL10nEntry(title: 'Brilliant Matchday', description: '75+ fantasy points in one matchday', information: 'Score at least 75 fantasy points in one matchday.'),
    'DAY_POINTS_100': AchievementL10nEntry(title: 'Epic Matchday', description: '100+ fantasy points in one matchday', information: 'Score at least 100 fantasy points in one matchday.'),
    'DAY_POINTS_150': AchievementL10nEntry(title: 'Legendary Matchday', description: '150+ fantasy points in one matchday', information: 'Score at least 150 fantasy points in one matchday.'),
    'CLAUSE_20M': AchievementL10nEntry(title: 'Release Clause I', description: 'Use clause on a 20M+ player', information: 'Trigger a clause for a player worth 20M or more.'),
    'CLAUSE_30M': AchievementL10nEntry(title: 'Release Clause II', description: 'Use clause on a 30M+ player', information: 'Trigger a clause for a player worth 30M or more.'),
    'CLAUSE_50M': AchievementL10nEntry(title: 'Release Clause III', description: 'Use clause on a 50M+ player', information: 'Trigger a clause for a player worth 50M or more.'),
    'CLAUSE_100M': AchievementL10nEntry(title: 'Release Clause IV', description: 'Use clause on a 100M+ player', information: 'Trigger a clause for a player worth 100M or more.'),
    'SHIELD_PLAYER': AchievementL10nEntry(title: 'Shielded', description: 'Protect a player with a card', information: 'Apply one protection card to your player.'),
    'SHIELD_3_ACTIVE': AchievementL10nEntry(title: 'Triple Wall', description: '3 protected players at once', information: 'Keep 3 shields active at the same time.'),
    'SHIELD_5_ACTIVE': AchievementL10nEntry(title: 'Bunker', description: '5 protected players at once', information: 'Keep 5 shields active at the same time.'),
    'SELL_50M': AchievementL10nEntry(title: 'Seller I', description: 'Sell for 50M+ (market or card)', information: 'Complete one sale worth 50M or more.'),
    'SELL_100M': AchievementL10nEntry(title: 'Seller II', description: 'Sell for 100M+', information: 'Complete one sale worth 100M or more.'),
    'SELL_150M': AchievementL10nEntry(title: 'Seller III', description: 'Sell for 150M+', information: 'Complete one sale worth 150M or more.'),
    'SELL_200M': AchievementL10nEntry(title: 'Seller IV', description: 'Sell for 200M+', information: 'Complete one sale worth 200M or more.'),
    'FINISH_LEAGUE_500': AchievementL10nEntry(title: 'Competitive Season', description: 'Finish single round league with 500+ points', information: 'Finish a single round league with at least 500 points.'),
    'FINISH_LEAGUE_750': AchievementL10nEntry(title: 'Elite Season', description: 'Finish single round league with 750+ points', information: 'Finish a single round league with at least 750 points.'),
    'FINISH_LEAGUE_1000': AchievementL10nEntry(title: 'Mythic Season', description: 'Finish single round league with 1000+ points', information: 'Finish a single round league with at least 1000 points.'),
    'PACKS_5': AchievementL10nEntry(title: 'Collector I', description: 'Open 5 packs in one league', information: 'Open 5 reward packs in the same league.'),
    'PACKS_10': AchievementL10nEntry(title: 'Collector II', description: 'Open 10 packs in one league', information: 'Open 10 reward packs in the same league.'),
    'PACKS_15': AchievementL10nEntry(title: 'Collector III', description: 'Open 15 packs in one league', information: 'Open 15 reward packs in the same league.'),
    'PACKS_20': AchievementL10nEntry(title: 'Collector IV', description: 'Open 20 packs in one league', information: 'Open 20 reward packs in the same league.'),
    'PUSH_WIN_5000': AchievementL10nEntry(title: 'Comfortable Bid', description: 'Win auction by <=5000€ margin', information: 'Win an auction by 5000€ margin or less.'),
    'PUSH_WIN_1000': AchievementL10nEntry(title: 'Tight Bid', description: 'Win auction by <=1000€ margin', information: 'Win an auction by 1000€ margin or less.'),
    'PUSH_WIN_500': AchievementL10nEntry(title: 'Nerve Bid', description: 'Win auction by <=500€ margin', information: 'Win an auction by 500€ margin or less.'),
    'PUSH_WIN_100': AchievementL10nEntry(title: 'Photo Finish Bid', description: 'Win auction by <=100€ margin', information: 'Win an auction by 100€ margin or less.'),
    'FIRST_LEAGUE': AchievementL10nEntry(title: 'First Step', description: 'Complete your first valid league', information: 'Finish one valid league, winning is not required.'),
    'COACH_ROULETTE': AchievementL10nEntry(title: 'Lucky Coach', description: 'Get a coach from roulette', information: 'Obtain a coach through reward roulette.'),
    'FRIEND_1': AchievementL10nEntry(title: 'First Mate', description: 'Get your first friend', information: 'Accept or confirm your first friendship on Eternal XI.'),
    'FRIEND_5': AchievementL10nEntry(title: 'Open Hand', description: 'Have 5 friends', information: 'Accumulate 5 confirmed friendships on your account.'),
    'FRIEND_15': AchievementL10nEntry(title: 'Social Captain', description: 'Have 15 friends', information: 'Reach 15 confirmed friends on the platform.'),
    'FAVORITE_ROSTER_HALF': AchievementL10nEntry(title: 'Half Catalog', description: 'Sign 50% of the roster', information: 'Sign at least half the catalog in finished leagues.'),
    'FAVORITE_ROSTER_COMPLETE': AchievementL10nEntry(title: 'Full Collection', description: 'Sign 100% of the roster', information: 'Sign every catalog player in finished leagues.'),
  };
}
