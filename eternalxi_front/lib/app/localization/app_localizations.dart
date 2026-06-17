import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('es'), Locale('en')];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    if (localizations == null) {
      return AppLocalizations(const Locale('es'));
    }
    return localizations;
  }

  static Locale localeResolutionCallback(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale == null) {
      return const Locale('es');
    }
    final code = locale.languageCode.toLowerCase();
    for (final item in supportedLocales) {
      if (item.languageCode == code) {
        return item;
      }
    }
    return const Locale('es');
  }

  static const _values = <String, Map<String, String>>{
    'es': {
      'appTitle': 'Eternal XI',
      'loading': 'Cargando...',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'saving': 'Guardando...',
      'retry': 'Reintentar',
      'continue': 'Continuar',
      'close': 'Cerrar',
      'copy': 'Copiar',
      'share': 'Compartir',
      'understand': 'Entendido',
      'delete': 'Eliminar',
      'confirm': 'Confirmar',
      'update': 'Actualizar',
      'join': 'Unirse',
      'create': 'Crear',
      'edit': 'Editar',
      'search': 'Buscar',
      'send': 'Enviar',
      'next': 'Siguiente',
      'back': 'Volver',
      'yes': 'Sí',
      'no': 'No',
      'emptyStateDash': '—',
      'history': 'Historial',
      'lineup': 'Alineación',
      'squad': 'Plantilla',
      'captain': 'Capitán',
      'home': 'Inicio',
      'standings': 'Tabla',
      'market': 'Mercado',
      'transfers': 'Traspasos',
      'settings': 'Ajustes',
      'login': 'Iniciar sesión',
      'register': 'Crear cuenta',
      'email': 'Correo electrónico',
      'password': 'Contraseña',
      'currentPassword': 'Contraseña actual',
      'newPassword': 'Nueva contraseña',
      'repeatPassword': 'Repetir contraseña',
      'nickname': 'Nickname',
      'verificationCode': 'Código de verificación',
      'requestCode': 'Solicitar código',
      'sendCode': 'Enviar código',
      'confirmAndContinue': 'Confirmar y continuar',
      'savePassword': 'Guardar contraseña',
      'forgotPassword': 'He olvidado la contraseña',
      'alreadyHaveAccount': 'Ya tengo cuenta',
      'backToLogin': 'Volver al inicio de sesión',
      'createAccount': 'Crear cuenta',
      'loginTitle': 'Entrar',
      'loginSubtitle':
          'Accede a tu cuenta, gestiona ligas y plantilla con el mismo estilo en toda la app.',
      'modeSelectionSubtitle': 'Elige cómo quieres jugar hoy.',
      'modeFantasyTitle': 'Fantasy',
      'modeFantasyDescription':
          'Ligas privadas, mercado, alineaciones y recompensas con tus amigos.',
      'modeFantasyEnter': 'Entrar a Fantasy',
      'modeClashTitle': 'Clash',
      'modeClashDescription':
          'Historia, cartas y batallas. Colecciona jugadores y compite en partidos 7vs7.',
      'modeClashEnter': 'Entrar a Clash',
      'clashPlaceholderTitle': 'Eternal XI Clash',
      'clashPlaceholderBody':
          'Próximamente: modo de historia, colección de cartas y batallas. Estamos preparando la experiencia.',
      'backToModeSelection': 'Cambiar modo',
      'clashTabHome': 'Inicio',
      'clashTabTeam': 'Equipo',
      'clashTabSummon': 'Invocar',
      'clashTabShop': 'Tienda',
      'clashEnergy': 'Energía',
      'clashCoins': 'Monedas',
      'clashGems': 'Gemas',
      'clashComingSoon': 'Disponible en una próxima actualización.',
      'clashHomeTitle': 'Eternal XI Clash',
      'clashHomeMainAccess': 'Accesos principales',
      'clashHomeStory': 'Historia',
      'clashHomeEvents': 'Eventos',
      'clashHomeChallenges': 'Desafíos',
      'clashHomeNews': 'Noticias',
      'clashHomeProtagonistSquad': 'Equipo Eternal XI',
      'clashHomeProtagonistHint':
          'Vista provisional del equipo protagonista. La composición real llegará con la colección.',
      'clashTeamLineup7': 'Alineación 7vs7',
      'clashTeamLineup11': 'Alineación 11vs11',
      'clashTeamCharacters': 'Personajes',
      'clashTeamUpgrade': 'Mejorar',
      'clashTeamSkillTree': 'Árbol de habilidades',
      'clashSummonBanners': 'Banners',
      'clashSummonSingle': 'Single',
      'clashSummonMulti': 'Multi',
      'clashSummonHistory': 'Historial',
      'clashSummonRates': 'Probabilidades',
      'clashShopGame': 'Tienda del juego',
      'clashShopEvent': 'Tienda de eventos',
      'clashShopExchange': 'Intercambio',
      'clashShopGems': 'Gemas',
      'clashShopPacks': 'Packs',
      'clashBack': 'Volver',
      'clashCollectionTitle': 'Personajes',
      'clashSearchHint': 'Buscar por nombre',
      'clashFilterAll': 'Todos',
      'clashFilterRarity': 'Rareza',
      'clashFilterPosition': 'Posición',
      'clashFilterStyle': 'Estilo',
      'clashSortLabel': 'Orden',
      'clashSortPower': 'Potencia',
      'clashSortLevel': 'Nivel',
      'clashSortName': 'Nombre',
      'clashSortDirection': 'Invertir orden',
      'clashCollectionEmpty': 'No hay cartas con estos filtros.',
      'clashCollectionLoadError': 'No se pudo cargar la colección.',
      'clashCardNotFound': 'Carta no encontrada.',
      'clashCardTeam': 'Equipo',
      'clashCardPosition': 'Posición',
      'clashCardStyle': 'Estilo',
      'clashCardLevel': 'Nivel',
      'clashCardPower': 'Potencia',
      'clashCardStats': 'Estadísticas',
      'clashStatSave': 'Parada',
      'clashStatDefense': 'Defensa',
      'clashStatPass': 'Pase',
      'clashStatDribble': 'Regate',
      'clashStatShot': 'Tiro',
      'clashStatPt': 'PT',
      'clashStatStamina': 'Resistencia',
      'clashTechniqueSection': 'Supertécnica',
      'clashTechniqueType': 'Tipo',
      'clashTechniquePower': 'Potencia',
      'clashTechniquePtCost': 'Coste PT',
      'clashTechniqueLevel': 'Nivel',
      'clashActionUpgrade': 'Mejorar',
      'clashActionEvolve': 'Evolución',
      'clashActionTree': 'Árbol',
      'clashLineupSlotEmpty': 'Vacío',
      'clashLineupTotalPower': 'Potencia total',
      'clashLineupComplete': 'Alineación completa',
      'clashLineupIncomplete': 'Alineación incompleta',
      'clashLineupMissingTitle': 'Posiciones pendientes:',
      'clashLineupSetActive': 'Establecer como activa',
      'clashLineupRenameTitle': 'Renombrar alineación',
      'clashLineupRenameHint': 'Nombre de la alineación',
      'clashLineupRenameSave': 'Guardar',
      'clashLineupLoadError': 'No se pudieron cargar las alineaciones.',
      'clashLineupClearSlot': 'Quitar carta',
      'clashLineupNoCompatibleCards':
          'No hay cartas compatibles para esta posición.',
      'clashLineupBlockWrongPosition': 'Posición incompatible',
      'clashLineupBlockDuplicatePlayer': 'Jugador ya en la alineación',
      'clashStoryLoadError': 'No se pudo cargar la historia.',
      'clashStoryTypeStory': 'Historia',
      'clashStoryTypeMatch': 'Partido',
      'clashStoryTypeMixed': 'Mixto',
      'clashStoryStatusLocked': 'Bloqueado',
      'clashStoryStatusAvailable': 'Disponible',
      'clashStoryStatusCompleted': 'Completado',
      'clashStorySkipScene': 'Omitir',
      'clashStoryNextScene': 'Siguiente',
      'clashStoryFinishLevel': 'Finalizar nivel',
      'clashStoryRewardTitle': 'Nivel completado',
      'clashStoryBackToMap': 'Volver al mapa',
      'clashStoryNextLevel': 'Siguiente nivel',
      'clashStoryTeamFormed': 'Equipo Eternal XI formado',
      'clashStoryCardsReceived': 'Cartas N recibidas',
      'clashStoryLevelBlockedTitle': 'Nivel bloqueado',
      'clashStoryLevelBlockedBody':
          'Completa los niveles anteriores para desbloquear este capítulo.',
      'clashStoryGateTeam': 'Completa el prólogo para formar Eternal XI.',
      'clashStoryGateSummon': 'Disponible tras formar Eternal XI.',
      'clashStoryGateEvents': 'Disponible después del prólogo.',
      'clashMatchPrepareType': 'Tipo',
      'clashMatchPrepareEnergy': 'Coste de energía',
      'clashMatchPrepareRecommendedPower': 'Potencia recomendada',
      'clashMatchPrepareLineupPower': 'Potencia de tu alineación',
      'clashMatchPrepareLineupComplete': 'Alineación activa completa',
      'clashMatchPrepareLineupIncomplete': 'Alineación activa incompleta',
      'clashMatchPreparePowerWarning':
          'Tu potencia está por debajo de la recomendada. Puedes jugar igualmente.',
      'clashMatchPrepareEditLineup': 'Editar alineación',
      'clashMatchPrepareStart': 'Comenzar partido',
      'clashMatchScoreLabel': '{user} - {rival}',
      'clashMatchWinTarget': 'Objetivo: primero a 3 goles',
      'clashMatchPhaseLabel': 'Fase',
      'clashMatchPhaseCoinToss': 'Sorteo inicial',
      'clashMatchPhasePlaying': 'En juego',
      'clashMatchPhaseHalftime': 'Descanso',
      'clashMatchPhaseFinished': 'Finalizado',
      'clashMatchCoinTossPrompt': 'Elige cara o cruz para el saque inicial',
      'clashMatchCoinHeads': 'Cara',
      'clashMatchCoinTails': 'Cruz',
      'clashMatchCoinResult': 'Resultado: {outcome}. Saca: {kickoff}',
      'clashMatchKickoffUser': 'Eternal XI',
      'clashMatchKickoffRival': 'Rival',
      'clashMatchPossessionUser': 'Posesión: Eternal XI',
      'clashMatchPossessionRival': 'Posesión: Rival',
      'clashMatchBallHolder': 'Balón: {player}',
      'clashMatchVictory': '¡Victoria!',
      'clashMatchDefeat': 'Derrota',
      'clashMatchViewRewards': 'Ver recompensas',
      'clashMatchDevGoalsHint':
          'Botones provisionales (tutorial/dev) — no son el gameplay final',
      'clashMatchDevGoalUser': 'Gol Eternal XI (provisional)',
      'clashMatchDevGoalRival': 'Gol Rival (provisional)',
      'clashMatchActionPass': 'Pasar',
      'clashMatchActionAdvance': 'Avanzar',
      'clashMatchActionShootSoon': 'Tirar (próximamente)',
      'clashMatchActionShoot': 'Tirar',
      'clashMatchActionShootNeedArea': 'Llega al área para tirar',
      'clashMatchActionRivalSim': 'Simular acción rival',
      'clashMatchZoneLabel': 'Zona del balón',
      'clashMatchStaminaLabel': 'Resistencia',
      'clashMatchPtStaminaLabel':
          'PT {currentPt}/{maxPt} · Resistencia {currentStamina}/{maxStamina}',
      'clashMatchHalftimeTitle': 'Descanso',
      'clashMatchHalftimeSquadTitle': 'Tu equipo',
      'clashMatchHalftimeItemsTitle': 'Objetos de partido',
      'clashMatchHalftimeContinue': 'Continuar partido',
      'clashMatchHalftimeCancel': 'Cancelar',
      'clashMatchHalftimeApplyItem': 'Usar objeto',
      'clashMatchHalftimeSelectPlayers': 'Elige hasta {count} jugadores',
      'clashMatchHalftimePtLabel': 'PT {current}/{max}',
      'clashMatchHalftimeStaminaLabel': 'RES {current}/{max}',
      'clashMatchHalftimeItemQty': 'x{qty}',
      'clashMatchHalftimeItemEffect': '+{amount} · hasta {targets} jug.',
      'clashMatchPressureLabel': 'Presión',
      'clashMatchRiskLabel': 'Riesgo de posesión',
      'clashMatchEventLogTitle': 'Últimos eventos',
      'clashMatchPassSheetTitle': 'Elegir compañero',
      'clashMatchPassSheetEmpty': 'No hay compañeros disponibles',
      'clashMatchPassPercent': '{percent}%',
      'clashMatchPassOptionPower': 'Potencia {power}',
      'clashMatchAdvanceChance': 'Probabilidad de avance: {percent}%',
      'clashMatchDuelTitle': 'Duelo',
      'clashMatchDuelNormalDribble': 'Regate normal',
      'clashMatchDuelEffectiveDribble': 'Regate efectivo',
      'clashMatchDuelEffectiveDefense': 'Defensa efectiva',
      'clashMatchDuelStyleAdvantage': 'Ventaja de estilo',
      'clashMatchDuelStyleDisadvantage': 'Desventaja de estilo',
      'clashMatchDuelStyleNeutral': 'Estilo neutral',
      'clashMatchDuelSuperTechniques': 'Supertécnicas',
      'clashMatchDuelTechniqueMeta':
          '{type} · {style} · Potencia {power} · Coste {cost} PT · Nivel {level}',
      'clashMatchDuelCurrentPt': 'PT actuales: {pt}',
      'clashMatchDuelInsufficientPt': 'PT insuficientes',
      'clashMatchDuelTechniqueUsed': 'Atacante: {name} (−{pt} PT)',
      'clashMatchDuelDefenderTechnique': 'Defensor: {name} (−{pt} PT)',
      'clashMatchDuelContinue': 'Continuar',
      'clashMatchDuelScore': 'Marcador del duelo: {attacker} — {defender}',
      'clashMatchDuelCoinTie': 'Empate resuelto por moneda',
      'clashMatchShotDuelTitle': 'Duelo de tiro',
      'clashMatchDuelNormalShot': 'Tiro normal',
      'clashMatchDuelEffectiveShot': 'Tiro efectivo',
      'clashMatchDuelEffectiveSave': 'Parada efectiva',
      'clashMatchDuelGoal': '¡GOL!',
      'clashMatchDuelSave': 'PARADA',
      'clashMatchDevSectionTitle': 'Herramientas dev/provisional',
      'registerTitle': 'Crear cuenta',
      'registerSubtitle':
          'Únete a Eternal XI. Usa un correo válido y un nickname que te represente en las ligas.',
      'birthDateLabel': 'Fecha de nacimiento',
      'birthDateHint': 'Selecciona tu fecha de nacimiento',
      'acceptTermsLabel':
          'Acepto los Términos de servicio y la Política de privacidad',
      'confirmMinAgeLabel': 'Confirmo que tengo al menos 13 años',
      'legalTermsTitle': 'Términos de servicio',
      'legalCommunityTitle': 'Normas de la comunidad',
      'legalPrivacyTitle': 'Privacidad y menores',
      'legalTermsLink': 'Términos de servicio',
      'legalCommunityLink': 'Normas de la comunidad',
      'legalPrivacyLink': 'Política de privacidad',
      'legalSectionTitle': 'Legal y seguridad',
      'ageConfirmationTitle': 'Confirma tu edad',
      'chatSafetyBanner':
          'Sé respetuoso. Puedes reportar mensajes y bloquear usuarios manteniendo pulsado un mensaje.',
      'chatReport': 'Reportar mensaje',
      'chatBlockUser': 'Bloquear usuario',
      'chatReportSent': 'Mensaje reportado. Lo revisaremos lo antes posible.',
      'chatUserBlocked': 'Usuario bloqueado. Ya no verás sus mensajes.',
      'chatReportConfirm':
          '¿Quieres reportar este mensaje por contenido inapropiado?',
      'chatBlockConfirm':
          '¿Quieres bloquear a este usuario? Dejarás de ver sus mensajes en el chat.',
      'validatorRequiredBirthDate': 'La fecha de nacimiento es obligatoria',
      'validatorUnderMinAge':
          'Debes tener al menos 13 años para usar Eternal XI',
      'validatorAcceptTermsRequired':
          'Debes aceptar los términos y la política de privacidad',
      'validatorConfirmMinAgeRequired':
          'Debes confirmar que cumples la edad mínima',
      'requestPasswordTitle': 'Recuperar contraseña',
      'requestPasswordSubtitle':
          'Te enviaremos un código al correo asociado a tu cuenta para definir una nueva contraseña.',
      'confirmPasswordTitle': 'Nueva contraseña',
      'confirmPasswordSubtitle':
          'Introduce el código recibido por correo y elige una contraseña segura.',
      'verifyEmailTitle': 'Verificar correo',
      'verifyEmailSubtitle':
          'Recibirás un código por email para continuar con el registro de forma segura.',
      'confirmCodeTitle': 'Confirmar código',
      'confirmCodeSubtitle':
          'Revisa tu bandeja de entrada e introduce el código que te hemos enviado.',
      'verifyEmailInvalidCode': 'Código no válido',
      'changeEmail': 'Cambiar correo',
      'requestEmailChange': 'Solicitar cambio de correo',
      'confirmEmailChange': 'Confirmar nuevo correo',
      'newEmail': 'Nuevo correo',
      'currentEmail': 'Correo actual',
      'sendCodeToNewEmail': 'Enviar código al nuevo correo',
      'confirmChange': 'Confirmar cambio',
      'showPassword': 'Mostrar contraseña',
      'hidePassword': 'Ocultar contraseña',
      'myLeagues': 'Mis ligas',
      'leaguesTab': 'Ligas',
      'achievementsTab': 'Logros',
      'joinLeague': 'Unirse a una liga',
      'createLeague': 'Crear liga',
      'leagueName': 'Nombre de la liga',
      'invitationCode': 'Código de invitación',
      'invitationHint': 'Ej. ABCD34XZ',
      'joinLeagueDescription':
          'Introduce el código que te ha compartido el administrador de la liga.',
      'noLeaguesYet': 'Aún no tienes ligas',
      'createOrJoinLeagueHint':
          'Crea una liga o únete con un código usando los iconos arriba a la derecha.',
      'noUserSession': 'No hay sesión de usuario',
      'noUserSessionHint':
          'Inicia sesión para ver tus ligas. Si ya iniciaste sesión, vuelve atrás e inténtalo de nuevo.',
      'league': 'Liga',
      'leagueInvalidId': 'Identificador de liga no válido.',
      'leagueContextError': 'No se pudo resolver el contexto de la liga.',
      'retryLoad': 'Reintentar',
      'budget': 'Tu presupuesto',
      'seasonUnavailable': 'No hay temporadas disponibles.',
      'advancedConfig': 'Configuración avanzada',
      'profile': 'Perfil',
      'accountData': 'Datos de la cuenta',
      'profileTokens': 'Recompensas',
      'logout': 'Cerrar sesión',
      'deleteAccount': 'Eliminar cuenta',
      'deleteAccountConfirmTitle': 'Eliminar cuenta',
      'deleteAccountConfirmBody':
          'Esta acción eliminará tu cuenta y los datos asociados (perfil, ligas fantasy, plantillas, mercado y progreso). No podrás recuperarla.\n\nTe enviaremos un correo con un código para confirmar tu identidad.',
      'deleteAccountRequestEmail': 'Enviar correo de confirmación',
      'confirmAccountDeletionTitle': 'Confirmar eliminación',
      'confirmAccountDeletionHint':
          'Introduce el código que te hemos enviado por correo. También puedes usar el enlace del email.',
      'accountDeletionCodeLabel': 'Código de confirmación',
      'accountDeletionCodeInvalid': 'Introduce el código recibido por correo',
      'confirmAccountDeletionAction': 'Eliminar mi cuenta',
      'accountDeletedSuccess': 'Cuenta eliminada correctamente',
      'accountDeletionRequestFailed':
          'No se pudo solicitar la eliminación de la cuenta',
      'changeEmailHint':
          'Por seguridad confirmamos tu identidad y enviamos un código al correo actual y otro al nuevo antes de aplicar el cambio.',
      'sendVerificationCodes': 'Enviar códigos de verificación',
      'confirmEmailChangeHint':
          'Introduce el código recibido en cada correo para confirmar el cambio.',
      'verificationCodeNewEmail': 'Código del nuevo correo',
      'verificationCodeCurrentEmail': 'Código del correo actual',
      'changeNickname': 'Cambiar nickname',
      'changeNicknameHint':
          'Por seguridad confirmamos tu identidad con la contraseña y un código enviado a tu correo.',
      'confirmNicknameChange': 'Confirmar nuevo nickname',
      'newNickname': 'Nuevo nickname',
      'currentNickname': 'Nickname actual',
      'sendNicknameVerificationCode': 'Enviar código de verificación',
      'verificationCodeSentToEmail':
          'Hemos enviado un código a tu correo. Introdúcelo para confirmar el nickname:',
      'verificationCodeSentTo': 'Introduce el código que hemos enviado a:',
      'achievements': 'Logros',
      'achievementsLoadError': 'No se pudieron cargar los logros',
      'achievementsFromCache':
          'Mostrando logros guardados en el dispositivo. Conéctate para actualizar.',
      'achievementsUnlockedSummary': '{unlocked} de {total} logros conseguidos',
      'achievementsHowToGet': 'Cómo conseguirlo',
      'achievementProgress': 'Progreso: {current}/{target}',
      'achievementRewardXp': 'Recompensa: +{xp} XP',
      'rewards': 'Recompensas',
      'leagueRewards': 'Recompensas de liga',
      'cancelOffer': 'Cancelar oferta',
      'unsavedLineupTitle': 'Alineación sin guardar',
      'unsavedLineupBody':
          'Tienes cambios sin guardar en tu alineación. ¿Qué quieres hacer?',
      'exitWithoutSaving': 'Salir sin guardar',
      'stayHere': 'Quedarme',
      'lineupSaved': 'Alineación guardada',
      'lineupLoadError': 'No se pudo cargar la alineación',
      'lineupIncomplete': 'Completa la alineación antes de guardar.',
      'lineupNeedStarterForCaptain':
          'Añade al menos un titular para elegir capitán.',
      'lineupNeedStarterToSave':
          'Añade al menos un titular para poder guardar.',
      'apiConnectionError':
          'No se pudo conectar con el servidor. Verifica backend y red.',
      'apiNetworkError':
          'Error de red. Revisa tu conexión y vuelve a intentar.',
      'apiCommunicationError': 'Error de comunicación con el servidor.',
      'apiUnexpectedError': 'Ocurrió un error inesperado.',
      'apiAmountMustBeInteger': 'El importe debe ser un número entero.',
      'apiInsufficientFunds': 'No tienes suficiente dinero.',
      'apiForbidden': 'No tienes permiso para hacer esta acción.',
      'apiEmailUnavailable':
          'No se puede enviar el correo ahora. Contacta con soporte o inténtalo más tarde.',
      'apiInternalError': 'Ha ocurrido un error. Inténtalo de nuevo.',
      'validatorRequiredEmail': 'El correo es obligatorio',
      'validatorEmailMaxLength': 'Máximo 190 caracteres',
      'validatorInvalidEmail': 'Correo inválido',
      'validatorRequiredPassword': 'La contraseña es obligatoria',
      'validatorPasswordMinLength': 'Mínimo 8 caracteres',
      'validatorPasswordMaxLength': 'Máximo 128 caracteres',
      'validatorRequiredNickname': 'El nickname es obligatorio',
      'validatorNicknameNoSpaces': 'El nickname no puede contener espacios',
      'validatorNicknameMinLength': 'Mínimo 3 caracteres',
      'validatorNicknameMaxLength': 'Máximo 24 caracteres',
      'validatorNicknameInvalidChars':
          'Solo letras, números, guiones, puntos y guiones bajos',
      'validatorConfirmPasswordRequired': 'Confirma la contraseña',
      'validatorPasswordsDontMatch': 'Las contraseñas no coinciden',
      'validatorRequiredCode': 'El código es obligatorio',
      'validatorRequiredLeagueName': 'El nombre de la liga es obligatorio',
      'validatorLeagueNameMinLength': 'Mínimo 3 caracteres',
      'validatorLeagueNameMaxLength': 'Máximo 50 caracteres',
      'validatorRequiredInvitationCode': 'Introduce el código de invitación',
      'validatorInvitationCodeMaxLength': 'Máximo 20 caracteres',
      'validatorCurrentPasswordRequired': 'Introduce tu contraseña actual',
      'validatorCodeSixChars': 'Introduce el código de 6 caracteres',
      'preferencesTitle': 'Preferencias',
      'themeModeLabel': 'Tema',
      'languageLabel': 'Idioma',
      'systemOption': 'Sistema',
      'lightOption': 'Claro',
      'darkOption': 'Oscuro',
      'spanishOption': 'Español',
      'englishOption': 'Inglés',
      'preferencesUpdated': 'Preferencias actualizadas',
      'preferencesLoadError': 'No se pudieron cargar las preferencias',
      'preferencesSaveError': 'No se pudieron guardar las preferencias',
      'savingPreferences': 'Guardando preferencias...',
      'chat': 'Chat',
      'chatComingSoon':
          'El chat de liga llegará pronto. Habla con tus rivales y celebra tus goles.',
      'chatHint': 'Escribe un mensaje a la liga...',
      'chatDismissKeyboard': 'Ocultar teclado',
      'chatEmpty': 'Sé el primero en escribir en el chat de la liga.',
      'chatYou': 'Tú',
      'chatSystemAuthor': 'Sistema',
      'chatSeedRivalAuthor': 'Rival_XI',
      'chatSeedRivalMessage': '¿Quién se lleva la jornada?',
      'chatLeagueFallback': 'Liga',
    },
    'en': {
      'appTitle': 'Eternal XI',
      'loading': 'Loading...',
      'cancel': 'Cancel',
      'save': 'Save',
      'saving': 'Saving...',
      'retry': 'Retry',
      'continue': 'Continue',
      'close': 'Close',
      'copy': 'Copy',
      'share': 'Share',
      'understand': 'Understood',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'update': 'Update',
      'join': 'Join',
      'create': 'Create',
      'edit': 'Edit',
      'search': 'Search',
      'send': 'Send',
      'next': 'Next',
      'back': 'Back',
      'yes': 'Yes',
      'no': 'No',
      'emptyStateDash': '-',
      'history': 'History',
      'lineup': 'Lineup',
      'squad': 'Squad',
      'captain': 'Captain',
      'home': 'Home',
      'standings': 'Standings',
      'market': 'Market',
      'transfers': 'Transfers',
      'settings': 'Settings',
      'login': 'Log in',
      'register': 'Create account',
      'email': 'Email',
      'password': 'Password',
      'currentPassword': 'Current password',
      'newPassword': 'New password',
      'repeatPassword': 'Repeat password',
      'nickname': 'Nickname',
      'verificationCode': 'Verification code',
      'requestCode': 'Request code',
      'sendCode': 'Send code',
      'confirmAndContinue': 'Confirm and continue',
      'savePassword': 'Save password',
      'forgotPassword': 'I forgot my password',
      'alreadyHaveAccount': 'I already have an account',
      'backToLogin': 'Back to login',
      'createAccount': 'Create account',
      'loginTitle': 'Sign in',
      'loginSubtitle':
          'Access your account, manage leagues and squad with the same style across the app.',
      'modeSelectionSubtitle': 'Choose how you want to play today.',
      'modeFantasyTitle': 'Fantasy',
      'modeFantasyDescription':
          'Private leagues, market, lineups and rewards with your friends.',
      'modeFantasyEnter': 'Enter Fantasy',
      'modeClashTitle': 'Clash',
      'modeClashDescription':
          'Story, cards and battles. Collect players and compete in 7v7 matches.',
      'modeClashEnter': 'Enter Clash',
      'clashPlaceholderTitle': 'Eternal XI Clash',
      'clashPlaceholderBody':
          'Coming soon: story mode, card collection and battles. We are building the experience.',
      'backToModeSelection': 'Change mode',
      'clashTabHome': 'Home',
      'clashTabTeam': 'Team',
      'clashTabSummon': 'Summon',
      'clashTabShop': 'Shop',
      'clashEnergy': 'Energy',
      'clashCoins': 'Coins',
      'clashGems': 'Gems',
      'clashComingSoon': 'Available in a future update.',
      'clashHomeTitle': 'Eternal XI Clash',
      'clashHomeMainAccess': 'Main access',
      'clashHomeStory': 'Story',
      'clashHomeEvents': 'Events',
      'clashHomeChallenges': 'Challenges',
      'clashHomeNews': 'News',
      'clashHomeProtagonistSquad': 'Eternal XI Squad',
      'clashHomeProtagonistHint':
          'Provisional view of the protagonist squad. The real roster arrives with collection.',
      'clashTeamLineup7': '7v7 lineup',
      'clashTeamLineup11': '11v11 lineup',
      'clashTeamCharacters': 'Characters',
      'clashTeamUpgrade': 'Upgrade',
      'clashTeamSkillTree': 'Skill tree',
      'clashSummonBanners': 'Banners',
      'clashSummonSingle': 'Single',
      'clashSummonMulti': 'Multi',
      'clashSummonHistory': 'History',
      'clashSummonRates': 'Rates',
      'clashShopGame': 'Game shop',
      'clashShopEvent': 'Event shop',
      'clashShopExchange': 'Exchange',
      'clashShopGems': 'Gems',
      'clashShopPacks': 'Packs',
      'clashBack': 'Back',
      'clashCollectionTitle': 'Characters',
      'clashSearchHint': 'Search by name',
      'clashFilterAll': 'All',
      'clashFilterRarity': 'Rarity',
      'clashFilterPosition': 'Position',
      'clashFilterStyle': 'Style',
      'clashSortLabel': 'Sort',
      'clashSortPower': 'Power',
      'clashSortLevel': 'Level',
      'clashSortName': 'Name',
      'clashSortDirection': 'Toggle sort direction',
      'clashCollectionEmpty': 'No cards match these filters.',
      'clashCollectionLoadError': 'Could not load the collection.',
      'clashCardNotFound': 'Card not found.',
      'clashCardTeam': 'Team',
      'clashCardPosition': 'Position',
      'clashCardStyle': 'Style',
      'clashCardLevel': 'Level',
      'clashCardPower': 'Power',
      'clashCardStats': 'Stats',
      'clashStatSave': 'Save',
      'clashStatDefense': 'Defense',
      'clashStatPass': 'Pass',
      'clashStatDribble': 'Dribble',
      'clashStatShot': 'Shot',
      'clashStatPt': 'TP',
      'clashStatStamina': 'Stamina',
      'clashTechniqueSection': 'Super technique',
      'clashTechniqueType': 'Type',
      'clashTechniquePower': 'Power',
      'clashTechniquePtCost': 'TP cost',
      'clashTechniqueLevel': 'Level',
      'clashActionUpgrade': 'Upgrade',
      'clashActionEvolve': 'Evolution',
      'clashActionTree': 'Tree',
      'clashLineupSlotEmpty': 'Empty',
      'clashLineupTotalPower': 'Total power',
      'clashLineupComplete': 'Lineup complete',
      'clashLineupIncomplete': 'Lineup incomplete',
      'clashLineupMissingTitle': 'Missing positions:',
      'clashLineupSetActive': 'Set as active',
      'clashLineupRenameTitle': 'Rename lineup',
      'clashLineupRenameHint': 'Lineup name',
      'clashLineupRenameSave': 'Save',
      'clashLineupLoadError': 'Could not load lineups.',
      'clashLineupClearSlot': 'Remove card',
      'clashLineupNoCompatibleCards': 'No compatible cards for this position.',
      'clashLineupBlockWrongPosition': 'Incompatible position',
      'clashLineupBlockDuplicatePlayer': 'Player already in lineup',
      'clashStoryLoadError': 'Could not load story.',
      'clashStoryTypeStory': 'Story',
      'clashStoryTypeMatch': 'Match',
      'clashStoryTypeMixed': 'Mixed',
      'clashStoryStatusLocked': 'Locked',
      'clashStoryStatusAvailable': 'Available',
      'clashStoryStatusCompleted': 'Completed',
      'clashStorySkipScene': 'Skip',
      'clashStoryNextScene': 'Next',
      'clashStoryFinishLevel': 'Finish level',
      'clashStoryRewardTitle': 'Level complete',
      'clashStoryBackToMap': 'Back to map',
      'clashStoryNextLevel': 'Next level',
      'clashStoryTeamFormed': 'Eternal XI team formed',
      'clashStoryCardsReceived': 'N cards received',
      'clashStoryLevelBlockedTitle': 'Level locked',
      'clashStoryLevelBlockedBody':
          'Complete previous levels to unlock this chapter.',
      'clashStoryGateTeam': 'Complete the prologue to form Eternal XI.',
      'clashStoryGateSummon': 'Available after forming Eternal XI.',
      'clashStoryGateEvents': 'Available after the prologue.',
      'clashMatchPrepareType': 'Type',
      'clashMatchPrepareEnergy': 'Energy cost',
      'clashMatchPrepareRecommendedPower': 'Recommended power',
      'clashMatchPrepareLineupPower': 'Your lineup power',
      'clashMatchPrepareLineupComplete': 'Active lineup complete',
      'clashMatchPrepareLineupIncomplete': 'Active lineup incomplete',
      'clashMatchPreparePowerWarning':
          'Your power is below the recommended value. You can still play.',
      'clashMatchPrepareEditLineup': 'Edit lineup',
      'clashMatchPrepareStart': 'Start match',
      'clashMatchScoreLabel': '{user} - {rival}',
      'clashMatchWinTarget': 'Goal: first to 3',
      'clashMatchPhaseLabel': 'Phase',
      'clashMatchPhaseCoinToss': 'Coin toss',
      'clashMatchPhasePlaying': 'In play',
      'clashMatchPhaseHalftime': 'Halftime',
      'clashMatchPhaseFinished': 'Finished',
      'clashMatchCoinTossPrompt': 'Choose heads or tails for kickoff',
      'clashMatchCoinHeads': 'Heads',
      'clashMatchCoinTails': 'Tails',
      'clashMatchCoinResult': 'Result: {outcome}. Kickoff: {kickoff}',
      'clashMatchKickoffUser': 'Eternal XI',
      'clashMatchKickoffRival': 'Rival',
      'clashMatchPossessionUser': 'Possession: Eternal XI',
      'clashMatchPossessionRival': 'Possession: Rival',
      'clashMatchBallHolder': 'Ball: {player}',
      'clashMatchVictory': 'Victory!',
      'clashMatchDefeat': 'Defeat',
      'clashMatchViewRewards': 'View rewards',
      'clashMatchDevGoalsHint':
          'Provisional buttons (tutorial/dev) — not final gameplay',
      'clashMatchDevGoalUser': 'Eternal XI goal (provisional)',
      'clashMatchDevGoalRival': 'Rival goal (provisional)',
      'clashMatchActionPass': 'Pass',
      'clashMatchActionAdvance': 'Advance',
      'clashMatchActionShootSoon': 'Shoot (coming soon)',
      'clashMatchActionShoot': 'Shoot',
      'clashMatchActionShootNeedArea': 'Reach the box to shoot',
      'clashMatchActionRivalSim': 'Simulate rival action',
      'clashMatchZoneLabel': 'Ball zone',
      'clashMatchStaminaLabel': 'Stamina',
      'clashMatchPtStaminaLabel':
          'PT {currentPt}/{maxPt} · Stamina {currentStamina}/{maxStamina}',
      'clashMatchHalftimeTitle': 'Halftime',
      'clashMatchHalftimeSquadTitle': 'Your squad',
      'clashMatchHalftimeItemsTitle': 'Match items',
      'clashMatchHalftimeContinue': 'Resume match',
      'clashMatchHalftimeCancel': 'Cancel',
      'clashMatchHalftimeApplyItem': 'Use item',
      'clashMatchHalftimeSelectPlayers': 'Pick up to {count} players',
      'clashMatchHalftimePtLabel': 'PT {current}/{max}',
      'clashMatchHalftimeStaminaLabel': 'STA {current}/{max}',
      'clashMatchHalftimeItemQty': 'x{qty}',
      'clashMatchHalftimeItemEffect': '+{amount} · up to {targets} players',
      'clashMatchPressureLabel': 'Pressure',
      'clashMatchRiskLabel': 'Possession risk',
      'clashMatchEventLogTitle': 'Recent events',
      'clashMatchPassSheetTitle': 'Choose teammate',
      'clashMatchPassSheetEmpty': 'No teammates available',
      'clashMatchPassPercent': '{percent}%',
      'clashMatchPassOptionPower': 'Power {power}',
      'clashMatchAdvanceChance': 'Advance chance: {percent}%',
      'clashMatchDuelTitle': 'Duel',
      'clashMatchDuelNormalDribble': 'Normal dribble',
      'clashMatchDuelEffectiveDribble': 'Effective dribble',
      'clashMatchDuelEffectiveDefense': 'Effective defense',
      'clashMatchDuelStyleAdvantage': 'Style advantage',
      'clashMatchDuelStyleDisadvantage': 'Style disadvantage',
      'clashMatchDuelStyleNeutral': 'Neutral style',
      'clashMatchDuelSuperTechniques': 'Super techniques',
      'clashMatchDuelTechniqueMeta':
          '{type} · {style} · Power {power} · Cost {cost} PT · Level {level}',
      'clashMatchDuelCurrentPt': 'Current PT: {pt}',
      'clashMatchDuelInsufficientPt': 'Insufficient PT',
      'clashMatchDuelTechniqueUsed': 'Attacker: {name} (−{pt} PT)',
      'clashMatchDuelDefenderTechnique': 'Defender: {name} (−{pt} PT)',
      'clashMatchDuelContinue': 'Continue',
      'clashMatchDuelScore': 'Duel score: {attacker} — {defender}',
      'clashMatchDuelCoinTie': 'Tie broken by coin flip',
      'clashMatchShotDuelTitle': 'Shot duel',
      'clashMatchDuelNormalShot': 'Normal shot',
      'clashMatchDuelEffectiveShot': 'Effective shot',
      'clashMatchDuelEffectiveSave': 'Effective save',
      'clashMatchDuelGoal': 'GOAL!',
      'clashMatchDuelSave': 'SAVE',
      'clashMatchDevSectionTitle': 'Dev/provisional tools',
      'registerTitle': 'Create account',
      'registerSubtitle':
          'Join Eternal XI. Use a valid email and a nickname that represents you in leagues.',
      'birthDateLabel': 'Date of birth',
      'birthDateHint': 'Select your date of birth',
      'acceptTermsLabel': 'I accept the Terms of Service and Privacy Policy',
      'confirmMinAgeLabel': 'I confirm I am at least 13 years old',
      'legalTermsTitle': 'Terms of Service',
      'legalCommunityTitle': 'Community Guidelines',
      'legalPrivacyTitle': 'Privacy and minors',
      'legalTermsLink': 'Terms of Service',
      'legalCommunityLink': 'Community Guidelines',
      'legalPrivacyLink': 'Privacy Policy',
      'legalSectionTitle': 'Legal & safety',
      'ageConfirmationTitle': 'Confirm your age',
      'chatSafetyBanner':
          'Be respectful. Long-press a message to report it or block a user.',
      'chatReport': 'Report message',
      'chatBlockUser': 'Block user',
      'chatReportSent':
          'Message reported. We will review it as soon as possible.',
      'chatUserBlocked': 'User blocked. You will no longer see their messages.',
      'chatReportConfirm': 'Report this message for inappropriate content?',
      'chatBlockConfirm':
          'Block this user? You will no longer see their chat messages.',
      'validatorRequiredBirthDate': 'Date of birth is required',
      'validatorUnderMinAge':
          'You must be at least 13 years old to use Eternal XI',
      'validatorAcceptTermsRequired':
          'You must accept the terms and privacy policy',
      'validatorConfirmMinAgeRequired':
          'You must confirm you meet the minimum age',
      'requestPasswordTitle': 'Reset password',
      'requestPasswordSubtitle':
          'We will send a code to your account email so you can set a new password.',
      'confirmPasswordTitle': 'New password',
      'confirmPasswordSubtitle':
          'Enter the code received by email and choose a secure password.',
      'verifyEmailTitle': 'Verify email',
      'verifyEmailSubtitle':
          'You will receive an email code to continue registration safely.',
      'confirmCodeTitle': 'Confirm code',
      'confirmCodeSubtitle': 'Check your inbox and enter the code we sent you.',
      'verifyEmailInvalidCode': 'Invalid code',
      'changeEmail': 'Change email',
      'requestEmailChange': 'Request email change',
      'confirmEmailChange': 'Confirm new email',
      'newEmail': 'New email',
      'currentEmail': 'Current email',
      'sendCodeToNewEmail': 'Send code to new email',
      'confirmChange': 'Confirm change',
      'showPassword': 'Show password',
      'hidePassword': 'Hide password',
      'myLeagues': 'My leagues',
      'leaguesTab': 'Leagues',
      'achievementsTab': 'Achievements',
      'joinLeague': 'Join league',
      'createLeague': 'Create league',
      'leagueName': 'League name',
      'invitationCode': 'Invitation code',
      'invitationHint': 'E.g. ABCD34XZ',
      'joinLeagueDescription':
          'Enter the code shared by the league administrator.',
      'noLeaguesYet': 'You have no leagues yet',
      'createOrJoinLeagueHint':
          'Create a league or join one with a code using the top-right icons.',
      'noUserSession': 'No user session',
      'noUserSessionHint':
          'Sign in to see your leagues. If you already signed in, go back and try again.',
      'league': 'League',
      'leagueInvalidId': 'Invalid league identifier.',
      'leagueContextError': 'Could not resolve league context.',
      'retryLoad': 'Retry',
      'budget': 'Your budget',
      'seasonUnavailable': 'No seasons available.',
      'advancedConfig': 'Advanced settings',
      'profile': 'Profile',
      'accountData': 'Account data',
      'profileTokens': 'Rewards',
      'logout': 'Log out',
      'deleteAccount': 'Delete account',
      'deleteAccountConfirmTitle': 'Delete account',
      'deleteAccountConfirmBody':
          'This will delete your account and associated data (profile, fantasy leagues, squads, market and progress). You cannot undo this.\n\nWe will email you a code to confirm your identity.',
      'deleteAccountRequestEmail': 'Send confirmation email',
      'confirmAccountDeletionTitle': 'Confirm deletion',
      'confirmAccountDeletionHint':
          'Enter the code we sent to your email. You can also use the link in that email.',
      'accountDeletionCodeLabel': 'Confirmation code',
      'accountDeletionCodeInvalid': 'Enter the code from your email',
      'confirmAccountDeletionAction': 'Delete my account',
      'accountDeletedSuccess': 'Account deleted successfully',
      'accountDeletionRequestFailed': 'Could not request account deletion',
      'changeEmailHint':
          'For security, we verify your identity and send a code to your current email and another to the new one before applying the change.',
      'sendVerificationCodes': 'Send verification codes',
      'confirmEmailChangeHint':
          'Enter the code received at each email address to confirm the change.',
      'verificationCodeNewEmail': 'New email code',
      'verificationCodeCurrentEmail': 'Current email code',
      'changeNickname': 'Change nickname',
      'changeNicknameHint':
          'For security, we verify your identity with your password and a code sent to your email.',
      'confirmNicknameChange': 'Confirm new nickname',
      'newNickname': 'New nickname',
      'currentNickname': 'Current nickname',
      'sendNicknameVerificationCode': 'Send verification code',
      'verificationCodeSentToEmail':
          'We sent a code to your email. Enter it to confirm your nickname:',
      'verificationCodeSentTo': 'Enter the code we sent to:',
      'achievements': 'Achievements',
      'achievementsLoadError': 'Could not load achievements',
      'achievementsFromCache':
          'Showing achievements saved on this device. Connect to refresh.',
      'achievementsUnlockedSummary':
          '{unlocked} of {total} achievements unlocked',
      'achievementsHowToGet': 'How to unlock',
      'achievementProgress': 'Progress: {current}/{target}',
      'achievementRewardXp': 'Reward: +{xp} XP',
      'rewards': 'Rewards',
      'leagueRewards': 'League rewards',
      'cancelOffer': 'Cancel offer',
      'unsavedLineupTitle': 'Unsaved lineup',
      'unsavedLineupBody':
          'You have unsaved lineup changes. What do you want to do?',
      'exitWithoutSaving': 'Leave without saving',
      'stayHere': 'Stay here',
      'lineupSaved': 'Lineup saved',
      'lineupLoadError': 'Could not load lineup',
      'lineupIncomplete': 'Complete the lineup before saving.',
      'lineupNeedStarterForCaptain':
          'Add at least one starter to choose a captain.',
      'lineupNeedStarterToSave': 'Add at least one starter to save.',
      'apiConnectionError':
          'Could not connect to server. Check backend and network.',
      'apiNetworkError': 'Network error. Check your connection and try again.',
      'apiCommunicationError': 'Communication error with server.',
      'apiUnexpectedError': 'An unexpected error occurred.',
      'apiAmountMustBeInteger': 'Amount must be an integer.',
      'apiInsufficientFunds': 'You do not have enough funds.',
      'apiForbidden': 'You do not have permission for this action.',
      'apiEmailUnavailable':
          'Email cannot be sent right now. Contact support or try again later.',
      'apiInternalError': 'An error occurred. Please try again.',
      'validatorRequiredEmail': 'Email is required',
      'validatorEmailMaxLength': 'Maximum 190 characters',
      'validatorInvalidEmail': 'Invalid email',
      'validatorRequiredPassword': 'Password is required',
      'validatorPasswordMinLength': 'Minimum 8 characters',
      'validatorPasswordMaxLength': 'Maximum 128 characters',
      'validatorRequiredNickname': 'Nickname is required',
      'validatorNicknameNoSpaces': 'Nickname cannot contain spaces',
      'validatorNicknameMinLength': 'Minimum 3 characters',
      'validatorNicknameMaxLength': 'Maximum 24 characters',
      'validatorNicknameInvalidChars':
          'Only letters, numbers, dashes, dots and underscores',
      'validatorConfirmPasswordRequired': 'Please confirm password',
      'validatorPasswordsDontMatch': 'Passwords do not match',
      'validatorRequiredCode': 'Code is required',
      'validatorRequiredLeagueName': 'League name is required',
      'validatorLeagueNameMinLength': 'Minimum 3 characters',
      'validatorLeagueNameMaxLength': 'Maximum 50 characters',
      'validatorRequiredInvitationCode': 'Enter invitation code',
      'validatorInvitationCodeMaxLength': 'Maximum 20 characters',
      'validatorCurrentPasswordRequired': 'Enter your current password',
      'validatorCodeSixChars': 'Enter the 6-character code',
      'preferencesTitle': 'Preferences',
      'themeModeLabel': 'Theme',
      'languageLabel': 'Language',
      'systemOption': 'System',
      'lightOption': 'Light',
      'darkOption': 'Dark',
      'spanishOption': 'Spanish',
      'englishOption': 'English',
      'preferencesUpdated': 'Preferences updated',
      'preferencesLoadError': 'Could not load preferences',
      'preferencesSaveError': 'Could not save preferences',
      'savingPreferences': 'Saving preferences...',
      'chat': 'Chat',
      'chatComingSoon':
          'League chat is coming soon. Talk to your rivals and celebrate your goals.',
      'chatHint': 'Write a message to the league...',
      'chatDismissKeyboard': 'Hide keyboard',
      'chatEmpty': 'Be the first to write in the league chat.',
      'chatYou': 'You',
      'chatSystemAuthor': 'System',
      'chatSeedRivalAuthor': 'Rival_XI',
      'chatSeedRivalMessage': 'Who\'s taking this matchday?',
      'chatLeagueFallback': 'League',
    },
  };

  String _t(String key) {
    final languageCode = locale.languageCode.toLowerCase();
    return _values[languageCode]?[key] ?? _values['es']![key]!;
  }

  String get appTitle => _t('appTitle');
  String get loading => _t('loading');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get saving => _t('saving');
  String get retry => _t('retry');
  String get continueText => _t('continue');
  String get close => _t('close');
  String get copy => _t('copy');
  String get share => _t('share');
  String get understand => _t('understand');
  String get delete => _t('delete');
  String get confirm => _t('confirm');
  String get update => _t('update');
  String get join => _t('join');
  String get create => _t('create');
  String get edit => _t('edit');
  String get search => _t('search');
  String get send => _t('send');
  String get next => _t('next');
  String get back => _t('back');
  String get yes => _t('yes');
  String get no => _t('no');
  String get emptyStateDash => _t('emptyStateDash');
  String get history => _t('history');
  String get lineup => _t('lineup');
  String get squad => _t('squad');
  String get captain => _t('captain');
  String get home => _t('home');
  String get standings => _t('standings');
  String get market => _t('market');
  String get transfers => _t('transfers');
  String get settings => _t('settings');
  String get chat => _t('chat');
  String get chatComingSoon => _t('chatComingSoon');
  String get chatHint => _t('chatHint');
  String get chatDismissKeyboard => _t('chatDismissKeyboard');
  String get chatEmpty => _t('chatEmpty');
  String get chatYou => _t('chatYou');
  String get chatSystemAuthor => _t('chatSystemAuthor');
  String get chatSeedRivalAuthor => _t('chatSeedRivalAuthor');
  String get chatSeedRivalMessage => _t('chatSeedRivalMessage');
  String get chatLeagueFallback => _t('chatLeagueFallback');

  String chatWelcomeMessage(String leagueName) {
    final en = locale.languageCode.toLowerCase() == 'en';
    return en
        ? 'Welcome to the $leagueName chat! ⚽'
        : '¡Bienvenidos al chat de $leagueName! ⚽';
  }

  String get login => _t('login');
  String get register => _t('register');
  String get email => _t('email');
  String get password => _t('password');
  String get currentPassword => _t('currentPassword');
  String get newPassword => _t('newPassword');
  String get repeatPassword => _t('repeatPassword');
  String get nickname => _t('nickname');
  String get verificationCode => _t('verificationCode');
  String get requestCode => _t('requestCode');
  String get sendCode => _t('sendCode');
  String get confirmAndContinue => _t('confirmAndContinue');
  String get savePassword => _t('savePassword');
  String get forgotPassword => _t('forgotPassword');
  String get alreadyHaveAccount => _t('alreadyHaveAccount');
  String get backToLogin => _t('backToLogin');
  String get createAccount => _t('createAccount');
  String get loginTitle => _t('loginTitle');
  String get loginSubtitle => _t('loginSubtitle');
  String get modeSelectionSubtitle => _t('modeSelectionSubtitle');
  String get modeFantasyTitle => _t('modeFantasyTitle');
  String get modeFantasyDescription => _t('modeFantasyDescription');
  String get modeFantasyEnter => _t('modeFantasyEnter');
  String get modeClashTitle => _t('modeClashTitle');
  String get modeClashDescription => _t('modeClashDescription');
  String get modeClashEnter => _t('modeClashEnter');
  String get clashPlaceholderTitle => _t('clashPlaceholderTitle');
  String get clashPlaceholderBody => _t('clashPlaceholderBody');
  String get backToModeSelection => _t('backToModeSelection');
  String get clashTabHome => _t('clashTabHome');
  String get clashTabTeam => _t('clashTabTeam');
  String get clashTabSummon => _t('clashTabSummon');
  String get clashTabShop => _t('clashTabShop');
  String get clashEnergy => _t('clashEnergy');
  String get clashCoins => _t('clashCoins');
  String get clashGems => _t('clashGems');
  String get clashComingSoon => _t('clashComingSoon');
  String get clashHomeTitle => _t('clashHomeTitle');
  String get clashHomeMainAccess => _t('clashHomeMainAccess');
  String get clashHomeStory => _t('clashHomeStory');
  String get clashHomeEvents => _t('clashHomeEvents');
  String get clashHomeChallenges => _t('clashHomeChallenges');
  String get clashHomeNews => _t('clashHomeNews');
  String get clashHomeProtagonistSquad => _t('clashHomeProtagonistSquad');
  String get clashHomeProtagonistHint => _t('clashHomeProtagonistHint');
  String get clashTeamLineup7 => _t('clashTeamLineup7');
  String get clashTeamLineup11 => _t('clashTeamLineup11');
  String get clashTeamCharacters => _t('clashTeamCharacters');
  String get clashTeamUpgrade => _t('clashTeamUpgrade');
  String get clashTeamSkillTree => _t('clashTeamSkillTree');
  String get clashSummonBanners => _t('clashSummonBanners');
  String get clashSummonSingle => _t('clashSummonSingle');
  String get clashSummonMulti => _t('clashSummonMulti');
  String get clashSummonHistory => _t('clashSummonHistory');
  String get clashSummonRates => _t('clashSummonRates');
  String get clashShopGame => _t('clashShopGame');
  String get clashShopEvent => _t('clashShopEvent');
  String get clashShopExchange => _t('clashShopExchange');
  String get clashShopGems => _t('clashShopGems');
  String get clashShopPacks => _t('clashShopPacks');
  String get clashBack => _t('clashBack');
  String get clashCollectionTitle => _t('clashCollectionTitle');
  String get clashSearchHint => _t('clashSearchHint');
  String get clashFilterAll => _t('clashFilterAll');
  String get clashFilterRarity => _t('clashFilterRarity');
  String get clashFilterPosition => _t('clashFilterPosition');
  String get clashFilterStyle => _t('clashFilterStyle');
  String get clashSortLabel => _t('clashSortLabel');
  String get clashSortPower => _t('clashSortPower');
  String get clashSortLevel => _t('clashSortLevel');
  String get clashSortName => _t('clashSortName');
  String get clashSortDirection => _t('clashSortDirection');
  String get clashCollectionEmpty => _t('clashCollectionEmpty');
  String get clashCollectionLoadError => _t('clashCollectionLoadError');
  String get clashCardNotFound => _t('clashCardNotFound');
  String get clashCardTeam => _t('clashCardTeam');
  String get clashCardPosition => _t('clashCardPosition');
  String get clashCardStyle => _t('clashCardStyle');
  String get clashCardLevel => _t('clashCardLevel');
  String get clashCardPower => _t('clashCardPower');
  String get clashCardStats => _t('clashCardStats');
  String get clashStatSave => _t('clashStatSave');
  String get clashStatDefense => _t('clashStatDefense');
  String get clashStatPass => _t('clashStatPass');
  String get clashStatDribble => _t('clashStatDribble');
  String get clashStatShot => _t('clashStatShot');
  String get clashStatPt => _t('clashStatPt');
  String get clashStatStamina => _t('clashStatStamina');
  String get clashTechniqueSection => _t('clashTechniqueSection');
  String get clashTechniqueType => _t('clashTechniqueType');
  String get clashTechniquePower => _t('clashTechniquePower');
  String get clashTechniquePtCost => _t('clashTechniquePtCost');
  String get clashTechniqueLevel => _t('clashTechniqueLevel');
  String get clashActionUpgrade => _t('clashActionUpgrade');
  String get clashActionEvolve => _t('clashActionEvolve');
  String get clashActionTree => _t('clashActionTree');
  String get clashLineupSlotEmpty => _t('clashLineupSlotEmpty');
  String get clashLineupTotalPower => _t('clashLineupTotalPower');
  String get clashLineupComplete => _t('clashLineupComplete');
  String get clashLineupIncomplete => _t('clashLineupIncomplete');
  String get clashLineupMissingTitle => _t('clashLineupMissingTitle');
  String get clashLineupSetActive => _t('clashLineupSetActive');
  String get clashLineupRenameTitle => _t('clashLineupRenameTitle');
  String get clashLineupRenameHint => _t('clashLineupRenameHint');
  String get clashLineupRenameSave => _t('clashLineupRenameSave');
  String get clashLineupLoadError => _t('clashLineupLoadError');
  String get clashLineupClearSlot => _t('clashLineupClearSlot');
  String get clashLineupNoCompatibleCards => _t('clashLineupNoCompatibleCards');
  String get clashLineupBlockWrongPosition =>
      _t('clashLineupBlockWrongPosition');
  String get clashLineupBlockDuplicatePlayer =>
      _t('clashLineupBlockDuplicatePlayer');

  String clashLineupPickCard(String position) {
    final en = locale.languageCode.toLowerCase() == 'en';
    return en ? 'Choose card · $position' : 'Elegir carta · $position';
  }

  String get clashStoryLoadError => _t('clashStoryLoadError');
  String get clashStoryTypeStory => _t('clashStoryTypeStory');
  String get clashStoryTypeMatch => _t('clashStoryTypeMatch');
  String get clashStoryTypeMixed => _t('clashStoryTypeMixed');
  String get clashStoryStatusLocked => _t('clashStoryStatusLocked');
  String get clashStoryStatusAvailable => _t('clashStoryStatusAvailable');
  String get clashStoryStatusCompleted => _t('clashStoryStatusCompleted');
  String get clashStorySkipScene => _t('clashStorySkipScene');
  String get clashStoryNextScene => _t('clashStoryNextScene');
  String get clashStoryFinishLevel => _t('clashStoryFinishLevel');
  String get clashStoryRewardTitle => _t('clashStoryRewardTitle');
  String get clashStoryBackToMap => _t('clashStoryBackToMap');
  String get clashStoryNextLevel => _t('clashStoryNextLevel');
  String get clashStoryTeamFormed => _t('clashStoryTeamFormed');
  String get clashStoryCardsReceived => _t('clashStoryCardsReceived');
  String get clashStoryLevelBlockedTitle => _t('clashStoryLevelBlockedTitle');
  String get clashStoryLevelBlockedBody => _t('clashStoryLevelBlockedBody');
  String get clashStoryGateTeam => _t('clashStoryGateTeam');
  String get clashStoryGateSummon => _t('clashStoryGateSummon');
  String get clashStoryGateEvents => _t('clashStoryGateEvents');

  String get clashMatchPrepareType => _t('clashMatchPrepareType');
  String get clashMatchPrepareEnergy => _t('clashMatchPrepareEnergy');
  String get clashMatchPrepareRecommendedPower =>
      _t('clashMatchPrepareRecommendedPower');
  String get clashMatchPrepareLineupPower => _t('clashMatchPrepareLineupPower');
  String get clashMatchPrepareLineupComplete =>
      _t('clashMatchPrepareLineupComplete');
  String get clashMatchPrepareLineupIncomplete =>
      _t('clashMatchPrepareLineupIncomplete');
  String get clashMatchPreparePowerWarning =>
      _t('clashMatchPreparePowerWarning');
  String get clashMatchPrepareEditLineup => _t('clashMatchPrepareEditLineup');
  String get clashMatchPrepareStart => _t('clashMatchPrepareStart');
  String get clashMatchWinTarget => _t('clashMatchWinTarget');
  String get clashMatchPhaseLabel => _t('clashMatchPhaseLabel');
  String get clashMatchPhaseCoinToss => _t('clashMatchPhaseCoinToss');
  String get clashMatchPhasePlaying => _t('clashMatchPhasePlaying');
  String get clashMatchPhaseHalftime => _t('clashMatchPhaseHalftime');
  String get clashMatchPhaseFinished => _t('clashMatchPhaseFinished');
  String get clashMatchCoinTossPrompt => _t('clashMatchCoinTossPrompt');
  String get clashMatchCoinHeads => _t('clashMatchCoinHeads');
  String get clashMatchCoinTails => _t('clashMatchCoinTails');
  String get clashMatchKickoffUser => _t('clashMatchKickoffUser');
  String get clashMatchKickoffRival => _t('clashMatchKickoffRival');
  String get clashMatchPossessionUser => _t('clashMatchPossessionUser');
  String get clashMatchPossessionRival => _t('clashMatchPossessionRival');
  String get clashMatchVictory => _t('clashMatchVictory');
  String get clashMatchDefeat => _t('clashMatchDefeat');
  String get clashMatchViewRewards => _t('clashMatchViewRewards');
  String get clashMatchDevGoalsHint => _t('clashMatchDevGoalsHint');
  String get clashMatchDevGoalUser => _t('clashMatchDevGoalUser');
  String get clashMatchDevGoalRival => _t('clashMatchDevGoalRival');
  String get clashMatchActionPass => _t('clashMatchActionPass');
  String get clashMatchActionAdvance => _t('clashMatchActionAdvance');
  String get clashMatchActionShootSoon => _t('clashMatchActionShootSoon');
  String get clashMatchActionShoot => _t('clashMatchActionShoot');
  String get clashMatchActionShootNeedArea =>
      _t('clashMatchActionShootNeedArea');
  String get clashMatchActionRivalSim => _t('clashMatchActionRivalSim');
  String get clashMatchZoneLabel => _t('clashMatchZoneLabel');
  String get clashMatchStaminaLabel => _t('clashMatchStaminaLabel');

  String clashMatchPtStaminaLabel(
    int currentPt,
    int maxPt,
    int currentStamina,
    int maxStamina,
  ) => _t('clashMatchPtStaminaLabel')
      .replaceAll('{currentPt}', '$currentPt')
      .replaceAll('{maxPt}', '$maxPt')
      .replaceAll('{currentStamina}', '$currentStamina')
      .replaceAll('{maxStamina}', '$maxStamina');

  String get clashMatchHalftimeTitle => _t('clashMatchHalftimeTitle');
  String get clashMatchHalftimeSquadTitle => _t('clashMatchHalftimeSquadTitle');
  String get clashMatchHalftimeItemsTitle => _t('clashMatchHalftimeItemsTitle');
  String get clashMatchHalftimeContinue => _t('clashMatchHalftimeContinue');
  String get clashMatchHalftimeCancel => _t('clashMatchHalftimeCancel');
  String get clashMatchHalftimeApplyItem => _t('clashMatchHalftimeApplyItem');

  String clashMatchHalftimeSelectPlayers(int count) =>
      _t('clashMatchHalftimeSelectPlayers').replaceAll('{count}', '$count');

  String clashMatchHalftimePtLabel(int current, int max) => _t(
    'clashMatchHalftimePtLabel',
  ).replaceAll('{current}', '$current').replaceAll('{max}', '$max');

  String clashMatchHalftimeStaminaLabel(int current, int max) => _t(
    'clashMatchHalftimeStaminaLabel',
  ).replaceAll('{current}', '$current').replaceAll('{max}', '$max');

  String clashMatchHalftimeItemQty(int qty) =>
      _t('clashMatchHalftimeItemQty').replaceAll('{qty}', '$qty');

  String clashMatchHalftimeItemEffect(int amount, int targets) => _t(
    'clashMatchHalftimeItemEffect',
  ).replaceAll('{amount}', '$amount').replaceAll('{targets}', '$targets');

  String get clashMatchPressureLabel => _t('clashMatchPressureLabel');
  String get clashMatchRiskLabel => _t('clashMatchRiskLabel');
  String get clashMatchEventLogTitle => _t('clashMatchEventLogTitle');
  String get clashMatchPassSheetTitle => _t('clashMatchPassSheetTitle');
  String get clashMatchPassSheetEmpty => _t('clashMatchPassSheetEmpty');
  String get clashMatchDevSectionTitle => _t('clashMatchDevSectionTitle');

  String clashMatchPassPercent(int percent) =>
      _t('clashMatchPassPercent').replaceAll('{percent}', '$percent');

  String clashMatchPassOptionPower(int power) =>
      _t('clashMatchPassOptionPower').replaceAll('{power}', '$power');

  String clashMatchAdvanceChance(int percent) =>
      _t('clashMatchAdvanceChance').replaceAll('{percent}', '$percent');

  String get clashMatchDuelTitle => _t('clashMatchDuelTitle');
  String get clashMatchDuelNormalDribble => _t('clashMatchDuelNormalDribble');
  String get clashMatchDuelEffectiveDribble =>
      _t('clashMatchDuelEffectiveDribble');
  String get clashMatchDuelEffectiveDefense =>
      _t('clashMatchDuelEffectiveDefense');
  String get clashMatchDuelStyleAdvantage => _t('clashMatchDuelStyleAdvantage');
  String get clashMatchDuelStyleDisadvantage =>
      _t('clashMatchDuelStyleDisadvantage');
  String get clashMatchDuelStyleNeutral => _t('clashMatchDuelStyleNeutral');
  String get clashMatchDuelSuperTechniques =>
      _t('clashMatchDuelSuperTechniques');
  String get clashMatchDuelInsufficientPt => _t('clashMatchDuelInsufficientPt');
  String get clashMatchDuelContinue => _t('clashMatchDuelContinue');
  String get clashMatchDuelCoinTie => _t('clashMatchDuelCoinTie');
  String get clashMatchShotDuelTitle => _t('clashMatchShotDuelTitle');
  String get clashMatchDuelNormalShot => _t('clashMatchDuelNormalShot');
  String get clashMatchDuelEffectiveShot => _t('clashMatchDuelEffectiveShot');
  String get clashMatchDuelEffectiveSave => _t('clashMatchDuelEffectiveSave');
  String get clashMatchDuelGoal => _t('clashMatchDuelGoal');
  String get clashMatchDuelSave => _t('clashMatchDuelSave');

  String clashMatchDuelScore(int attacker, int defender) => _t(
    'clashMatchDuelScore',
  ).replaceAll('{attacker}', '$attacker').replaceAll('{defender}', '$defender');

  String clashMatchDuelCurrentPt(int pt) =>
      _t('clashMatchDuelCurrentPt').replaceAll('{pt}', '$pt');

  String clashMatchDuelTechniqueMeta(
    String type,
    String style,
    int power,
    int cost,
    String level,
  ) => _t('clashMatchDuelTechniqueMeta')
      .replaceAll('{type}', type)
      .replaceAll('{style}', style)
      .replaceAll('{power}', '$power')
      .replaceAll('{cost}', '$cost')
      .replaceAll('{level}', level);

  String clashMatchDuelTechniqueUsed(String name, int pt) => _t(
    'clashMatchDuelTechniqueUsed',
  ).replaceAll('{name}', name).replaceAll('{pt}', '$pt');

  String clashMatchDuelDefenderTechnique(String name, int pt) => _t(
    'clashMatchDuelDefenderTechnique',
  ).replaceAll('{name}', name).replaceAll('{pt}', '$pt');

  String clashMatchScoreLabel(int user, int rival) {
    return _t(
      'clashMatchScoreLabel',
    ).replaceAll('{user}', '$user').replaceAll('{rival}', '$rival');
  }

  String clashMatchCoinResult(String outcome, String kickoff) {
    return _t(
      'clashMatchCoinResult',
    ).replaceAll('{outcome}', outcome).replaceAll('{kickoff}', kickoff);
  }

  String clashMatchBallHolder(String player) {
    return _t('clashMatchBallHolder').replaceAll('{player}', player);
  }

  String clashStoryRewardGems(int count) {
    final en = locale.languageCode.toLowerCase() == 'en';
    return en ? '$count gem(s)' : '$count gema(s)';
  }

  String clashStoryRewardCoins(int count) {
    final en = locale.languageCode.toLowerCase() == 'en';
    return en ? '$count coin(s)' : '$count moneda(s)';
  }

  String get registerTitle => _t('registerTitle');
  String get registerSubtitle => _t('registerSubtitle');
  String get birthDateLabel => _t('birthDateLabel');
  String get birthDateHint => _t('birthDateHint');
  String get acceptTermsLabel => _t('acceptTermsLabel');
  String get confirmMinAgeLabel => _t('confirmMinAgeLabel');
  String get legalTermsTitle => _t('legalTermsTitle');
  String get legalCommunityTitle => _t('legalCommunityTitle');
  String get legalPrivacyTitle => _t('legalPrivacyTitle');
  String get legalTermsLink => _t('legalTermsLink');
  String get legalCommunityLink => _t('legalCommunityLink');
  String get legalPrivacyLink => _t('legalPrivacyLink');
  String get legalSectionTitle => _t('legalSectionTitle');
  String get ageConfirmationTitle => _t('ageConfirmationTitle');
  String get chatSafetyBanner => _t('chatSafetyBanner');
  String get chatReport => _t('chatReport');
  String get chatBlockUser => _t('chatBlockUser');
  String get chatReportSent => _t('chatReportSent');
  String get chatUserBlocked => _t('chatUserBlocked');
  String get chatReportConfirm => _t('chatReportConfirm');
  String get chatBlockConfirm => _t('chatBlockConfirm');
  String get validatorRequiredBirthDate => _t('validatorRequiredBirthDate');
  String get validatorUnderMinAge => _t('validatorUnderMinAge');
  String get validatorAcceptTermsRequired => _t('validatorAcceptTermsRequired');
  String get validatorConfirmMinAgeRequired =>
      _t('validatorConfirmMinAgeRequired');

  String ageConfirmationBody(int minAge) {
    final en = locale.languageCode.toLowerCase() == 'en';
    return en
        ? 'To comply with age requirements, confirm your date of birth. You must be at least $minAge years old to use Eternal XI, including league chat.'
        : 'Para cumplir los requisitos de edad, confirma tu fecha de nacimiento. Debes tener al menos $minAge años para usar Eternal XI, incluido el chat de liga.';
  }

  String get legalTermsBody {
    final en = locale.languageCode.toLowerCase() == 'en';
    return en
        ? 'Eternal XI is a fantasy football app for private leagues among people who know each other. By creating an account you agree to use the service lawfully, not harass other users, and not publish illegal, hateful, sexual or spam content in chat or profile. We may suspend accounts that break these rules. The service is not directed at children under 13.'
        : 'Eternal XI es una app de fantasy football para ligas privadas entre personas que se conocen. Al crear una cuenta aceptas usar el servicio de forma lícita, no acosar a otros usuarios y no publicar contenido ilegal, de odio, sexual o spam en el chat o perfil. Podemos suspender cuentas que incumplan estas normas. El servicio no está dirigido a menores de 13 años.';
  }

  String get legalCommunityBody {
    final en = locale.languageCode.toLowerCase() == 'en';
    return en
        ? 'League chat is for coordinating your fantasy league, not for bullying or sharing personal data of others.\n\n• Be respectful to league members.\n• Do not share phone numbers, addresses or private information.\n• Report inappropriate messages with a long press.\n• Block users whose messages you do not want to see.\n• Administrators may remove users from a league for serious misconduct.\n\nWe review reports and may remove content or suspend accounts.'
        : 'El chat de liga sirve para coordinar vuestra liga fantasy, no para acosar ni compartir datos personales de terceros.\n\n• Sé respetuoso con los miembros de la liga.\n• No compartas teléfonos, direcciones ni información privada.\n• Reporta mensajes inapropiados con pulsación larga.\n• Bloquea usuarios cuyos mensajes no quieras ver.\n• Los administradores pueden expulsar de una liga por conductas graves.\n\nRevisamos los reportes y podemos eliminar contenido o suspender cuentas.';
  }

  String get legalPrivacyBody {
    final en = locale.languageCode.toLowerCase() == 'en';
    return en
        ? 'We collect your email, nickname, optional profile photo, game data and league chat messages. Date of birth is used only to verify you meet the minimum age of 13. Chat messages are stored on our servers so league members can read them; you can report and block users from the app. You can delete your account from Profile. Full policy: eternalxi.com/privacy-policy.html'
        : 'Recopilamos tu correo, nickname, foto de perfil opcional, datos de juego y mensajes del chat de liga. La fecha de nacimiento se usa solo para verificar que cumples la edad mínima de 13 años. Los mensajes del chat se almacenan en nuestros servidores para que los miembros de la liga puedan leerlos; puedes reportar y bloquear usuarios desde la app. Puedes eliminar tu cuenta desde Perfil. Política completa: eternalxi.com/privacy-policy.html';
  }

  String get requestPasswordTitle => _t('requestPasswordTitle');
  String get requestPasswordSubtitle => _t('requestPasswordSubtitle');
  String get confirmPasswordTitle => _t('confirmPasswordTitle');
  String get confirmPasswordSubtitle => _t('confirmPasswordSubtitle');
  String get verifyEmailTitle => _t('verifyEmailTitle');
  String get verifyEmailSubtitle => _t('verifyEmailSubtitle');
  String get confirmCodeTitle => _t('confirmCodeTitle');
  String get confirmCodeSubtitle => _t('confirmCodeSubtitle');
  String get verifyEmailInvalidCode => _t('verifyEmailInvalidCode');
  String get changeEmail => _t('changeEmail');
  String get requestEmailChange => _t('requestEmailChange');
  String get confirmEmailChange => _t('confirmEmailChange');
  String get newEmail => _t('newEmail');
  String get currentEmail => _t('currentEmail');
  String get sendCodeToNewEmail => _t('sendCodeToNewEmail');
  String get confirmChange => _t('confirmChange');
  String get showPassword => _t('showPassword');
  String get hidePassword => _t('hidePassword');
  String get myLeagues => _t('myLeagues');
  String get leaguesTab => _t('leaguesTab');
  String get achievementsTab => _t('achievementsTab');
  String get joinLeague => _t('joinLeague');
  String get createLeague => _t('createLeague');
  String get leagueName => _t('leagueName');
  String get invitationCode => _t('invitationCode');
  String get invitationHint => _t('invitationHint');
  String get joinLeagueDescription => _t('joinLeagueDescription');
  String get noLeaguesYet => _t('noLeaguesYet');
  String get createOrJoinLeagueHint => _t('createOrJoinLeagueHint');
  String get noUserSession => _t('noUserSession');
  String get noUserSessionHint => _t('noUserSessionHint');
  String get league => _t('league');
  String get leagueInvalidId => _t('leagueInvalidId');
  String get leagueContextError => _t('leagueContextError');
  String get retryLoad => _t('retryLoad');
  String get budget => _t('budget');
  String get seasonUnavailable => _t('seasonUnavailable');
  String get advancedConfig => _t('advancedConfig');
  String get profile => _t('profile');
  String get accountData => _t('accountData');
  String get profileTokens => _t('profileTokens');
  String get logout => _t('logout');
  String get deleteAccount => _t('deleteAccount');
  String get deleteAccountConfirmTitle => _t('deleteAccountConfirmTitle');
  String get deleteAccountConfirmBody => _t('deleteAccountConfirmBody');
  String get deleteAccountRequestEmail => _t('deleteAccountRequestEmail');
  String get confirmAccountDeletionTitle => _t('confirmAccountDeletionTitle');
  String get confirmAccountDeletionHint => _t('confirmAccountDeletionHint');
  String get accountDeletionCodeLabel => _t('accountDeletionCodeLabel');
  String get accountDeletionCodeInvalid => _t('accountDeletionCodeInvalid');
  String get confirmAccountDeletionAction => _t('confirmAccountDeletionAction');
  String get accountDeletedSuccess => _t('accountDeletedSuccess');
  String get accountDeletionRequestFailed => _t('accountDeletionRequestFailed');
  String get changeEmailHint => _t('changeEmailHint');
  String get sendVerificationCodes => _t('sendVerificationCodes');
  String get confirmEmailChangeHint => _t('confirmEmailChangeHint');
  String get verificationCodeNewEmail => _t('verificationCodeNewEmail');
  String get verificationCodeCurrentEmail => _t('verificationCodeCurrentEmail');
  String get changeNickname => _t('changeNickname');
  String get changeNicknameHint => _t('changeNicknameHint');
  String get confirmNicknameChange => _t('confirmNicknameChange');
  String get newNickname => _t('newNickname');
  String get currentNickname => _t('currentNickname');
  String get sendNicknameVerificationCode => _t('sendNicknameVerificationCode');
  String get verificationCodeSentToEmail => _t('verificationCodeSentToEmail');
  String get verificationCodeSentTo => _t('verificationCodeSentTo');
  String get achievements => _t('achievements');
  String get achievementsLoadError => _t('achievementsLoadError');
  String get achievementsFromCache => _t('achievementsFromCache');
  String achievementsUnlockedSummary(int unlocked, int total) {
    return _t(
      'achievementsUnlockedSummary',
    ).replaceAll('{unlocked}', '$unlocked').replaceAll('{total}', '$total');
  }

  String get achievementsHowToGet => _t('achievementsHowToGet');
  String achievementProgress(int current, int target) {
    return _t(
      'achievementProgress',
    ).replaceAll('{current}', '$current').replaceAll('{target}', '$target');
  }

  String achievementRewardXp(int xp) =>
      _t('achievementRewardXp').replaceAll('{xp}', '$xp');
  String get rewards => _t('rewards');
  String get leagueRewards => _t('leagueRewards');
  String get cancelOffer => _t('cancelOffer');
  String get unsavedLineupTitle => _t('unsavedLineupTitle');
  String get unsavedLineupBody => _t('unsavedLineupBody');
  String get exitWithoutSaving => _t('exitWithoutSaving');
  String get stayHere => _t('stayHere');
  String get lineupSaved => _t('lineupSaved');
  String get lineupLoadError => _t('lineupLoadError');
  String get lineupIncomplete => _t('lineupIncomplete');
  String get lineupNeedStarterForCaptain => _t('lineupNeedStarterForCaptain');
  String get lineupNeedStarterToSave => _t('lineupNeedStarterToSave');
  String get apiConnectionError => _t('apiConnectionError');
  String get apiNetworkError => _t('apiNetworkError');
  String get apiCommunicationError => _t('apiCommunicationError');
  String get apiUnexpectedError => _t('apiUnexpectedError');
  String get apiAmountMustBeInteger => _t('apiAmountMustBeInteger');
  String get apiInsufficientFunds => _t('apiInsufficientFunds');
  String get apiForbidden => _t('apiForbidden');
  String get apiEmailUnavailable => _t('apiEmailUnavailable');
  String get apiInternalError => _t('apiInternalError');
  String get validatorRequiredEmail => _t('validatorRequiredEmail');
  String get validatorEmailMaxLength => _t('validatorEmailMaxLength');
  String get validatorInvalidEmail => _t('validatorInvalidEmail');
  String get validatorRequiredPassword => _t('validatorRequiredPassword');
  String get validatorPasswordMinLength => _t('validatorPasswordMinLength');
  String get validatorPasswordMaxLength => _t('validatorPasswordMaxLength');
  String get validatorRequiredNickname => _t('validatorRequiredNickname');
  String get validatorNicknameNoSpaces => _t('validatorNicknameNoSpaces');
  String get validatorNicknameMinLength => _t('validatorNicknameMinLength');
  String get validatorNicknameMaxLength => _t('validatorNicknameMaxLength');
  String get validatorNicknameInvalidChars =>
      _t('validatorNicknameInvalidChars');
  String get validatorConfirmPasswordRequired =>
      _t('validatorConfirmPasswordRequired');
  String get validatorPasswordsDontMatch => _t('validatorPasswordsDontMatch');
  String get validatorRequiredCode => _t('validatorRequiredCode');
  String get validatorRequiredLeagueName => _t('validatorRequiredLeagueName');
  String get validatorLeagueNameMinLength => _t('validatorLeagueNameMinLength');
  String get validatorLeagueNameMaxLength => _t('validatorLeagueNameMaxLength');
  String get validatorRequiredInvitationCode =>
      _t('validatorRequiredInvitationCode');
  String get validatorInvitationCodeMaxLength =>
      _t('validatorInvitationCodeMaxLength');
  String get validatorCurrentPasswordRequired =>
      _t('validatorCurrentPasswordRequired');
  String get validatorCodeSixChars => _t('validatorCodeSixChars');
  String get preferencesTitle => _t('preferencesTitle');
  String get themeModeLabel => _t('themeModeLabel');
  String get languageLabel => _t('languageLabel');
  String get systemOption => _t('systemOption');
  String get lightOption => _t('lightOption');
  String get darkOption => _t('darkOption');
  String get spanishOption => _t('spanishOption');
  String get englishOption => _t('englishOption');
  String get preferencesUpdated => _t('preferencesUpdated');
  String get preferencesLoadError => _t('preferencesLoadError');
  String get preferencesSaveError => _t('preferencesSaveError');
  String get savingPreferences => _t('savingPreferences');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (item) => item.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
