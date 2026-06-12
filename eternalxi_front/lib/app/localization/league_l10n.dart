import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/core/utils/league_money_format.dart';
import 'package:flutter/widgets.dart';

/// Textos de la feature de ligas (es/en).
class LeagueL10n {
  LeagueL10n(this.locale);

  final Locale locale;

  bool get _en => locale.languageCode.toLowerCase().startsWith('en');

  bool get isEnglish => _en;

  static LeagueL10n of(BuildContext context) =>
      LeagueL10n(AppLocalizations.of(context).locale);

  static LeagueL10n fromL10n(AppLocalizations l10n) => LeagueL10n(l10n.locale);

  // —— Clasificación ——
  String get viewLabel => _en ? 'View' : 'Vista';
  String get globalStandings => _en ? 'Overall standings' : 'Clasificación global';
  String matchday(int n) => _en ? 'Matchday $n' : 'Jornada $n';
  String matchdayShort(int n) => 'J${n > 0 ? n : '?'}';
  String get roundStandingsHint => _en
      ? 'Team fantasy points and reward chips received in that matchday.'
      : 'Puntos del equipo y fichas de recompensa recibidas en esa jornada.';
  String get noRoundStandingsData =>
      _en ? 'No data for this matchday.' : 'Sin datos para esta jornada.';
  String get noStandingsYet =>
      _en ? 'No standings yet' : 'Sin clasificación todavía';
  String get noStandingsYetHint => _en
      ? 'When there are participants and points, they will appear here in server order.'
      : 'Cuando haya participantes y puntos, aparecerán aquí en el orden que envíe el servidor.';
  String get noTeamStandingsYet => _en
      ? 'No team standings available yet'
      : 'Todavía no hay clasificación disponible';
  String get teamStandingsTitle =>
      _en ? 'Team standings' : 'Clasificación de equipos';
  String get teamColumn => _en ? 'Team' : 'Equipo';

  // —— Inicio liga ——
  String get topScorers => _en ? 'Top scorers' : 'Mejores goleadores';
  String get topScorersSubtitle => _en
      ? 'Full list of league top scorers.'
      : 'Listado completo de goleadores de la liga.';
  String get topAssists => _en ? 'Top assists' : 'Mejores asistentes';
  String get topAssistsSubtitle => _en
      ? 'Full list of league top assist providers.'
      : 'Listado completo de asistentes de la liga.';
  String get cleanSheets => _en ? 'Clean sheets' : 'Porterías a cero';
  String get cleanSheetsSubtitle => _en
      ? 'Goalkeepers with the most clean sheets.'
      : 'Porteros con más porterías a cero.';
  String get injuredPlayers => _en ? 'Injured' : 'Lesionados';
  String get seeAll => _en ? 'See all' : 'Ver todo';
  String get injuredPlayersSubtitle => _en
      ? 'Active injured players sorted by return date.'
      : 'Jugadores lesionados activos ordenados por vuelta.';
  String get suspendedPlayers => _en ? 'Suspended' : 'Sancionados';
  String get suspendedPlayersSubtitle => _en
      ? 'Active suspended players sorted by return date.'
      : 'Jugadores sancionados activos ordenados por vuelta.';
  String get noMatchesScheduled => _en
      ? 'No matches scheduled for this date.'
      : 'No hay partidos programados para esta fecha.';
  String get noStatsYet =>
      _en ? 'No statistics yet' : 'Aún no hay estadísticas';
  String get noRoundsInResponse => _en
      ? 'No matchdays in the server response.'
      : 'No hay jornadas en la respuesta del servidor.';
  String get noRoundsWithMatches => _en
      ? 'Matchdays exist but no matches with a start time were found, or a matchday failed to load. Refresh and try again.'
      : 'Hay jornadas pero no se encontraron partidos con fecha de inicio (inicioEn) o falló la carga de alguna jornada. Usa actualizar e inténtalo de nuevo.';

  // —— Jornadas / alineaciones ——
  String get noMatchdaysAvailable =>
      _en ? 'No matchdays available' : 'No hay jornadas disponibles';
  String get noMatchdaysHint => _en
      ? 'When the backend has lineups per matchday, they will appear here.'
      : 'Cuando el backend tenga alineaciones por jornada, aparecerán aquí.';
  String get lineupDetailTitle =>
      _en ? 'Lineup detail' : 'Detalle de alineación';
  String get noLineupsForMatch => _en
      ? 'No lineups available for this match yet.'
      : 'Aun no hay alineaciones disponibles para este partido.';
  String get noLineupSaved => _en
      ? 'No saved lineup for this matchday.'
      : 'Sin alineación guardada en esta jornada.';
  String get couldNotLoadLineup => _en
      ? 'Could not load the matchday lineup.'
      : 'No se pudo cargar la alineación de la jornada.';
  String get couldNotLoadRound => _en
      ? 'Could not load matchday'
      : 'No se pudo cargar la jornada';

  // —— Partidos ——
  String get timelineTab => _en ? 'Timeline' : 'Cronología';
  String get lineupsTab => _en ? 'Lineups' : 'Alineaciones';
  String get homeTeam => _en ? 'Home' : 'Local';
  String get awayTeam => _en ? 'Away' : 'Visitante';
  String get kickoffLabel => _en ? 'Kickoff' : 'Inicio';
  String get scheduledKickoffLabel =>
      _en ? 'Scheduled kickoff' : 'Inicio previsto';
  String get liveBadge => _en ? 'LIVE' : 'EN JUEGO';
  String get inPlayLabel => _en ? 'In play' : 'En juego';
  String get finishedLabel => _en ? 'Finished' : 'Finalizado';
  String get matchTitle => _en ? 'Match' : 'Partido';
  String get coachLabel => _en ? 'Coach' : 'Entrenador';
  String get noMatchEventsYet => _en
      ? 'No events for this match yet.'
      : 'Aun no hay eventos para este partido.';
  String get halfTime => _en ? 'Half-time' : 'Descanso';
  String get secondHalfStart =>
      _en ? 'Second half begins' : 'Empieza la segunda parte';
  String get matchEnd => _en ? 'Full time' : 'Final del partido';
  String get matchStart => _en ? 'Kick-off' : 'Inicio del partido';
  String get genericEvent => _en ? 'Event' : 'Evento';
  String get noPriceChange => _en ? 'No change' : 'Sin cambio';
  String get todayChip => _en ? 'Today' : 'Hoy';
  String get matchPhaseScheduled => _en ? 'Scheduled' : 'Programado';
  String get matchPhaseLive => _en ? 'In play' : 'En juego';
  String get matchPhaseFinished => _en ? 'Finished' : 'Finalizado';
  String get starterProbUnknown => _en ? 'Not calculated' : 'Sin calcular';
  String get starterProbVeryLikely => _en ? 'Very likely' : 'Muy probable';
  String get starterProbLikely => _en ? 'Likely' : 'Probable';
  String get starterProbDoubt => _en ? 'Doubtful' : 'Duda';
  String get starterProbUnlikely => _en ? 'Unlikely' : 'Poco probable';
  String get starterProbUnavailable => _en ? 'Unavailable' : 'No disponible';
  String matchesOnDate(String date) => _en ? 'Matches · $date' : 'Partidos · $date';

  // —— Estadísticas jugador ——
  String get statMinutes => _en ? 'Minutes' : 'Minutos';
  String get statMinutesPlayed =>
      _en ? 'Minutes played' : 'Minutos jugados';
  String get statGoals => _en ? 'Goals' : 'Goles';
  String get statAssists => _en ? 'Assists' : 'Asistencias';
  String get statYellowCards =>
      _en ? 'Yellow cards' : 'Tarjetas amarillas';
  String get statRedCards => _en ? 'Red cards' : 'Tarjetas rojas';
  String get statNewspaperRating =>
      _en ? 'Newspaper rating' : 'Nota del periódico';
  String get statGoalsConceded =>
      _en ? 'Goals conceded' : 'Goles encajados';
  String get statCleanSheet => _en ? 'Clean sheet' : 'Portería a cero';
  String get statInjuredInMatch =>
      _en ? 'Injured in match' : 'Lesionado en partido';
  String get statSaves => _en ? 'Saves' : 'Paradas';
  String get statDribbles => _en ? 'Dribbles' : 'Regates';
  String get statBallsRecovered =>
      _en ? 'Balls recovered' : 'Balones recuperados';
  String get statPoints => _en ? 'Points' : 'Puntos';

  // —— Perfil jugador / mercado ——
  String get playerTitle => _en ? 'Player' : 'Jugador';
  String get sellPlayer => _en ? 'Sell player' : 'Vender jugador';
  String get buyPlayer => _en ? 'Buy player' : 'Comprar jugador';
  String get sell => _en ? 'Sell' : 'Vender';
  String get buy => _en ? 'Buy' : 'Comprar';
  String get makeOffer => _en ? 'Make offer' : 'Hacer oferta';
  String get buyX2 => _en ? 'Buy x2' : 'Comprar x2';
  String offersCount(int n) => _en ? 'Offers ($n)' : 'Ofertas ($n)';
  String get sellToLeague => _en ? 'Sell to league' : 'Vender a la liga';
  String get ownerLabel => _en ? 'Owner' : 'Propietario';
  String ownerNamed(String name) =>
      _en ? 'Owner: $name' : 'Propietario: $name';
  String get positionLabel => _en ? 'Position' : 'Posición';
  String get valuationLabel => _en ? 'Rating' : 'Valoración';
  String get currentValueLabel => _en ? 'Current value' : 'Valor actual';
  String get fatigueLabel => _en ? 'Fatigue' : 'Cansancio';
  String get suspended => _en ? 'Suspended' : 'Sancionado';
  String get injured => _en ? 'Injured' : 'Lesionado';
  String get protectedSeason =>
      _en ? 'Protected for season' : 'Protegido temporada';
  String protectedUntilMatchday(int n) =>
      _en ? 'Protected until MD$n' : 'Protegido hasta J$n';
  String get protectedGeneric => _en ? 'Protected' : 'Protegido';
  String get noPendingOffers =>
      _en ? 'No pending offers.' : 'No hay ofertas pendientes.';
  String get reject => _en ? 'Reject' : 'Rechazar';
  String get accept => _en ? 'Accept' : 'Aceptar';
  String get offerAccepted => _en ? 'Offer accepted.' : 'Oferta aceptada.';
  String get offerRejected => _en ? 'Offer rejected.' : 'Oferta rechazada.';
  String get noOffersPendingSnack =>
      _en ? 'You have no pending offers.' : 'No tienes ofertas pendientes.';
  String get cannotOfferOwnPlayer => _en
      ? 'You cannot make an offer on your own player.'
      : 'No puedes hacer una oferta por tu propio jugador.';
  String get resolvingPlayerStatus => _en
      ? 'Still resolving the player\'s real status. Try again.'
      : 'Aún se está resolviendo el estado real del jugador. Inténtalo de nuevo.';
  String get seeTeam => _en ? 'View team' : 'Ver equipo';
  String seeTeamNamed(String name) =>
      _en ? 'View team · $name' : 'Ver equipo · $name';
  String get noDateAvailable =>
      _en ? 'No date available' : 'Sin fecha disponible';
  String availableForMatchday(int n) => _en
      ? 'Available for matchday $n'
      : 'Disponible para la jornada $n';
  String availableOn(String date) =>
      _en ? 'Available on $date' : 'Disponible el $date';
  String get noMatchdayAvailable =>
      _en ? 'No matchday available' : 'Sin jornada disponible';
  String get noReturnDate =>
      _en ? 'No return date' : 'Sin fecha de vuelta';
  String get currentOwner => _en ? 'Current owner' : 'Dueño actual';
  String get yourCurrentOffer =>
      _en ? 'Your current offer' : 'Tu oferta actual';
  String get availableBalance =>
      _en ? 'Available balance' : 'Saldo disponible';
  String get yourOffer => _en ? 'Your offer' : 'Tu oferta';
  String get offerSentTitle => _en ? 'Offer sent' : 'Oferta enviada';
  String get offerSentBody => _en
      ? 'Your offer has been sent. You will be notified when the owner responds.'
      : 'Tu oferta ha sido enviada. Te avisaremos cuando el dueño responda.';
  String get offerUpdated =>
      _en ? 'Offer updated successfully.' : 'Oferta actualizada correctamente.';
  String get cannotOfferOwnSnack => _en
      ? 'You cannot send an offer for your own player.'
      : 'No puedes enviar oferta por un jugador tuyo.';
  String get updateOffer => _en ? 'Update offer' : 'Actualizar oferta';
  String get activeOfferExistsTitle => _en
      ? 'You already have an active offer'
      : 'Ya tienes una oferta activa';
  String activeOfferExistsBody(String amount) => _en
      ? 'You already have a pending offer of $amount for this player. You can only update or cancel it.'
      : 'Ya tienes una oferta pendiente de $amount por este jugador. Solo puedes actualizarla o anularla.';
  String sellInstantBody(String amount) => _en
      ? 'This sells instantly at 90% of current value.\n\nEstimated payout: $amount'
      : 'Esta operación vende instantáneamente al 90% del valor actual.\n\nCobro estimado: $amount';
  String buyDirectBody(String amount) => _en
      ? 'Direct purchase for $amount (2× current value).'
      : 'Se realizará la compra directa por $amount (2x del valor actual).';
  String buyDirectDetailedBody(String price, String currentValue) => _en
      ? 'Direct purchase for $price (2× current value $currentValue).'
      : 'Se realizará la compra directa por $price (2× el valor actual $currentValue).';
  String saleCompleted(String amount) =>
      _en ? 'Sold for $amount.' : 'Venta realizada por $amount.';
  String purchaseCompleted(String amount, String balance) => _en
      ? 'Purchased for $amount. New balance: $balance.'
      : 'Compra por $amount. Nuevo saldo: $balance.';
  String get couldNotLoadPlayerDetail => _en
      ? 'Could not resolve league, user or player to load details.'
      : 'No se pudo resolver liga, usuario o jugador para cargar el detalle.';
  String get couldNotOpenFantasyDetail => _en
      ? 'Could not open fantasy detail for this player.'
      : 'No se pudo abrir el detalle fantasy para este jugador.';
  String get couldNotResolveParticipant => _en
      ? 'Could not resolve your participant in this league.'
      : 'No se pudo resolver tu participante en esta liga.';
  String get couldNotResolveLeagueContext => _en
      ? 'Could not resolve the league context.'
      : 'No se pudo resolver el contexto de la liga.';
  String get couldNotLoadLeagueContext => _en
      ? 'Could not load the league context.'
      : 'No se pudo cargar el contexto de la liga.';
  String get genericPlayer => _en ? 'Player' : 'Jugador';
  String get genericUser => _en ? 'User' : 'Usuario';

  // —— Plantilla / alineación ——
  String get substitute => _en ? 'Substitute' : 'Suplente';
  String get substitutesLabel => _en ? 'Substitutes' : 'Suplentes';
  String substitutePick(String role) => _en
      ? 'Pick a substitute for $role (one per position).'
      : 'Elige un suplente para $role (solo uno por posición).';
  String substituteChange(String role) => _en
      ? 'Change $role substitute or swap with a starter.'
      : 'Cambiar suplente de $role o intercambiar con un titular.';
  String get removeSubstitute =>
      _en ? 'Remove substitute' : 'Quitar suplente';
  String get noCoach => _en ? 'No coach' : 'Sin entrenador';
  String get coach => _en ? 'Coach' : 'Entrenador';
  String get starterLabel => _en ? 'Starter' : 'Titular';
  String get autoFill => _en ? 'Auto-fill' : 'Completar';
  String get loadingCoaches =>
      _en ? 'Loading coaches…' : 'Cargando entrenadores…';
  String get equipped => _en ? 'Equipped' : 'Equipado';
  String get selectCoachForMatchday => _en
      ? 'Choose how you want to play this matchday.'
      : 'Selecciona cómo quieres jugar esta jornada.';

  // —— Ajustes liga ——
  String get configuration => _en ? 'Settings' : 'Configuración';
  String get invitationCodeTitle =>
      _en ? 'Invitation code' : 'Código de invitación';
  String get participants => _en ? 'Participants' : 'Participantes';
  String get administration => _en ? 'Administration' : 'Administración';
  String get delegateAdmin =>
      _en ? 'Delegate admin' : 'Delegar administrador';
  String get closeLeague => _en ? 'Close league' : 'Cerrar liga';
  String get yourParticipation =>
      _en ? 'Your participation' : 'Tu participación';
  String get leaveLeague => _en ? 'Leave league' : 'Salir de la liga';
  String get leaveLeagueUnavailable =>
      _en ? 'Leave league (unavailable)' : 'Salir de la liga (no disponible)';
  String get cannotLeaveLeagueTitle =>
      _en ? 'You cannot leave the league' : 'No puedes abandonar la liga';
  String get confirmLeaveTitle =>
      _en ? 'Confirm leaving' : 'Confirmar salida';
  String get cedeAndLeave => _en ? 'Transfer and leave' : 'Ceder y salir';
  String get currentAdmin =>
      _en ? 'Current administrator' : 'Administrador actual';
  String get youLabel => _en ? 'You' : 'Tú';
  String get kickTooltip => _en ? 'Remove' : 'Expulsar';
  String get participantExpelled =>
      _en ? 'Participant removed' : 'Participante expulsado';
  String delegateAdminConfirm(String nick) => _en
      ? 'Delegate league administration to $nick?'
      : '¿Delegar la administración de la liga a $nick?';
  String kickParticipantConfirm(String nick) => _en
      ? 'Remove $nick from the league?'
      : '¿Expulsar a $nick?';
  String get kickParticipantTitle =>
      _en ? 'Remove participant' : 'Expulsar participante';
  String get leaveLeagueConfirmTitle =>
      _en ? 'Leave league' : 'Salir de la liga';

  // —— Mercado ——
  String get teamListTitle =>
      _en ? 'Team list' : 'Listado de equipos';
  String get marketHistoryTitle =>
      _en ? 'League history' : 'Historial de liga';
  String get marketPoolName => _en ? 'Market' : 'Mercado';

  String marketHistoryFilterLabel(String key) {
    switch (key.trim().toUpperCase()) {
      case 'ALL':
        return _en ? 'All' : 'Todo';
      case 'ADJUDICACION_MERCADO':
        return _en ? 'Auction' : 'Subasta';
      case 'COMPRA_DIRECTA_DOBLE':
        return _en ? 'Buy x2' : 'Compra x2';
      case 'ACUERDO_USUARIOS':
        return _en ? 'Transfers' : 'Traspasos';
      case 'VENTA_MERCADO':
        return _en ? 'Sales' : 'Ventas';
      case 'ADMIN_KICK':
        return _en ? 'Expulsions' : 'Expulsiones';
      default:
        return key;
    }
  }

  String marketHistoryTypeTitle(String rawType) {
    switch (rawType.trim().toUpperCase()) {
      case 'ADJUDICACION_MERCADO':
        return _en ? 'Awarded bid' : 'Adjudicación';
      case 'COMPRA_DIRECTA_DOBLE':
        return _en ? 'Direct buy' : 'Compra directa';
      case 'ACUERDO_USUARIOS':
        return _en ? 'Deal' : 'Acuerdo';
      case 'VENTA_MERCADO':
        return _en ? 'Sold to market' : 'Venta al mercado';
      case 'ADMIN_KICK':
        return _en ? 'Expulsion' : 'Expulsión';
      default:
        return _en ? 'Market activity' : 'Movimiento de mercado';
    }
  }

  String marketHistoryDescription({
    required String tipo,
    required int idUsuarioComprador,
    required String compradorNombre,
    required int? idUsuarioVendedor,
    required String? vendedorNombre,
    required String jugadorNombre,
    required int precio,
  }) {
    final buyer = _marketHistoryParticipantName(
      idUsuarioComprador,
      compradorNombre,
    );
    final seller = vendedorNombre == null
        ? null
        : _marketHistoryParticipantName(
            idUsuarioVendedor ?? 0,
            vendedorNombre,
          );
    final player = jugadorNombre.trim().isEmpty
        ? (_en ? 'Player' : 'Jugador')
        : jugadorNombre.trim();
    final price = LeagueMoneyFormat.money(precio.toDouble());

    switch (tipo.trim().toUpperCase()) {
      case 'ADJUDICACION_MERCADO':
        return _en
            ? '$buyer won $player from the market for $price'
            : '$buyer se ha llevado del mercado a $player por $price';
      case 'COMPRA_DIRECTA_DOBLE':
        return _en
            ? '$buyer bought $player from the market at double price for $price'
            : '$buyer se ha llevado a $player del mercado pagando el doble por $price';
      case 'ACUERDO_USUARIOS':
        final s = seller ?? (_en ? 'another manager' : 'otro manager');
        return _en
            ? '$buyer reached a deal with $s for $player for $price'
            : '$buyer ha llegado a un acuerdo con $s por $player por $price';
      case 'VENTA_MERCADO':
        final v = seller ?? marketPoolName;
        return _en
            ? '$v sold $player to the market for $price'
            : '$v ha vendido a $player al mercado por $price';
      default:
        return _en
            ? '$buyer · $player · $price'
            : '$buyer · $player · $price';
    }
  }

  String marketHistoryTimestamp(DateTime? value) {
    if (value == null) {
      return _en ? 'Date unavailable' : 'Fecha no disponible';
    }
    final d = value.toLocal();
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    if (diff == 0) {
      return _en ? 'Today · $hh:$mm' : 'Hoy · $hh:$mm';
    }
    if (diff == 1) {
      return _en ? 'Yesterday · $hh:$mm' : 'Ayer · $hh:$mm';
    }
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return '$dd/$mo/${d.year} · $hh:$mm';
  }

  String _marketHistoryParticipantName(int id, String name) {
    final trimmed = name.trim();
    if (id == 1 ||
        trimmed.toLowerCase() == 'mercado' ||
        trimmed.toLowerCase() == 'market') {
      return marketPoolName;
    }
    if (trimmed.isEmpty) {
      return _en ? 'User $id' : 'Usuario $id';
    }
    return trimmed;
  }

  String get deleteBid => _en ? 'Remove bid' : 'Eliminar puja';
  String get totalBids => _en ? 'Total bids' : 'Pujas totales';
  String get offersTab => _en ? 'Offers' : 'Ofertas';

  // —— Config liga ——
  String get leagueParticipantsTitle =>
      _en ? 'League participants' : 'Participantes de la liga';
  String get leagueParticipantsSubtitle => _en
      ? 'Fantasy managers (not real calendar teams).'
      : 'Managers fantasy (no equipos del calendario real).';
  String get signingWeekTitle =>
      _en ? 'Pre-season signing week' : 'Semana previa de fichajes';
  String get signingWeekSubtitle => _en
      ? 'If enabled, the first matchday is delayed one week for transfers.'
      : 'Si está activa, la primera jornada se retrasa una semana para fichar.';
  String get midweekMatchdaysTitle =>
      _en ? 'Add midweek matchdays' : 'Añadir jornadas entre semana';
  String get midweekMatchdaysSubtitle => _en
      ? 'There will also be Tuesday and Wednesday matchdays to finish sooner.'
      : 'también habrá jornadas martes y miércoles para que termine antes.';
  String get leagueFormat => _en ? 'League format' : 'Formato de liga';
  String get roundTrip => _en ? 'Home and away' : 'Ida y vuelta';
  String get singleLeg => _en ? 'Single round' : 'Solo ida';
  String get minRewardPerMatchday =>
      _en ? 'Minimum reward per matchday' : 'Recompensa mínima por jornada';
  String get moneyPerFantasyPoint =>
      _en ? 'Money per fantasy point' : 'Dinero por punto fantasy';
  String get configParticipants => _en ? 'Participants' : 'Participantes';
  String get configCalendar => _en ? 'Calendar' : 'Calendario';
  String get configFormat => _en ? 'Format' : 'Formato';
  String get configSigningWeek =>
      _en ? 'Pre-season signing week' : 'Semana previa de fichajes';
  String get configMatchdayReward =>
      _en ? 'Matchday reward' : 'Recompensa jornada';
  String get configMoney => _en ? 'Money' : 'Dinero';
  String get calendarWeekendsOnly =>
      _en ? 'weekends only' : 'fines de semana';
  String get calendarWithMidweek => _en
      ? 'weekends + Tue/Wed'
      : 'fines de semana + martes/miércoles';
  String minRewardPts(int pts) => _en
      ? 'Min. $pts chips (last place)'
      : 'Mín. $pts fichas (último puesto)';
  String rewardDistributionPreview(String first, String second, int min) =>
      _en
          ? '$first, $second, …, $min chips/matchday'
          : '$first, $second, …, $min fichas/jornada';
  String perPoint(String amount) => _en ? '$amount/point' : '$amount/punto';
  String leagueStartAt(String dateTime) => dateTime;
  String get yesWord => _en ? 'Yes' : 'Sí';
  String get noWord => _en ? 'No' : 'No';

  // —— Inicio liga (extra) ——
  String get leagueSummaryTitle =>
      _en ? 'League summary' : 'Resumen de liga';
  String get noInjuredCurrently =>
      _en ? 'No injured players currently' : 'No hay lesionados actualmente';
  String get noSuspendedCurrently => _en
      ? 'No suspended players currently'
      : 'No hay sancionados actualmente';
  String get assistsShort => _en ? 'Ast.' : 'Asist.';
  String get cleanSheetsShort => _en ? 'CS' : 'PC';
  String seeTeamColon(String name) =>
      _en ? 'View team: $name' : 'Ver equipo: $name';

  // —— Ajustes liga (extra) ——
  String get leaveLeagueBody => _en
      ? 'You will leave this league. You can only rejoin with a new invitation.'
      : 'Dejarás de participar en esta liga. Podrás volver a unirte solo con una nueva invitación.';
  String get leaveButton => _en ? 'Leave' : 'Salir';
  String get understood => _en ? 'Got it' : 'Entendido';
  String get cannotLeaveOnlyParticipantBody => _en
      ? 'You are the only participant. There is no one to delegate administration to. '
          'To leave, close the league first using the administration button.'
      : 'Eres el único participante. No hay a quien delegar la administración. '
          'Para salir, primero cierra la liga con el botón de administración.';
  String get noOtherParticipantsToDelegate => _en
      ? 'There are no other participants to delegate to. Refresh or close the league.'
      : 'No hay otros participantes para delegar. Actualiza o cierra la liga.';
  String leaveAfterDelegateBody(String nick) => _en
      ? 'We will first delegate administration to $nick and then you will leave the league. This cannot be undone from the app.'
      : 'Primero delegaremos la administración a $nick y después saldrás de la liga. Esta acción no se puede deshacer desde la app.';
  String get cannotCloseLeagueWithParticipants => _en
      ? 'You cannot close the league while there are other participants. Delegate the administrator before leaving.'
      : 'No puedes cerrar la liga mientras haya más participantes. Delega el administrador antes de salir.';
  String get closeLeagueBody => _en
      ? 'The league will be closed for everyone. All squads will be dissolved: players return to the market and coaches become available again. This cannot be undone.'
      : 'La liga se cerrará para todos. Se disolverán las plantillas: los jugadores volverán al mercado y los entrenadores quedarán otra vez disponibles. Esta acción no se puede deshacer.';
  String get noParticipantsToDelegateAdmin => _en
      ? 'No participants available to delegate the administrator.'
      : 'No hay participantes disponibles para delegar el administrador.';
  String get delegateAction => _en ? 'Delegate' : 'Delegar';
  String get kickAction => _en ? 'Remove' : 'Expulsar';
  String get newAdminTitle =>
      _en ? 'New administrator' : 'Nuevo administrador';
  String get newAdminSubtitle => _en
      ? 'Choose who receives the administrator role. You will confirm leaving next.'
      : 'Elige a quién cedes el rol de administrador. Después confirmarás la salida.';
  String get closeLeagueHint => _en
      ? 'Everyone will lose access. Use this when the competition is over.'
      : 'Todos perderán el acceso. Usa esta opción cuando la competición haya terminado.';
  String get adminAloneCannotLeaveHint => _en
      ? 'You are the only member: you cannot leave without delegating. '
          'Use «Close league» under Administration to finish.'
      : 'Eres el único miembro: no puedes abandonar la liga sin delegar. '
          'Usa «Cerrar liga» en Administración para finalizar.';
  String get adminLeaveParticipationHint => _en
      ? 'You will leave after choosing who to delegate administration to.'
      : 'Saldrás de la liga tras elegir a quién delegar la administración.';
  String get memberLeaveParticipationHint => _en
      ? 'You will no longer see this league in your list until you join again.'
      : 'Dejarás de ver esta liga en tu listado hasta que vuelvas a unirte.';
  String get noParticipantsInResponse => _en
      ? 'No participants in the server response.'
      : 'No hay participantes en la respuesta del servidor.';
  String get administratorBadge =>
      _en ? 'Administrator' : 'Administrador';
  String administratorNamed(String name) =>
      _en ? 'Administrator: $name' : 'Administrador: $name';
  String get leagueConfigSummaryTitle =>
      _en ? 'League settings' : 'Configuración de la liga';
  String participantsCount(int n) =>
      _en ? '$n participants' : '$n participantes';
  String get seasonLabel => _en ? 'Season' : 'Temporada';
  String get noSessionWithRoute => _en
      ? 'No user in session. Log in or pass idUsuario in the route.'
      : 'No hay usuario en sesión. Inicia sesión o pasa idUsuario en la ruta.';
  String get metricPoints => _en ? 'Points' : 'Puntos';
  String get metricMoney => _en ? 'Money' : 'Dinero';
  String get metricTeamValue => _en ? 'Squad value' : 'Valor equipo';
  String get hasPendingOfferTooltip => _en
      ? 'Has a pending offer'
      : 'Tiene una oferta pendiente';

  // —— Plantilla (extra) ——
  String get couldNotLoadLineupTitle =>
      _en ? 'Could not load lineup' : 'No se pudo cargar la alineación';
  String get emptySquadTitle => _en ? 'Empty squad' : 'Plantilla vacía';
  String get emptySquadBody => _en
      ? 'You have no players assigned in this league yet, or the server returned an empty list.'
      : 'Aún no tienes jugadores asignados en esta liga o el servidor devolvió una lista vacía.';
  String get noMorePlayersForRole => _en
      ? 'No more players available for this position'
      : 'No hay más jugadores disponibles para esta demarcación';
  String get noPlayersForRole => _en
      ? 'No players available for this position'
      : 'No hay jugadores disponibles para esta demarcación';

  // —— Mercado (extra) ——
  String get noPlayersToday =>
      _en ? 'No players today' : 'Sin jugadores hoy';
  String get noPlayersAvailableYet => _en
      ? 'No players available yet.'
      : 'Aún no hay jugadores disponibles.';
  String playersCount(int n) => _en ? '$n players' : '$n jugadores';
  String get noPlayersInLeague =>
      _en ? 'No players in the league' : 'Sin jugadores en la liga';
  String get emptyGlobalMarketList => _en
      ? 'The global listing returned no rows for this league.'
      : 'El listado global no devolvió filas para esta liga.';
  String get youAreOwnerAlready =>
      _en ? 'You already own this player' : 'Eres el dueño';
  String get deleteAction => _en ? 'Delete' : 'Eliminar';
  String get deleteBidConfirmBody => _en
      ? 'Are you sure you want to remove your bid? The held funds will return to your available balance.'
      : '¿Seguro que quieres eliminar tu puja? El dinero retenido '
          'volverá a tu saldo disponible.';
  String get deleteBidBodyShort => _en
      ? 'Your bid will be removed and the held balance will become available again.'
      : 'Se eliminará tu puja y el saldo retenido volverá a estar disponible.';
  String get tieBreakHint => _en
      ? 'If two users bid the same amount, the older bid wins.'
      : 'Si dos usuarios pujan lo mismo, gana la puja más antigua.';
  String get bidAmountLabel =>
      _en ? 'Bid amount' : 'Importe de la puja';
  String get confirmBid => _en ? 'Confirm bid' : 'Confirmar puja';
  String get bidForPlayer => _en ? 'Bid for player' : 'Pujar por jugador';
  String get updateBid => _en ? 'Update bid' : 'Actualizar puja';
  String get yourCurrentBid =>
      _en ? 'Your current bid' : 'Tu puja actual';
  String get bidMustBePositiveInteger => _en
      ? 'The amount must be a positive integer.'
      : 'El importe debe ser un entero positivo.';
  String bidBelowMinimum(String min) => _en
      ? 'The bid cannot be below the minimum allowed ($min).'
      : 'La puja no puede ser inferior al minimo permitido ($min).';
  String maxBidError(String max) => _en
      ? 'Based on your balance and current bid, the maximum you can bid is $max.'
      : 'Según tu saldo y tu puja actual, el máximo que puedes pujar '
          'es $max.';
  String get historySubtitleGeneric => _en
      ? 'Recent movements and events in the league'
      : 'Movimientos y eventos recientes de la liga';
  String historySubtitleNamed(String name) => _en
      ? 'Recent movements and events in $name'
      : 'Movimientos y eventos recientes de $name';
  String get noMovementsForFilter => _en
      ? 'No movements for this filter yet.'
      : 'Aún no hay movimientos para este filtro.';
  String get offerAmountLabel =>
      _en ? 'Offer amount' : 'Cantidad ofertada';
  String get indicateAmount =>
      _en ? 'Enter an amount.' : 'Indica un importe.';
  String get amountMustBePositive => _en
      ? 'The amount must be greater than 0.'
      : 'El importe debe ser mayor que 0.';
  String get goBack => _en ? 'Go back' : 'Volver';
  String get cancelOfferConfirmBody => _en
      ? 'Are you sure you want to cancel your offer? The held funds will return to your available balance.'
      : '¿Seguro que quieres cancelar tu oferta? El dinero retenido '
          'volverá a tu saldo disponible.';
  String get confirmOffer =>
      _en ? 'Confirm offer' : 'Confirmar oferta';
  String get sendOfferButton =>
      _en ? 'Send offer' : 'Enviar oferta';
  String get offerCancelledSuccess =>
      _en ? 'Offer cancelled successfully.' : 'Oferta cancelada correctamente.';
  String minOfferError(String min) => _en
      ? 'The minimum offer for this player is $min.'
      : 'La oferta mínima por este jugador es $min.';
  String maxOfferError(String max) => _en
      ? 'Based on your balance and current offer, the maximum you can offer is $max.'
      : 'Según tu saldo y tu oferta actual, el máximo que puedes ofertar '
          'es $max.';
  String get offerRegisteredBody => _en
      ? 'Your offer was registered. You can update or cancel it in '
          'Market → Offers tab (if you have pending offers).'
      : 'Tu oferta quedó registrada. Puedes actualizarla o cancelarla en '
          'Mercado → pestaña Ofertas (si tienes ofertas pendientes).';
  String get cancelOfferTooltip =>
      _en ? 'Cancel offer' : 'Cancelar oferta';
  String get protectedLabel => _en ? 'Protected' : 'Protegido';
  String get noRoundsForPlayerDetail => _en
      ? 'This player has no matchdays available in the server detail yet.'
      : 'Este jugador aún no tiene jornadas disponibles en el detalle del servidor.';

  // —— Partidos (extra) ——
  String get invalidMatchIdError => _en
      ? 'Cannot load match: invalid identifier.'
      : 'No se puede cargar el partido: identificador no válido.';
  String get couldNotLoadMatchInfo => _en
      ? 'Could not load match information.'
      : 'No se pudo cargar la información del partido.';
  String get genericTeam => _en ? 'Team' : 'Equipo';

  // —— Config creación liga ——
  String get advancedConfigSubtitle => _en
      ? 'Participants, calendar, rewards and league economy.'
      : 'Participantes, calendario, recompensas y economía de la liga.';
  String get signingWeekSubtitleFull => _en
      ? 'If enabled, the first matchday is delayed one week for transfers. '
          'If not, the league starts in the first available block.'
      : 'Si está activa, la primera jornada se retrasa una semana para fichar. '
          'Si no, la liga empieza en el primer bloque disponible.';
  String get midweekMatchdaysSubtitleFull => _en
      ? 'The league always plays on weekends. If you enable this option, '
          'there will also be Tuesday and Wednesday matchdays to finish sooner.'
      : 'La liga siempre jugará los fines de semana. Si activas esta opción, '
          'también habrá jornadas martes y miércoles para que termine antes.';
  String minRewardSliderSubtitle(int step, int min, int max) => _en
      ? 'Last place receives this minimum; +$step chips for each rank above ($min–$max chips).'
      : 'Último puesto recibe este mínimo; +$step fichas por cada puesto que subes '
          '($min–$max fichas).';
  String rewardDistributionWithParticipants(int count, String preview) =>
      _en ? 'With $count participants: $preview' : 'Con $count participantes: $preview';
  String createLeagueParticipantsSummary(int count, String calendar, String format) =>
      _en ? '$count participants · $calendar · $format' : '$count participantes · $calendar · $format';

  // —— Alineaciones historial ——
  String get noBenchInLineup => _en
      ? 'No substitutes in this lineup.'
      : 'No hay reservas en esta alineación.';
  String playerPointsBreakdown(double v) => _en
      ? 'Player points (formation): ${v.toStringAsFixed(1)}'
      : 'Puntos jugadores (formación): ${v.toStringAsFixed(1)}';
  String fantasyGapPenalty(double v) => _en
      ? 'Fantasy gap penalty: ${v.toStringAsFixed(1)}'
      : 'Penalización huecos fantasy: ${v.toStringAsFixed(1)}';
  String get benchPointsHint => _en
      ? 'Bench points that count in fantasy when replacing starters.'
      : 'Puntos del banquillo que sí cuentan en el fantasy por sustituir '
          'titulares.';

  // —— Catálogo ——
  String get noCatalogPlayers => _en
      ? 'This team has no players in the catalog.'
      : 'Este equipo no tiene jugadores en catálogo.';

  String get notificationsTitle =>
      _en ? 'Notifications' : 'Notificaciones';
  String get markAllNotificationsRead =>
      _en ? 'Mark all read' : 'Marcar todas leídas';
  String get notificationsEmpty => _en
      ? 'You have no notifications yet.'
      : 'Aún no tienes notificaciones.';
  String get notificationViewAction =>
      _en ? 'View' : 'Ver';

  String get receivedOffersTitle =>
      _en ? 'Received offers' : 'Ofertas recibidas';
  String get leagueDataTitle =>
      _en ? 'League data' : 'Datos en liga';
  String get loadingHistoryFromServer => _en
      ? 'Loading history from server...'
      : 'Cargando historial desde el servidor...';

  // —— Historial alineaciones ——
  String get lineupHistoryTitle =>
      _en ? 'Lineup history' : 'Historial de alineaciones';
  String get roundHistoryByMatchdays =>
      _en ? 'Matchday history' : 'Historial por jornadas';
  String get couldNotLoadHistoryTitle =>
      _en ? 'Could not load history' : 'No se pudo cargar el historial';
  String get participantFallback =>
      _en ? 'Participant' : 'Participante';
  String get startersLabel => _en ? 'Starters' : 'Titulares';
  String get reservesLabel => _en ? 'Substitutes' : 'Reservas';
  String get benchLabel => _en ? 'Bench' : 'Banquillo';
  String get roundPending => _en ? 'Pending' : 'Pendiente';
  String get roundInProgress => _en ? 'In progress' : 'En curso';

  String get roundInProgressMatchday =>
      _en ? 'Matchday in progress' : 'Jornada en curso';
  String get roundFinished => _en ? 'Finished' : 'Finalizada';
  String get serverBreakdownReference => _en
      ? 'Breakdown (server reference)'
      : 'Desglose (referencia del servidor)';
  String coachPointsBreakdown(double v) => _en
      ? 'Coach points (fantasy): ${v.toStringAsFixed(1)}'
      : 'Puntos entrenador (fantasy): ${v.toStringAsFixed(1)}';
  String get starterNoPointsHint => _en
      ? 'Starter with no fantasy points this matchday: bench substitute counts.'
      : 'Titular sin puntos fantasy en esta jornada: cuentan los del '
          'suplente de tu banquillo.';
  String get starterSubstitutionHint => _en
      ? 'Bench points that count in fantasy when replacing the starter.'
      : 'Puntos del banquillo que sí cuentan en el fantasy por sustituir '
          'al titular.';

  String starterProbabilityBandLabel(int? p) {
    if (p == null) {
      return starterProbUnknown;
    }
    if (p >= 80) {
      return starterProbVeryLikely;
    }
    if (p >= 50) {
      return starterProbLikely;
    }
    if (p >= 25) {
      return starterProbDoubt;
    }
    if (p >= 1) {
      return starterProbUnlikely;
    }
    return starterProbUnavailable;
  }

  String statLabel(String key) {
    switch (key) {
      case 'minutes':
      case 'minutos':
        return statMinutes;
      case 'minutesPlayed':
        return statMinutesPlayed;
      case 'goals':
      case 'goles':
        return statGoals;
      case 'assists':
      case 'asistencias':
        return statAssists;
      case 'yellowCards':
        return statYellowCards;
      case 'redCards':
        return statRedCards;
      case 'newspaperRating':
        return statNewspaperRating;
      case 'goalsConceded':
        return statGoalsConceded;
      case 'cleanSheet':
        return statCleanSheet;
      case 'injuredInMatch':
        return statInjuredInMatch;
      case 'saves':
        return statSaves;
      case 'dribbles':
        return statDribbles;
      case 'ballsRecovered':
        return statBallsRecovered;
      case 'points':
        return statPoints;
      default:
        return key;
    }
  }
}

extension LeagueL10nBuildContext on BuildContext {
  LeagueL10n get leagueL10n => LeagueL10n.of(this);
}
