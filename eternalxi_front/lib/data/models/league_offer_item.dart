import 'package:eternal_xi/data/models/league_json_read.dart';

class LeagueOfferItem {
  const LeagueOfferItem({
    required this.idOferta,
    required this.idLiga,
    required this.idLigaJugador,
    required this.idUsuarioComprador,
    required this.cantidad,
    required this.estado,
    required this.creadaEn,
    required this.actualizadaEn,
    required this.respondidaEn,
    required this.idJugador,
    required this.nombre,
    required this.pila,
    required this.nombreVisible,
    required this.posicion,
    required this.fotoJugador,
    required this.idEquipo,
    required this.nombreEquipo,
    required this.fotoEquipo,
    required this.estadoJugador,
    required this.cansancio,
    required this.valorActual,
    required this.idUsuarioDuenoActual,
    required this.nicknameDuenoActual,
    required this.nicknameComprador,
    required this.fotoUsuarioComprador,
    this.probabilidadTitular,
    this.motivoTitularidad,
    this.idPartidoProbabilidad,
    this.calculadoEnProbabilidad,
  });

  final int idOferta;
  final int idLiga;
  final int idLigaJugador;
  final int idUsuarioComprador;
  final int cantidad;
  final String estado;
  final String creadaEn;
  final String actualizadaEn;
  final String respondidaEn;
  final int idJugador;
  final String nombre;
  final String pila;
  final String nombreVisible;
  final String posicion;
  final String fotoJugador;
  final int idEquipo;
  final String nombreEquipo;
  final String fotoEquipo;
  final String estadoJugador;
  final int cansancio;
  final int valorActual;
  final int idUsuarioDuenoActual;
  final String nicknameDuenoActual;
  final String nicknameComprador;
  final String fotoUsuarioComprador;

  final int? probabilidadTitular;
  final String? motivoTitularidad;
  final int? idPartidoProbabilidad;
  final DateTime? calculadoEnProbabilidad;

  factory LeagueOfferItem.fromJson(Map<String, dynamic> json) {
    return LeagueOfferItem(
      idOferta: readLeagueInt(json, const ['idOferta', 'id_oferta']),
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idLigaJugador: readLeagueInt(json, const [
        'idLigaJugador',
        'id_liga_jugador',
      ]),
      idUsuarioComprador: readLeagueInt(json, const [
        'idUsuarioComprador',
        'id_usuario_comprador',
      ]),
      cantidad: readLeagueInt(json, const ['cantidad']),
      estado: readLeagueString(json, const ['estado']),
      creadaEn: readLeagueString(json, const ['creadaEn', 'creada_en']),
      actualizadaEn: readLeagueString(json, const [
        'actualizadaEn',
        'actualizada_en',
      ]),
      respondidaEn: readLeagueString(json, const [
        'respondidaEn',
        'respondida_en',
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
      estadoJugador: readLeagueString(json, const [
        'estadoJugador',
        'estado_jugador',
      ]),
      cansancio: readLeagueInt(json, const ['cansancio']),
      valorActual: readLeagueInt(json, const ['valorActual', 'valor_actual']),
      idUsuarioDuenoActual: readLeagueInt(json, const [
        'idUsuarioDuenoActual',
        'id_usuario_dueno_actual',
      ]),
      nicknameDuenoActual: readLeagueString(json, const [
        'nicknameDuenoActual',
        'nickname_dueno_actual',
      ]),
      nicknameComprador: readLeagueString(json, const [
        'nicknameComprador',
        'nickname_comprador',
        'nicknameUsuarioComprador',
        'nickname_usuario_comprador',
        'nickComprador',
        'nick_comprador',
      ]),
      fotoUsuarioComprador: readLeagueString(json, const [
        'fotoUsuarioComprador',
        'foto_usuario_comprador',
        'avatarComprador',
        'avatar_comprador',
        'imagenComprador',
        'imagen_comprador',
      ]),
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
    );
  }

  bool get pendiente => estado.trim().toUpperCase() == 'PENDIENTE';
}
