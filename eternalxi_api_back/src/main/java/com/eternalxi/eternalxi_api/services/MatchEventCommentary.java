package com.eternalxi.eternalxi_api.services;

import java.util.Random;

/**
 * Frases variadas para la cronología ({@code partido_eventos.texto}). Tono épico y serio salvo
 * {@code TARJETA_ROJA} y {@code LESION}, pensados con humor. El front pinta por {@code tipo}.
 */
public final class MatchEventCommentary {

    private MatchEventCommentary() {}

    private static String pick(Random rng, String[] lines, Object... args) {
        String t = lines[rng.nextInt(lines.length)];
        return args.length == 0 ? t : String.format(t, args);
    }

    private static final String[] RECOVERY = {
            "%s recupera la posesión con autoridad.",
            "%s anticipa la jugada y corta el circuito rival.",
            "%s roba el balón en zona caliente.",
            "%s gana el duelo físico y se queda el esférico.",
            "%s intercepta un pase clave.",
            "%s desarticula el ataque contrario con timing perfecto.",
            "%s domina el rechace y devuelve el orden.",
            "%s mete la pierna en el momento justo.",
            "%s somete al rival y arranca la transición.",
            "%s lee la jugada antes que nadie y corta.",
            "%s se impone en la disputa y emerge con el balón.",
            "%s frena el ímpetu rival con una recuperación limpia.",
            "%s neutraliza la amenaza con temple.",
            "%s se interpone y cambia el ritmo del partido.",
            "%s conquista la segunda jugada para su equipo."
    };

    private static final String[] RECOVERY_AFTER_SHOT = {
            "%s domina el rechace y corta la continuación.",
            "%s llega primero al balón suelto.",
            "%s barre la zona y neutraliza el peligro.",
            "%s captura el segundo balón con determinación.",
            "%s impone presencia tras el disparo.",
            "%s gana la jugada dividida.",
            "%s se lleva el rechazo y oxigena a su equipo.",
            "%s cierra la puerta a la segunda acción.",
            "%s aparece en el corazón del área para limpiar.",
            "%s roba el rebote con frialdad."
    };

    private static final String[] DRIBBLE = {
            "%s rompe la línea con un quiebro devastador.",
            "%s encadena regates y avanza con determinación.",
            "%s conduce el balón con paso firme.",
            "%s deja atrás rivales con técnica sobresaliente.",
            "%s cambia de ritmo y rompe el equilibrio.",
            "%s avanza en conducción imparable.",
            "%s perfila con clase en el uno contra uno.",
            "%s se deshace de la presión con elegancia.",
            "%s acelera por la banda y rompe el orden defensivo.",
            "%s domina el regate en espacio reducido.",
            "%s filtra entre rivales con autoridad.",
            "%s amaga y arranca hacia la meta rival.",
            "%s dibuja una diagonal letal.",
            "%s mantiene el control bajo asedio.",
            "%s demuestra sangre fría en la conducción."
    };

    private static final String[] FOUL = {
            "Entrada tardía de %s sobre %s; el árbitro detiene el juego.",
            "%s derriba a %s con claridad.",
            "%s corta la carrera de %s de forma irregular.",
            "%s comete falta en la disputa con %s.",
            "%s llega tarde al duelo con %s.",
            "%s derriba a %s en la frontal.",
            "%s obstruye a %s con el cuerpo.",
            "%s derriba a %s en la disputa aérea.",
            "Falta clara de %s sobre %s.",
            "%s sujeta a %s en la marca.",
            "%s impacta a %s en la entrada.",
            "%s derriba a %s al disputar el balón.",
            "%s zanca la pierna de %s.",
            "%s empuja a %s en la lucha por posición.",
            "%s comete infracción sobre %s."
    };

    private static final String[] OCASION = {
            "%s se perfila ante la meta; el estadio contiene el aliento.",
            "%s aparece en posición de remate letal.",
            "%s remata con potencia en el corazón del área.",
            "%s se eleva para el cabezazo decisivo.",
            "%s define una jugada de manual.",
            "%s encara la portería con el tiempo detenido.",
            "%s acecha el segundo palo con instinto de gol.",
            "%s recorta dentro del área y amenaza.",
            "%s recibe en la frontal en situación privilegiada.",
            "%s culmina la jugada con un remate claro.",
            "%s arranca el disparo entre líneas.",
            "%s busca el ángulo con frialdad.",
            "%s impacta el balón con convicción desde corta distancia.",
            "%s aparece solo ante la portería.",
            "%s lleva el peligro hasta la línea de gol."
    };

    private static final String[] SHOT = {
            "%s dispara con convicción.",
            "%s prueba desde fuera del área.",
            "%s saca un disparo potente que silba.",
            "%s remata con técnica.",
            "%s golpea el balón buscando la escuadra.",
            "%s intenta sorprender desde la frontal.",
            "%s dispara entre rivales.",
            "%s busca el hueco con determinación.",
            "%s remata con fuerza.",
            "%s suelta un derechazo contundente.",
            "%s prueba con la zurda desde la frontal.",
            "%s impacta el balón con rosca.",
            "%s remata en carrera.",
            "%s dispara sin dudar.",
            "%s ensaya el disparo desde posición ventajosa."
    };

    private static final String[] GOAL = {
            "¡GOL! %s anota para %s.",
            "%s fusila la portería; gol de %s.",
            "%s define con frialdad y marca para %s.",
            "%s rubrica la jugada con gol para %s.",
            "%s hunde el balón en la red de %s.",
            "%s culmina la acción con tanto para %s.",
            "%s no perdona el mano a mano; gol de %s.",
            "%s clava el disparo al fondo de la red (%s).",
            "%s marca un gol de mucho calibre para %s.",
            "%s eleva al equipo con su tanto (%s).",
            "%s castiga la portería rival (%s).",
            "%s rompe el empate con gol para %s.",
            "%s firma el tanto decisivo de %s.",
            "%s remacha el balón dentro (%s).",
            "%s aparece para sentenciar la jugada (%s)."
    };

    private static final String[] ASSIST = {
            "%s habilita a %s con un pase magistral.",
            "%s sirve el balón en medida perfecta para %s.",
            "%s rompe la línea defensiva con un envío para %s.",
            "%s filtra un balón medido hacia %s.",
            "%s inventa la asistencia que culmina %s.",
            "%s envía un centro preciso hacia %s.",
            "%s habilita la jugada para que %s marque.",
            "%s asiste con visión de juego a %s.",
            "%s coloca el balón donde %s lo necesita.",
            "%s da el último pase a %s.",
            "%s desbloquea la jugada para %s.",
            "%s conecta con %s en la frontal.",
            "%s asiste con clase a %s.",
            "%s prolonga la jugada hacia %s.",
            "%s envía un pase interior para %s."
    };

    private static final String[] SAVE = {
            "%s detiene el disparo de %s con una parada espectacular.",
            "%s estira la mano y niega el gol a %s.",
            "%s salva el equipo en el mano a mano ante %s.",
            "%s despeja el peligro con los puños ante %s.",
            "%s responde con una parada monumental a %s.",
            "%s vuela y desvía el remate de %s.",
            "%s cierra el ángulo y frustra a %s.",
            "%s realiza una intervención de mérito ante %s.",
            "%s tapa el disparo de %s con reflejos sobresalientes.",
            "%s anticipa la intención de %s.",
            "%s bloca con seguridad el tiro de %s.",
            "%s detiene el cañonazo de %s.",
            "%s se estira en plancha para negar a %s.",
            "%s impone su presencia ante el remate de %s.",
            "%s se crece bajo palos ante %s."
    };

    private static final String[] RED_CARD = {
            "¡Roja! %s pierde los papeles con el colegiado y lo paga caro.",
            "Tarjeta roja para %s: la protesta escaló nivel telenovela.",
            "%s ve la roja; rumores de que el árbitro buscaba las gafas.",
            "Expulsado %s tras una encendida discusión sobre geometría del fuera de juego.",
            "%s abandona el campo entre gestos teatrales.",
            "¡Roja directa! %s cruza la línea entre intensidad y meme.",
            "%s recibe la cartulina carmesí; hasta el linier suspira.",
            "%s se marcha: la calentura le duró más que la jugada.",
            "El árbitro no perdona: %s fuera por imprudencia extrema.",
            "%s protesta tanto que la tarjeta llegó en modo exprés.",
            "¡Expulsión! %s y el cuarto árbitro ya no se siguen en redes.",
            "%s ve roja por una entrada que el VAR revisaría… en otro deporte.",
            "Roja para %s: intentó convencer al árbitro con el puño cerrado. Mal negocio.",
            "%s se va antes de tiempo; el vestuario tiembla.",
            "%s confunde el pecho con la cara del árbitro y… adiós.",
            "¡Directa! %s amenaza con \"hablar con el manager\" del árbitro.",
            "%s recibe roja tras insinuar que el colegiado compra las gafas en el chino.",
            "%s explota: la charla con el árbitro acaba en meme viral y cartulina."
    };

    /** Tono humorístico (único bloque de lesión con cachondeo). */
    private static final String[] INJURY = {
            "%s se inventa una caída de óscar y hasta el linier aplaude.",
            "%s se agarra la rodilla como si rodara la temporada entera.",
            "¡Lesión! %s pide el cambio entre muecas dignas de telenovela.",
            "%s cree que el césped estaba mojado… en seco.",
            "%s se duele; el fisio corre más rápido que en entreno.",
            "%s tropieza con el aire y el banquillo ya tiembla.",
            "%s se retuerce; hasta el VAR revisa si es postureo.",
            "%s abandona el campo como si hubiera pisado Lego.",
            "%s pide agua bendita antes que vendajes.",
            "%s se lesiona en la jugada más inofensiva del siglo.",
            "%s grita tanto que el rival piensa que ya marcó.",
            "%s queda tendido; el público en silencio incómodo.",
            "%s dice que no puede más… justo cuando tocaba sprint.",
            "%s confunde el maletero con el muslo — cambio forzoso.",
            "%s se lleva la mano a la cabeza como si fuera final de Champions."
    };

    /** Formato: equipo, jugador que entra, jugador que sale */
    private static final String[] SUBSTITUTION = {
            "Cambio en %s: %s entra en lugar de %s.",
            "%s mueve el banquillo; relevo %s por %s.",
            "%s refresca el equipo: entra %s, sale %s.",
            "Sustitución en %s — %s toma el testigo de %s.",
            "%s busca nuevo impulso con la entrada de %s por %s.",
            "%s ordena el relevo: %s sustituye a %s.",
            "%s ajusta el dibujo; %s entra por %s.",
            "%s da minutos frescos a %s; abandona %s.",
            "Rotación en %s: %s ocupa el puesto de %s.",
            "%s confía en %s para el tramo final; sale %s.",
            "%s mueve piezas: %s incorpora la línea por %s.",
            "%s refuerza el medio con %s en lugar de %s.",
            "%s cambia el perfil del equipo: entra %s por %s.",
            "%s decide el relevo — %s por %s.",
            "%s introduce a %s y retira a %s.",
            "%s ejecuta el cambio %s ↔ %s."
    };

    private static final String[] GK_SUB_AFTER_RED = {
            "Tras la expulsión del guardameta, %s entra por %s (%s).",
            "%s ocupa la portería en una reorganización forzada; sale %s (%s).",
            "El técnico de %s envía a %s bajo palos; abandona el campo %s.",
            "%s asume el marco; %s deja su posición (%s).",
            "Sustitución de urgencia en %s: %s custodia la meta, relevo %s."
    };

    private static final String[] GK_EMERGENCY_OUTFIELD = {
            "Sin portero suplente, %s improvisa bajo palos tras la expulsión de %s (%s).",
            "%s ocupa la portería por necesidad extrema; %s ha sido expulsado (%s).",
            "%s defiende la portería en una medida extrema; expulsado %s (%s).",
            "%s asume los guantes de forma provisional; fuera %s (%s).",
            "En inferioridad numérica, %s ocupa la portería; marcha %s (%s)."
    };

    public static String recovery(Random rng, String player) {
        return pick(rng, RECOVERY, player);
    }

    public static String recoveryAfterShot(Random rng, String recoverer) {
        return pick(rng, RECOVERY_AFTER_SHOT, recoverer);
    }

    public static String dribble(Random rng, String player) {
        return pick(rng, DRIBBLE, player);
    }

    public static String foul(Random rng, String fouler, String victim) {
        return pick(rng, FOUL, fouler, victim);
    }

    public static String occasion(Random rng, String shooter) {
        return pick(rng, OCASION, shooter);
    }

    public static String shot(Random rng, String shooter) {
        return pick(rng, SHOT, shooter);
    }

    public static String goal(Random rng, String scorer, String teamName) {
        return pick(rng, GOAL, scorer, teamName);
    }

    public static String assist(Random rng, String assistant, String scorer) {
        return pick(rng, ASSIST, assistant, scorer);
    }

    public static String save(Random rng, String goalkeeper, String shooter) {
        return pick(rng, SAVE, goalkeeper, shooter);
    }

    public static String redCard(Random rng, String player) {
        return pick(rng, RED_CARD, player);
    }

    public static String injury(Random rng, String player) {
        return pick(rng, INJURY, player);
    }

    public static String substitution(Random rng, String teamName, String incoming, String outgoing) {
        return pick(rng, SUBSTITUTION, teamName, incoming, outgoing);
    }

    /** incoming GK, outgoing outfield, team name */
    public static String goalkeeperSubAfterRed(Random rng, String incomingGk, String outgoing, String teamName) {
        return pick(rng, GK_SUB_AFTER_RED, incomingGk, outgoing, teamName);
    }

    /** emergency outfield GK, expelled GK name, team name */
    public static String emergencyGoalkeeper(Random rng, String outfieldGk, String expelledGk, String teamName) {
        return pick(rng, GK_EMERGENCY_OUTFIELD, outfieldGk, expelledGk, teamName);
    }
}
