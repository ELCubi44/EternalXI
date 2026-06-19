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
      'clashHomeHubTitle': 'Eternal Clash',
      'clashHomeHubSubtitle': 'Historia, eventos y cartas',
      'clashHomePlaySection': 'Jugar',
      'clashHomeDailyActivity': 'Actividad diaria',
      'clashHomeNoticesSection': 'Avisos y recompensas',
      'clashHomePrimaryStoryDesc': 'Saga y niveles del prólogo',
      'clashHomePrimaryEventsDesc': 'Eventos de personaje',
      'clashHomePrimaryTeamDesc': 'Alineación 7vs7',
      'clashHomePrimarySummonDesc': 'Invocar cartas',
      'clashHomePrimaryLocked': 'Desbloquéalo en Historia.',
      'clashHomeFeaturedEventTitle': 'Evento destacado',
      'clashHomeFeaturedEventEnter': 'Entrar',
      'clashHomeFeaturedEventProgress': '{completed}/{total} fases',
      'clashHomeShopBalance': 'Monedas: {coins} · Gemas: {gems}',
      'clashHomeShopView': 'Ver',
      'clashDailyMissionsTitle': 'Misiones diarias',
      'clashDailyMissionsResetHint': 'Se reinician mañana',
      'clashDailyMissionsCompletedSummary': 'Completadas {completed}/{total}',
      'clashDailyMissionsClaimedSummary': 'Reclamadas {claimed}/{total}',
      'clashDailyMissionsStatusInProgress': 'En progreso',
      'clashDailyMissionsStatusClaim': 'Reclamar',
      'clashDailyMissionsStatusClaimed': 'Reclamada',
      'clashDailyMissionsClaimAll': 'Reclamar todas',
      'clashDailyMissionsClaimSuccess': 'Recompensa reclamada',
      'clashDailyMissionsHomeTitle': 'Misiones diarias',
      'clashDailyMissionsHomePending': '{count} pendientes de reclamar',
      'clashDailyMissionsHomeView': 'Ver',
      'clashDailyMissionsRewardCoins': '{count} monedas',
      'clashDailyMissionsRewardGems': '{count} gemas',
      'clashDailyMissionsProgress': '{current}/{target}',
      'clashDailyMissionsEmpty': 'No hay misiones disponibles',
      'clashEngagementRewardsLabel': 'Recompensa',
      'clashAchievementsTitle': 'Logros',
      'clashAchievementsPermanentHint':
          'Progreso permanente. No se reinician cada día.',
      'clashAchievementsCompletedSummary': 'Completados {completed}/{total}',
      'clashAchievementsClaimedSummary': 'Reclamados {claimed}/{total}',
      'clashAchievementsFilterAll': 'Todos',
      'clashAchievementsFilterInProgress': 'En progreso',
      'clashAchievementsFilterCompleted': 'Completados',
      'clashAchievementsFilterClaimed': 'Reclamados',
      'clashAchievementsEmptyFilter': 'Sin logros en este filtro',
      'clashAchievementsStatusInProgress': 'En progreso',
      'clashAchievementsStatusClaim': 'Reclamar',
      'clashAchievementsStatusClaimed': 'Reclamado',
      'clashAchievementsClaimAll': 'Reclamar todas',
      'clashAchievementsClaimSuccess': 'Recompensa reclamada',
      'clashAchievementsHomeTitle': 'Logros',
      'clashAchievementsHomePending': '{count} pendientes de reclamar',
      'clashAchievementsHomeView': 'Ver',
      'clashAchievementsRewardCoins': '{count} monedas',
      'clashAchievementsRewardGems': '{count} gemas',
      'clashAchievementsProgress': '{current}/{target}',
      'clashWeeklyMissionsTitle': 'Misiones semanales',
      'clashWeeklyMissionsResetHint': 'Se reinician el lunes',
      'clashWeeklyMissionsWeekLabel': 'Semana actual: {weekKey}',
      'clashWeeklyMissionsCompletedSummary': 'Completadas {completed}/{total}',
      'clashWeeklyMissionsClaimedSummary': 'Reclamadas {claimed}/{total}',
      'clashWeeklyMissionsStatusInProgress': 'En progreso',
      'clashWeeklyMissionsStatusClaim': 'Reclamar',
      'clashWeeklyMissionsStatusClaimed': 'Reclamada',
      'clashWeeklyMissionsClaimAll': 'Reclamar todas',
      'clashWeeklyMissionsClaimSuccess': 'Recompensa reclamada',
      'clashWeeklyMissionsHomeTitle': 'Misiones semanales',
      'clashWeeklyMissionsHomePending': '{count} pendientes de reclamar',
      'clashWeeklyMissionsHomeView': 'Ver',
      'clashWeeklyMissionsRewardCoins': '{count} monedas',
      'clashWeeklyMissionsRewardGems': '{count} gemas',
      'clashWeeklyMissionsProgress': '{current}/{target}',
      'clashWeeklyMissionsEmpty': 'No hay misiones semanales disponibles',
      'clashNewsTitle': 'Noticias',
      'clashNewsMarkAllRead': 'Marcar todas como leídas',
      'clashNewsFilterAll': 'Todas',
      'clashNewsFilterUnread': 'No leídas',
      'clashNewsFilterUpdates': 'Actualizaciones',
      'clashNewsFilterEvents': 'Eventos',
      'clashNewsFilterBanners': 'Banners',
      'clashNewsFilterNotices': 'Avisos',
      'clashNewsEmptyFilter': 'Sin noticias en este filtro',
      'clashNewsBadgeNew': 'Nuevo',
      'clashNewsTypeUpdate': 'Actualización',
      'clashNewsTypeEvent': 'Evento',
      'clashNewsTypeBanner': 'Banner',
      'clashNewsTypeMaintenance': 'Mantenimiento',
      'clashNewsTypeGift': 'Regalo',
      'clashNewsHomeTitle': 'Noticias',
      'clashNewsHomeUnread': '{count} sin leer',
      'clashNewsHomeAllCaughtUp': 'Todo al día',
      'clashNewsHomeView': 'Ver',
      'clashNewsUnreadSummary': '{count} sin leer',
      'clashGiftsTitle': 'Regalos',
      'clashGiftsPendingSummary': 'Pendientes {count}',
      'clashGiftsClaimedSummary': 'Reclamados {claimed}/{total}',
      'clashGiftsClaimAll': 'Reclamar todos',
      'clashGiftsClaimSuccess': 'Regalo reclamado',
      'clashGiftsStatusAvailable': 'Disponible',
      'clashGiftsStatusClaimed': 'Reclamado',
      'clashGiftsStatusExpired': 'Expirado',
      'clashGiftsStatusClaim': 'Reclamar',
      'clashGiftsHomeTitle': 'Regalos',
      'clashGiftsHomePending': '{count} pendientes',
      'clashGiftsHomeNone': 'Sin regalos pendientes',
      'clashGiftsHomeView': 'Ver',
      'clashGiftsEmptyPending': 'No hay regalos pendientes',
      'clashEventsTitle': 'Eventos',
      'clashEventsEmpty': 'No hay eventos disponibles',
      'clashEventsNotFound': 'Evento no encontrado',
      'clashEventsEnter': 'Entrar',
      'clashEventsProgress': 'Fases completadas {completed}/{total}',
      'clashEventsStagesTitle': 'Fases',
      'clashEventsFeaturedCard': 'Carta destacada: {cardId}',
      'clashEventsStageLocked': 'Bloqueada',
      'clashEventsStageAvailable': 'Disponible',
      'clashEventsStageCompleted': 'Completada',
      'clashEventsStageRead': 'Leer',
      'clashEventsStageReadAgain': 'Leer de nuevo',
      'clashEventsStagePrepare': 'Preparar partido',
      'clashEventsStageRepeat': 'Repetir',
      'clashEventsStageTypeStory': 'Historia',
      'clashEventsStageTypeMatch': 'Partido 7vs7',
      'clashEventsStageClearCount': 'Victorias: {count}',
      'clashEventsFirstClear': 'Primera vez',
      'clashEventsRepeatRewards': 'Repetición',
      'clashEventsStoryComplete': 'Completar',
      'clashEventsStoryPlaceholder': 'Continúa el entrenamiento.',
      'clashEventsStageNotFound': 'Fase no encontrada',
      'clashEventsRewardTitle': 'Recompensas',
      'clashEventsRewardFirstClear': '¡Primera victoria!',
      'clashEventsRewardRepeat': 'Recompensa de repetición',
      'clashEventsRewardDuplicate': 'Copia duplicada: {cardId}',
      'clashEventsRewardContinue': 'Continuar',
      'clashEventsCardXpReward': 'EXP por carta',
      'clashEventsHomeTitle': 'Eventos',
      'clashEventsHomeAvailable': '{count} disponibles',
      'clashEventsHomeNone': 'Sin eventos activos',
      'clashEventsHomeView': 'Ver',
      'clashEventsBack': 'Volver al evento',
      'clashEventsMatchDefeatHint':
          'No hay recompensas en derrota. Puedes reintentar.',
      'clashEventsStageCompletedTitle': 'Fase completada: {title}',
      'clashEventsLocalTestLabel': 'Eventos locales de prueba',
      'clashEventsFeaturedCardTitle': 'Carta destacada',
      'clashEventsFirstVictory': 'Primera victoria',
      'clashEventsRepeats': 'Repeticiones',
      'clashEventsRepeatable': 'Repetible',
      'clashEventsCompletedTimes': 'Completada {count} veces',
      'clashEventsFirstTimeCard': 'Primera vez: consigues la carta',
      'clashEventsRepeatDuplicates': 'Repeticiones: duplicados/materiales',
      'clashEventsAvailableCount': '{count} eventos disponibles',
      'clashTeamLineup7': 'Alineación 7vs7',
      'clashTeamLineup11': 'Alineación 11vs11',
      'clashTeamCharacters': 'Personajes',
      'clashTeamUpgrade': 'Mejorar',
      'clashTeamSkillTree': 'Árbol de habilidades',
      'clashTeamInventory': 'Inventario',
      'clashInventoryTitle': 'Inventario',
      'clashInventoryAll': 'Todos',
      'clashInventoryExp': 'Materiales EXP',
      'clashInventoryTechnique': 'Libros de técnica',
      'clashInventoryEvolution': 'Materiales de evolución',
      'clashInventoryMatch': 'Objetos de partido',
      'clashInventoryTickets': 'Tickets',
      'clashInventorySummaryTitle': 'Resumen',
      'clashInventoryTotalItems': 'Total de unidades: {count}',
      'clashInventoryCategoryCount': '{category}: {count}',
      'clashInventoryUseFromCardDetail': 'Usar desde detalle de carta',
      'clashInventoryUseDuringHalftime': 'Usar durante el descanso',
      'clashInventoryUseInSummon': 'Usar en Invocar',
      'clashInventoryMatchKitProvisional': 'Kit provisional por partido',
      'clashInventoryEmptyCategory': 'Sin unidades en esta categoría',
      'clashInventoryEmptyFilter': 'No hay ítems en esta categoría',
      'clashInventoryGoToShop': 'Ir a tienda',
      'clashInventoryZeroQuantityHeader': 'Sin stock',
      'clashGachaLocalDisclaimer': 'Simulación local · sin compras reales',
      'clashGachaWalletGems': 'Gemas: {count}',
      'clashGachaWalletTickets': 'Tickets: {count}',
      'clashGachaSingleButton': 'Single ×{cost} gemas',
      'clashGachaMultiButton': 'Multi ×{cost} gemas ({count} cartas)',
      'clashGachaDailyButton': 'Single diario ×{cost} gema',
      'clashGachaDailyUsed': 'Single diario ya usado hoy',
      'clashGachaInsufficientGems': 'Gemas insuficientes',
      'clashGachaEarnGemsHint': 'Consigue gemas en Historia',
      'clashGachaMultiGuarantee': 'Multi: al menos 1 SR garantizado',
      'clashGachaResultTitle': 'Resultado de invocación',
      'clashGachaResultSpent': 'Gastadas: {spent} · Restantes: {remaining}',
      'clashGachaResultNew': 'Nueva',
      'clashGachaResultDuplicate': 'Duplicado',
      'clashGachaResultUpgraded': 'Rareza mejorada',
      'clashGachaResultDuplicates': 'Duplicados: {count}',
      'clashGachaViewHistory': 'Ver historial',
      'clashGachaHistoryTitle': 'Historial de invocaciones',
      'clashGachaHistoryEmpty': 'Todavía no has hecho invocaciones',
      'clashGachaHistoryPullSingle': 'Single',
      'clashGachaHistoryPullMulti': 'Multi',
      'clashGachaHistoryPullDaily': 'Diario',
      'clashGachaHistorySpent': '{spent} gemas',
      'clashGachaHistorySummary': '{count} cartas · Mejor rareza: {rarity}',
      'clashGachaPityProgress': 'Pity SR: {current}/{max}',
      'clashGachaPityRemaining': 'Faltan {count} invocaciones',
      'clashGachaPityChip': 'Pity SR',
      'clashGachaMultiGuaranteeChip': 'Garantía multi',
      'clashGachaTicketsAvailable': 'Tickets disponibles',
      'clashGachaUseTicketButton': 'Usar ticket (×{count})',
      'clashGachaNoTickets': 'No tienes tickets',
      'clashGachaResultTicket': 'Ticket · Restantes gemas: {remaining}',
      'clashGachaHistoryPullTicket': 'Ticket',
      'clashGachaLrXiUnavailable': 'LR/XI no disponibles aún',
      'clashGachaButtonDisabledGems': 'Gemas insuficientes',
      'clashGachaButtonDisabledDaily': 'Diario ya usado',
      'clashGachaButtonDisabledTickets': 'Sin tickets',
      'clashGachaPulling': 'Invocando…',
      'clashGachaResultBestRarity': 'Mejor rareza: {rarity}',
      'clashGachaResultPullType': 'Tirada: {type}',
      'clashGachaClose': 'Cerrar',
      'clashGachaHistoryTotal': '{count} tiradas guardadas',
      'clashGachaHistoryFilterAll': 'Todas',
      'clashGachaHistoryFilterSingle': 'Single',
      'clashGachaHistoryFilterMulti': 'Multi',
      'clashGachaHistoryFilterDaily': 'Diario',
      'clashGachaHistoryFilterTicket': 'Ticket',
      'clashGachaChipSingle': 'Single {cost}',
      'clashGachaChipMulti': 'Multi {cost}',
      'clashGachaChipDaily': 'Diario {cost}',
      'clashGachaChipPity': 'Pity {max}',
      'clashGachaDailyStatusAvailable': 'Diario disponible',
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
      'clashShopLocalDisclaimer': 'Tienda local · sin compras reales',
      'clashShopWalletCoins': 'Monedas: {count}',
      'clashShopProductCost': '{count} monedas',
      'clashShopIncludes': 'Incluye:',
      'clashShopGrantLine': '{label} ×{count}',
      'clashShopBuyButton': 'Comprar',
      'clashShopButtonDisabledCoins': 'Monedas insuficientes',
      'clashShopSectionMaterials': 'Materiales',
      'clashShopSectionTechniques': 'Técnicas',
      'clashShopSectionEvolution': 'Evolución',
      'clashShopSectionTickets': 'Tickets',
      'clashShopConfirmTitle': 'Confirmar compra',
      'clashShopConfirmMessage': '¿Comprar {name} por {cost} monedas?',
      'clashShopConfirmBalanceAfter': 'Saldo tras compra: {count} monedas',
      'clashShopConfirmRewards': 'Recibirás:',
      'clashShopPurchaseSuccess': 'Compra realizada',
      'clashShopPurchaseSuccessDetail': 'Compra realizada: +{quantity} {label}',
      'clashShopInsufficientCoins': 'Monedas insuficientes',
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
      'clashCollectionOwnedCount': '{count} cartas',
      'clashCollectionTotalPower': 'PWR {power}',
      'clashCollectionStrongest': 'Más fuerte: {name} ({power})',
      'clashCollectionActiveFilters': 'Filtros activos',
      'clashCollectionEmptyTitle': 'Sin resultados',
      'clashCollectionEmptyFiltered':
          'Prueba otros filtros o limpia la búsqueda.',
      'clashCollectionEmptyOwnedTitle': 'Colección vacía',
      'clashCollectionEmptyOwned':
          'Aún no tienes cartas. Juega Historia o invoca.',
      'clashCollectionGoStory': 'Ir a Historia',
      'clashCollectionGoSummon': 'Ir a Invocar',
      'clashCollectionClearFilters': 'Limpiar filtros',
      'clashCollectionLoadError': 'No se pudo cargar la colección.',
      'clashCardNotFound': 'Carta no encontrada.',
      'clashCardTeam': 'Equipo',
      'clashCardPosition': 'Posición',
      'clashCardStyle': 'Estilo',
      'clashCardLevel': 'Nivel',
      'clashCardXpTitle': 'Experiencia',
      'clashCardXpProgress': 'EXP: {current} / {needed}',
      'clashCardMaxLevel': 'Nivel máximo',
      'clashCardPower': 'Potencia',
      'clashCardPowerValue': '{power} PWR',
      'clashCardLevelShort': 'Lv {level}',
      'clashCardEvolved': 'Evolucionada',
      'clashCardBonusIncluded': 'Incluye bonus de nivel, evolución y árbol',
      'clashCardPortraitPlaceholder': 'Arte próximamente',
      'clashCardDetailTitle': 'Detalle de carta',
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
      'clashTechniqueBasePower': 'Potencia base',
      'clashTechniquePower': 'Potencia efectiva',
      'clashTechniquePtCost': 'Coste PT',
      'clashTechniqueLevel': 'Nivel',
      'clashTechniqueUpgradeTitle': 'Mejorar técnica',
      'clashTechniqueBookEffect': '+{steps} nivel',
      'clashTechniqueBookUse': 'Usar',
      'clashTechniqueLevelUpSnack': '{name}: {from} → {to}',
      'clashActionUpgrade': 'Mejorar',
      'clashExpMaterialXp': '+{xp} EXP',
      'clashExpMaterialQuantity': 'Cantidad: {count}',
      'clashExpMaterialUseOne': 'Usar 1',
      'clashExpMaterialLevelUp': 'Sube de nivel: {from} → {to}',
      'clashUpgradeMaxLevelHint':
          'Nivel máximo alcanzado. No se pueden usar materiales.',
      'clashActionEvolve': 'Evolución',
      'clashEvolutionCannotEvolveMore': 'Esta carta no puede evolucionar más',
      'clashEvolutionRarityArrow': '{from} → {to}',
      'clashEvolutionRequiredLevel': 'Nivel requerido: {level}',
      'clashEvolutionCurrentLevel': 'Nivel actual: {level}',
      'clashEvolutionRequiredMaterial':
          '{name} ×{required} (tienes: {available})',
      'clashEvolutionCoinsPending': 'Monedas: pendiente',
      'clashEvolutionButton': 'Evolucionar',
      'clashEvolutionMissingLevel': 'Nivel insuficiente',
      'clashEvolutionMissingMaterial': 'Faltan materiales',
      'clashEvolutionSnack': 'Carta evolucionada: {from} → {to}',
      'clashSkillTreeTitle': 'Árbol de habilidades',
      'clashSkillTreeLockedRarity': 'Disponible al alcanzar SR',
      'clashSkillTreeDuplicates': 'Duplicados disponibles: {count}',
      'clashSkillTreeProgress': 'Nodos desbloqueados: {current}/{max}',
      'clashSkillTreeNodeLocked': 'Bloqueado',
      'clashSkillTreeNodeAvailable': 'Disponible',
      'clashSkillTreeNodeUnlocked': 'Desbloqueado',
      'clashSkillTreeUnlock': 'Desbloquear',
      'clashSkillTreeNoDuplicates': 'Sin duplicados',
      'clashSkillTreeUnlockSnack': 'Nodo desbloqueado: {boost}',
      'clashCardDuplicateCopies': '+{count} copias',
      'clashCardSkillTreeShort': 'Árbol {current}/{max}',
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
      'clashLineupBlockAlreadyUsed': 'Ya usada',
      'clashLineupChooseSlot': 'Elegir',
      'clashLineupSlotsFilled': '{filled}/7 posiciones',
      'clashLineupReadyToPlay': 'Listo para jugar',
      'clashLineupNoGoalkeeper': 'Sin portero',
      'clashLineupZoneAttack': 'Ataque',
      'clashLineupZoneMidfield': 'Medio',
      'clashLineupZoneDefense': 'Defensa',
      'clashLineupZoneGoalkeeper': 'Portería',
      'clashLineupPickerCompatible': 'Compatibles',
      'clashLineupPickerAll': 'Todas',
      'clashLineupPickerByRarity': 'Rareza',
      'clashLineupCardCompatible': 'Compatible',
      'clashLineupCardIncompatible': 'Incompatible',
      'clashLineupNoOwnedCards': 'No tienes cartas en tu colección.',
      'clashTeamSummaryTitle': 'Resumen del equipo',
      'clashTeamActiveLineup': 'Alineación activa',
      'clashTeamNoActiveLineup': 'Sin alineación activa',
      'clashTeamUpgradeCards': 'Mejorar cartas',
      'clashTeamComingSoonBadge': 'Próximamente',
      'clashTeamTactics': 'Tácticas',
      'clashTeamAdvancedFormations': 'Formaciones avanzadas',
      'clashTeamComingSoonSection': 'Próximamente',
      'clashStoryTypeStory': 'Historia',
      'clashStoryTypeMatch': 'Partido',
      'clashStoryTypeMixed': 'Mixto',
      'clashStoryStatusLocked': 'Bloqueado',
      'clashStoryStatusAvailable': 'Disponible',
      'clashStoryStatusCompleted': 'Completado',
      'clashStoryProgressTitle': 'Progreso',
      'clashStoryCurrentChapter': 'Capítulo actual',
      'clashStoryLevelsProgress': '{completed}/{total} niveles',
      'clashStoryFirstClear': 'Primera vez',
      'clashStoryFirstClearClaimed': 'Primera vez reclamada',
      'clashStoryFirstClearRewardsTitle': 'Recompensas de primera vez',
      'clashStoryActionRead': 'Leer',
      'clashStoryActionPlay': 'Jugar',
      'clashStoryActionReplay': 'Repetir',
      'clashStoryCompletePreviousLevel': 'Completa el nivel anterior',
      'clashStoryPrepareTeam': 'Preparar equipo',
      'clashStoryStartMatch': 'Empezar partido',
      'clashStoryReadAgain': 'Leer de nuevo',
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
      'clashMatchPrepareRival': 'Rival',
      'clashMatchPrepareDifficulty': 'Dificultad {difficulty}',
      'clashMatchPrepareStandardRival': 'Rival estándar',
      'clashMatchPrepareViewRivalLineup': 'Ver alineación rival',
      'clashMatchPrepareOwnPower': 'Tu potencia',
      'clashMatchPrepareRivalPower': 'Potencia rival',
      'clashMatchPreparePowerDifference': 'Diferencia',
      'clashMatchPreparePowerAdvantage': 'Ventaja clara',
      'clashMatchPreparePowerEven': 'Partido igualado',
      'clashMatchPreparePowerDisadvantage': 'Desventaja',
      'clashMatchPreparePowerVeryHard': 'Muy difícil',
      'clashMatchPrepareDifficultyEasy': 'Fácil',
      'clashMatchPrepareDifficultyNormal': 'Normal',
      'clashMatchPrepareDifficultyHard': 'Difícil',
      'clashMatchPrepareDifficultyChip': 'Dificultad {difficulty} · {label}',
      'clashMatchPrepareRivalPlayersCount': '{current}/{total} jugadores',
      'clashMatchPreparePredominantStyles': 'Estilos predominantes',
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
      'clashMatchRetry': 'Reintentar',
      'clashMatchFinalScore': 'Marcador final: {user} - {rival}',
      'clashMatchLevelCompleted': 'Nivel completado: {title}',
      'clashMatchNoRewards': 'Sin recompensas en esta derrota.',
      'clashMatchObjectivesTitle': 'Objetivos',
      'clashMatchObjectiveCompleted': 'Completado',
      'clashMatchObjectiveIncomplete': 'No completado',
      'clashMatchObjectiveStatusPending': 'Pendiente',
      'clashMatchObjectiveStatusInProgress': 'En progreso',
      'clashMatchObjectiveStatusCompleted': 'Cumplido',
      'clashMatchObjectiveStatusFailed': 'Fallido',
      'clashMatchObjectiveStatusReviewedAtEnd': 'Se revisa al final',
      'clashMatchObjectivesNone': 'Sin objetivos secundarios',
      'clashMatchEndCompletedSubtitle': 'Partido completado',
      'clashMatchEndNoRewards': 'No se obtuvieron recompensas',
      'clashMatchEndScoreYouRival': 'Tú {user} - {rival} Rival',
      'clashMatchRewardsEarnedTitle': 'Recompensas obtenidas',
      'clashMatchRewardsPendingTitle': 'Recompensas pendientes',
      'clashMatchRewardsEmptyState': 'Sin recompensas en este intento',
      'clashMatchCardProgressTitle': 'Progreso de cartas',
      'clashMatchObjectiveRetryHint':
          'Completa el objetivo en otro intento para conseguirlas.',
      'clashMatchLineupXpTotal': '+{amount} EXP para la alineación',
      'clashMatchObjectiveFailConcededGoal': 'Encajaste un gol',
      'clashMatchObjectiveFailNoShotTechnique':
          'No marcaste con técnica de tiro',
      'clashMatchContinue': 'Continuar',
      'clashMatchCardLevelFromTo': 'Nv. {from} → {to}',
      'clashMatchObjectivesDefeatHint':
          'Debes ganar el partido para recibir recompensas de objetivos',
      'clashMatchRewardsTotalTitle': 'Total obtenido',
      'clashMatchCardXpTitle': 'Experiencia de cartas',
      'clashMatchCardXpGained': '+{amount} EXP',
      'clashMatchCardLevelUp': 'Nv. {from} → {to} · Sube de nivel',
      'clashMatchCardLevelSame': 'Nv. {level}',
      'clashMatchNoCardXpOnDefeat': 'Sin EXP por derrota',
      'clashMatchRewardsTitle': 'Recompensas del nivel',
      'clashMatchRewardsBasic': 'Progreso registrado al reclamar.',
      'clashMatchRewardGems': 'Gemas: +{amount}',
      'clashMatchRewardCoins': 'Monedas: +{amount}',
      'clashMatchRewardCards': 'Cartas: +{count}',
      'clashMatchStatusBallUser': 'Balón para Eternal XI',
      'clashMatchStatusShootNeedArea':
          'Avanza hasta el área rival para poder tirar',
      'clashMatchStatusCanShoot': 'Estás en posición de tiro',
      'clashMatchStatusRivalTurn': 'Turno rival',
      'clashMatchStatusRivalTurnHint':
          'Pulsa «Continuar acción rival» para ver su jugada',
      'clashMatchStatusHalftime': 'Descanso',
      'clashMatchStatusHalftimeHint':
          'Recupera PT o resistencia con objetos antes de seguir',
      'clashMatchStatusDefendRivalHint':
          'El rival se aproxima: elige cómo defender',
      'clashMatchStatusPickDefender': 'Elige quién defiende',
      'clashMatchStatusUserDuel': 'Duelo en curso',
      'clashMatchStatusUserAdvanceDuelHint':
          'Elige regate normal o supertécnica',
      'clashMatchStatusUserShotDuelHint': 'Elige tiro normal o supertécnica',
      'clashMatchStatusDuelResult': 'Resultado del duelo',
      'clashMatchStatusDuelResultHint': 'Pulsa Continuar para seguir jugando',
      'clashMatchPassUnavailable': 'No hay compañeros válidos para pasar',
      'clashMatchActionPass': 'Pasar',
      'clashMatchActionAdvance': 'Avanzar',
      'clashMatchActionShootSoon': 'Tirar (próximamente)',
      'clashMatchActionShoot': 'Tirar',
      'clashMatchActionShootNeedArea': 'Llega al área para tirar',
      'clashMatchActionRivalSim': 'Simular acción rival',
      'clashMatchActionRivalContinue': 'Continuar acción rival',
      'clashMatchRivalTurnTitle': 'Turno rival',
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
      'clashMatchHeaderVsRival': 'vs {rival}',
      'clashMatchStatusChipUserPossession': 'Tu posesión',
      'clashMatchStatusChipRivalPossession': 'Posesión rival',
      'clashMatchStatusChipDuel': 'Duelo',
      'clashMatchStatusChipHalftime': 'Descanso',
      'clashMatchStatusChipFinished': 'Finalizado',
      'clashMatchActivePlayerTitle': 'Tu jugador activo',
      'clashMatchRivalActivePlayerTitle': 'Rival activo',
      'clashMatchPlayerPowerLabel': 'Potencia {power}',
      'clashMatchActionPanelTitle': 'Acciones',
      'clashMatchActionResolveDuel': 'Resuelve el duelo primero',
      'clashMatchActionWaitDefense': 'Espera tu reacción defensiva',
      'clashMatchPassRiskLabel': 'Riesgo {percent}%',
      'clashMatchPitchLegendBall': 'Balón',
      'clashMatchPitchLegendUser': 'Tú',
      'clashMatchPitchLegendRival': 'Rival',
      'clashMatchHalftimeItemsHint': 'Solo puedes usar objetos en el descanso',
      'clashMatchDefendChooseSave': 'Elige parada',
      'clashMatchRivalPreparingAdvance': 'El rival prepara un avance',
      'clashMatchRivalPreparingShot': 'El rival prepara un tiro',
      'clashMatchRivalAwaitingDefense': 'El rival espera tu defensa',
      'clashMatchDuelVsLabel': 'VS',
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
      'clashMatchDefendAdvanceTitle': 'Defiende el avance',
      'clashMatchDefendShotTitle': 'Detén el tiro',
      'clashMatchDefendSelectDefenderTitle': 'Elige quién defiende',
      'clashMatchDefendNormalDefense': 'Defensa normal',
      'clashMatchDefendNormalSave': 'Parada normal',
      'clashMatchRivalAttackNormal': 'Rival: acción normal',
      'clashMatchRivalAttackTechnique': 'Rival: {name}',
      'clashMatchDefendCandidateMeta':
          'DEF {defense} · PT {pt} · RES {stamina} · {style}',
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
      'clashHomeHubTitle': 'Eternal Clash',
      'clashHomeHubSubtitle': 'Story, events and cards',
      'clashHomePlaySection': 'Play',
      'clashHomeDailyActivity': 'Daily activity',
      'clashHomeNoticesSection': 'Notices and rewards',
      'clashHomePrimaryStoryDesc': 'Saga and prologue levels',
      'clashHomePrimaryEventsDesc': 'Character events',
      'clashHomePrimaryTeamDesc': '7vs7 lineup',
      'clashHomePrimarySummonDesc': 'Summon cards',
      'clashHomePrimaryLocked': 'Unlock it in Story.',
      'clashHomeFeaturedEventTitle': 'Featured event',
      'clashHomeFeaturedEventEnter': 'Enter',
      'clashHomeFeaturedEventProgress': '{completed}/{total} stages',
      'clashHomeShopBalance': 'Coins: {coins} · Gems: {gems}',
      'clashHomeShopView': 'View',
      'clashDailyMissionsTitle': 'Daily missions',
      'clashDailyMissionsResetHint': 'They reset tomorrow',
      'clashDailyMissionsCompletedSummary': 'Completed {completed}/{total}',
      'clashDailyMissionsClaimedSummary': 'Claimed {claimed}/{total}',
      'clashDailyMissionsStatusInProgress': 'In progress',
      'clashDailyMissionsStatusClaim': 'Claim',
      'clashDailyMissionsStatusClaimed': 'Claimed',
      'clashDailyMissionsClaimAll': 'Claim all',
      'clashDailyMissionsClaimSuccess': 'Reward claimed',
      'clashDailyMissionsHomeTitle': 'Daily missions',
      'clashDailyMissionsHomePending': '{count} ready to claim',
      'clashDailyMissionsHomeView': 'View',
      'clashDailyMissionsRewardCoins': '{count} coins',
      'clashDailyMissionsRewardGems': '{count} gems',
      'clashDailyMissionsProgress': '{current}/{target}',
      'clashDailyMissionsEmpty': 'No missions available',
      'clashEngagementRewardsLabel': 'Reward',
      'clashAchievementsTitle': 'Achievements',
      'clashAchievementsPermanentHint':
          'Permanent progress. They do not reset daily.',
      'clashAchievementsCompletedSummary': 'Completed {completed}/{total}',
      'clashAchievementsClaimedSummary': 'Claimed {claimed}/{total}',
      'clashAchievementsFilterAll': 'All',
      'clashAchievementsFilterInProgress': 'In progress',
      'clashAchievementsFilterCompleted': 'Completed',
      'clashAchievementsFilterClaimed': 'Claimed',
      'clashAchievementsEmptyFilter': 'No achievements in this filter',
      'clashAchievementsStatusInProgress': 'In progress',
      'clashAchievementsStatusClaim': 'Claim',
      'clashAchievementsStatusClaimed': 'Claimed',
      'clashAchievementsClaimAll': 'Claim all',
      'clashAchievementsClaimSuccess': 'Reward claimed',
      'clashAchievementsHomeTitle': 'Achievements',
      'clashAchievementsHomePending': '{count} ready to claim',
      'clashAchievementsHomeView': 'View',
      'clashAchievementsRewardCoins': '{count} coins',
      'clashAchievementsRewardGems': '{count} gems',
      'clashAchievementsProgress': '{current}/{target}',
      'clashWeeklyMissionsTitle': 'Weekly missions',
      'clashWeeklyMissionsResetHint': 'They reset on Monday',
      'clashWeeklyMissionsWeekLabel': 'Current week: {weekKey}',
      'clashWeeklyMissionsCompletedSummary': 'Completed {completed}/{total}',
      'clashWeeklyMissionsClaimedSummary': 'Claimed {claimed}/{total}',
      'clashWeeklyMissionsStatusInProgress': 'In progress',
      'clashWeeklyMissionsStatusClaim': 'Claim',
      'clashWeeklyMissionsStatusClaimed': 'Claimed',
      'clashWeeklyMissionsClaimAll': 'Claim all',
      'clashWeeklyMissionsClaimSuccess': 'Reward claimed',
      'clashWeeklyMissionsHomeTitle': 'Weekly missions',
      'clashWeeklyMissionsHomePending': '{count} ready to claim',
      'clashWeeklyMissionsHomeView': 'View',
      'clashWeeklyMissionsRewardCoins': '{count} coins',
      'clashWeeklyMissionsRewardGems': '{count} gems',
      'clashWeeklyMissionsProgress': '{current}/{target}',
      'clashWeeklyMissionsEmpty': 'No weekly missions available',
      'clashNewsTitle': 'News',
      'clashNewsMarkAllRead': 'Mark all as read',
      'clashNewsFilterAll': 'All',
      'clashNewsFilterUnread': 'Unread',
      'clashNewsFilterUpdates': 'Updates',
      'clashNewsFilterEvents': 'Events',
      'clashNewsFilterBanners': 'Banners',
      'clashNewsFilterNotices': 'Notices',
      'clashNewsEmptyFilter': 'No news in this filter',
      'clashNewsBadgeNew': 'New',
      'clashNewsTypeUpdate': 'Update',
      'clashNewsTypeEvent': 'Event',
      'clashNewsTypeBanner': 'Banner',
      'clashNewsTypeMaintenance': 'Maintenance',
      'clashNewsTypeGift': 'Gift',
      'clashNewsHomeTitle': 'News',
      'clashNewsHomeUnread': '{count} unread',
      'clashNewsHomeAllCaughtUp': 'All caught up',
      'clashNewsHomeView': 'View',
      'clashNewsUnreadSummary': '{count} unread',
      'clashGiftsTitle': 'Gifts',
      'clashGiftsPendingSummary': 'Pending {count}',
      'clashGiftsClaimedSummary': 'Claimed {claimed}/{total}',
      'clashGiftsClaimAll': 'Claim all',
      'clashGiftsClaimSuccess': 'Gift claimed',
      'clashGiftsStatusAvailable': 'Available',
      'clashGiftsStatusClaimed': 'Claimed',
      'clashGiftsStatusExpired': 'Expired',
      'clashGiftsStatusClaim': 'Claim',
      'clashGiftsHomeTitle': 'Gifts',
      'clashGiftsHomePending': '{count} pending',
      'clashGiftsHomeNone': 'No pending gifts',
      'clashGiftsHomeView': 'View',
      'clashGiftsEmptyPending': 'No pending gifts',
      'clashEventsTitle': 'Events',
      'clashEventsEmpty': 'No events available',
      'clashEventsNotFound': 'Event not found',
      'clashEventsEnter': 'Enter',
      'clashEventsProgress': 'Stages completed {completed}/{total}',
      'clashEventsStagesTitle': 'Stages',
      'clashEventsFeaturedCard': 'Featured card: {cardId}',
      'clashEventsStageLocked': 'Locked',
      'clashEventsStageAvailable': 'Available',
      'clashEventsStageCompleted': 'Completed',
      'clashEventsStageRead': 'Read',
      'clashEventsStageReadAgain': 'Read again',
      'clashEventsStagePrepare': 'Prepare match',
      'clashEventsStageRepeat': 'Repeat',
      'clashEventsStageTypeStory': 'Story',
      'clashEventsStageTypeMatch': '7v7 match',
      'clashEventsStageClearCount': 'Clears: {count}',
      'clashEventsFirstClear': 'First clear',
      'clashEventsRepeatRewards': 'Repeat',
      'clashEventsStoryComplete': 'Complete',
      'clashEventsStoryPlaceholder': 'Continue the training.',
      'clashEventsStageNotFound': 'Stage not found',
      'clashEventsRewardTitle': 'Rewards',
      'clashEventsRewardFirstClear': 'First clear!',
      'clashEventsRewardRepeat': 'Repeat reward',
      'clashEventsRewardDuplicate': 'Duplicate copy: {cardId}',
      'clashEventsRewardContinue': 'Continue',
      'clashEventsCardXpReward': 'Card XP',
      'clashEventsHomeTitle': 'Events',
      'clashEventsHomeAvailable': '{count} available',
      'clashEventsHomeNone': 'No active events',
      'clashEventsHomeView': 'View',
      'clashEventsBack': 'Back to event',
      'clashEventsMatchDefeatHint': 'No rewards on defeat. You can retry.',
      'clashEventsStageCompletedTitle': 'Stage completed: {title}',
      'clashEventsLocalTestLabel': 'Local test events',
      'clashEventsFeaturedCardTitle': 'Featured card',
      'clashEventsFirstVictory': 'First victory',
      'clashEventsRepeats': 'Repeats',
      'clashEventsRepeatable': 'Repeatable',
      'clashEventsCompletedTimes': 'Completed {count} times',
      'clashEventsFirstTimeCard': 'First time: you get the card',
      'clashEventsRepeatDuplicates': 'Repeats: duplicates/materials',
      'clashEventsAvailableCount': '{count} events available',
      'clashTeamLineup7': '7v7 lineup',
      'clashTeamLineup11': '11v11 lineup',
      'clashTeamCharacters': 'Characters',
      'clashTeamUpgrade': 'Upgrade',
      'clashTeamSkillTree': 'Skill tree',
      'clashTeamInventory': 'Inventory',
      'clashInventoryTitle': 'Inventory',
      'clashInventoryAll': 'All',
      'clashInventoryExp': 'EXP materials',
      'clashInventoryTechnique': 'Technique books',
      'clashInventoryEvolution': 'Evolution materials',
      'clashInventoryMatch': 'Match items',
      'clashInventoryTickets': 'Tickets',
      'clashInventorySummaryTitle': 'Summary',
      'clashInventoryTotalItems': 'Total units: {count}',
      'clashInventoryCategoryCount': '{category}: {count}',
      'clashInventoryUseFromCardDetail': 'Use from card detail',
      'clashInventoryUseDuringHalftime': 'Use during halftime',
      'clashInventoryUseInSummon': 'Use in Summon',
      'clashInventoryMatchKitProvisional': 'Provisional kit per match',
      'clashInventoryEmptyCategory': 'No units in this category',
      'clashInventoryEmptyFilter': 'No items in this category',
      'clashInventoryGoToShop': 'Go to shop',
      'clashInventoryZeroQuantityHeader': 'Out of stock',
      'clashGachaLocalDisclaimer': 'Local simulation · no real purchases',
      'clashGachaWalletGems': 'Gems: {count}',
      'clashGachaWalletTickets': 'Tickets: {count}',
      'clashGachaSingleButton': 'Single ×{cost} gems',
      'clashGachaMultiButton': 'Multi ×{cost} gems ({count} cards)',
      'clashGachaDailyButton': 'Daily single ×{cost} gem',
      'clashGachaDailyUsed': 'Daily single already used today',
      'clashGachaInsufficientGems': 'Insufficient gems',
      'clashGachaEarnGemsHint': 'Earn gems in Story',
      'clashGachaMultiGuarantee': 'Multi: at least 1 SR guaranteed',
      'clashGachaResultTitle': 'Summon result',
      'clashGachaResultSpent': 'Spent: {spent} · Remaining: {remaining}',
      'clashGachaResultNew': 'New',
      'clashGachaResultDuplicate': 'Duplicate',
      'clashGachaResultUpgraded': 'Rarity upgraded',
      'clashGachaResultDuplicates': 'Duplicates: {count}',
      'clashGachaViewHistory': 'View history',
      'clashGachaHistoryTitle': 'Summon history',
      'clashGachaHistoryEmpty': 'You have not summoned yet',
      'clashGachaHistoryPullSingle': 'Single',
      'clashGachaHistoryPullMulti': 'Multi',
      'clashGachaHistoryPullDaily': 'Daily',
      'clashGachaHistorySpent': '{spent} gems',
      'clashGachaHistorySummary': '{count} cards · Best rarity: {rarity}',
      'clashGachaPityProgress': 'SR pity: {current}/{max}',
      'clashGachaPityRemaining': '{count} summons remaining',
      'clashGachaPityChip': 'SR pity',
      'clashGachaMultiGuaranteeChip': 'Multi guarantee',
      'clashGachaTicketsAvailable': 'Available tickets',
      'clashGachaUseTicketButton': 'Use ticket (×{count})',
      'clashGachaNoTickets': 'You have no tickets',
      'clashGachaResultTicket': 'Ticket · Gems remaining: {remaining}',
      'clashGachaHistoryPullTicket': 'Ticket',
      'clashGachaLrXiUnavailable': 'LR/XI not available yet',
      'clashGachaButtonDisabledGems': 'Insufficient gems',
      'clashGachaButtonDisabledDaily': 'Daily already used',
      'clashGachaButtonDisabledTickets': 'No tickets',
      'clashGachaPulling': 'Summoning…',
      'clashGachaResultBestRarity': 'Best rarity: {rarity}',
      'clashGachaResultPullType': 'Pull: {type}',
      'clashGachaClose': 'Close',
      'clashGachaHistoryTotal': '{count} pulls saved',
      'clashGachaHistoryFilterAll': 'All',
      'clashGachaHistoryFilterSingle': 'Single',
      'clashGachaHistoryFilterMulti': 'Multi',
      'clashGachaHistoryFilterDaily': 'Daily',
      'clashGachaHistoryFilterTicket': 'Ticket',
      'clashGachaChipSingle': 'Single {cost}',
      'clashGachaChipMulti': 'Multi {cost}',
      'clashGachaChipDaily': 'Daily {cost}',
      'clashGachaChipPity': 'Pity {max}',
      'clashGachaDailyStatusAvailable': 'Daily available',
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
      'clashShopLocalDisclaimer': 'Local shop · no real purchases',
      'clashShopWalletCoins': 'Coins: {count}',
      'clashShopProductCost': '{count} coins',
      'clashShopIncludes': 'Includes:',
      'clashShopGrantLine': '{label} ×{count}',
      'clashShopBuyButton': 'Buy',
      'clashShopButtonDisabledCoins': 'Insufficient coins',
      'clashShopSectionMaterials': 'Materials',
      'clashShopSectionTechniques': 'Techniques',
      'clashShopSectionEvolution': 'Evolution',
      'clashShopSectionTickets': 'Tickets',
      'clashShopConfirmTitle': 'Confirm purchase',
      'clashShopConfirmMessage': 'Buy {name} for {cost} coins?',
      'clashShopConfirmBalanceAfter': 'Balance after purchase: {count} coins',
      'clashShopConfirmRewards': 'You will receive:',
      'clashShopPurchaseSuccess': 'Purchase completed',
      'clashShopPurchaseSuccessDetail':
          'Purchase completed: +{quantity} {label}',
      'clashShopInsufficientCoins': 'Insufficient coins',
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
      'clashCollectionOwnedCount': '{count} cards',
      'clashCollectionTotalPower': 'PWR {power}',
      'clashCollectionStrongest': 'Strongest: {name} ({power})',
      'clashCollectionActiveFilters': 'Active filters',
      'clashCollectionEmptyTitle': 'No results',
      'clashCollectionEmptyFiltered': 'Try other filters or clear the search.',
      'clashCollectionEmptyOwnedTitle': 'Empty collection',
      'clashCollectionEmptyOwned':
          'You have no cards yet. Play Story or summon.',
      'clashCollectionGoStory': 'Go to Story',
      'clashCollectionGoSummon': 'Go to Summon',
      'clashCollectionClearFilters': 'Clear filters',
      'clashCollectionLoadError': 'Could not load the collection.',
      'clashCardNotFound': 'Card not found.',
      'clashCardTeam': 'Team',
      'clashCardPosition': 'Position',
      'clashCardStyle': 'Style',
      'clashCardLevel': 'Level',
      'clashCardXpTitle': 'Experience',
      'clashCardXpProgress': 'XP: {current} / {needed}',
      'clashCardMaxLevel': 'Max level',
      'clashCardPower': 'Power',
      'clashCardPowerValue': '{power} PWR',
      'clashCardLevelShort': 'Lv {level}',
      'clashCardEvolved': 'Evolved',
      'clashCardBonusIncluded': 'Includes level, evolution and tree bonuses',
      'clashCardPortraitPlaceholder': 'Artwork coming soon',
      'clashCardDetailTitle': 'Card detail',
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
      'clashTechniqueBasePower': 'Base power',
      'clashTechniquePower': 'Effective power',
      'clashTechniquePtCost': 'TP cost',
      'clashTechniqueLevel': 'Level',
      'clashTechniqueUpgradeTitle': 'Upgrade technique',
      'clashTechniqueBookEffect': '+{steps} level',
      'clashTechniqueBookUse': 'Use',
      'clashTechniqueLevelUpSnack': '{name}: {from} → {to}',
      'clashActionUpgrade': 'Upgrade',
      'clashExpMaterialXp': '+{xp} XP',
      'clashExpMaterialQuantity': 'Quantity: {count}',
      'clashExpMaterialUseOne': 'Use 1',
      'clashExpMaterialLevelUp': 'Level up: {from} → {to}',
      'clashUpgradeMaxLevelHint':
          'Max level reached. Materials cannot be used.',
      'clashActionEvolve': 'Evolution',
      'clashEvolutionCannotEvolveMore': 'This card cannot evolve further',
      'clashEvolutionRarityArrow': '{from} → {to}',
      'clashEvolutionRequiredLevel': 'Required level: {level}',
      'clashEvolutionCurrentLevel': 'Current level: {level}',
      'clashEvolutionRequiredMaterial':
          '{name} ×{required} (owned: {available})',
      'clashEvolutionCoinsPending': 'Coins: pending',
      'clashEvolutionButton': 'Evolve',
      'clashEvolutionMissingLevel': 'Insufficient level',
      'clashEvolutionMissingMaterial': 'Missing materials',
      'clashEvolutionSnack': 'Card evolved: {from} → {to}',
      'clashSkillTreeTitle': 'Skill tree',
      'clashSkillTreeLockedRarity': 'Available when reaching SR',
      'clashSkillTreeDuplicates': 'Available duplicates: {count}',
      'clashSkillTreeProgress': 'Unlocked nodes: {current}/{max}',
      'clashSkillTreeNodeLocked': 'Locked',
      'clashSkillTreeNodeAvailable': 'Available',
      'clashSkillTreeNodeUnlocked': 'Unlocked',
      'clashSkillTreeUnlock': 'Unlock',
      'clashSkillTreeNoDuplicates': 'No duplicates',
      'clashSkillTreeUnlockSnack': 'Node unlocked: {boost}',
      'clashCardDuplicateCopies': '+{count} copies',
      'clashCardSkillTreeShort': 'Tree {current}/{max}',
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
      'clashLineupBlockAlreadyUsed': 'Already used',
      'clashLineupChooseSlot': 'Choose',
      'clashLineupSlotsFilled': '{filled}/7 positions',
      'clashLineupReadyToPlay': 'Ready to play',
      'clashLineupNoGoalkeeper': 'No goalkeeper',
      'clashLineupZoneAttack': 'Attack',
      'clashLineupZoneMidfield': 'Midfield',
      'clashLineupZoneDefense': 'Defense',
      'clashLineupZoneGoalkeeper': 'Goal',
      'clashLineupPickerCompatible': 'Compatible',
      'clashLineupPickerAll': 'All',
      'clashLineupPickerByRarity': 'Rarity',
      'clashLineupCardCompatible': 'Compatible',
      'clashLineupCardIncompatible': 'Incompatible',
      'clashLineupNoOwnedCards': 'You do not own any cards yet.',
      'clashTeamSummaryTitle': 'Team summary',
      'clashTeamActiveLineup': 'Active lineup',
      'clashTeamNoActiveLineup': 'No active lineup',
      'clashTeamUpgradeCards': 'Upgrade cards',
      'clashTeamComingSoonBadge': 'Coming soon',
      'clashTeamTactics': 'Tactics',
      'clashTeamAdvancedFormations': 'Advanced formations',
      'clashTeamComingSoonSection': 'Coming soon',
      'clashStoryLoadError': 'Could not load story.',
      'clashStoryTypeStory': 'Story',
      'clashStoryTypeMatch': 'Match',
      'clashStoryTypeMixed': 'Mixed',
      'clashStoryStatusLocked': 'Locked',
      'clashStoryStatusAvailable': 'Available',
      'clashStoryStatusCompleted': 'Completed',
      'clashStoryProgressTitle': 'Progress',
      'clashStoryCurrentChapter': 'Current chapter',
      'clashStoryLevelsProgress': '{completed}/{total} levels',
      'clashStoryFirstClear': 'First clear',
      'clashStoryFirstClearClaimed': 'First clear claimed',
      'clashStoryFirstClearRewardsTitle': 'First-time rewards',
      'clashStoryActionRead': 'Read',
      'clashStoryActionPlay': 'Play',
      'clashStoryActionReplay': 'Replay',
      'clashStoryCompletePreviousLevel': 'Complete the previous level',
      'clashStoryPrepareTeam': 'Prepare team',
      'clashStoryStartMatch': 'Start match',
      'clashStoryReadAgain': 'Read again',
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
      'clashMatchPrepareRival': 'Rival',
      'clashMatchPrepareDifficulty': 'Difficulty {difficulty}',
      'clashMatchPrepareStandardRival': 'Standard rival',
      'clashMatchPrepareViewRivalLineup': 'View rival lineup',
      'clashMatchPrepareOwnPower': 'Your power',
      'clashMatchPrepareRivalPower': 'Rival power',
      'clashMatchPreparePowerDifference': 'Difference',
      'clashMatchPreparePowerAdvantage': 'Clear advantage',
      'clashMatchPreparePowerEven': 'Even match',
      'clashMatchPreparePowerDisadvantage': 'Disadvantage',
      'clashMatchPreparePowerVeryHard': 'Very hard',
      'clashMatchPrepareDifficultyEasy': 'Easy',
      'clashMatchPrepareDifficultyNormal': 'Normal',
      'clashMatchPrepareDifficultyHard': 'Hard',
      'clashMatchPrepareDifficultyChip': 'Difficulty {difficulty} · {label}',
      'clashMatchPrepareRivalPlayersCount': '{current}/{total} players',
      'clashMatchPreparePredominantStyles': 'Predominant styles',
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
      'clashMatchRetry': 'Retry',
      'clashMatchFinalScore': 'Final score: {user} - {rival}',
      'clashMatchLevelCompleted': 'Level completed: {title}',
      'clashMatchNoRewards': 'No rewards on defeat.',
      'clashMatchObjectivesTitle': 'Objectives',
      'clashMatchObjectiveCompleted': 'Completed',
      'clashMatchObjectiveIncomplete': 'Not completed',
      'clashMatchObjectiveStatusPending': 'Pending',
      'clashMatchObjectiveStatusInProgress': 'In progress',
      'clashMatchObjectiveStatusCompleted': 'Completed',
      'clashMatchObjectiveStatusFailed': 'Failed',
      'clashMatchObjectiveStatusReviewedAtEnd': 'Checked at the end',
      'clashMatchObjectivesNone': 'No secondary objectives',
      'clashMatchEndCompletedSubtitle': 'Match completed',
      'clashMatchEndNoRewards': 'No rewards earned',
      'clashMatchEndScoreYouRival': 'You {user} - {rival} Rival',
      'clashMatchRewardsEarnedTitle': 'Rewards earned',
      'clashMatchRewardsPendingTitle': 'Pending rewards',
      'clashMatchRewardsEmptyState': 'No rewards this attempt',
      'clashMatchCardProgressTitle': 'Card progress',
      'clashMatchObjectiveRetryHint':
          'Complete the objective on another attempt to earn them.',
      'clashMatchLineupXpTotal': '+{amount} XP for the lineup',
      'clashMatchObjectiveFailConcededGoal': 'You conceded a goal',
      'clashMatchObjectiveFailNoShotTechnique':
          'You did not score with a shot technique',
      'clashMatchContinue': 'Continue',
      'clashMatchCardLevelFromTo': 'Lv. {from} → {to}',
      'clashMatchObjectivesDefeatHint':
          'You must win the match to receive objective rewards',
      'clashMatchRewardsTotalTitle': 'Total earned',
      'clashMatchCardXpTitle': 'Card experience',
      'clashMatchCardXpGained': '+{amount} XP',
      'clashMatchCardLevelUp': 'Lv. {from} → {to} · Level up',
      'clashMatchCardLevelSame': 'Lv. {level}',
      'clashMatchNoCardXpOnDefeat': 'No XP on defeat',
      'clashMatchRewardsTitle': 'Level rewards',
      'clashMatchRewardsBasic': 'Progress saved when you claim.',
      'clashMatchRewardGems': 'Gems: +{amount}',
      'clashMatchRewardCoins': 'Coins: +{amount}',
      'clashMatchRewardCards': 'Cards: +{count}',
      'clashMatchStatusBallUser': 'Ball for Eternal XI',
      'clashMatchStatusShootNeedArea': 'Advance to the rival box to shoot',
      'clashMatchStatusCanShoot': 'You are in shooting range',
      'clashMatchStatusRivalTurn': 'Rival turn',
      'clashMatchStatusRivalTurnHint':
          'Tap «Continue rival action» to see their play',
      'clashMatchStatusHalftime': 'Halftime',
      'clashMatchStatusHalftimeHint':
          'Recover PT or stamina with items before continuing',
      'clashMatchStatusDefendRivalHint':
          'The rival is closing in: choose how to defend',
      'clashMatchStatusPickDefender': 'Choose a defender',
      'clashMatchStatusUserDuel': 'Duel in progress',
      'clashMatchStatusUserAdvanceDuelHint':
          'Choose normal dribble or super technique',
      'clashMatchStatusUserShotDuelHint':
          'Choose normal shot or super technique',
      'clashMatchStatusDuelResult': 'Duel result',
      'clashMatchStatusDuelResultHint': 'Tap Continue to keep playing',
      'clashMatchPassUnavailable': 'No valid teammates to pass to',
      'clashMatchActionPass': 'Pass',
      'clashMatchActionAdvance': 'Advance',
      'clashMatchActionShootSoon': 'Shoot (coming soon)',
      'clashMatchActionShoot': 'Shoot',
      'clashMatchActionShootNeedArea': 'Reach the box to shoot',
      'clashMatchActionRivalSim': 'Simulate rival action',
      'clashMatchActionRivalContinue': 'Continue rival action',
      'clashMatchRivalTurnTitle': 'Rival turn',
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
      'clashMatchHeaderVsRival': 'vs {rival}',
      'clashMatchStatusChipUserPossession': 'Your possession',
      'clashMatchStatusChipRivalPossession': 'Rival possession',
      'clashMatchStatusChipDuel': 'Duel',
      'clashMatchStatusChipHalftime': 'Halftime',
      'clashMatchStatusChipFinished': 'Finished',
      'clashMatchActivePlayerTitle': 'Your active player',
      'clashMatchRivalActivePlayerTitle': 'Active rival',
      'clashMatchPlayerPowerLabel': 'Power {power}',
      'clashMatchActionPanelTitle': 'Actions',
      'clashMatchActionResolveDuel': 'Resolve the duel first',
      'clashMatchActionWaitDefense': 'Wait for your defensive reaction',
      'clashMatchPassRiskLabel': 'Risk {percent}%',
      'clashMatchPitchLegendBall': 'Ball',
      'clashMatchPitchLegendUser': 'You',
      'clashMatchPitchLegendRival': 'Rival',
      'clashMatchHalftimeItemsHint': 'You can only use items at halftime',
      'clashMatchDefendChooseSave': 'Choose save',
      'clashMatchRivalPreparingAdvance': 'Rival is preparing an advance',
      'clashMatchRivalPreparingShot': 'Rival is preparing a shot',
      'clashMatchRivalAwaitingDefense': 'Rival awaits your defense',
      'clashMatchDuelVsLabel': 'VS',
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
      'clashMatchDefendAdvanceTitle': 'Defend the advance',
      'clashMatchDefendShotTitle': 'Stop the shot',
      'clashMatchDefendSelectDefenderTitle': 'Choose who defends',
      'clashMatchDefendNormalDefense': 'Normal defense',
      'clashMatchDefendNormalSave': 'Normal save',
      'clashMatchRivalAttackNormal': 'Rival: normal action',
      'clashMatchRivalAttackTechnique': 'Rival: {name}',
      'clashMatchDefendCandidateMeta':
          'DEF {defense} · PT {pt} · STA {stamina} · {style}',
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
  String get clashHomeHubTitle => _t('clashHomeHubTitle');
  String get clashHomeHubSubtitle => _t('clashHomeHubSubtitle');
  String get clashHomePlaySection => _t('clashHomePlaySection');
  String get clashHomeDailyActivity => _t('clashHomeDailyActivity');
  String get clashHomeNoticesSection => _t('clashHomeNoticesSection');
  String get clashHomePrimaryStoryDesc => _t('clashHomePrimaryStoryDesc');
  String get clashHomePrimaryEventsDesc => _t('clashHomePrimaryEventsDesc');
  String get clashHomePrimaryTeamDesc => _t('clashHomePrimaryTeamDesc');
  String get clashHomePrimarySummonDesc => _t('clashHomePrimarySummonDesc');
  String get clashHomePrimaryLocked => _t('clashHomePrimaryLocked');
  String get clashHomeFeaturedEventTitle => _t('clashHomeFeaturedEventTitle');
  String get clashHomeFeaturedEventEnter => _t('clashHomeFeaturedEventEnter');
  String clashHomeFeaturedEventProgress(int completed, int total) => _t(
    'clashHomeFeaturedEventProgress',
  ).replaceAll('{completed}', '$completed').replaceAll('{total}', '$total');
  String clashHomeShopBalance(int coins, int gems) => _t(
    'clashHomeShopBalance',
  ).replaceAll('{coins}', '$coins').replaceAll('{gems}', '$gems');
  String get clashHomeShopView => _t('clashHomeShopView');
  String get clashDailyMissionsTitle => _t('clashDailyMissionsTitle');
  String get clashDailyMissionsResetHint => _t('clashDailyMissionsResetHint');
  String clashDailyMissionsCompletedSummary(int completed, int total) => _t(
    'clashDailyMissionsCompletedSummary',
  ).replaceAll('{completed}', '$completed').replaceAll('{total}', '$total');
  String clashDailyMissionsClaimedSummary(int claimed, int total) => _t(
    'clashDailyMissionsClaimedSummary',
  ).replaceAll('{claimed}', '$claimed').replaceAll('{total}', '$total');
  String get clashDailyMissionsStatusInProgress =>
      _t('clashDailyMissionsStatusInProgress');
  String get clashDailyMissionsStatusClaim =>
      _t('clashDailyMissionsStatusClaim');
  String get clashDailyMissionsStatusClaimed =>
      _t('clashDailyMissionsStatusClaimed');
  String get clashDailyMissionsClaimAll => _t('clashDailyMissionsClaimAll');
  String get clashDailyMissionsClaimSuccess =>
      _t('clashDailyMissionsClaimSuccess');
  String get clashDailyMissionsHomeTitle => _t('clashDailyMissionsHomeTitle');
  String clashDailyMissionsHomePending(int count) =>
      _t('clashDailyMissionsHomePending').replaceAll('{count}', '$count');
  String get clashDailyMissionsHomeView => _t('clashDailyMissionsHomeView');
  String clashDailyMissionsRewardCoins(int count) =>
      _t('clashDailyMissionsRewardCoins').replaceAll('{count}', '$count');
  String clashDailyMissionsRewardGems(int count) =>
      _t('clashDailyMissionsRewardGems').replaceAll('{count}', '$count');
  String clashDailyMissionsProgress(int current, int target) => _t(
    'clashDailyMissionsProgress',
  ).replaceAll('{current}', '$current').replaceAll('{target}', '$target');
  String get clashDailyMissionsEmpty => _t('clashDailyMissionsEmpty');
  String get clashEngagementRewardsLabel => _t('clashEngagementRewardsLabel');
  String get clashAchievementsTitle => _t('clashAchievementsTitle');
  String get clashAchievementsPermanentHint =>
      _t('clashAchievementsPermanentHint');
  String clashAchievementsCompletedSummary(int completed, int total) => _t(
    'clashAchievementsCompletedSummary',
  ).replaceAll('{completed}', '$completed').replaceAll('{total}', '$total');
  String clashAchievementsClaimedSummary(int claimed, int total) => _t(
    'clashAchievementsClaimedSummary',
  ).replaceAll('{claimed}', '$claimed').replaceAll('{total}', '$total');
  String get clashAchievementsFilterAll => _t('clashAchievementsFilterAll');
  String get clashAchievementsFilterInProgress =>
      _t('clashAchievementsFilterInProgress');
  String get clashAchievementsFilterCompleted =>
      _t('clashAchievementsFilterCompleted');
  String get clashAchievementsFilterClaimed =>
      _t('clashAchievementsFilterClaimed');
  String get clashAchievementsEmptyFilter => _t('clashAchievementsEmptyFilter');
  String get clashAchievementsStatusInProgress =>
      _t('clashAchievementsStatusInProgress');
  String get clashAchievementsStatusClaim => _t('clashAchievementsStatusClaim');
  String get clashAchievementsStatusClaimed =>
      _t('clashAchievementsStatusClaimed');
  String get clashAchievementsClaimAll => _t('clashAchievementsClaimAll');
  String get clashAchievementsClaimSuccess =>
      _t('clashAchievementsClaimSuccess');
  String get clashAchievementsHomeTitle => _t('clashAchievementsHomeTitle');
  String clashAchievementsHomePending(int count) =>
      _t('clashAchievementsHomePending').replaceAll('{count}', '$count');
  String get clashAchievementsHomeView => _t('clashAchievementsHomeView');
  String clashAchievementsRewardCoins(int count) =>
      _t('clashAchievementsRewardCoins').replaceAll('{count}', '$count');
  String clashAchievementsRewardGems(int count) =>
      _t('clashAchievementsRewardGems').replaceAll('{count}', '$count');
  String clashAchievementsProgress(int current, int target) => _t(
    'clashAchievementsProgress',
  ).replaceAll('{current}', '$current').replaceAll('{target}', '$target');
  String get clashWeeklyMissionsTitle => _t('clashWeeklyMissionsTitle');
  String get clashWeeklyMissionsResetHint => _t('clashWeeklyMissionsResetHint');
  String clashWeeklyMissionsWeekLabel(String weekKey) =>
      _t('clashWeeklyMissionsWeekLabel').replaceAll('{weekKey}', weekKey);
  String clashWeeklyMissionsCompletedSummary(int completed, int total) => _t(
    'clashWeeklyMissionsCompletedSummary',
  ).replaceAll('{completed}', '$completed').replaceAll('{total}', '$total');
  String clashWeeklyMissionsClaimedSummary(int claimed, int total) => _t(
    'clashWeeklyMissionsClaimedSummary',
  ).replaceAll('{claimed}', '$claimed').replaceAll('{total}', '$total');
  String get clashWeeklyMissionsStatusInProgress =>
      _t('clashWeeklyMissionsStatusInProgress');
  String get clashWeeklyMissionsStatusClaim =>
      _t('clashWeeklyMissionsStatusClaim');
  String get clashWeeklyMissionsStatusClaimed =>
      _t('clashWeeklyMissionsStatusClaimed');
  String get clashWeeklyMissionsClaimAll => _t('clashWeeklyMissionsClaimAll');
  String get clashWeeklyMissionsClaimSuccess =>
      _t('clashWeeklyMissionsClaimSuccess');
  String get clashWeeklyMissionsHomeTitle => _t('clashWeeklyMissionsHomeTitle');
  String clashWeeklyMissionsHomePending(int count) =>
      _t('clashWeeklyMissionsHomePending').replaceAll('{count}', '$count');
  String get clashWeeklyMissionsHomeView => _t('clashWeeklyMissionsHomeView');
  String clashWeeklyMissionsRewardCoins(int count) =>
      _t('clashWeeklyMissionsRewardCoins').replaceAll('{count}', '$count');
  String clashWeeklyMissionsRewardGems(int count) =>
      _t('clashWeeklyMissionsRewardGems').replaceAll('{count}', '$count');
  String clashWeeklyMissionsProgress(int current, int target) => _t(
    'clashWeeklyMissionsProgress',
  ).replaceAll('{current}', '$current').replaceAll('{target}', '$target');
  String get clashWeeklyMissionsEmpty => _t('clashWeeklyMissionsEmpty');
  String get clashNewsTitle => _t('clashNewsTitle');
  String get clashNewsMarkAllRead => _t('clashNewsMarkAllRead');
  String get clashNewsFilterAll => _t('clashNewsFilterAll');
  String get clashNewsFilterUnread => _t('clashNewsFilterUnread');
  String get clashNewsFilterUpdates => _t('clashNewsFilterUpdates');
  String get clashNewsFilterEvents => _t('clashNewsFilterEvents');
  String get clashNewsFilterBanners => _t('clashNewsFilterBanners');
  String get clashNewsFilterNotices => _t('clashNewsFilterNotices');
  String get clashNewsEmptyFilter => _t('clashNewsEmptyFilter');
  String get clashNewsBadgeNew => _t('clashNewsBadgeNew');
  String get clashNewsTypeUpdate => _t('clashNewsTypeUpdate');
  String get clashNewsTypeEvent => _t('clashNewsTypeEvent');
  String get clashNewsTypeBanner => _t('clashNewsTypeBanner');
  String get clashNewsTypeMaintenance => _t('clashNewsTypeMaintenance');
  String get clashNewsTypeGift => _t('clashNewsTypeGift');
  String get clashNewsHomeTitle => _t('clashNewsHomeTitle');
  String clashNewsHomeUnread(int count) =>
      _t('clashNewsHomeUnread').replaceAll('{count}', '$count');
  String get clashNewsHomeAllCaughtUp => _t('clashNewsHomeAllCaughtUp');
  String get clashNewsHomeView => _t('clashNewsHomeView');
  String clashNewsUnreadSummary(int count) =>
      _t('clashNewsUnreadSummary').replaceAll('{count}', '$count');
  String get clashGiftsTitle => _t('clashGiftsTitle');
  String clashGiftsPendingSummary(int count) =>
      _t('clashGiftsPendingSummary').replaceAll('{count}', '$count');
  String clashGiftsClaimedSummary(int claimed, int total) => _t(
    'clashGiftsClaimedSummary',
  ).replaceAll('{claimed}', '$claimed').replaceAll('{total}', '$total');
  String get clashGiftsClaimAll => _t('clashGiftsClaimAll');
  String get clashGiftsClaimSuccess => _t('clashGiftsClaimSuccess');
  String get clashGiftsStatusAvailable => _t('clashGiftsStatusAvailable');
  String get clashGiftsStatusClaimed => _t('clashGiftsStatusClaimed');
  String get clashGiftsStatusExpired => _t('clashGiftsStatusExpired');
  String get clashGiftsStatusClaim => _t('clashGiftsStatusClaim');
  String get clashGiftsHomeTitle => _t('clashGiftsHomeTitle');
  String clashGiftsHomePending(int count) =>
      _t('clashGiftsHomePending').replaceAll('{count}', '$count');
  String get clashGiftsHomeNone => _t('clashGiftsHomeNone');
  String get clashGiftsHomeView => _t('clashGiftsHomeView');
  String get clashGiftsEmptyPending => _t('clashGiftsEmptyPending');
  String get clashEventsTitle => _t('clashEventsTitle');
  String get clashEventsEmpty => _t('clashEventsEmpty');
  String get clashEventsNotFound => _t('clashEventsNotFound');
  String get clashEventsEnter => _t('clashEventsEnter');
  String clashEventsProgress(int completed, int total) => _t(
    'clashEventsProgress',
  ).replaceAll('{completed}', '$completed').replaceAll('{total}', '$total');
  String get clashEventsStagesTitle => _t('clashEventsStagesTitle');
  String clashEventsFeaturedCard(String cardId) =>
      _t('clashEventsFeaturedCard').replaceAll('{cardId}', cardId);
  String get clashEventsStageLocked => _t('clashEventsStageLocked');
  String get clashEventsStageAvailable => _t('clashEventsStageAvailable');
  String get clashEventsStageCompleted => _t('clashEventsStageCompleted');
  String get clashEventsStageRead => _t('clashEventsStageRead');
  String get clashEventsStageReadAgain => _t('clashEventsStageReadAgain');
  String get clashEventsStagePrepare => _t('clashEventsStagePrepare');
  String get clashEventsStageRepeat => _t('clashEventsStageRepeat');
  String get clashEventsStageTypeStory => _t('clashEventsStageTypeStory');
  String get clashEventsStageTypeMatch => _t('clashEventsStageTypeMatch');
  String clashEventsStageClearCount(int count) =>
      _t('clashEventsStageClearCount').replaceAll('{count}', '$count');
  String get clashEventsFirstClear => _t('clashEventsFirstClear');
  String get clashEventsRepeatRewards => _t('clashEventsRepeatRewards');
  String get clashEventsStoryComplete => _t('clashEventsStoryComplete');
  String get clashEventsStoryPlaceholder => _t('clashEventsStoryPlaceholder');
  String get clashEventsStageNotFound => _t('clashEventsStageNotFound');
  String get clashEventsRewardTitle => _t('clashEventsRewardTitle');
  String get clashEventsRewardFirstClear => _t('clashEventsRewardFirstClear');
  String get clashEventsRewardRepeat => _t('clashEventsRewardRepeat');
  String clashEventsRewardDuplicate(String cardId) =>
      _t('clashEventsRewardDuplicate').replaceAll('{cardId}', cardId);
  String get clashEventsRewardContinue => _t('clashEventsRewardContinue');
  String get clashEventsCardXpReward => _t('clashEventsCardXpReward');
  String get clashEventsHomeTitle => _t('clashEventsHomeTitle');
  String clashEventsHomeAvailable(int count) =>
      _t('clashEventsHomeAvailable').replaceAll('{count}', '$count');
  String get clashEventsHomeNone => _t('clashEventsHomeNone');
  String get clashEventsHomeView => _t('clashEventsHomeView');
  String get clashEventsBack => _t('clashEventsBack');
  String get clashEventsMatchDefeatHint => _t('clashEventsMatchDefeatHint');
  String clashEventsStageCompletedTitle(String title) =>
      _t('clashEventsStageCompletedTitle').replaceAll('{title}', title);
  String get clashEventsLocalTestLabel => _t('clashEventsLocalTestLabel');
  String get clashEventsFeaturedCardTitle => _t('clashEventsFeaturedCardTitle');
  String get clashEventsFirstVictory => _t('clashEventsFirstVictory');
  String get clashEventsRepeats => _t('clashEventsRepeats');
  String get clashEventsRepeatable => _t('clashEventsRepeatable');
  String clashEventsCompletedTimes(int count) =>
      _t('clashEventsCompletedTimes').replaceAll('{count}', '$count');
  String get clashEventsFirstTimeCard => _t('clashEventsFirstTimeCard');
  String get clashEventsRepeatDuplicates => _t('clashEventsRepeatDuplicates');
  String clashEventsAvailableCount(int count) =>
      _t('clashEventsAvailableCount').replaceAll('{count}', '$count');
  String get clashTeamLineup7 => _t('clashTeamLineup7');
  String get clashTeamLineup11 => _t('clashTeamLineup11');
  String get clashTeamCharacters => _t('clashTeamCharacters');
  String get clashTeamUpgrade => _t('clashTeamUpgrade');
  String get clashTeamSkillTree => _t('clashTeamSkillTree');
  String get clashTeamInventory => _t('clashTeamInventory');
  String get clashInventoryTitle => _t('clashInventoryTitle');
  String get clashInventoryAll => _t('clashInventoryAll');
  String get clashInventoryExp => _t('clashInventoryExp');
  String get clashInventoryTechnique => _t('clashInventoryTechnique');
  String get clashInventoryEvolution => _t('clashInventoryEvolution');
  String get clashInventoryMatch => _t('clashInventoryMatch');
  String get clashInventoryTickets => _t('clashInventoryTickets');
  String get clashInventorySummaryTitle => _t('clashInventorySummaryTitle');
  String clashInventoryTotalItems(int count) =>
      _t('clashInventoryTotalItems').replaceAll('{count}', '$count');
  String clashInventoryCategoryCount(String category, int count) => _t(
    'clashInventoryCategoryCount',
  ).replaceAll('{category}', category).replaceAll('{count}', '$count');
  String get clashInventoryUseFromCardDetail =>
      _t('clashInventoryUseFromCardDetail');
  String get clashInventoryUseDuringHalftime =>
      _t('clashInventoryUseDuringHalftime');
  String get clashInventoryUseInSummon => _t('clashInventoryUseInSummon');
  String get clashInventoryMatchKitProvisional =>
      _t('clashInventoryMatchKitProvisional');
  String get clashInventoryEmptyCategory => _t('clashInventoryEmptyCategory');
  String get clashInventoryEmptyFilter => _t('clashInventoryEmptyFilter');
  String get clashInventoryGoToShop => _t('clashInventoryGoToShop');
  String get clashInventoryZeroQuantityHeader =>
      _t('clashInventoryZeroQuantityHeader');
  String get clashGachaLocalDisclaimer => _t('clashGachaLocalDisclaimer');
  String clashGachaWalletGems(int count) =>
      _t('clashGachaWalletGems').replaceAll('{count}', '$count');
  String clashGachaSingleButton(int cost) =>
      _t('clashGachaSingleButton').replaceAll('{cost}', '$cost');
  String clashGachaMultiButton(int cost, int count) => _t(
    'clashGachaMultiButton',
  ).replaceAll('{cost}', '$cost').replaceAll('{count}', '$count');
  String clashGachaDailyButton(int cost) =>
      _t('clashGachaDailyButton').replaceAll('{cost}', '$cost');
  String get clashGachaDailyUsed => _t('clashGachaDailyUsed');
  String get clashGachaInsufficientGems => _t('clashGachaInsufficientGems');
  String get clashGachaEarnGemsHint => _t('clashGachaEarnGemsHint');
  String get clashGachaMultiGuarantee => _t('clashGachaMultiGuarantee');
  String get clashGachaResultTitle => _t('clashGachaResultTitle');
  String clashGachaResultSpent(int spent, int remaining) => _t(
    'clashGachaResultSpent',
  ).replaceAll('{spent}', '$spent').replaceAll('{remaining}', '$remaining');
  String get clashGachaResultNew => _t('clashGachaResultNew');
  String get clashGachaResultDuplicate => _t('clashGachaResultDuplicate');
  String get clashGachaResultUpgraded => _t('clashGachaResultUpgraded');
  String clashGachaResultDuplicates(int count) =>
      _t('clashGachaResultDuplicates').replaceAll('{count}', '$count');
  String get clashGachaViewHistory => _t('clashGachaViewHistory');
  String get clashGachaHistoryTitle => _t('clashGachaHistoryTitle');
  String get clashGachaHistoryEmpty => _t('clashGachaHistoryEmpty');
  String get clashGachaHistoryPullSingle => _t('clashGachaHistoryPullSingle');
  String get clashGachaHistoryPullMulti => _t('clashGachaHistoryPullMulti');
  String get clashGachaHistoryPullDaily => _t('clashGachaHistoryPullDaily');
  String clashGachaHistorySpent(int spent) =>
      _t('clashGachaHistorySpent').replaceAll('{spent}', '$spent');
  String clashGachaHistorySummary(int count, String rarity) => _t(
    'clashGachaHistorySummary',
  ).replaceAll('{count}', '$count').replaceAll('{rarity}', rarity);
  String clashGachaPityProgress(int current, int max) => _t(
    'clashGachaPityProgress',
  ).replaceAll('{current}', '$current').replaceAll('{max}', '$max');
  String clashGachaPityRemaining(int count) =>
      _t('clashGachaPityRemaining').replaceAll('{count}', '$count');
  String get clashGachaPityChip => _t('clashGachaPityChip');
  String get clashGachaMultiGuaranteeChip => _t('clashGachaMultiGuaranteeChip');
  String get clashGachaTicketsAvailable => _t('clashGachaTicketsAvailable');
  String clashGachaUseTicketButton(int count) =>
      _t('clashGachaUseTicketButton').replaceAll('{count}', '$count');
  String get clashGachaNoTickets => _t('clashGachaNoTickets');
  String clashGachaResultTicket(int remaining) =>
      _t('clashGachaResultTicket').replaceAll('{remaining}', '$remaining');
  String get clashGachaHistoryPullTicket => _t('clashGachaHistoryPullTicket');
  String get clashGachaLrXiUnavailable => _t('clashGachaLrXiUnavailable');
  String get clashGachaButtonDisabledGems => _t('clashGachaButtonDisabledGems');
  String get clashGachaButtonDisabledDaily =>
      _t('clashGachaButtonDisabledDaily');
  String get clashGachaButtonDisabledTickets =>
      _t('clashGachaButtonDisabledTickets');
  String get clashGachaPulling => _t('clashGachaPulling');
  String clashGachaResultBestRarity(String rarity) =>
      _t('clashGachaResultBestRarity').replaceAll('{rarity}', rarity);
  String clashGachaResultPullType(String type) =>
      _t('clashGachaResultPullType').replaceAll('{type}', type);
  String get clashGachaClose => _t('clashGachaClose');
  String clashGachaHistoryTotal(int count) =>
      _t('clashGachaHistoryTotal').replaceAll('{count}', '$count');
  String get clashGachaHistoryFilterAll => _t('clashGachaHistoryFilterAll');
  String get clashGachaHistoryFilterSingle =>
      _t('clashGachaHistoryFilterSingle');
  String get clashGachaHistoryFilterMulti => _t('clashGachaHistoryFilterMulti');
  String get clashGachaHistoryFilterDaily => _t('clashGachaHistoryFilterDaily');
  String get clashGachaHistoryFilterTicket =>
      _t('clashGachaHistoryFilterTicket');
  String clashGachaChipSingle(int cost) =>
      _t('clashGachaChipSingle').replaceAll('{cost}', '$cost');
  String clashGachaChipMulti(int cost) =>
      _t('clashGachaChipMulti').replaceAll('{cost}', '$cost');
  String clashGachaChipDaily(int cost) =>
      _t('clashGachaChipDaily').replaceAll('{cost}', '$cost');
  String clashGachaChipPity(int max) =>
      _t('clashGachaChipPity').replaceAll('{max}', '$max');
  String get clashGachaDailyStatusAvailable =>
      _t('clashGachaDailyStatusAvailable');
  String clashGachaWalletTickets(int count) =>
      _t('clashGachaWalletTickets').replaceAll('{count}', '$count');
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
  String get clashShopLocalDisclaimer => _t('clashShopLocalDisclaimer');
  String clashShopWalletCoins(int count) =>
      _t('clashShopWalletCoins').replaceAll('{count}', '$count');
  String clashShopProductCost(int count) =>
      _t('clashShopProductCost').replaceAll('{count}', '$count');
  String get clashShopIncludes => _t('clashShopIncludes');
  String clashShopGrantLine(String label, int count) => _t(
    'clashShopGrantLine',
  ).replaceAll('{label}', label).replaceAll('{count}', '$count');
  String get clashShopBuyButton => _t('clashShopBuyButton');
  String get clashShopButtonDisabledCoins => _t('clashShopButtonDisabledCoins');
  String get clashShopSectionMaterials => _t('clashShopSectionMaterials');
  String get clashShopSectionTechniques => _t('clashShopSectionTechniques');
  String get clashShopSectionEvolution => _t('clashShopSectionEvolution');
  String get clashShopSectionTickets => _t('clashShopSectionTickets');
  String get clashShopConfirmTitle => _t('clashShopConfirmTitle');
  String clashShopConfirmMessage(String name, int cost) => _t(
    'clashShopConfirmMessage',
  ).replaceAll('{name}', name).replaceAll('{cost}', '$cost');
  String clashShopConfirmBalanceAfter(int count) =>
      _t('clashShopConfirmBalanceAfter').replaceAll('{count}', '$count');
  String get clashShopConfirmRewards => _t('clashShopConfirmRewards');
  String get clashShopPurchaseSuccess => _t('clashShopPurchaseSuccess');
  String clashShopPurchaseSuccessDetail(int quantity, String label) => _t(
    'clashShopPurchaseSuccessDetail',
  ).replaceAll('{quantity}', '$quantity').replaceAll('{label}', label);
  String get clashShopInsufficientCoins => _t('clashShopInsufficientCoins');
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
  String clashCollectionOwnedCount(int count) =>
      _t('clashCollectionOwnedCount').replaceAll('{count}', '$count');
  String clashCollectionTotalPower(int power) =>
      _t('clashCollectionTotalPower').replaceAll('{power}', '$power');
  String clashCollectionStrongest(String name, int power) => _t(
    'clashCollectionStrongest',
  ).replaceAll('{name}', name).replaceAll('{power}', '$power');
  String get clashCollectionActiveFilters => _t('clashCollectionActiveFilters');
  String get clashCollectionEmptyTitle => _t('clashCollectionEmptyTitle');
  String get clashCollectionEmptyFiltered => _t('clashCollectionEmptyFiltered');
  String get clashCollectionEmptyOwnedTitle =>
      _t('clashCollectionEmptyOwnedTitle');
  String get clashCollectionEmptyOwned => _t('clashCollectionEmptyOwned');
  String get clashCollectionGoStory => _t('clashCollectionGoStory');
  String get clashCollectionGoSummon => _t('clashCollectionGoSummon');
  String get clashCollectionClearFilters => _t('clashCollectionClearFilters');
  String get clashCollectionLoadError => _t('clashCollectionLoadError');
  String get clashCardNotFound => _t('clashCardNotFound');
  String get clashCardTeam => _t('clashCardTeam');
  String get clashCardPosition => _t('clashCardPosition');
  String get clashCardStyle => _t('clashCardStyle');
  String get clashCardLevel => _t('clashCardLevel');
  String get clashCardXpTitle => _t('clashCardXpTitle');
  String get clashCardMaxLevel => _t('clashCardMaxLevel');
  String clashCardPowerValue(int power) =>
      _t('clashCardPowerValue').replaceAll('{power}', '$power');
  String clashCardLevelShort(int level) =>
      _t('clashCardLevelShort').replaceAll('{level}', '$level');
  String get clashCardEvolved => _t('clashCardEvolved');
  String get clashCardBonusIncluded => _t('clashCardBonusIncluded');
  String get clashCardPortraitPlaceholder => _t('clashCardPortraitPlaceholder');
  String get clashCardDetailTitle => _t('clashCardDetailTitle');

  String clashCardXpProgress(int current, int needed) => _t(
    'clashCardXpProgress',
  ).replaceAll('{current}', '$current').replaceAll('{needed}', '$needed');
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
  String get clashTechniqueBasePower => _t('clashTechniqueBasePower');
  String get clashTechniquePower => _t('clashTechniquePower');
  String get clashTechniquePtCost => _t('clashTechniquePtCost');
  String get clashTechniqueLevel => _t('clashTechniqueLevel');
  String get clashTechniqueUpgradeTitle => _t('clashTechniqueUpgradeTitle');
  String clashTechniqueBookEffect(int steps) =>
      _t('clashTechniqueBookEffect').replaceAll('{steps}', '$steps');
  String get clashTechniqueBookUse => _t('clashTechniqueBookUse');
  String clashTechniqueLevelUpSnack(String name, String from, String to) =>
      _t('clashTechniqueLevelUpSnack')
          .replaceAll('{name}', name)
          .replaceAll('{from}', from)
          .replaceAll('{to}', to);
  String get clashActionUpgrade => _t('clashActionUpgrade');
  String clashExpMaterialXp(int xp) =>
      _t('clashExpMaterialXp').replaceAll('{xp}', '$xp');
  String clashExpMaterialQuantity(int count) =>
      _t('clashExpMaterialQuantity').replaceAll('{count}', '$count');
  String get clashExpMaterialUseOne => _t('clashExpMaterialUseOne');
  String clashExpMaterialLevelUp(int from, int to) => _t(
    'clashExpMaterialLevelUp',
  ).replaceAll('{from}', '$from').replaceAll('{to}', '$to');
  String get clashUpgradeMaxLevelHint => _t('clashUpgradeMaxLevelHint');
  String get clashActionEvolve => _t('clashActionEvolve');
  String get clashEvolutionCannotEvolveMore =>
      _t('clashEvolutionCannotEvolveMore');
  String clashEvolutionRarityArrow(String from, String to) => _t(
    'clashEvolutionRarityArrow',
  ).replaceAll('{from}', from).replaceAll('{to}', to);
  String clashEvolutionRequiredLevel(int level) =>
      _t('clashEvolutionRequiredLevel').replaceAll('{level}', '$level');
  String clashEvolutionCurrentLevel(int level) =>
      _t('clashEvolutionCurrentLevel').replaceAll('{level}', '$level');
  String clashEvolutionRequiredMaterial(
    String name,
    int required,
    int available,
  ) => _t('clashEvolutionRequiredMaterial')
      .replaceAll('{name}', name)
      .replaceAll('{required}', '$required')
      .replaceAll('{available}', '$available');
  String get clashEvolutionCoinsPending => _t('clashEvolutionCoinsPending');
  String get clashEvolutionButton => _t('clashEvolutionButton');
  String get clashEvolutionMissingLevel => _t('clashEvolutionMissingLevel');
  String get clashEvolutionMissingMaterial =>
      _t('clashEvolutionMissingMaterial');
  String clashEvolutionSnack(String from, String to) => _t(
    'clashEvolutionSnack',
  ).replaceAll('{from}', from).replaceAll('{to}', to);
  String get clashSkillTreeTitle => _t('clashSkillTreeTitle');
  String get clashSkillTreeLockedRarity => _t('clashSkillTreeLockedRarity');
  String clashSkillTreeDuplicates(int count) =>
      _t('clashSkillTreeDuplicates').replaceAll('{count}', '$count');
  String clashSkillTreeProgress(int current, int max) => _t(
    'clashSkillTreeProgress',
  ).replaceAll('{current}', '$current').replaceAll('{max}', '$max');
  String get clashSkillTreeNodeLocked => _t('clashSkillTreeNodeLocked');
  String get clashSkillTreeNodeAvailable => _t('clashSkillTreeNodeAvailable');
  String get clashSkillTreeNodeUnlocked => _t('clashSkillTreeNodeUnlocked');
  String get clashSkillTreeUnlock => _t('clashSkillTreeUnlock');
  String get clashSkillTreeNoDuplicates => _t('clashSkillTreeNoDuplicates');
  String clashSkillTreeUnlockSnack(String boost) =>
      _t('clashSkillTreeUnlockSnack').replaceAll('{boost}', boost);
  String clashCardDuplicateCopies(int count) =>
      _t('clashCardDuplicateCopies').replaceAll('{count}', '$count');
  String clashCardSkillTreeShort(int current, int max) => _t(
    'clashCardSkillTreeShort',
  ).replaceAll('{current}', '$current').replaceAll('{max}', '$max');
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
  String get clashLineupBlockAlreadyUsed => _t('clashLineupBlockAlreadyUsed');
  String get clashLineupChooseSlot => _t('clashLineupChooseSlot');
  String clashLineupSlotsFilled(int filled) =>
      _t('clashLineupSlotsFilled').replaceAll('{filled}', '$filled');
  String get clashLineupReadyToPlay => _t('clashLineupReadyToPlay');
  String get clashLineupNoGoalkeeper => _t('clashLineupNoGoalkeeper');
  String get clashLineupZoneAttack => _t('clashLineupZoneAttack');
  String get clashLineupZoneMidfield => _t('clashLineupZoneMidfield');
  String get clashLineupZoneDefense => _t('clashLineupZoneDefense');
  String get clashLineupZoneGoalkeeper => _t('clashLineupZoneGoalkeeper');
  String get clashLineupPickerCompatible => _t('clashLineupPickerCompatible');
  String get clashLineupPickerAll => _t('clashLineupPickerAll');
  String get clashLineupPickerByRarity => _t('clashLineupPickerByRarity');
  String get clashLineupCardCompatible => _t('clashLineupCardCompatible');
  String get clashLineupCardIncompatible => _t('clashLineupCardIncompatible');
  String get clashLineupNoOwnedCards => _t('clashLineupNoOwnedCards');
  String get clashTeamSummaryTitle => _t('clashTeamSummaryTitle');
  String get clashTeamActiveLineup => _t('clashTeamActiveLineup');
  String get clashTeamNoActiveLineup => _t('clashTeamNoActiveLineup');
  String get clashTeamUpgradeCards => _t('clashTeamUpgradeCards');
  String get clashTeamComingSoonBadge => _t('clashTeamComingSoonBadge');
  String get clashTeamTactics => _t('clashTeamTactics');
  String get clashTeamAdvancedFormations => _t('clashTeamAdvancedFormations');
  String get clashTeamComingSoonSection => _t('clashTeamComingSoonSection');

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
  String get clashStoryProgressTitle => _t('clashStoryProgressTitle');
  String get clashStoryCurrentChapter => _t('clashStoryCurrentChapter');
  String clashStoryLevelsProgress(int completed, int total) => _t(
    'clashStoryLevelsProgress',
  ).replaceAll('{completed}', '$completed').replaceAll('{total}', '$total');
  String get clashStoryFirstClear => _t('clashStoryFirstClear');
  String get clashStoryFirstClearClaimed => _t('clashStoryFirstClearClaimed');
  String get clashStoryFirstClearRewardsTitle =>
      _t('clashStoryFirstClearRewardsTitle');
  String get clashStoryActionRead => _t('clashStoryActionRead');
  String get clashStoryActionPlay => _t('clashStoryActionPlay');
  String get clashStoryActionReplay => _t('clashStoryActionReplay');
  String get clashStoryCompletePreviousLevel =>
      _t('clashStoryCompletePreviousLevel');
  String get clashStoryPrepareTeam => _t('clashStoryPrepareTeam');
  String get clashStoryStartMatch => _t('clashStoryStartMatch');
  String get clashStoryReadAgain => _t('clashStoryReadAgain');
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
  String get clashMatchPrepareRival => _t('clashMatchPrepareRival');
  String clashMatchPrepareDifficulty(int difficulty) => _t(
    'clashMatchPrepareDifficulty',
  ).replaceAll('{difficulty}', '$difficulty');
  String get clashMatchPrepareStandardRival =>
      _t('clashMatchPrepareStandardRival');
  String get clashMatchPrepareViewRivalLineup =>
      _t('clashMatchPrepareViewRivalLineup');
  String get clashMatchPrepareOwnPower => _t('clashMatchPrepareOwnPower');
  String get clashMatchPrepareRivalPower => _t('clashMatchPrepareRivalPower');
  String get clashMatchPreparePowerDifference =>
      _t('clashMatchPreparePowerDifference');
  String get clashMatchPreparePowerAdvantage =>
      _t('clashMatchPreparePowerAdvantage');
  String get clashMatchPreparePowerEven => _t('clashMatchPreparePowerEven');
  String get clashMatchPreparePowerDisadvantage =>
      _t('clashMatchPreparePowerDisadvantage');
  String get clashMatchPreparePowerVeryHard =>
      _t('clashMatchPreparePowerVeryHard');
  String get clashMatchPrepareDifficultyEasy =>
      _t('clashMatchPrepareDifficultyEasy');
  String get clashMatchPrepareDifficultyNormal =>
      _t('clashMatchPrepareDifficultyNormal');
  String get clashMatchPrepareDifficultyHard =>
      _t('clashMatchPrepareDifficultyHard');
  String clashMatchPrepareDifficultyChip(int difficulty) =>
      _t('clashMatchPrepareDifficultyChip')
          .replaceAll('{difficulty}', '$difficulty')
          .replaceAll('{label}', clashMatchPrepareDifficultyName(difficulty));
  String clashMatchPrepareDifficultyName(int difficulty) =>
      switch (difficulty) {
        1 => clashMatchPrepareDifficultyEasy,
        2 => clashMatchPrepareDifficultyNormal,
        3 => clashMatchPrepareDifficultyHard,
        _ => clashMatchPrepareDifficulty(difficulty),
      };
  String clashMatchPrepareRivalPlayersCount(int current, int total) => _t(
    'clashMatchPrepareRivalPlayersCount',
  ).replaceAll('{current}', '$current').replaceAll('{total}', '$total');
  String get clashMatchPreparePredominantStyles =>
      _t('clashMatchPreparePredominantStyles');
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
  String get clashMatchRetry => _t('clashMatchRetry');

  String clashMatchFinalScore(int user, int rival) => _t(
    'clashMatchFinalScore',
  ).replaceAll('{user}', '$user').replaceAll('{rival}', '$rival');

  String clashMatchLevelCompleted(String title) =>
      _t('clashMatchLevelCompleted').replaceAll('{title}', title);

  String get clashMatchNoRewards => _t('clashMatchNoRewards');
  String get clashMatchObjectivesTitle => _t('clashMatchObjectivesTitle');
  String get clashMatchObjectiveCompleted => _t('clashMatchObjectiveCompleted');
  String get clashMatchObjectiveIncomplete =>
      _t('clashMatchObjectiveIncomplete');
  String get clashMatchObjectiveStatusPending =>
      _t('clashMatchObjectiveStatusPending');
  String get clashMatchObjectiveStatusInProgress =>
      _t('clashMatchObjectiveStatusInProgress');
  String get clashMatchObjectiveStatusCompleted =>
      _t('clashMatchObjectiveStatusCompleted');
  String get clashMatchObjectiveStatusFailed =>
      _t('clashMatchObjectiveStatusFailed');
  String get clashMatchObjectiveStatusReviewedAtEnd =>
      _t('clashMatchObjectiveStatusReviewedAtEnd');
  String get clashMatchObjectivesNone => _t('clashMatchObjectivesNone');
  String get clashMatchEndCompletedSubtitle =>
      _t('clashMatchEndCompletedSubtitle');
  String get clashMatchEndNoRewards => _t('clashMatchEndNoRewards');
  String clashMatchEndScoreYouRival(int user, int rival) => _t(
    'clashMatchEndScoreYouRival',
  ).replaceAll('{user}', '$user').replaceAll('{rival}', '$rival');
  String get clashMatchRewardsEarnedTitle => _t('clashMatchRewardsEarnedTitle');
  String get clashMatchRewardsPendingTitle =>
      _t('clashMatchRewardsPendingTitle');
  String get clashMatchRewardsEmptyState => _t('clashMatchRewardsEmptyState');
  String get clashMatchCardProgressTitle => _t('clashMatchCardProgressTitle');
  String get clashMatchObjectiveRetryHint => _t('clashMatchObjectiveRetryHint');
  String clashMatchLineupXpTotal(int amount) =>
      _t('clashMatchLineupXpTotal').replaceAll('{amount}', '$amount');
  String get clashMatchObjectiveFailConcededGoal =>
      _t('clashMatchObjectiveFailConcededGoal');
  String get clashMatchObjectiveFailNoShotTechnique =>
      _t('clashMatchObjectiveFailNoShotTechnique');
  String get clashMatchContinue => _t('clashMatchContinue');
  String clashMatchCardLevelFromTo(int from, int to) => _t(
    'clashMatchCardLevelFromTo',
  ).replaceAll('{from}', '$from').replaceAll('{to}', '$to');
  String get clashMatchObjectivesDefeatHint =>
      _t('clashMatchObjectivesDefeatHint');
  String get clashMatchRewardsTotalTitle => _t('clashMatchRewardsTotalTitle');
  String get clashMatchCardXpTitle => _t('clashMatchCardXpTitle');
  String get clashMatchNoCardXpOnDefeat => _t('clashMatchNoCardXpOnDefeat');

  String clashMatchCardXpGained(int amount) =>
      _t('clashMatchCardXpGained').replaceAll('{amount}', '$amount');

  String clashMatchCardLevelUp(int from, int to) => _t(
    'clashMatchCardLevelUp',
  ).replaceAll('{from}', '$from').replaceAll('{to}', '$to');

  String clashMatchCardLevelSame(int level) =>
      _t('clashMatchCardLevelSame').replaceAll('{level}', '$level');

  String get clashMatchRewardsTitle => _t('clashMatchRewardsTitle');
  String get clashMatchRewardsBasic => _t('clashMatchRewardsBasic');

  String clashMatchRewardGems(int amount) =>
      _t('clashMatchRewardGems').replaceAll('{amount}', '$amount');

  String clashMatchRewardCoins(int amount) =>
      _t('clashMatchRewardCoins').replaceAll('{amount}', '$amount');

  String clashMatchRewardCards(int count) =>
      _t('clashMatchRewardCards').replaceAll('{count}', '$count');

  String get clashMatchStatusBallUser => _t('clashMatchStatusBallUser');
  String get clashMatchStatusShootNeedArea =>
      _t('clashMatchStatusShootNeedArea');
  String get clashMatchStatusCanShoot => _t('clashMatchStatusCanShoot');
  String get clashMatchStatusRivalTurn => _t('clashMatchStatusRivalTurn');
  String get clashMatchStatusRivalTurnHint =>
      _t('clashMatchStatusRivalTurnHint');
  String get clashMatchStatusHalftime => _t('clashMatchStatusHalftime');
  String get clashMatchStatusHalftimeHint => _t('clashMatchStatusHalftimeHint');
  String get clashMatchStatusDefendRivalHint =>
      _t('clashMatchStatusDefendRivalHint');
  String get clashMatchStatusPickDefender => _t('clashMatchStatusPickDefender');
  String get clashMatchStatusUserDuel => _t('clashMatchStatusUserDuel');
  String get clashMatchStatusUserAdvanceDuelHint =>
      _t('clashMatchStatusUserAdvanceDuelHint');
  String get clashMatchStatusUserShotDuelHint =>
      _t('clashMatchStatusUserShotDuelHint');
  String get clashMatchStatusDuelResult => _t('clashMatchStatusDuelResult');
  String get clashMatchStatusDuelResultHint =>
      _t('clashMatchStatusDuelResultHint');
  String get clashMatchPassUnavailable => _t('clashMatchPassUnavailable');
  String get clashMatchActionPass => _t('clashMatchActionPass');
  String get clashMatchActionAdvance => _t('clashMatchActionAdvance');
  String get clashMatchActionShootSoon => _t('clashMatchActionShootSoon');
  String get clashMatchActionShoot => _t('clashMatchActionShoot');
  String get clashMatchActionShootNeedArea =>
      _t('clashMatchActionShootNeedArea');
  String get clashMatchActionRivalSim => _t('clashMatchActionRivalSim');
  String get clashMatchActionRivalContinue =>
      _t('clashMatchActionRivalContinue');
  String get clashMatchRivalTurnTitle => _t('clashMatchRivalTurnTitle');
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

  String clashMatchPassPercent(int percent) =>
      _t('clashMatchPassPercent').replaceAll('{percent}', '$percent');

  String clashMatchPassOptionPower(int power) =>
      _t('clashMatchPassOptionPower').replaceAll('{power}', '$power');

  String clashMatchAdvanceChance(int percent) =>
      _t('clashMatchAdvanceChance').replaceAll('{percent}', '$percent');

  String clashMatchHeaderVsRival(String rival) =>
      _t('clashMatchHeaderVsRival').replaceAll('{rival}', rival);

  String get clashMatchStatusChipUserPossession =>
      _t('clashMatchStatusChipUserPossession');
  String get clashMatchStatusChipRivalPossession =>
      _t('clashMatchStatusChipRivalPossession');
  String get clashMatchStatusChipDuel => _t('clashMatchStatusChipDuel');
  String get clashMatchStatusChipHalftime => _t('clashMatchStatusChipHalftime');
  String get clashMatchStatusChipFinished => _t('clashMatchStatusChipFinished');
  String get clashMatchActivePlayerTitle => _t('clashMatchActivePlayerTitle');
  String get clashMatchRivalActivePlayerTitle =>
      _t('clashMatchRivalActivePlayerTitle');
  String clashMatchPlayerPowerLabel(int power) =>
      _t('clashMatchPlayerPowerLabel').replaceAll('{power}', '$power');
  String get clashMatchActionPanelTitle => _t('clashMatchActionPanelTitle');
  String get clashMatchActionResolveDuel => _t('clashMatchActionResolveDuel');
  String get clashMatchActionWaitDefense => _t('clashMatchActionWaitDefense');
  String clashMatchPassRiskLabel(int percent) =>
      _t('clashMatchPassRiskLabel').replaceAll('{percent}', '$percent');
  String get clashMatchPitchLegendBall => _t('clashMatchPitchLegendBall');
  String get clashMatchPitchLegendUser => _t('clashMatchPitchLegendUser');
  String get clashMatchPitchLegendRival => _t('clashMatchPitchLegendRival');
  String get clashMatchHalftimeItemsHint => _t('clashMatchHalftimeItemsHint');
  String get clashMatchDefendChooseSave => _t('clashMatchDefendChooseSave');
  String get clashMatchRivalPreparingAdvance =>
      _t('clashMatchRivalPreparingAdvance');
  String get clashMatchRivalPreparingShot => _t('clashMatchRivalPreparingShot');
  String get clashMatchRivalAwaitingDefense =>
      _t('clashMatchRivalAwaitingDefense');
  String get clashMatchDuelVsLabel => _t('clashMatchDuelVsLabel');

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
  String get clashMatchDefendAdvanceTitle => _t('clashMatchDefendAdvanceTitle');
  String get clashMatchDefendShotTitle => _t('clashMatchDefendShotTitle');
  String get clashMatchDefendSelectDefenderTitle =>
      _t('clashMatchDefendSelectDefenderTitle');
  String get clashMatchDefendNormalDefense =>
      _t('clashMatchDefendNormalDefense');
  String get clashMatchDefendNormalSave => _t('clashMatchDefendNormalSave');
  String get clashMatchRivalAttackNormal => _t('clashMatchRivalAttackNormal');
  String clashMatchRivalAttackTechnique(String name) =>
      _t('clashMatchRivalAttackTechnique').replaceAll('{name}', name);
  String clashMatchDefendCandidateMeta(
    int defense,
    int pt,
    int stamina,
    String style,
  ) => _t('clashMatchDefendCandidateMeta')
      .replaceAll('{defense}', '$defense')
      .replaceAll('{pt}', '$pt')
      .replaceAll('{stamina}', '$stamina')
      .replaceAll('{style}', style);

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
