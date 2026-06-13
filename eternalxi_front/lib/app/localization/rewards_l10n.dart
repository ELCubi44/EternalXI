import 'dart:convert';

import 'package:eternal_xi/data/models/league_activity_event.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_event_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_card_target_model.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_coach_item.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_redeem_result_model.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:flutter/material.dart';

/// Textos del módulo de recompensas / tienda de fichas (es + en).
class RewardsL10n {
  RewardsL10n(this._en);

  final bool _en;

  factory RewardsL10n.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return RewardsL10n(code == 'en');
  }

  String _t(String es, String en) => _en ? en : es;

  // ─── Hub / navegación ───

  String get shopSubtitle =>
      _t('Sobres, cartas y entrenador', 'Packs, cards and coach');

  String get noUserSession => _t(
        'No se pudo identificar el usuario actual.',
        'Could not identify the current user.',
      );

  String get yourLeagues => _t('Tus ligas', 'Your leagues');

  String get noLeaguesHint => _t(
        'No participas en ninguna liga. Crea una o únete con código.',
        'You are not in any league. Create one or join with a code.',
      );

  String get selectLeagueTitle => _t('Selecciona una liga', 'Select a league');

  String get selectLeagueBody => _t(
        'Cada liga tiene sus propias fichas de recompensa, sobres, cartas y entrenador.',
        'Each league has its own reward chips, packs, cards and coach.',
      );

  String participants(int n) => _t('$n participantes', '$n participants');

  String get youAdmin => _t('Administras', 'You manage');

  String get enter => _t('Entrar', 'Enter');

  String get tabPacks => _t('Sobres', 'Packs');

  String get tabCoach => _t('Entrenador', 'Coach');

  String get tabCards => _t('Cartas', 'Cards');

  String get tabHistory => _t('Historial', 'History');

  String get points => _t('Fichas', 'Chips');

  String get fichas => points;

  String get fichasUnit => _t('fichas', 'chips');

  String get cardsAvailable => _t('Cartas disponibles', 'Available cards');

  String get spin => _t('Girar', 'Spin');

  String get openPack => _t('Abrir sobre', 'Open pack');

  String get close => _t('Cerrar', 'Close');

  String get continueLabel => _t('Continuar', 'Continue');

  String get useCard => _t('Usar carta', 'Use card');

  String get use => _t('Usar', 'Use');

  String get viewMyCards => _t('Ver mis cartas', 'View my cards');

  String get ok => 'OK';

  String get confirm => _t('Confirmar', 'Confirm');

  String get filterAll => _t('Todas', 'All');

  String get filterSell => _t('Venta', 'Sale');

  String get filterClause => _t('Cláusula', 'Clause');

  String get filterProtection => _t('Protección', 'Protection');

  String get filterPoints => _t('Puntos', 'Points');

  String get filterValue => _t('Subida valor', 'Value boost');

  String get activityEmpty => _t(
        'Aún no hay actividad en esta liga.',
        'No activity in this league yet.',
      );

  String get actionFailed => _t(
        'No se pudo completar la acción. Inténtalo de nuevo.',
        'Could not complete the action. Please try again.',
      );

  String get rouletteAlreadyUsed => _t(
        'La ruleta ya estaba usada. Se muestra el entrenador asignado.',
        'The roulette was already used. Showing the assigned coach.',
      );

  String shopFilterLabel(String key) {
    switch (key) {
      case 'ALL':
        return _t('Todo', 'All');
      case 'PACK_OPENED':
        return tabPacks;
      case 'COACH_ROULETTE':
        return _t('Ruleta', 'Roulette');
      case 'CARD_REDEEMED':
        return tabCards;
      default:
        return key;
    }
  }

  String get insufficientPoints =>
      _t('Fichas insuficientes', 'Insufficient chips');

  String get coachRouletteTitle => _t('Ruleta de entrenador', 'Coach roulette');

  String get yourCoach => _t('Tu entrenador', 'Your coach');

  String get rouletteUsed => _t('Ruleta ya utilizada', 'Roulette already used');

  String get coachRouletteHint => _t(
        'Consigue un entrenador libre para esta liga.',
        'Get a free coach for this league.',
      );

  String moneyRange(String min, String max) =>
      _t('Dinero: $min — $max', 'Budget: $min — $max');

  String get rewardPointsTooltip =>
      _t('Fichas de recompensa', 'Reward chips');

  String leagueFallbackName(int id) => _t('Liga $id', 'League $id');

  // ─── Sobres ───

  String get packProbabilitiesTitle =>
      _t('Probabilidades del sobre', 'Pack probabilities');

  String packCost(String points) => _t('Coste: $points', 'Cost: $points');

  String packBudget(String min, String max) =>
      _t('Presupuesto: $min — $max', 'Budget: $min — $max');

  String get noProbabilityData => _t(
        'Sin datos de probabilidades.',
        'No probability data available.',
      );

  String get openingPack => _t('Abriendo sobre…', 'Opening pack…');

  // ─── Cartas (grid / detalle) ───

  String get noCardsYet => _t(
        'No tienes cartas en esta liga todavía. Abre sobres para conseguir cartas.',
        'You have no cards in this league yet. Open packs to get cards.',
      );

  String get cardEffect => _t('Efecto', 'Effect');

  String get cardStatus => _t('Estado', 'Status');

  String get cardObtained => _t('Obtenida', 'Obtained');

  String get cardUsedOn => _t('Usada', 'Used on');

  String get cardUsedLabel => _t('Carta usada', 'Card used');

  String get quantityLabel => _t('Cantidad', 'Amount');

  String quantity(int n) => _t('Cantidad: $n', 'Amount: $n');

  // ─── Rareza ───

  String rarityLabel(String? rarity) {
    switch ((rarity ?? '').trim().toUpperCase()) {
      case 'BASIC':
        return _t('Básica', 'Basic');
      case 'NORMAL':
        return _t('Normal', 'Normal');
      case 'SPECIAL':
        return _t('Especial', 'Special');
      case 'SUPER_RARE':
      case 'SUPERRARE':
        return _t('Súper rara', 'Super rare');
      case 'LEGENDARY':
        return _t('Legendaria', 'Legendary');
      default:
        return (rarity ?? '').replaceAll('_', ' ');
    }
  }

  // ─── Tipos de efecto ───

  String tipoEfectoLabel(String code) {
    switch (code.trim().toUpperCase()) {
      case 'SELL_PLAYER_BONUS':
        return _t('Venta de jugador', 'Player sale');
      case 'DIRECT_CLAUSE':
        return filterClause;
      case 'PROTECT_PLAYER':
        return filterProtection;
      case 'ADD_LEAGUE_POINTS':
        return _t('Puntos de liga', 'League points');
      case 'TEMPORARY_VALUE_RECOVERY':
      case 'PLAYER_VALUE_BOOST':
        return _t('Subida de valor', 'Value boost');
      default:
        return '';
    }
  }

  String tipoEfectoLabelShort(String code) {
    switch (code.trim().toUpperCase()) {
      case 'SELL_PLAYER_BONUS':
        return filterSell;
      case 'DIRECT_CLAUSE':
        return filterClause;
      case 'PROTECT_PLAYER':
        return filterProtection;
      case 'ADD_LEAGUE_POINTS':
        return filterPoints;
      case 'TEMPORARY_VALUE_RECOVERY':
      case 'PLAYER_VALUE_BOOST':
        return filterValue;
      default:
        return '';
    }
  }

  /// Nombre visible; sustituye textos legacy de recuperación temporal.
  String cardDisplayName(RewardCardModel card) {
    final byCode = _cardNameByCode(card.codigo);
    if (byCode != null) {
      return byCode;
    }
    if (!card.isValueBoost) {
      return card.nombre;
    }
    return _valueBoostNameByCode(card.codigo) ?? card.nombre;
  }

  /// Descripción visible; sustituye textos legacy de recuperación temporal.
  String cardDisplayDescription(RewardCardModel card) {
    final byCode = _cardDescriptionByCode(card);
    if (byCode != null) {
      return byCode;
    }
    if (!card.isValueBoost) {
      return card.descripcion;
    }
    final pct = _valueBoostPercentFromParams(card.parametrosJson) ??
        _valueBoostPercentByCode(card.codigo);
    if (pct != null) {
      return _t(
        'Elige un jugador de tu plantilla y sube su valor de mercado un $pct% de forma permanente.',
        'Choose a squad player and permanently increase their market value by $pct%.',
      );
    }
    return card.descripcion;
  }

  String? _cardNameByCode(String codigo) {
    switch (codigo.trim().toUpperCase()) {
      case 'SELL_100':
        return _t('Venta Justa', 'Fair Sale');
      case 'SELL_120':
        return _t('Venta Mejorada', 'Improved Sale');
      case 'SELL_140':
        return _t('Venta Premium', 'Premium Sale');
      case 'SELL_160':
        return _t('Venta Maestra', 'Master Sale');
      case 'SELL_200':
        return _t('Venta Legendaria', 'Legendary Sale');
      case 'CLAUSE_5M':
        return _t('Cláusula Menor', 'Minor Clause');
      case 'CLAUSE_10M':
        return _t('Cláusula Media', 'Medium Clause');
      case 'CLAUSE_20M':
        return _t('Cláusula Especial', 'Special Clause');
      case 'CLAUSE_35M':
        return _t('Cláusula Élite', 'Elite Clause');
      case 'CLAUSE_ANY':
        return _t('Cláusula Legendaria', 'Legendary Clause');
      case 'PROTECT_1_ROUND':
        return _t('Protección Básica', 'Basic Protection');
      case 'PROTECT_2_ROUNDS':
        return _t('Protección Normal', 'Standard Protection');
      case 'PROTECT_4_ROUNDS':
        return _t('Protección Especial', 'Special Protection');
      case 'PROTECT_8_ROUNDS':
        return _t('Protección Élite', 'Elite Protection');
      case 'PROTECT_SEASON':
        return _t('Protección Legendaria', 'Legendary Protection');
      case 'LEAGUE_POINTS_5':
        return _t('Empujón de Puntos', 'Points Boost');
      case 'LEAGUE_POINTS_10':
        return _t('Racha Positiva', 'Positive Streak');
      case 'LEAGUE_POINTS_20':
        return _t('Jornada Inspirada', 'Inspired Matchday');
      case 'LEAGUE_POINTS_35':
        return _t('Golpe de Clasificación', 'Standings Strike');
      case 'LEAGUE_POINTS_60':
        return _t('Leyenda de la Liga', 'League Legend');
      default:
        return null;
    }
  }

  String? _cardDescriptionByCode(RewardCardModel card) {
    final code = card.codigo.trim().toUpperCase();
    final mult = _sellMultiplierFromCard(card);
    if (mult != null) {
      final pct = (mult * 100).round();
      return _t(
        'Vende un jugador por el $pct% de su valor.',
        'Sell a player for $pct% of their value.',
      );
    }
    final maxVal = _maxClauseValueFromCard(card);
    if (maxVal != null) {
      final label = _formatMoneyShort(maxVal);
      return _t(
        'Ficha directamente un jugador rival de hasta $label pagando el 100% de su valor.',
        'Sign a rival player worth up to $label paying 100% of their value.',
      );
    }
    if (code == 'CLAUSE_ANY') {
      return _t(
        'Ficha directamente un jugador rival de hasta 50M pagando el 100% de su valor.',
        'Sign a rival player worth up to 50M paying 100% of their value.',
      );
    }
    final rounds = _protectRoundsFromCard(card);
    if (rounds != null) {
      if (rounds < 0) {
        return _t(
          'Protege un jugador durante toda la temporada.',
          'Protect a player for the entire season.',
        );
      }
      return _t(
        'Protege un jugador durante $rounds jornadas.',
        'Protect a player for $rounds matchdays.',
      );
    }
    final pts = _leaguePointsFromCard(card);
    if (pts != null) {
      return _t(
        'Suma $pts puntos al total de la liga.',
        'Adds $pts points to your league total.',
      );
    }
    return null;
  }

  double? _sellMultiplierFromCard(RewardCardModel card) {
    if (card.tipoEfecto.trim().toUpperCase() != 'SELL_PLAYER_BONUS') {
      return null;
    }
    final params = _cardParams(card.parametrosJson);
    final mult = _num(params['sellMultiplier'] ?? params['multiplicadorVenta']);
    return mult?.toDouble();
  }

  int? _maxClauseValueFromCard(RewardCardModel card) {
    if (card.tipoEfecto.trim().toUpperCase() != 'DIRECT_CLAUSE') {
      return null;
    }
    final params = _cardParams(card.parametrosJson);
    final max = _num(params['maxPlayerValue'] ?? params['valorMaximoJugador']);
    return max?.toInt();
  }

  int? _protectRoundsFromCard(RewardCardModel card) {
    if (card.tipoEfecto.trim().toUpperCase() != 'PROTECT_PLAYER') {
      return null;
    }
    final params = _cardParams(card.parametrosJson);
    if (params['seasonLong'] == true) {
      return -1;
    }
    final rounds = _num(params['rounds'] ?? params['jornadas']);
    return rounds?.toInt();
  }

  int? _leaguePointsFromCard(RewardCardModel card) {
    if (card.tipoEfecto.trim().toUpperCase() != 'ADD_LEAGUE_POINTS') {
      return null;
    }
    final params = _cardParams(card.parametrosJson);
    final pts = _num(params['points'] ?? params['puntos']);
    return pts?.toInt();
  }

  Map<String, dynamic> _cardParams(String? json) {
    if (json == null || json.isEmpty) {
      return const {};
    }
    try {
      final raw = jsonDecode(json);
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    } catch (_) {}
    return const {};
  }

  String _formatMoneyShort(int amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return m == m.roundToDouble() ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      return k == k.roundToDouble() ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    }
    return '$amount';
  }

  String? _valueBoostNameByCode(String codigo) {
    switch (codigo.trim().toUpperCase()) {
      case 'VALUE_RECOVERY_SMALL':
        return _t('Impulso de mercado I', 'Market boost I');
      case 'VALUE_RECOVERY_MEDIUM':
        return _t('Impulso de mercado II', 'Market boost II');
      case 'VALUE_RECOVERY_SPECIAL':
        return _t('Impulso de mercado III', 'Market boost III');
      case 'VALUE_RECOVERY_ELITE':
        return _t('Impulso de mercado IV', 'Market boost IV');
      case 'VALUE_RECOVERY_LEGENDARY':
        return _t('Impulso de mercado V', 'Market boost V');
      default:
        return null;
    }
  }

  int? _valueBoostPercentByCode(String codigo) {
    switch (codigo.trim().toUpperCase()) {
      case 'VALUE_RECOVERY_SMALL':
        return 7;
      case 'VALUE_RECOVERY_MEDIUM':
        return 10;
      case 'VALUE_RECOVERY_SPECIAL':
        return 15;
      case 'VALUE_RECOVERY_ELITE':
        return 18;
      case 'VALUE_RECOVERY_LEGENDARY':
        return 25;
      default:
        return null;
    }
  }

  int? _valueBoostPercentFromParams(String? parametrosJson) {
    if (parametrosJson == null || parametrosJson.isEmpty) {
      return null;
    }
    try {
      final raw = json.decode(parametrosJson);
      if (raw is! Map) return null;
      final params = Map<String, dynamic>.from(raw);
      final pct = _num(params['percentage'] ?? params['porcentaje']);
      if (pct == null || pct <= 0) return null;
      return pct <= 1 ? (pct * 100).round() : pct.round();
    } catch (_) {
      return null;
    }
  }

  String estadoLabel(String estado) {
    switch (estado.trim().toUpperCase()) {
      case 'AVAILABLE':
        return _t('Disponible', 'Available');
      case 'USED':
        return _t('Usada', 'Used');
      case 'EXPIRED':
        return _t('Expirada', 'Expired');
      default:
        return estado;
    }
  }

  List<String> parseCardParams(String? parametrosJson) {
    if (parametrosJson == null || parametrosJson.isEmpty) {
      return const [];
    }
    try {
      final raw = json.decode(parametrosJson);
      if (raw is! Map) return const [];
      final params = Map<String, dynamic>.from(raw);
      final lines = <String>[];

      final mult = _num(params['sellMultiplier'] ?? params['multiplicadorVenta']);
      if (mult != null && mult > 0) {
        lines.add(_t(
          'Venta por el ${(mult * 100).round()}% del valor',
          'Sell for ${(mult * 100).round()}% of value',
        ));
      }

      final pts = _intVal(params['points'] ?? params['puntos']);
      if (pts != null && pts > 0) {
        lines.add(_t('Suma +$pts puntos', 'Adds +$pts points'));
      }

      final rounds = _intVal(params['rounds'] ?? params['jornadas']);
      if (rounds != null && rounds > 0) {
        lines.add(_t(
          'Protege durante $rounds jornadas',
          'Protects for $rounds matchdays',
        ));
      }

      if (params['seasonLong'] == true || params['temporadaCompleta'] == true) {
        lines.add(_t(
          'Protege hasta final de temporada',
          'Protects until end of season',
        ));
      }

      final pct = _num(params['percentage'] ?? params['porcentaje']);
      if (pct != null && pct > 0) {
        final display = pct <= 1 ? (pct * 100).round() : pct.round();
        lines.add(_t(
          'Sube el valor de mercado de un jugador propio un $display%',
          'Increases a squad player\'s market value by $display%',
        ));
      }

      final maxVal =
          _intVal(params['maxPlayerValue'] ?? params['valorMaximoJugador']);
      if (maxVal != null && maxVal > 0) {
        lines.add(_t(
          'Máximo jugador: ${formatRewardMoney(maxVal)}',
          'Max player: ${formatRewardMoney(maxVal)}',
        ));
      }

      final buyerMult = _num(
        params['buyerMultiplier'] ?? params['multiplicadorComprador'],
      );
      if (buyerMult != null && buyerMult > 0) {
        lines.add(_t(
          'Pagas el ${(buyerMult * 100).round()}%',
          'You pay ${(buyerMult * 100).round()}%',
        ));
      }

      final ownerComp = _num(
        params['ownerCompensationMultiplier'] ??
            params['multiplicadorCompensacionPropietario'],
      );
      if (ownerComp != null && ownerComp > 0) {
        lines.add(_t(
          'El propietario recibe el ${(ownerComp * 100).round()}%',
          'Owner receives ${(ownerComp * 100).round()}%',
        ));
      }

      return lines;
    } catch (_) {
      return const [];
    }
  }

  String get packTapToOpen => _t('TOCA PARA ABRIR', 'TAP TO OPEN');

  String get packOpening => _t('ABRIENDO...', 'OPENING...');

  String get packReward => _t('RECOMPENSA', 'REWARD');

  String get packYourCard => _t('TU CARTA', 'YOUR CARD');

  // ─── Historial de eventos ───

  String rewardEventDescription(RewardEventModel event) {
    if (!_en) {
      return event.descripcion;
    }
    final tipo = event.tipo.trim().toUpperCase();
    final pack = event.packType?.trim();
    final qty = event.cantidad;
    switch (tipo) {
      case 'PACK_OPENED':
        if (pack != null && pack.isNotEmpty) {
          return 'Opened $pack pack${qty != null ? ' (−$qty chips)' : ''}.';
        }
        return qty != null
            ? 'Pack opened (−$qty chips).'
            : 'Pack opened.';
      case 'BUDGET_GRANTED':
        return qty != null
            ? 'Budget reward from pack: +$qty.'
            : 'Budget reward from pack.';
      case 'CARD_OBTAINED':
        return 'Card obtained from pack.';
      case 'CARD_REDEEMED':
        return 'Card redeemed.';
      case 'COACH_ROULETTE_SPIN':
        return qty != null
            ? 'Coach roulette spin (−$qty chips).'
            : 'Coach roulette spin.';
      default:
        return event.descripcion;
    }
  }

  String activityMessage(LeagueActivityEvent event) {
    if (!_en) {
      return event.mensaje;
    }
    final tipo = event.tipo.trim().toUpperCase();
    final nick = event.actorNickname.trim();
    final msg = event.mensaje.trim();

    switch (tipo) {
      case 'ADMIN_KICK':
        final kicked = _parseAdminKickTarget(msg);
        if (kicked != null && nick.isNotEmpty) {
          return '$nick kicked $kicked from the league.';
        }
        return nick.isNotEmpty
            ? '$nick removed a participant from the league.'
            : 'A participant was removed from the league.';
      case 'PACK_OPENED':
        final pack = _parsePackOpened(msg);
        if (pack != null) {
          return '${pack.$1} opened a ${pack.$2} and received ${pack.$3}.';
        }
        return nick.isNotEmpty ? '$nick opened a pack.' : 'Pack opened.';
      case 'COACH_ROULETTE':
      case 'COACH_ROULETTE_SPIN':
        final coach = _parseCoachRoulette(msg);
        if (coach != null) {
          return '${coach.$1} spun the coach roulette and got ${coach.$2}.';
        }
        return nick.isNotEmpty
            ? '$nick used the coach roulette.'
            : 'Coach roulette used.';
      case 'CARD_REDEEMED':
      case 'PLAYER_SOLD_WITH_CARD':
      case 'DIRECT_CLAUSE_EXECUTED':
      case 'PLAYER_PROTECTION_APPLIED':
      case 'LEAGUE_POINTS_BONUS_APPLIED':
      case 'VALUE_RECOVERY_APPLIED':
      case 'VALUE_BOOST_APPLIED':
        final redeemed = _parseCardRedeem(msg);
        if (redeemed != null) {
          return redeemed;
        }
        return nick.isNotEmpty ? '$nick used a reward card.' : 'Reward card used.';
      case 'ROUND_FINISHED':
        return 'Matchday finished.';
      default:
        return msg.isNotEmpty ? msg : 'League activity.';
    }
  }

  (String, String, String)? _parsePackOpened(String msg) {
    final m = RegExp(
      r'^(.+?) abrió un (.+?) y recibió (.+?)\.$',
    ).firstMatch(msg);
    if (m == null) {
      return null;
    }
    return (m.group(1)!, m.group(2)!, m.group(3)!);
  }

  (String, String)? _parseCoachRoulette(String msg) {
    final m = RegExp(
      r'^(.+?) usó la ruleta de entrenador y obtuvo a (.+?)\.$',
    ).firstMatch(msg);
    if (m == null) {
      return null;
    }
    return (m.group(1)!, m.group(2)!);
  }

  String? _parseAdminKickTarget(String msg) {
    final m = RegExp(
      r'^.+? expulsó a (.+?) de la liga\.$',
    ).firstMatch(msg);
    return m?.group(1);
  }

  String? _parseCardRedeem(String msg) {
    final sell = RegExp(
      r'^(.+?) usó (.+?) y vendió a (.+?) por (.+?)\.$',
    ).firstMatch(msg);
    if (sell != null) {
      return '${sell.group(1)} used ${sell.group(2)} and sold ${sell.group(3)} for ${sell.group(4)}.';
    }
    final clause = RegExp(
      r'^(.+?) usó (.+?) y fichó a (.+?) de (.+?) pagando (.+?)\.$',
    ).firstMatch(msg);
    if (clause != null) {
      return '${clause.group(1)} used ${clause.group(2)} and signed ${clause.group(3)} from ${clause.group(4)} for ${clause.group(5)}.';
    }
    final protectUntil = RegExp(
      r'^(.+?) protegió a (.+?) hasta la jornada (\d+)\.$',
    ).firstMatch(msg);
    if (protectUntil != null) {
      return '${protectUntil.group(1)} protected ${protectUntil.group(2)} until matchday ${protectUntil.group(3)}.';
    }
    final protectSeason = RegExp(
      r'^(.+?) protegió a (.+?) toda la temporada\.$',
    ).firstMatch(msg);
    if (protectSeason != null) {
      return '${protectSeason.group(1)} protected ${protectSeason.group(2)} for the whole season.';
    }
    final points = RegExp(
      r'^(.+?) usó (.+?) y sumó \+(\d+) puntos\.$',
    ).firstMatch(msg);
    if (points != null) {
      return '${points.group(1)} used ${points.group(2)} and added +${points.group(3)} points.';
    }
    final boost = RegExp(
      r'^(.+?) subió el valor de mercado de (.+?) un (\d+)%\.$',
    ).firstMatch(msg);
    if (boost != null) {
      return '${boost.group(1)} increased ${boost.group(2)}\'s market value by ${boost.group(3)}%.';
    }
    return null;
  }

  String rewardEventTypeLabel(String tipo) {
    switch (tipo.trim().toUpperCase()) {
      case 'PACK_OPENED':
        return _t('Sobre abierto', 'Pack opened');
      case 'BUDGET_GRANTED':
        return _t('Presupuesto recibido', 'Budget received');
      case 'CARD_OBTAINED':
        return _t('Carta obtenida', 'Card obtained');
      case 'CARD_REDEEMED':
        return _t('Carta usada', 'Card used');
      case 'COACH_ROULETTE_SPIN':
        return coachRouletteTitle;
      case 'PLAYER_SOLD_WITH_CARD':
        return _t('Venta especial', 'Special sale');
      case 'DIRECT_CLAUSE_EXECUTED':
        return filterClause;
      case 'PLAYER_PROTECTION_APPLIED':
        return filterProtection;
      case 'LEAGUE_POINTS_BONUS_APPLIED':
        return _t('Bonus de puntos', 'Points bonus');
      case 'VALUE_RECOVERY_APPLIED':
      case 'VALUE_BOOST_APPLIED':
        return _t('Subida de valor', 'Value boost');
      default:
        return tipo;
    }
  }

  String relativeTime(DateTime local, DateTime now) {
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return _t('ahora', 'now');
    if (diff.inMinutes < 60) {
      return _t('hace ${diff.inMinutes} min', '${diff.inMinutes} min ago');
    }
    if (diff.inHours < 24) {
      return _t('hace ${diff.inHours} h', '${diff.inHours} h ago');
    }
    if (diff.inDays < 7) {
      return _t('hace ${diff.inDays} d', '${diff.inDays} d ago');
    }
    return '';
  }

  // ─── Entrenador ───

  String coachBonusExplanation(RewardCoachItem coach) {
    final bonus = coach.bonusPuntos > 0 ? coach.bonusPuntos : 3;
    final team = (coach.nombreEquipo ?? '').trim();
    if (team.isEmpty) {
      return _t(
        'Si lo activas y alineas jugadores de su equipo con minutos, recibes +$bonus pts por cada uno en tu once.',
        'If you activate them and line up players from their team with minutes, you get +$bonus pts for each in your XI.',
      );
    }
    return _t(
      'Si lo activas y alineas jugadores de $team con minutos, recibes +$bonus pts por cada uno en tu once.',
      'If you activate them and line up $team players with minutes, you get +$bonus pts for each in your XI.',
    );
  }

  String get coachWonTitle =>
      _t('¡Entrenador conseguido!', 'Coach unlocked!');

  String get coachWonHint => _t(
        'Equípalo y actívalo desde Alineación para sumar el bonus en cada jornada.',
        'Assign and activate them from Lineup to earn the bonus each matchday.',
      );

  String get rouletteSingleSpinTitle =>
      _t('Una sola tirada', 'One spin only');

  String get rouletteSingleSpinBody => _t(
        'Solo puedes girar la ruleta una vez por liga. Obtendrás un entrenador libre al azar.',
        'You can only spin the roulette once per league. You will get a random free coach.',
      );

  String get rouletteCostTitle => _t('Coste', 'Cost');

  String rouletteCostBody(String fichas) => _t(
        'Girar cuesta $fichas.',
        'Spinning costs $fichas.',
      );

  String get rouletteFreeCostBody => _t(
        'Girar no tiene coste en fichas.',
        'Spinning costs no chips.',
      );

  String get rouletteBonusTitle =>
      _t('Bonus por alineación', 'Lineup bonus');

  String get rouletteBonusBody => _t(
        'Cada entrenador otorga puntos extra por jugador de su club que alinees en tu once y que juegue minutos. El bonus concreto depende del entrenador que consigas (p. ej. +3 pts por jugador). Actívalo desde Alineación para aplicarlo en la jornada.',
        'Each coach grants extra points for club players you line up in your XI who play minutes. The exact bonus depends on the coach you get (e.g. +3 pts per player). Activate them from Lineup to apply it on matchday.',
      );

  // ─── Canje de cartas ───

  String get unsupportedCardType => _t(
        'Tipo de carta no soportado en la app',
        'Card type not supported in the app',
      );

  String unsupportedCardTypeWithCode(String tipo) =>
      '${unsupportedCardType}: $tipo';

  String valuation(int value) =>
      _t('Valoración: $value', 'Rating: $value');

  String humanizeBlockedReason(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return '';
    final u = t.toUpperCase().replaceAll(' ', '_');
    switch (u) {
      case 'SUPERA_VALOR_MAXIMO_CARTA':
        return _t(
          'Supera el valor máximo de esta carta',
          'Exceeds this card\'s maximum player value',
        );
      case 'JUGADOR_PROTEGIDO':
      case 'PLAYER_PROTECTED':
        return _t('Jugador protegido', 'Protected player');
      case 'PROTECCION_ACTIVA':
        return _t('Protección activa', 'Active protection');
      case 'PROTECCION_IGUAL_O_SUPERIOR':
        return _t(
          'Protección igual o superior activa',
          'Equal or stronger protection active',
        );
      default:
        return '';
    }
  }

  String blockedPlayerMessage(RewardCardTargetPlayer p) {
    final m = humanizeBlockedReason(p.motivoBloqueo);
    if (m.isNotEmpty) return m;
    if (p.protegido == true) return _t('Jugador protegido', 'Protected player');
    return '';
  }

  String? protectionOwnerLine(RewardCardTargetPlayer p) {
    if (p.protegido != true) return null;
    if (p.proteccionHastaFinTemporada == true) {
      return _t('Protegido toda la temporada', 'Protected for the whole season');
    }
    final n = p.numeroJornadaFinProteccion;
    if (n != null) {
      return _t('Protegido hasta la jornada $n', 'Protected until matchday $n');
    }
    return null;
  }

  String valueLabel(String money) => _t('Valor: $money', 'Value: $money');

  String currentValueLabel(String money) =>
      _t('Valor actual: $money', 'Current value: $money');

  String youWillReceive(String money) =>
      _t('Recibirás: $money', 'You will receive: $money');

  String youWillPay(String money) =>
      _t('Pagarás: $money', 'You will pay: $money');

  String costLabel(String money) => _t('Coste: $money', 'Cost: $money');

  String expiresOnMatchday(int n) =>
      _t('Expira en la jornada $n', 'Expires on matchday $n');

  String protectedUntilMatchday(int n) =>
      _t('Protegido hasta la jornada $n', 'Protected until matchday $n');

  String get sell => _t('Vender', 'Sell');

  String get clause => _t('Clausular', 'Trigger clause');

  String get protect => _t('Proteger', 'Protect');

  String get apply => _t('Aplicar', 'Apply');

  String get notAvailable => _t('No disponible', 'Unavailable');

  String get notAvailableToProtect => _t(
        'No disponible para proteger.',
        'Not available to protect.',
      );

  String get choosePlayerToSell => _t(
        'Elige jugador para vender',
        'Choose a player to sell',
      );

  String get noSellTargets => _t(
        'No tienes jugadores disponibles para usar esta carta de venta.',
        'You have no players available for this sale card.',
      );

  String get chooseRivalParticipant => _t(
        'Elige participante rival',
        'Choose rival participant',
      );

  String participantsAvailableBlocked(int available, int blocked) => _t(
        '$available disponibles · $blocked bloqueados',
        '$available available · $blocked blocked',
      );

  String squadOf(String nickname) =>
      _t('Plantilla de $nickname', '$nickname\'s squad');

  String get noClauseTargets => _t(
        'No hay jugadores disponibles para esta cláusula.',
        'No players available for this clause.',
      );

  String get noPlayersForParticipant => _t(
        'Este participante no tiene jugadores disponibles.',
        'This participant has no available players.',
      );

  String get availablePlayers => _t('Disponibles', 'Available');

  String get blockedPlayers => _t('Bloqueados', 'Blocked');

  String get choosePlayerToProtect => _t(
        'Elige jugador a proteger',
        'Choose a player to protect',
      );

  String get noProtectTargets => _t(
        'No tienes jugadores disponibles para proteger.',
        'You have no players available to protect.',
      );

  String get protectUntilSeasonEnd => _t(
        'Esta carta protege hasta final de temporada',
        'This card protects until end of season',
      );

  String protectForRounds(int rounds) => _t(
        'Esta carta protege durante $rounds jornadas',
        'This card protects for $rounds matchdays',
      );

  String get chooseValueBoostPlayer => _t(
        'Elige un jugador de tu plantilla para subir su valor de mercado',
        'Choose a squad player to increase their market value',
      );

  String get noValueBoostTargets => _t(
        'No tienes jugadores en plantilla para usar esta carta.',
        'You have no squad players for this card.',
      );

  String? valueBoostNewValueLine(RewardCardTargetPlayer p) {
    final nuevo = p.valorTemporalEstimado;
    if (nuevo == null || nuevo <= 0) return null;
    return _t(
      'Nuevo valor: ${formatRewardMoneyFull(nuevo)}',
      'New value: ${formatRewardMoneyFull(nuevo)}',
    );
  }

  String? valueBoostPercentLine(RewardCardTargetPlayer p) {
    final pct = p.porcentajeRecuperacion;
    if (pct == null || pct <= 0) return null;
    final display = pct <= 1 ? (pct * 100).round() : pct.round();
    return _t('+$display% sobre el valor actual', '+$display% on current value');
  }

  String addPointsPreview(int preview) => _t(
        'Esta carta sumará +$preview puntos a tu clasificación de liga.',
        'This card will add +$preview points to your league standing.',
      );

  String get addPointsGeneric => _t(
        'Sumará puntos a tu clasificación de esta liga.',
        'Will add points to your league standing.',
      );

  String get sellPlayerTitle => _t('Vender jugador', 'Sell player');

  String sellPlayerConfirm(String name, String amount) => _t(
        'Vas a vender a $name.\nRecibirás $amount.\nEsta acción no se puede deshacer.',
        'You are about to sell $name.\nYou will receive $amount.\nThis action cannot be undone.',
      );

  String get executeClauseTitle => _t('Ejecutar cláusula', 'Execute clause');

  String executeClauseConfirm(String name, String amount) => _t(
        'Vas a clausular a $name.\nPagarás $amount.\nEsta acción no se puede deshacer.',
        'You are about to trigger the clause on $name.\nYou will pay $amount.\nThis action cannot be undone.',
      );

  String get applyProtectionTitle =>
      _t('Aplicar protección', 'Apply protection');

  String applyProtectionConfirm(String name) => _t(
        'Se aplicará protección sobre $name.\nEsta acción no se puede deshacer.',
        'Protection will be applied to $name.\nThis action cannot be undone.',
      );

  String get applyValueBoostTitle =>
      _t('Subir valor de mercado', 'Increase market value');

  String applyValueBoostConfirm(String name) => _t(
        'Se subirá de forma permanente el valor de mercado de $name según el porcentaje de la carta.\nEsta acción no se puede deshacer.',
        'Market value for $name will be permanently increased by the card percentage.\nThis action cannot be undone.',
      );

  String get doneTitle => _t('Listo', 'Done');

  String get saleCompleted => _t('Venta completada', 'Sale completed');

  String playerLabel(String name) => _t('Jugador: $name', 'Player: $name');

  String receivedAmount(String amount) =>
      _t('Has recibido $amount', 'You received $amount');

  String newBudget(String amount) =>
      _t('Nuevo presupuesto: $amount', 'New budget: $amount');

  String get clauseExecuted => _t('Cláusula ejecutada', 'Clause executed');

  String playerNowInSquad(String name) => _t(
        '$name ahora está en tu plantilla.',
        '$name is now in your squad.',
      );

  String get playerAddedToSquad => _t(
        'Jugador añadido a tu plantilla.',
        'Player added to your squad.',
      );

  String paidAmount(String amount) => _t('Pagado: $amount', 'Paid: $amount');

  String yourBudget(String amount) =>
      _t('Tu presupuesto: $amount', 'Your budget: $amount');

  String get playerProtected => _t('Jugador protegido', 'Player protected');

  String get pointsAdded => _t('Puntos añadidos', 'Points added');

  String pointsAddedAmount(int n) => _t('+$n puntos', '+$n points');

  String newTotal(int n) => _t('Nuevo total: $n', 'New total: $n');

  String get valueBoostApplied =>
      _t('Valor de mercado aumentado', 'Market value increased');

  String newMarketValue(String amount) => _t(
        'Nuevo valor de mercado: $amount',
        'New market value: $amount',
      );

  String get operationCompleted =>
      _t('Operación completada', 'Operation completed');

  String get operationCompletedDot =>
      _t('Operación completada.', 'Operation completed.');

  RedeemSuccessMessage redeemSuccessMessage(RewardRedeemResultModel r) {
    final tipo = r.tipoEfecto.toUpperCase();
    final lines = <String>[];

    switch (tipo) {
      case 'SELL_PLAYER_BONUS':
        var title = saleCompleted;
        if (r.nombreJugador != null) lines.add(playerLabel(r.nombreJugador!));
        if (r.cantidadRecibida != null) {
          lines.add(receivedAmount(formatRewardMoneyFull(r.cantidadRecibida!)));
        }
        if (r.nuevoDineroLiga != null) {
          lines.add(newBudget(formatRewardMoneyFull(r.nuevoDineroLiga!)));
        }
        return RedeemSuccessMessage(title, lines);
      case 'DIRECT_CLAUSE':
        var title = clauseExecuted;
        if (r.nombreJugador != null) {
          lines.add(playerNowInSquad(r.nombreJugador!));
        } else {
          lines.add(playerAddedToSquad);
        }
        if (r.pagadoPorAtacante != null) {
          lines.add(paidAmount(formatRewardMoneyFull(r.pagadoPorAtacante!)));
        }
        if (r.nuevoDineroAtacante != null) {
          lines.add(yourBudget(formatRewardMoneyFull(r.nuevoDineroAtacante!)));
        }
        return RedeemSuccessMessage(title, lines);
      case 'PROTECT_PLAYER':
        var title = playerProtected;
        if (r.nombreJugador != null) lines.add(r.nombreJugador!);
        if (r.proteccionHastaFinTemporada == true) {
          lines.add(protectUntilSeasonEnd);
        } else if (r.numeroJornadaFinProteccion != null) {
          lines.add(protectedUntilMatchday(r.numeroJornadaFinProteccion!));
        }
        return RedeemSuccessMessage(title, lines);
      case 'ADD_LEAGUE_POINTS':
        var title = pointsAdded;
        if (r.puntosAnadidos != null) {
          lines.add(pointsAddedAmount(r.puntosAnadidos!));
        }
        if (r.puntosTotalesEfectivos != null) {
          lines.add(newTotal(r.puntosTotalesEfectivos!));
        }
        return RedeemSuccessMessage(title, lines);
      case 'TEMPORARY_VALUE_RECOVERY':
      case 'PLAYER_VALUE_BOOST':
        var title = valueBoostApplied;
        if (r.nombreJugador != null) lines.add(r.nombreJugador!);
        if (r.valorTemporal != null) {
          lines.add(newMarketValue(formatRewardMoneyFull(r.valorTemporal!)));
        }
        if (r.porcentajeRecuperacion != null && r.porcentajeRecuperacion! > 0) {
          final pct = r.porcentajeRecuperacion! <= 1
              ? (r.porcentajeRecuperacion! * 100).round()
              : r.porcentajeRecuperacion!.round();
          lines.add(_t('+$pct% aplicado', '+$pct% applied'));
        }
        return RedeemSuccessMessage(title, lines);
      default:
        return RedeemSuccessMessage(operationCompleted, [operationCompletedDot]);
    }
  }

  num? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  int? _intVal(Object? v) {
    final n = _num(v);
    return n?.toInt();
  }
}

class RedeemSuccessMessage {
  const RedeemSuccessMessage(this.title, this.lines);
  final String title;
  final List<String> lines;
}

extension RewardsL10nContext on BuildContext {
  RewardsL10n get rewardsL10n => RewardsL10n.of(this);
}
