import 'package:eternal_xi/data/models/league_json_read.dart';

/// Respuesta de `POST .../players/{idLigaJugador}/buy-now`.
class LeagueBuyNowResult {
  const LeagueBuyNowResult({
    required this.idLiga,
    required this.idLigaJugador,
    required this.idUsuario,
    required this.valorActual,
    required this.cantidadCompra,
    required this.nuevoSaldo,
  });

  final int idLiga;
  final int idLigaJugador;
  final int idUsuario;
  final int valorActual;
  final int cantidadCompra;
  final int nuevoSaldo;

  factory LeagueBuyNowResult.fromJson(Map<String, dynamic> json) {
    return LeagueBuyNowResult(
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idLigaJugador: readLeagueInt(json, const [
        'idLigaJugador',
        'id_liga_jugador',
      ]),
      idUsuario: readLeagueInt(json, const ['idUsuario', 'id_usuario']),
      valorActual: readLeagueInt(json, const ['valorActual', 'valor_actual']),
      cantidadCompra: readLeagueInt(json, const [
        'cantidadCompra',
        'cantidad_compra',
      ]),
      nuevoSaldo: readLeagueInt(json, const ['nuevoSaldo', 'nuevo_saldo']),
    );
  }
}
