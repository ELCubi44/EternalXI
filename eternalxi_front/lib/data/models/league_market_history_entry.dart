import 'package:eternal_xi/data/models/league_json_read.dart';

class LeagueMarketHistoryEntry {
  const LeagueMarketHistoryEntry({
    required this.id,
    required this.idLiga,
    required this.idLigaJugador,
    required this.idJugador,
    required this.idUsuarioComprador,
    required this.compradorNombre,
    required this.idUsuarioVendedor,
    required this.vendedorNombre,
    required this.tipo,
    required this.precio,
    required this.jugadorNombre,
    required this.descripcion,
    required this.creadoEn,
  });

  final int id;
  final int idLiga;
  final int idLigaJugador;
  final int? idJugador;
  final int idUsuarioComprador;
  final String compradorNombre;
  final int? idUsuarioVendedor;
  final String? vendedorNombre;
  final String tipo;
  final int precio;
  final String jugadorNombre;
  final String descripcion;
  final DateTime? creadoEn;

  factory LeagueMarketHistoryEntry.fromJson(Map<String, dynamic> json) {
    final parsedJugadorId = readLeagueInt(
      json,
      const ['idJugador', 'id_jugador'],
      fallback: -1,
    );
    final parsedVendedorId = readLeagueInt(
      json,
      const ['idUsuarioVendedor', 'id_usuario_vendedor'],
      fallback: -1,
    );
    return LeagueMarketHistoryEntry(
      id: readLeagueInt(json, const ['id']),
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idLigaJugador: readLeagueInt(
        json,
        const ['idLigaJugador', 'id_liga_jugador'],
      ),
      idJugador: parsedJugadorId > 0 ? parsedJugadorId : null,
      idUsuarioComprador: readLeagueInt(
        json,
        const ['idUsuarioComprador', 'id_usuario_comprador'],
      ),
      compradorNombre: readLeagueString(
        json,
        const ['compradorNombre', 'comprador_nombre'],
      ),
      idUsuarioVendedor: parsedVendedorId > 0 ? parsedVendedorId : null,
      vendedorNombre: () {
        final value = json['vendedorNombre'] ?? json['vendedor_nombre'];
        if (value == null) {
          return null;
        }
        final txt = value.toString().trim();
        return txt.isEmpty ? null : txt;
      }(),
      tipo: readLeagueString(json, const ['tipo']),
      precio: readLeagueInt(json, const ['precio']),
      jugadorNombre: readLeagueString(
        json,
        const ['jugadorNombre', 'jugador_nombre'],
      ),
      descripcion: readLeagueString(json, const ['descripcion']),
      creadoEn: DateTime.tryParse(
        readLeagueString(
          json,
          const ['creadoEn', 'creado_en'],
        ),
      ),
    );
  }
}
