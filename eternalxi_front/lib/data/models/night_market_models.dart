import 'package:eternal_xi/data/models/league_json_read.dart';

/// Respuesta de `GET /leagues/{idLiga}/night-market`.
class NightMarketResponse {
  const NightMarketResponse({
    required this.idLiga,
    required this.idUsuario,
    required this.fechaMercado,
    required this.saldoDisponible,
    required this.saldoRetenido,
    required this.totalItems,
    required this.items,
  });

  final int idLiga;
  final int idUsuario;
  final String fechaMercado;
  final int saldoDisponible;
  final int saldoRetenido;
  final int totalItems;
  final List<NightMarketItem> items;

  factory NightMarketResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <NightMarketItem>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) {
          items.add(NightMarketItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return NightMarketResponse(
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idUsuario: readLeagueInt(json, const ['idUsuario', 'id_usuario']),
      fechaMercado: readLeagueString(json, const [
        'fechaMercado',
        'fecha_mercado',
      ]),
      saldoDisponible: readLeagueInt(json, const [
        'saldoDisponible',
        'saldo_disponible',
      ]),
      saldoRetenido: readLeagueInt(json, const [
        'saldoRetenido',
        'saldo_retenido',
      ]),
      totalItems: readLeagueInt(json, const ['totalItems', 'total_items']),
      items: items,
    );
  }
}

/// Un ítem del mercado nocturno diario.
class NightMarketItem {
  const NightMarketItem({
    required this.idMercadoDiario,
    required this.idLiga,
    required this.fecha,
    required this.resuelto,
    required this.resueltoEn,
    required this.idUsuarioGanador,
    required this.pujaGanadora,
    required this.idLigaJugador,
    required this.idJugador,
    required this.nombre,
    required this.pila,
    required this.nombreVisible,
    required this.posicion,
    required this.fotoJugador,
    required this.idEquipo,
    required this.nombreEquipo,
    required this.fotoEquipo,
    required this.estado,
    required this.cansancio,
    required this.valorActual,
    required this.valoracion,
    required this.precioSalida,
    required this.miPuja,
    required this.pujaMasAlta,
    required this.totalPujas,
  });

  final int idMercadoDiario;
  final int idLiga;
  final String fecha;
  final bool resuelto;
  final String? resueltoEn;
  final int? idUsuarioGanador;
  final int? pujaGanadora;
  final int idLigaJugador;
  final int idJugador;
  final String nombre;
  final String pila;
  final String nombreVisible;
  final String posicion;
  final String fotoJugador;
  final int idEquipo;
  final String nombreEquipo;
  final String fotoEquipo;
  final String estado;
  final int cansancio;
  final int valorActual;
  final int valoracion;
  final int precioSalida;
  final int? miPuja;
  final int? pujaMasAlta;
  final int totalPujas;

  factory NightMarketItem.fromJson(Map<String, dynamic> json) {
    final resueltoEnRaw = json['resueltoEn'] ?? json['resuelto_en'];
    return NightMarketItem(
      idMercadoDiario: readLeagueInt(json, const [
        'idMercadoDiario',
        'id_mercado_diario',
      ]),
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      fecha: readLeagueString(json, const ['fecha']),
      resuelto: readLeagueBool(json, const ['resuelto']),
      resueltoEn: resueltoEnRaw == null
          ? null
          : resueltoEnRaw.toString().trim().isEmpty
          ? null
          : resueltoEnRaw.toString(),
      idUsuarioGanador: _readNullableInt(json, const [
        'idUsuarioGanador',
        'id_usuario_ganador',
      ]),
      pujaGanadora: _readNullableInt(json, const [
        'pujaGanadora',
        'puja_ganadora',
      ]),
      idLigaJugador: readLeagueInt(json, const [
        'idLigaJugador',
        'id_liga_jugador',
      ]),
      idJugador: readLeagueInt(json, const ['idJugador', 'id_jugador']),
      nombre: readLeagueString(json, const ['nombre']),
      pila: readLeagueString(json, const ['pila']),
      nombreVisible: readLeagueString(json, const [
        'nombreVisible',
        'nombre_visible',
      ]),
      posicion: readLeagueString(json, const ['posicion', 'posición']),
      fotoJugador: readLeagueString(json, const [
        'fotoJugador',
        'foto_jugador',
      ]),
      idEquipo: readLeagueInt(json, const ['idEquipo', 'id_equipo']),
      nombreEquipo: readLeagueString(json, const [
        'nombreEquipo',
        'nombre_equipo',
      ]),
      fotoEquipo: readLeagueString(json, const ['fotoEquipo', 'foto_equipo']),
      estado: readLeagueString(json, const ['estado']),
      cansancio: readLeagueInt(json, const ['cansancio']),
      valorActual: readLeagueInt(json, const ['valorActual', 'valor_actual']),
      valoracion: readLeagueInt(json, const ['valoracion', 'valoración']),
      precioSalida: readLeagueInt(json, const [
        'precioSalida',
        'precio_salida',
      ]),
      miPuja: _readNullableInt(json, const ['miPuja', 'mi_puja']),
      pujaMasAlta: _readNullableInt(json, const [
        'pujaMasAlta',
        'puja_mas_alta',
      ]),
      totalPujas: readLeagueInt(json, const ['totalPujas', 'total_pujas']),
    );
  }

  static int? _readNullableInt(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (!json.containsKey(k)) {
        continue;
      }
      final v = json[k];
      if (v == null) {
        return null;
      }
      if (v is int) {
        return v;
      }
      if (v is double) {
        return v.round();
      }
      return int.tryParse(v.toString().trim());
    }
    return null;
  }
}
