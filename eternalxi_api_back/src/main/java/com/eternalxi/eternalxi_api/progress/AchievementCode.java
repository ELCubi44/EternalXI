package com.eternalxi.eternalxi_api.progress;

public enum AchievementCode {
    WIN_LEAGUE_1("Primera corona", "Gana una liga válida", 80, AchievementCategory.LEAGUE),
    WIN_LEAGUE_3("Tricampeón", "Gana 3 ligas válidas", 150, AchievementCategory.LEAGUE),
    WIN_LEAGUE_5("Dominador", "Gana 5 ligas válidas", 250, AchievementCategory.LEAGUE),

    GOALS_50("Goleador", "50 goles acumulados con tus jugadores", 60, AchievementCategory.PERFORMANCE),
    GOALS_100("Artillero", "100 goles acumulados con tus jugadores", 100, AchievementCategory.PERFORMANCE),
    GOALS_250("Máquina de goles", "250 goles acumulados con tus jugadores", 180, AchievementCategory.PERFORMANCE),
    ASSISTS_25("Creador", "25 asistencias acumuladas", 55, AchievementCategory.PERFORMANCE),
    ASSISTS_100("Maestro del pase", "100 asistencias acumuladas", 120, AchievementCategory.PERFORMANCE),
    CLEAN_SHEETS_10("Muralla", "10 porterías a cero acumuladas", 50, AchievementCategory.PERFORMANCE),
    CLEAN_SHEETS_50("Fortín", "50 porterías a cero acumuladas", 110, AchievementCategory.PERFORMANCE),
    INJURIES_15("Consultorio", "15 lesiones acumuladas en tu plantilla", 40, AchievementCategory.PERFORMANCE),
    SANCTIONS_25("Tarjetero", "25 sanciones acumuladas en tu plantilla", 45, AchievementCategory.PERFORMANCE),

    DAY_POINTS_50("Jornada sólida", "50+ pts fantasy en una jornada", 40, AchievementCategory.PERFORMANCE),
    DAY_POINTS_75("Jornada brillante", "75+ pts fantasy en una jornada", 60, AchievementCategory.PERFORMANCE),
    DAY_POINTS_100("Jornada épica", "100+ pts fantasy en una jornada", 90, AchievementCategory.PERFORMANCE),
    DAY_POINTS_150("Jornada legendaria", "150+ pts fantasy en una jornada", 130, AchievementCategory.PERFORMANCE),

    CLAUSE_20M("Clausulazo I", "Cláusula a jugador de 20M+", 50, AchievementCategory.CARDS),
    CLAUSE_30M("Clausulazo II", "Cláusula a jugador de 30M+", 75, AchievementCategory.CARDS),
    CLAUSE_50M("Clausulazo III", "Cláusula a jugador de 50M+", 110, AchievementCategory.CARDS),
    CLAUSE_100M("Clausulazo IV", "Cláusula a jugador de 100M+", 180, AchievementCategory.CARDS),

    SHIELD_PLAYER("Blindaje", "Protege a un jugador con carta", 35, AchievementCategory.CARDS),
    SHIELD_3_ACTIVE("Muralla triple", "3 jugadores protegidos a la vez en una liga", 70, AchievementCategory.CARDS),
    SHIELD_5_ACTIVE("Bunker", "5 jugadores protegidos a la vez en una liga", 120, AchievementCategory.CARDS),

    SELL_50M("Vendedor I", "Vende por 50M+ (mercado o carta)", 45, AchievementCategory.MARKET),
    SELL_100M("Vendedor II", "Vende por 100M+", 80, AchievementCategory.MARKET),
    SELL_150M("Vendedor III", "Vende por 150M+", 120, AchievementCategory.MARKET),
    SELL_200M("Vendedor IV", "Vende por 200M+", 170, AchievementCategory.MARKET),

    FINISH_LEAGUE_500("Temporada competida", "Termina liga ida con 500+ pts totales", 60, AchievementCategory.LEAGUE),
    FINISH_LEAGUE_750("Temporada elite", "Termina liga ida con 750+ pts totales", 90, AchievementCategory.LEAGUE),
    FINISH_LEAGUE_1000("Temporada mítica", "Termina liga ida con 1000+ pts totales", 130, AchievementCategory.LEAGUE),

    PACKS_5("Coleccionista I", "Abre 5 sobres en una liga", 40, AchievementCategory.REWARDS),
    PACKS_10("Coleccionista II", "Abre 10 sobres en una liga", 70, AchievementCategory.REWARDS),
    PACKS_15("Coleccionista III", "Abre 15 sobres en una liga", 100, AchievementCategory.REWARDS),
    PACKS_20("Coleccionista IV", "Abre 20 sobres en una liga", 140, AchievementCategory.REWARDS),

    PUSH_WIN_5000("Puja holgada", "Gana subasta por ≤5000€ de margen", 35, AchievementCategory.MARKET),
    PUSH_WIN_1000("Puja ajustada", "Gana subasta por ≤1000€ de margen", 50, AchievementCategory.MARKET),
    PUSH_WIN_500("Puja tensa", "Gana subasta por ≤500€ de margen", 70, AchievementCategory.MARKET),
    PUSH_WIN_100("Puja milimétrica", "Gana subasta por ≤100€ de margen", 100, AchievementCategory.MARKET),

    FIRST_LEAGUE("Primer paso", "Completa tu primera liga válida", 50, AchievementCategory.LEAGUE),
    COACH_ROULETTE("Míster con suerte", "Consigue entrenador en la ruleta", 40, AchievementCategory.REWARDS),

    FRIEND_1("Primer colega", "Consigue tu primer amigo en Eternal XI", 35, AchievementCategory.SOCIAL),
    FRIEND_5("Mano extendida", "Ten 5 amigos en la plataforma", 80, AchievementCategory.SOCIAL),
    FRIEND_15("Capitán social", "Ten 15 amigos en la plataforma", 150, AchievementCategory.SOCIAL),

    FAVORITE_ROSTER_HALF(
            "Mediatoteca",
            "Ficha al menos el 50% de los jugadores del catálogo en ligas terminadas",
            120,
            AchievementCategory.CARDS
    ),
    FAVORITE_ROSTER_COMPLETE(
            "Colección total",
            "Ficha al 100% de los jugadores del catálogo en ligas terminadas",
            250,
            AchievementCategory.CARDS
    );

    private final String title;
    private final String description;
    private final int xpReward;
    private final AchievementCategory category;

    AchievementCode(String title, String description, int xpReward, AchievementCategory category) {
        this.title = title;
        this.description = description;
        this.xpReward = xpReward;
        this.category = category;
    }

    public String code() {
        return name();
    }

    public String title() {
        return title;
    }

    public String description() {
        return description;
    }

    public int xpReward() {
        return xpReward;
    }

    public AchievementCategory category() {
        return category;
    }

    /** Texto ampliado para el botón de información en la app. */
    public String helpDetail() {
        return switch (this) {
            case WIN_LEAGUE_1 -> """
                    Termina una liga en 1.º puesto cuando el cierre sea válido para progreso: \
                    al menos 3 participantes desde el inicio, sin expulsiones, y con alineación \
                    guardada en todas las jornadas finalizadas. Solo cuenta una vez por liga.""";
            case WIN_LEAGUE_3 -> """
                    Gana 3 ligas distintas cumpliendo las mismas reglas de liga válida. \
                    El progreso se acumula en tu cuenta (p. ej. 2/3). No hace falta ganarlas seguidas.""";
            case WIN_LEAGUE_5 -> """
                    Gana 5 ligas válidas en total. Cada campeonato cerrado correctamente suma \
                    una victoria si quedas primero en la clasificación final.""";

            case GOALS_50 -> """
                    Suma 50 goles en total con jugadores de tu propiedad en todas tus ligas. \
                    Cuentan los goles registrados en jornadas finalizadas.""";
            case GOALS_100 -> """
                    Alcanza 100 goles acumulados con tus jugadores. El progreso se muestra \
                    en las estadísticas de tu perfil.""";
            case GOALS_250 -> """
                    Llega a 250 goles acumulados con tus jugadores a lo largo de tu cuenta.""";
            case ASSISTS_25 -> """
                    Registra 25 asistencias totales con jugadores de tu plantilla en ligas jugadas.""";
            case ASSISTS_100 -> """
                    Acumula 100 asistencias con tus jugadores. Aparece en tu perfil público.""";
            case CLEAN_SHEETS_10 -> """
                    Consigue 10 porterías a cero con tus porteros en jornadas finalizadas.""";
            case CLEAN_SHEETS_50 -> """
                    Acumula 50 porterías a cero con tus porteros en todas tus temporadas.""";
            case INJURIES_15 -> """
                    Tus jugadores acumulan 15 lesiones en partido. Un logro irónico visible \
                    en las estadísticas de tu perfil.""";
            case SANCTIONS_25 -> """
                    Tus jugadores suman 25 tarjetas (amarillas + rojas) en jornadas jugadas.""";

            case DAY_POINTS_50 -> """
                    En una misma jornada, suma 50 o más puntos fantasy con tu alineación \
                    (incluye bonus de entrenador si aplica). Solo cuenta la jornada en la que \
                    se supera el umbral.""";
            case DAY_POINTS_75 -> """
                    Necesitas 75+ puntos fantasy en una sola jornada. Si lo consigues, también \
                    obtienes el logro de 50+ si aún no lo tenías.""";
            case DAY_POINTS_100 -> """
                    Marca 100 o más puntos fantasy en una jornada. Suele requerir varios \
                    jugadores con nota alta y buen multiplicador de entrenador.""";
            case DAY_POINTS_150 -> """
                    Consigue 150+ puntos fantasy en una sola jornada. Es una actuación \
                    excepcional; solo se desbloquea una vez en toda tu cuenta.""";

            case CLAUSE_20M -> """
                    En cualquier liga, ejecuta una cláusula directa con carta sobre un rival \
                    cuyo valor efectivo sea de al menos 20 millones. El jugador no puede \
                    estar protegido ni ser tuyo.""";
            case CLAUSE_30M -> """
                    Misma acción que Clausulazo I, pero el jugador objetivo debe valer \
                    30 millones o más en el momento de la cláusula.""";
            case CLAUSE_50M -> """
                    Ejecuta una cláusula con carta sobre un fichaje rival valorado en \
                    50 millones o más. Comprueba el valor en la ficha antes de canjear la carta.""";
            case CLAUSE_100M -> """
                    La cláusula más exigente: fichaje rival de 100 millones o más. \
                    Usa una carta de cláusula válida para ese tramo de valor.""";

            case SHIELD_PLAYER -> """
                    Canjea una carta de protección sobre uno de tus jugadores en una liga. \
                    Basta con tener un escudo activo aplicado correctamente.""";
            case SHIELD_3_ACTIVE -> """
                    En la misma liga, ten 3 jugadores protegidos a la vez (escudos activos \
                    simultáneos). Puedes aplicarlos en jornadas distintas mientras sigan vigentes.""";
            case SHIELD_5_ACTIVE -> """
                    En la misma liga, mantén 5 escudos activos al mismo tiempo. \
                    Planifica varias cartas de protección sin dejar caducar las anteriores.""";

            case SELL_50M -> """
                    Vende un jugador por 50 millones o más en una sola operación. \
                    Cuenta venta directa al mercado o venta con carta de bonus.""";
            case SELL_100M -> """
                    Ingresa 100 millones o más en una venta (mercado o carta). \
                    El importe es el que recibes tú, no el valor de mercado del jugador.""";
            case SELL_150M -> """
                    Venta única de 150 millones o más. Ideal con estrellas valoradas \
                    y cartas que multipliquen el precio de venta.""";
            case SELL_200M -> """
                    Venta única de 200 millones o más. Uno de los logros de mercado más difíciles.""";

            case FINISH_LEAGUE_500 -> """
                    Termina una liga de solo ida (no ida y vuelta) con 500 o más puntos \
                    totales en clasificación. Debe ser liga válida para progreso.""";
            case FINISH_LEAGUE_750 -> """
                    Igual que Temporada competida, pero con 750+ puntos totales al cierre \
                    en una liga de solo ida.""";
            case FINISH_LEAGUE_1000 -> """
                    Termina una liga de solo ida con 1000+ puntos totales. Requiere \
                    regularidad alta en todas las jornadas.""";

            case PACKS_5 -> """
                    Abre 5 sobres de recompensa en la misma liga (gasta puntos de recompensa \
                    en la tienda de la liga). El contador es por participación en esa liga.""";
            case PACKS_10 -> """
                    Abre 10 sobres en una misma liga. Puedes ir desbloqueando también \
                    los logros inferiores (5, 10…) en cascada.""";
            case PACKS_15 -> """
                    Abre 15 sobres en una sola liga. Acumula puntos de recompensa ganando jornadas.""";
            case PACKS_20 -> """
                    Abre 20 sobres en la misma liga. El máximo del coleccionista en una temporada.""";

            case PUSH_WIN_5000 -> """
                    Gana una subasta del mercado nocturno donde tu puja supere a la segunda \
                    por 5000 € o menos. Si ganas con margen menor, también obtienes los logros más fáciles.""";
            case PUSH_WIN_1000 -> """
                    Gana una subasta con margen de 1000 € o menos respecto al segundo clasificado. \
                    Puja justo por encima del rival.""";
            case PUSH_WIN_500 -> """
                    Gana una subasta con margen de 500 € o menos. Necesitas calcular bien \
                    la segunda puja más alta.""";
            case PUSH_WIN_100 -> """
                    Gana una subasta con margen de 100 € o menos: victoria milimétrica. \
                    También desbloquea automáticamente los logros de pujas más holgadas.""";

            case FIRST_LEAGUE -> """
                    Completa tu primera liga válida (mínimo 3 participantes activos, sin trampas \
                    de expulsión y con alineaciones en todas las jornadas). No hace falta ganar; \
                    basta con que la liga cierre correctamente y hayas jugado toda la competición.""";
            case COACH_ROULETTE -> """
                    En la tienda de recompensas de una liga, usa la ruleta de entrenador \
                    y obtén un míster. Gastas puntos de recompensa y solo cuenta la primera \
                    ruleta exitosa (no repetible).""";
            case FRIEND_1 -> """
                    Acepta tu primera solicitud de amistad o consigue que otro jugador acepte \
                    la tuya. Cuenta amistades confirmadas a nivel de cuenta.""";
            case FRIEND_5 -> """
                    Acumula 5 amigos aceptados en tu perfil. Puedes encontrarlos desde la \
                    pantalla de amigos o aceptar solicitudes en la pestaña de solicitudes.""";
            case FRIEND_15 -> """
                    Llega a 15 amigos confirmados en Eternal XI. Un logro social para managers \
                    que disfrutan compitiendo con su gente.""";
            case FAVORITE_ROSTER_HALF -> """
                    Ficha jugadores distintos en ligas que hayan terminado de forma natural \
                    (todas las jornadas finalizadas). Cuando hayas fichado al menos la mitad \
                    del catálogo total en esas ligas, desbloqueas este logro. Cada jugador \
                    cuenta una sola vez aunque lo hayas tenido en varias temporadas.""";
            case FAVORITE_ROSTER_COMPLETE -> """
                    Ficha todos los jugadores del catálogo al menos una vez en ligas terminadas. \
                    Es el complemento del logro al 50%: necesitas haber sido propietario de cada \
                    jugador en alguna liga que ya haya acabado.""";
        };
    }

    /** Meta numérica para logros acumulativos (p. ej. 3 ligas ganadas). */
    public Integer progressTarget() {
        return switch (this) {
            case WIN_LEAGUE_1 -> 1;
            case WIN_LEAGUE_3 -> 3;
            case WIN_LEAGUE_5 -> 5;
            case GOALS_50 -> 50;
            case GOALS_100 -> 100;
            case GOALS_250 -> 250;
            case ASSISTS_25 -> 25;
            case ASSISTS_100 -> 100;
            case CLEAN_SHEETS_10 -> 10;
            case CLEAN_SHEETS_50 -> 50;
            case INJURIES_15 -> 15;
            case SANCTIONS_25 -> 25;
            case PACKS_5 -> 5;
            case PACKS_10 -> 10;
            case PACKS_15 -> 15;
            case PACKS_20 -> 20;
            case FRIEND_1 -> 1;
            case FRIEND_5 -> 5;
            case FRIEND_15 -> 15;
            case FAVORITE_ROSTER_HALF -> 50;
            case FAVORITE_ROSTER_COMPLETE -> 100;
            default -> null;
        };
    }

    public static AchievementCode fromCode(String code) {
        if (code == null || code.isBlank()) {
            return null;
        }
        try {
            return AchievementCode.valueOf(code.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
