import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';

/// Parsea instante de inicio desde ISO-8601 (p. ej. `...Z`) o epoch ms/seg.
/// Debe ser la única fuente de verdad para alinear calendario, listado y detalle.
DateTime? parseLeagueKickoffInstant(dynamic v) {
  if (v == null) {
    return null;
  }
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(s);
    if (parsed != null) {
      return parsed;
    }
    return null;
  }
  if (v is int) {
    if (v <= 0) {
      return null;
    }
    if (v > 2000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
    }
    if (v > 2000000000) {
      return DateTime.fromMillisecondsSinceEpoch(v * 1000, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
  }
  if (v is double) {
    return parseLeagueKickoffInstant(v.round());
  }
  return null;
}

/// Lee el kickoff real del JSON de un partido (round o detalle).
DateTime? pickLeagueMatchKickoffFromMap(Map<String, dynamic> json) {
  for (final key in const [
    'inicioEn',
    'inicio_en',
    'inicioPartido',
    'inicio_partido',
    'fechaInicio',
    'fecha_inicio',
    'kickoff',
    'fechaHora',
    'fecha_hora',
    'inicio',
  ]) {
    if (!json.containsKey(key)) {
      continue;
    }
    final parsed = parseLeagueKickoffInstant(json[key]);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

/// Partido resumido (lista por día, detalle de jornada, etc.).
class LeagueMatchSummary {
  const LeagueMatchSummary({
    required this.idPartido,
    required this.idEquipoLocal,
    required this.idEquipoVisitante,
    required this.nombreLocal,
    required this.nombreVisitante,
    required this.fotoEscudoLocal,
    required this.fotoEscudoVisitante,
    this.fechaPartido,
    this.golesLocal = 0,
    this.golesVisitante = 0,
    this.estado = '',
    this.idJornada,
    this.numeroJornada,
  });

  final int idPartido;
  final int idEquipoLocal;
  final int idEquipoVisitante;
  final String nombreLocal;
  final String nombreVisitante;
  final String fotoEscudoLocal;
  final String fotoEscudoVisitante;
  final DateTime? fechaPartido;
  final int golesLocal;
  final int golesVisitante;

  /// `PENDIENTE`, `EN_JUEGO`, `FINALIZADO`, etc. (según backend).
  final String estado;

  /// Contexto de jornada cuando viene de `GET .../rounds/{id}` (opcional).
  final int? idJornada;
  final int? numeroJornada;

  LeagueMatchSummary copyWith({
    int? idPartido,
    int? idEquipoLocal,
    int? idEquipoVisitante,
    String? nombreLocal,
    String? nombreVisitante,
    String? fotoEscudoLocal,
    String? fotoEscudoVisitante,
    DateTime? fechaPartido,
    int? golesLocal,
    int? golesVisitante,
    String? estado,
    int? idJornada,
    int? numeroJornada,
    bool clearIdJornada = false,
    bool clearNumeroJornada = false,
  }) {
    return LeagueMatchSummary(
      idPartido: idPartido ?? this.idPartido,
      idEquipoLocal: idEquipoLocal ?? this.idEquipoLocal,
      idEquipoVisitante: idEquipoVisitante ?? this.idEquipoVisitante,
      nombreLocal: nombreLocal ?? this.nombreLocal,
      nombreVisitante: nombreVisitante ?? this.nombreVisitante,
      fotoEscudoLocal: fotoEscudoLocal ?? this.fotoEscudoLocal,
      fotoEscudoVisitante: fotoEscudoVisitante ?? this.fotoEscudoVisitante,
      fechaPartido: fechaPartido ?? this.fechaPartido,
      golesLocal: golesLocal ?? this.golesLocal,
      golesVisitante: golesVisitante ?? this.golesVisitante,
      estado: estado ?? this.estado,
      idJornada: clearIdJornada ? null : (idJornada ?? this.idJornada),
      numeroJornada: clearNumeroJornada
          ? null
          : (numeroJornada ?? this.numeroJornada),
    );
  }

  String? escudoLocalUrl() => LeagueAssetUrls.resolveTeamBadgeUrl(
        idEquipo: idEquipoLocal,
        rawFoto: fotoEscudoLocal,
      );

  String? escudoVisitanteUrl() => LeagueAssetUrls.resolveTeamBadgeUrl(
        idEquipo: idEquipoVisitante,
        rawFoto: fotoEscudoVisitante,
      );

  /// Fila de `partidos` en `GET .../rounds/{idJornada}` (`LeagueRoundMatchResponse`).
  factory LeagueMatchSummary.fromRoundMatchRow(Map<String, dynamic> json) {
    final idJ = readLeagueInt(json, const ['idJornada', 'id_jornada']);
    final numJ = readLeagueInt(json, const [
      'numeroJornada',
      'numero_jornada',
      'numero',
    ]);
    final kickoff = pickLeagueMatchKickoffFromMap(json);
    return LeagueMatchSummary(
      idPartido: readLeagueInt(json, const ['idPartido']),
      idEquipoLocal: readLeagueInt(json, const ['idEquipoLocal']),
      idEquipoVisitante: readLeagueInt(json, const ['idEquipoVisitante']),
      nombreLocal: readLeagueString(json, const ['nombreEquipoLocal']),
      nombreVisitante: readLeagueString(json, const ['nombreEquipoVisitante']),
      fotoEscudoLocal: '',
      fotoEscudoVisitante: '',
      fechaPartido: kickoff,
      golesLocal: readLeagueInt(json, const ['golesLocal']),
      golesVisitante: readLeagueInt(json, const ['golesVisitante']),
      estado: readLeagueString(json, const [
        'estado',
        'status',
        'estadoPartido',
        'estado_partido',
        'matchStatus',
        'match_status',
        'fase',
      ]),
      idJornada: idJ > 0 ? idJ : null,
      numeroJornada: numJ > 0 ? numJ : null,
    );
  }

  factory LeagueMatchSummary.fromJson(Map<String, dynamic> json) {
    final local = _readTeamBlock(json, isLocal: true);
    final visit = _readTeamBlock(json, isLocal: false);
    return LeagueMatchSummary(
      idPartido: readLeagueInt(json, const [
        'idPartido',
        'id_partido',
        'id',
        'idMatch',
        'matchId',
      ]),
      idEquipoLocal: local.isNotEmpty
          ? readLeagueInt(local, const [
              'idEquipo',
              'id_equipo',
              'equipoId',
              'id',
            ])
          : readLeagueInt(json, const [
              'idEquipoLocal',
              'id_equipo_local',
              'idLocal',
              'id_local',
              'idEquipoCasa',
            ]),
      idEquipoVisitante: visit.isNotEmpty
          ? readLeagueInt(visit, const [
              'idEquipo',
              'id_equipo',
              'equipoId',
              'id',
            ])
          : readLeagueInt(json, const [
              'idEquipoVisitante',
              'id_equipo_visitante',
              'idVisitante',
              'id_visitante',
              'idEquipoFuera',
            ]),
      nombreLocal: local.isNotEmpty
          ? readLeagueString(local, const [
              'nombre',
              'nombreEquipo',
              'nombre_equipo',
              'club',
            ])
          : readLeagueString(json, const [
              'nombreLocal',
              'nombre_local',
              'equipoLocal',
              'local',
            ]),
      nombreVisitante: visit.isNotEmpty
          ? readLeagueString(visit, const [
              'nombre',
              'nombreEquipo',
              'nombre_equipo',
              'club',
            ])
          : readLeagueString(json, const [
              'nombreVisitante',
              'nombre_visitante',
              'equipoVisitante',
              'visitante',
            ]),
      fotoEscudoLocal: local.isNotEmpty
          ? readLeagueString(local, const [
              'foto',
              'escudo',
              'fotoEquipo',
              'foto_equipo',
              'badge',
            ])
          : readLeagueString(json, const [
              'fotoEquipoLocal',
              'foto_local',
              'escudoLocal',
            ]),
      fotoEscudoVisitante: visit.isNotEmpty
          ? readLeagueString(visit, const [
              'foto',
              'escudo',
              'fotoEquipo',
              'foto_equipo',
              'badge',
            ])
          : readLeagueString(json, const [
              'fotoEquipoVisitante',
              'foto_visitante',
              'escudoVisitante',
            ]),
      fechaPartido: _parseDate(json),
      golesLocal: readLeagueInt(json, const ['golesLocal']),
      golesVisitante: readLeagueInt(json, const ['golesVisitante']),
      estado: readLeagueString(json, const [
        'estado',
        'status',
        'estadoPartido',
        'estado_partido',
        'matchStatus',
        'match_status',
        'fase',
      ]),
      idJornada: () {
        final v = readLeagueInt(json, const ['idJornada', 'id_jornada']);
        return v > 0 ? v : null;
      }(),
      numeroJornada: () {
        final v = readLeagueInt(json, const [
          'numeroJornada',
          'numero_jornada',
          'numero',
        ]);
        return v > 0 ? v : null;
      }(),
    );
  }

  static Map<String, dynamic> _readTeamBlock(
    Map<String, dynamic> json, {
    required bool isLocal,
  }) {
    final keys = isLocal
        ? const ['equipoLocal', 'equipo_local', 'local', 'home', 'casa']
        : const [
            'equipoVisitante',
            'equipo_visitante',
            'visitante',
            'away',
            'fuera',
          ];
    for (final k in keys) {
      final v = json[k];
      if (v is Map<String, dynamic>) {
        return v;
      }
      if (v is Map) {
        return v.map((a, b) => MapEntry(a.toString(), b));
      }
    }
    return json;
  }

  static DateTime? _parseDate(Map<String, dynamic> json) {
    for (final key in const [
      'fecha',
      'fechaPartido',
      'fecha_partido',
      'fechaHora',
      'fecha_hora',
      'inicio',
      'date',
      'kickoff',
      'inicioEn',
      'inicioPartido',
    ]) {
      final v = json[key];
      final parsed = parseLeagueKickoffInstant(v);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }
}

/// Fila de `GET .../rounds` (`LeagueRoundSummaryResponse`): sin lista `partidos`.
class LeagueRoundSummary {
  const LeagueRoundSummary({
    required this.id,
    required this.nombre,
    required this.matches,
    this.idLiga = 0,
    this.numero = 0,
    this.scheduleInicio,
    this.scheduleFin,
    this.scheduleInicioEn,
    this.estado = '',
    this.totalPartidos = 0,
    this.partidosFinalizados = 0,
    this.actual = false,
    this.proxima = false,
    this.finalizada = false,
  });

  final int id;
  final String nombre;
  final List<LeagueMatchSummary> matches;

  final int idLiga;
  final int numero;
  final DateTime? scheduleInicio;
  final DateTime? scheduleFin;
  final DateTime? scheduleInicioEn;
  final String estado;
  final int totalPartidos;
  final int partidosFinalizados;
  final bool actual;
  final bool proxima;
  final bool finalizada;

  /// `inicio` / `fin` son [LocalDate] en el API (string `yyyy-MM-dd`).
  factory LeagueRoundSummary.fromScheduleRow(Map<String, dynamic> json) {
    final num = readLeagueInt(json, const ['numero']);
    return LeagueRoundSummary(
      id: readLeagueInt(json, const ['idJornada']),
      idLiga: readLeagueInt(json, const ['idLiga']),
      numero: num,
      nombre: num > 0 ? 'Jornada $num' : 'Jornada',
      matches: const [],
      scheduleInicio: parseScheduleLocalDate(json['inicio']),
      scheduleFin: parseScheduleLocalDate(json['fin']),
      scheduleInicioEn: parseScheduleInstant(json['inicioEn']),
      estado: readLeagueString(json, const ['estado']),
      totalPartidos: readLeagueInt(json, const ['totalPartidos']),
      partidosFinalizados: readLeagueInt(json, const ['partidosFinalizados']),
      actual: readLeagueBool(json, const ['actual']),
      proxima: readLeagueBool(json, const ['proxima']),
      finalizada: readLeagueBool(json, const ['finalizada']),
    );
  }

  static DateTime? parseScheduleInstant(dynamic v) {
    return parseLeagueKickoffInstant(v);
  }

  static DateTime? parseScheduleLocalDate(dynamic v) {
    if (v is String && v.length >= 10) {
      return DateTime.tryParse(v.substring(0, 10));
    }
    return null;
  }

  /// Día calendario [day] (solo fecha) dentro de [scheduleInicio]–[scheduleFin] inclusive.
  bool coversCalendarDay(DateTime day) {
    final a = scheduleInicio;
    final b = scheduleFin;
    if (a == null || b == null) {
      return false;
    }
    final d = DateTime(day.year, day.month, day.day);
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return !d.isBefore(da) && !d.isAfter(db);
  }
}

/// Respuesta de `GET .../rounds/{idJornada}` (`LeagueRoundDetailResponse`).
class LeagueRoundDetailData {
  const LeagueRoundDetailData({
    required this.idJornada,
    required this.idLiga,
    required this.numero,
    required this.partidos,
    this.inicio,
    this.inicioEn,
    this.fin,
    this.estado = '',
    this.totalPartidos = 0,
    this.partidosFinalizados = 0,
  });

  final int idJornada;
  final int idLiga;
  final int numero;
  final DateTime? inicio;
  final DateTime? inicioEn;
  final DateTime? fin;
  final String estado;
  final int totalPartidos;
  final int partidosFinalizados;
  final List<LeagueMatchSummary> partidos;

  factory LeagueRoundDetailData.fromBackend(Map<String, dynamic> json) {
    final raw = json['partidos'];
    final list = <LeagueMatchSummary>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is! Map) {
          continue;
        }
        list.add(
          LeagueMatchSummary.fromRoundMatchRow(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
          ),
        );
      }
    }
    return LeagueRoundDetailData(
      idJornada: readLeagueInt(json, const ['idJornada']),
      idLiga: readLeagueInt(json, const ['idLiga']),
      numero: readLeagueInt(json, const ['numero']),
      inicio: LeagueRoundSummary.parseScheduleLocalDate(json['inicio']),
      fin: LeagueRoundSummary.parseScheduleLocalDate(json['fin']),
      inicioEn: LeagueRoundSummary.parseScheduleInstant(json['inicioEn']),
      estado: readLeagueString(json, const ['estado']),
      totalPartidos: readLeagueInt(json, const ['totalPartidos']),
      partidosFinalizados: readLeagueInt(json, const ['partidosFinalizados']),
      partidos: list,
    );
  }
}

/// `GET .../rounds`: solo resúmenes de jornada (`LeagueRoundSummaryResponse`).
List<LeagueRoundSummary> parseLeagueRoundsResponse(dynamic data) {
  final direct = readLeagueListMap(data);
  return direct.map(LeagueRoundSummary.fromScheduleRow).toList();
}
