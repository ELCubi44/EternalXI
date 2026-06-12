import 'package:eternal_xi/data/models/league_json_read.dart';
import 'package:eternal_xi/data/models/league_player_round_stats.dart';
import 'package:eternal_xi/data/models/league_squad_player.dart';
import 'package:flutter/foundation.dart';

/// Detalle completo de jugador en el contexto de una liga concreta.
class LeaguePlayerDetail {
  const LeaguePlayerDetail({
    required this.idLigaJugador,
    required this.idJugador,
    required this.nombre,
    required this.pila,
    required this.posicion,
    required this.valoracion,
    required this.idEquipo,
    required this.nombreEquipo,
    required this.estado,
    required this.cansancio,
    required this.valor,
    required this.valorAnterior,
    required this.fotoJugador,
    this.puntosTotales = 0.0,
    this.puntosFantasyTotales,
    this.estadoVisible,
    this.idUsuarioDueno = 0,
    this.enPoolMercado = false,
    this.esMercado = false,
    this.enMercadoHoy = false,
    this.tieneOfertaPendiente = false,
    this.nombreDuenoVisible = '',
    this.propietarioNick = '',
    required this.estadisticasJornadas,
    this.probabilidadTitular,
    this.motivoTitularidad,
    this.idPartidoProbabilidad,
    this.calculadoEnProbabilidad,
    this.jugadorProtegido = false,
    this.proteccionHastaFinTemporada = false,
    this.proteccionJornadaFin,
    this.valorMercadoEfectivo,
  });

  final int idLigaJugador;
  final int idJugador;
  final String nombre;
  final String pila;
  final String posicion;
  final double valoracion;
  final int idEquipo;
  final String nombreEquipo;
  final String estado;
  final int cansancio;
  final double valor;
  final double valorAnterior;
  final String fotoJugador;
  final double puntosTotales;

  /// Total fantasy oficial si el backend lo envía aparte de [puntosTotales].
  final double? puntosFantasyTotales;

  /// Estado visible enmascarado (prioridad sobre [estado] en UI).
  final String? estadoVisible;

  final int idUsuarioDueno;
  final bool enPoolMercado;
  final bool esMercado;
  final bool enMercadoHoy;
  final bool tieneOfertaPendiente;
  final String nombreDuenoVisible;
  final String propietarioNick;
  final List<LeaguePlayerRoundStats> estadisticasJornadas;

  final int? probabilidadTitular;
  final String? motivoTitularidad;
  final int? idPartidoProbabilidad;
  final DateTime? calculadoEnProbabilidad;

  final bool jugadorProtegido;
  final bool proteccionHastaFinTemporada;
  final int? proteccionJornadaFin;

  final double? valorMercadoEfectivo;

  /// Valor de mercado a mostrar (con modificadores si el backend los envía).
  double get displayValor {
    final effective = valorMercadoEfectivo;
    if (effective != null && effective > 0) {
      return effective;
    }
    return valor;
  }

  /// Total a mostrar en cabecera: backend primero, sin sumar jornadas en cliente.
  double get displayFantasyTotalPoints {
    final fantasy = puntosFantasyTotales;
    if (fantasy != null) {
      return fantasy;
    }
    return puntosTotales;
  }

  factory LeaguePlayerDetail.fromJson(Map<String, dynamic> json) {
    final stats = <LeaguePlayerRoundStats>[];
    final rawList =
        json['estadisticasJornadas'] ??
        json['estadisticasPorJornada'] ??
        json['estadisticas_jornadas'] ??
        json['estadisticas_por_jornada'] ??
        json['historialJornadas'] ??
        json['historial_jornadas'] ??
        json['jornadas'];
    if (rawList is List) {
      for (final row in rawList) {
        if (row is! Map) {
          continue;
        }
        final map = row is Map<String, dynamic>
            ? row
            : Map<String, dynamic>.from(row);
        stats.add(LeaguePlayerRoundStats.fromJson(map));
      }
    }

    const ownerKeys = <String>[
      'idUsuarioDueno',
      'id_usuario_dueno',
      'idUsuarioDueño',
      'idDueno',
      'id_dueño',
      'id_dueno',
      'idOwner',
      'id_owner',
      'ownerId',
      'owner_id',
      'idUsuarioOwner',
      'id_usuario_owner',
      'idUsuarioPropietario',
      'id_usuario_propietario',
      'duenoId',
      'dueno_id',
      'propietarioId',
      'propietario_id',
      'idPropietario',
      'id_propietario',
    ];
    const poolKeys = <String>[
      'enPoolMercado',
      'en_pool_mercado',
      'enMercado',
      'en_mercado',
      'inMarket',
      'in_market',
      'mercadoLibre',
      'mercado_libre',
      'libreEnMercado',
      'poolMercado',
    ];
    const marketKeys = <String>[
      'esMercado',
      'es_mercado',
      'market',
      'isMarket',
      'is_market',
    ];
    const todayMarketKeys = <String>[
      'enMercadoHoy',
      'en_mercado_hoy',
    ];
    final parsedIdLigaJugador = readLeagueInt(json, const [
      'idLigaJugador',
      'id_liga_jugador',
    ]);
    final ownerParsed = readLeagueInt(json, ownerKeys);
    final esMercadoParsed = readLeagueBool(json, marketKeys);
    final enPoolMercadoParsed = readLeagueBool(json, poolKeys);
    final enMercadoHoyParsed = readLeagueBool(json, todayMarketKeys);
    if (kDebugMode) {
      String? firstPresent(List<String> keys) {
        for (final k in keys) {
          if (json.containsKey(k)) return k;
        }
        return null;
      }

      final ownerRawKey = firstPresent(ownerKeys);
      final esMercadoRawKey = firstPresent(marketKeys);
      final enPoolRawKey = firstPresent(poolKeys);
      final enMercadoHoyRawKey = firstPresent(todayMarketKeys);
      debugPrint(
        '[player-detail][detail-parse] idLigaJugador=$parsedIdLigaJugador ownerRaw=${ownerRawKey == null ? null : json[ownerRawKey]} ownerParsed=$ownerParsed esMercadoRaw=${esMercadoRawKey == null ? null : json[esMercadoRawKey]} esMercadoParsed=$esMercadoParsed enPoolMercadoRaw=${enPoolRawKey == null ? null : json[enPoolRawKey]} enPoolMercadoParsed=$enPoolMercadoParsed enMercadoHoyRaw=${enMercadoHoyRawKey == null ? null : json[enMercadoHoyRawKey]} enMercadoHoyParsed=$enMercadoHoyParsed',
      );
    }

    return LeaguePlayerDetail(
      idLigaJugador: parsedIdLigaJugador,
      idJugador: readLeagueInt(json, const ['idJugador', 'id_jugador']),
      nombre: readLeagueString(json, const ['nombre']),
      pila: readLeagueString(json, const ['pila']),
      posicion: readLeagueString(json, const ['posicion']),
      valoracion: readLeagueDouble(json, const [
        'valoracion',
        'valoracionActual',
        'valoracion_actual',
      ]),
      idEquipo: readLeagueInt(json, const ['idEquipo', 'id_equipo']),
      nombreEquipo: readLeagueString(json, const [
        'nombreEquipo',
        'nombre_equipo',
      ]),
      estado: readLeagueString(json, const ['estado']),
      cansancio: readLeagueInt(json, const ['cansancio']),
      valor: readLeagueDouble(json, const ['valor']),
      valorMercadoEfectivo: readLeagueOptionalDouble(json, const [
        'valorMercadoEfectivo',
        'valor_mercado_efectivo',
      ]),
      valorAnterior: readLeagueDouble(json, const [
        'valorAnterior',
        'valor_anterior',
      ]),
      fotoJugador: readLeagueString(json, const [
        'fotoJugador',
        'foto_jugador',
      ]),
      puntosTotales: readLeagueDouble(json, const [
        'puntosTotales',
        'puntos_totales',
        'puntos',
      ]),
      puntosFantasyTotales: _readOptionalDoubleField(json, const [
        'puntosFantasyTotales',
        'puntos_fantasy_totales',
      ]),
      estadoVisible: readLeagueOptionalNonEmptyString(json, const [
        'estadoVisible',
        'estado_visible',
      ]),
      idUsuarioDueno: ownerParsed,
      enPoolMercado: enPoolMercadoParsed,
      esMercado: esMercadoParsed,
      enMercadoHoy: enMercadoHoyParsed,
      tieneOfertaPendiente: readLeagueBool(json, const [
        'tieneOfertaPendiente',
        'tiene_oferta_pendiente',
      ]),
      nombreDuenoVisible: readLeagueString(json, const [
        'nombreDuenoVisible',
        'nombre_dueno_visible',
        'duenoVisible',
        'dueno_visible',
        'ownerVisibleName',
        'owner_visible_name',
        'ownerDisplayName',
      ]),
      propietarioNick: readLeagueString(json, const [
        'propietarioNickname',
        'propietario_nickname',
        'nicknameDueno',
        'nickname_dueno',
        'nickDueno',
        'nick_dueno',
        'ownerNick',
        'owner_nick',
        'nicknamePropietario',
        'duenoNickname',
        'ownerNickname',
        'nickPropietario',
      ]),
      estadisticasJornadas: stats,
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

  /// Convierte el detalle en [LeagueSquadPlayer], conservando datos del stub si faltan.
  LeagueSquadPlayer toSquadPlayer({LeagueSquadPlayer? fallback}) {
    String pickString(String primary, String fb) {
      final p = primary.trim();
      if (p.isNotEmpty) {
        return p;
      }
      return fb.trim();
    }

    return LeagueSquadPlayer(
      idLigaJugador: idLigaJugador,
      idJugador: idJugador,
      nombre: pickString(nombre, fallback?.nombre ?? ''),
      pila: pickString(pila, fallback?.pila ?? ''),
      posicion: pickString(posicion, fallback?.posicion ?? ''),
      valoracion: valoracion > 0 ? valoracion : (fallback?.valoracion ?? 0),
      idEquipo: idEquipo > 0 ? idEquipo : (fallback?.idEquipo ?? 0),
      nombreEquipo: pickString(nombreEquipo, fallback?.nombreEquipo ?? ''),
      estado: pickString(estado, fallback?.estado ?? ''),
      estadoVisible: estadoVisible ?? fallback?.estadoVisible,
      cansancio: cansancio,
      valor: valor > 0 ? valor : (fallback?.valor ?? 0),
      valorAnterior: valorAnterior > 0 ? valorAnterior : (fallback?.valorAnterior ?? 0),
      fotoJugador: pickString(fotoJugador, fallback?.fotoJugador ?? ''),
      enPoolMercado: enPoolMercado || (fallback?.enPoolMercado ?? false),
      propietarioNick: pickString(propietarioNick, fallback?.propietarioNick ?? ''),
      idUsuarioDueno: idUsuarioDueno > 0
          ? idUsuarioDueno
          : (fallback?.idUsuarioDueno ?? 0),
      fotoEquipo: fallback?.fotoEquipo ?? '',
      nombreDuenoVisible: pickString(
        nombreDuenoVisible,
        fallback?.nombreDuenoVisible ?? '',
      ),
      esMercado: esMercado || (fallback?.esMercado ?? false),
      tieneOfertaPendiente:
          tieneOfertaPendiente || (fallback?.tieneOfertaPendiente ?? false),
      probabilidadTitular: probabilidadTitular ?? fallback?.probabilidadTitular,
      motivoTitularidad: motivoTitularidad ?? fallback?.motivoTitularidad,
      idPartidoProbabilidad:
          idPartidoProbabilidad ?? fallback?.idPartidoProbabilidad,
      calculadoEnProbabilidad:
          calculadoEnProbabilidad ?? fallback?.calculadoEnProbabilidad,
      jugadorProtegido: jugadorProtegido || (fallback?.jugadorProtegido ?? false),
      proteccionHastaFinTemporada: proteccionHastaFinTemporada ||
          (fallback?.proteccionHastaFinTemporada ?? false),
      proteccionJornadaFin: proteccionJornadaFin ?? fallback?.proteccionJornadaFin,
    );
  }
}

double? _readOptionalDoubleField(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final v = json[key];
    if (v == null) {
      return null;
    }
    if (v is double) {
      return v;
    }
    if (v is int) {
      return v.toDouble();
    }
    if (v is String) {
      return double.tryParse(v.trim().replaceAll(',', '.'));
    }
  }
  return null;
}
