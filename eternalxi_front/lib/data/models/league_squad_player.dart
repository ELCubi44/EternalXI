import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/data/models/league_player_round_stat.dart';

/// Jugador en la plantilla del usuario para una liga.
class LeagueSquadPlayer {
  const LeagueSquadPlayer({
    required this.idLigaJugador,
    required this.idJugador,
    required this.nombre,
    required this.pila,
    required this.posicion,
    required this.valoracion,
    required this.idEquipo,
    required this.nombreEquipo,
    required this.estado,
    this.estadoVisible,
    required this.cansancio,
    required this.valor,
    required this.fotoJugador,
    required this.enPoolMercado,
    required this.propietarioNick,
    required this.idUsuarioDueno,
    this.idLiga = 0,
    this.descripcion = '',
    this.dorsal = 0,
    this.genero = '',
    this.fotoEquipo = '',
    this.valorAnterior = 0.0,
    this.adquiridoEn = '',
    this.nombreDuenoVisible = '',
    this.esMercado = false,
    this.puntosTotales = 0.0,
    this.tieneOfertaPendiente = false,
    this.roundStats = const [],
    this.probabilidadTitular,
    this.motivoTitularidad,
    this.idPartidoProbabilidad,
    this.calculadoEnProbabilidad,
    this.jugadorProtegido = false,
    this.proteccionHastaFinTemporada = false,
    this.proteccionJornadaFin,
  });

  /// Usuario dueño lógico del jugador en liga (1 = mercado).
  static const int usuarioMercadoId = 1;

  final int idLigaJugador;
  final int idJugador;
  final String nombre;
  final String pila;
  final String posicion;
  final double valoracion;
  final int idEquipo;
  final String nombreEquipo;
  final String estado;

  /// Estado visible enmascarado del backend (prioridad en UI).
  final String? estadoVisible;

  final int cansancio;
  final double valor;
  final String fotoJugador;

  /// Si el backend indica que el jugador está en el mercado / libre.
  final bool enPoolMercado;

  /// Nickname corto del propietario (usuario), si aplica.
  final String propietarioNick;

  /// Dueño real del jugador en la liga (`id_usuario_dueno`, etc.). 0 = no informado.
  final int idUsuarioDueno;

  final int idLiga;
  final String descripcion;
  final int dorsal;
  final String genero;
  final String fotoEquipo;
  final double valorAnterior;
  final String adquiridoEn;

  /// Texto listo para UI según backend (`Mercado`, nickname, etc.).
  final String nombreDuenoVisible;

  /// Campo explícito del API de mercado.
  final bool esMercado;

  /// Puntos acumulados del jugador en la liga.
  final double puntosTotales;

  /// Indica si existe al menos una oferta pendiente sobre el jugador.
  final bool tieneOfertaPendiente;

  /// Estadísticas por jornada si el backend las anexa al jugador (plantilla/mercado).
  final List<LeaguePlayerRoundStat> roundStats;

  /// 0–95 o `null` si el backend aún no calculó titularidad para la jornada.
  final int? probabilidadTitular;

  /// Texto explicativo del modelo de titularidad, si viene.
  final String? motivoTitularidad;

  /// Partido asociado al cálculo de probabilidad, si aplica.
  final int? idPartidoProbabilidad;

  /// Marca temporal del cálculo en servidor.
  final DateTime? calculadoEnProbabilidad;

  final bool jugadorProtegido;
  final bool proteccionHastaFinTemporada;
  final int? proteccionJornadaFin;

  /// Escudo: ruta API segura o `GET /assets/teams/{idEquipo}`.
  String? resolvedFotoEquipoUrl() {
    return LeagueAssetUrls.resolveTeamBadgeUrl(
      idEquipo: idEquipo,
      rawFoto: fotoEquipo,
    );
  }

  factory LeagueSquadPlayer.fromJson(Map<String, dynamic> json) {
    final esMercadoApi = readLeagueBool(json, const [
      'esMercado',
      'es_mercado',
    ]);
    final legacyMercado = readLeagueBool(json, const [
      'enMercado',
      'en_mercado',
      'mercadoLibre',
      'mercado_libre',
      'libreEnMercado',
      'poolMercado',
    ]);
    return LeagueSquadPlayer(
      idLigaJugador: readLeagueInt(json, const [
        'idLigaJugador',
        'id_liga_jugador',
        'ligaJugadorId',
      ]),
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idJugador: readLeagueInt(json, const [
        'idJugador',
        'id_jugador',
        'jugadorId',
      ]),
      nombre: readLeagueString(json, const ['nombre', 'name']),
      pila: readLeagueString(json, const [
        'pila',
        'apodo',
        'nick',
        'alias',
        'nombreVisible',
        'nombre_visible',
      ]),
      descripcion: readLeagueString(json, const [
        'descripcion',
        'descripción',
        'description',
        'bio',
      ]),
      posicion: readLeagueString(json, const [
        'posicion',
        'posición',
        'demarcacion',
        'demarcación',
        'rol',
      ]),
      valoracion: readLeagueDouble(json, const [
        'valoracion',
        'valoración',
        'rating',
        'overall',
        'media',
      ]),
      idEquipo: readLeagueInt(json, const [
        'idEquipo',
        'id_equipo',
        'equipoId',
      ]),
      nombreEquipo: readLeagueString(json, const [
        'nombreEquipo',
        'nombre_equipo',
        'equipo',
        'club',
      ]),
      fotoEquipo: readLeagueString(json, const [
        'fotoEquipo',
        'foto_equipo',
        'escudoEquipo',
        'escudo_equipo',
      ]),
      estado: readLeagueString(json, const ['estado', 'status']),
      estadoVisible: readLeagueOptionalNonEmptyString(json, const [
        'estadoVisible',
        'estado_visible',
      ]),
      cansancio: readLeagueInt(json, const ['cansancio', 'fatiga', 'fatigue']),
      valor: readLeagueDouble(json, const ['valor', 'precio', 'marketValue']),
      valorAnterior: readLeagueDouble(json, const [
        'valorAnterior',
        'valor_anterior',
        'previousValue',
      ]),
      fotoJugador: readLeagueString(json, const [
        'fotoUrl',
        'foto_url',
        'fotoJugadorUrl',
        'foto_jugador_url',
        'fotoJugador',
        'foto_jugador',
        'foto',
        'imagen',
        'urlFoto',
      ]),
      dorsal: readLeagueInt(json, const ['dorsal', 'numero', 'número', 'num']),
      genero: readLeagueString(json, const ['genero', 'género', 'gender']),
      adquiridoEn: readLeagueString(json, const [
        'adquiridoEn',
        'adquirido_en',
        'fechaAdquisicion',
      ]),
      enPoolMercado: esMercadoApi || legacyMercado,
      esMercado: esMercadoApi,
      puntosTotales: readLeagueDouble(json, const [
        'puntosTotales',
        'puntos_totales',
        'puntos',
      ]),
      tieneOfertaPendiente: readLeagueBool(json, const [
        'tieneOfertaPendiente',
        'tiene_oferta_pendiente',
      ]),
      propietarioNick: readLeagueString(json, const [
        'propietarioNickname',
        'propietario_nickname',
        'nicknamePropietario',
        'duenoNickname',
        'ownerNickname',
        'nickPropietario',
      ]),
      idUsuarioDueno: readLeagueInt(json, const [
        'idUsuarioDueno',
        'id_usuario_dueno',
        'idUsuarioDueño',
        'duenoId',
        'propietarioId',
        'idPropietario',
        'id_propietario',
      ]),
      nombreDuenoVisible: readLeagueString(json, const [
        'nombreDuenoVisible',
        'nombre_dueno_visible',
        'duenoVisible',
        'ownerDisplayName',
      ]),
      roundStats: parseLeaguePlayerRoundStatsList(json),
      // Titularidad (backend): camelCase + snake_case; sin otros alias (p. ej. starterProbability).
      probabilidadTitular: readLeagueOptionalProbabilityTitular(json),
      motivoTitularidad: readLeagueOptionalNonEmptyString(json, const [
        'motivoTitularidad',
        'motivo_titularidad',
      ]),
      idPartidoProbabilidad: readLeagueOptionalPositiveInt(json, const [
        'idPartidoProbabilidad',
        'id_partido_probabilidad',
      ]),
      calculadoEnProbabilidad: readLeagueOptionalDateTime(json, const [
        'calculadoEnProbabilidad',
        'calculado_en_probabilidad',
      ]),
      jugadorProtegido: readLeagueBool(json, const [
        'jugadorProtegido',
        'jugador_protegido',
      ]),
      proteccionHastaFinTemporada: readLeagueBool(json, const [
        'proteccionHastaFinTemporada',
        'proteccion_hasta_fin_temporada',
      ]),
      proteccionJornadaFin: readLeagueOptionalPositiveInt(json, const [
        'proteccionJornadaFin',
        'proteccion_jornada_fin',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idLigaJugador': idLigaJugador,
      'idLiga': idLiga,
      'idJugador': idJugador,
      'nombre': nombre,
      'pila': pila,
      'descripcion': descripcion,
      'posicion': posicion,
      'valoracion': valoracion,
      'idEquipo': idEquipo,
      'nombreEquipo': nombreEquipo,
      'fotoEquipo': fotoEquipo,
      'estado': estado,
      'cansancio': cansancio,
      'valor': valor,
      'valorAnterior': valorAnterior,
      'fotoJugador': fotoJugador,
      'dorsal': dorsal,
      'genero': genero,
      'adquiridoEn': adquiridoEn,
      'enPoolMercado': enPoolMercado,
      'esMercado': esMercado,
      'puntosTotales': puntosTotales,
      'tieneOfertaPendiente': tieneOfertaPendiente,
      'propietarioNick': propietarioNick,
      'idUsuarioDueno': idUsuarioDueno,
      'nombreDuenoVisible': nombreDuenoVisible,
      if (probabilidadTitular != null)
        'probabilidadTitular': probabilidadTitular,
      if (motivoTitularidad != null && motivoTitularidad!.trim().isNotEmpty)
        'motivoTitularidad': motivoTitularidad!.trim(),
      if (idPartidoProbabilidad != null)
        'idPartidoProbabilidad': idPartidoProbabilidad,
      if (calculadoEnProbabilidad != null)
        'calculadoEnProbabilidad':
            calculadoEnProbabilidad!.toIso8601String(),
      'jugadorProtegido': jugadorProtegido,
      'proteccionHastaFinTemporada': proteccionHastaFinTemporada,
      if (proteccionJornadaFin != null)
        'proteccionJornadaFin': proteccionJornadaFin,
      'roundStats': roundStats
          .map(
            (e) => {
              'idJornada': e.idJornada,
              'numeroJornada': e.numeroJornada,
              'minutosJugados': e.minutosJugados,
              'goles': e.goles,
              'asistencias': e.asistencias,
              'tarjetasAmarillas': e.tarjetasAmarillas,
              'tarjetasRojas': e.tarjetasRojas,
              'puntos': e.puntos,
            },
          )
          .toList(),
    };
  }
}
