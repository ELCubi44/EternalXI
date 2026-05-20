/// Estado de jugador para la jornada (API normalizada: `LESIONADO`, `SANCIONADO`,
/// `DISPONIBLE`, `DUDA`, etc.).
String leaguePlayerEstadoNormalized(String raw) => raw.trim().toUpperCase();

bool leaguePlayerEstadoIsLesionado(String estado) =>
    leaguePlayerEstadoNormalized(estado) == 'LESIONADO';

bool leaguePlayerEstadoIsSancionado(String estado) =>
    leaguePlayerEstadoNormalized(estado) == 'SANCIONADO';

/// Lesión o sanción tienen prioridad visual sobre [probabilidadTitular].
bool leaguePlayerEstadoOcultaProbabilidadTitular(String estado) =>
    leaguePlayerEstadoIsLesionado(estado) ||
    leaguePlayerEstadoIsSancionado(estado);
