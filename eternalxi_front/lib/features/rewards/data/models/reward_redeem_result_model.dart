import 'package:eternal_xi/data/models/league_json_read.dart';

class RewardRedeemResultModel {
  const RewardRedeemResultModel({
    required this.raw,
    required this.cartaUsada,
    required this.tipoEfecto,
  });

  final Map<String, dynamic> raw;
  final bool cartaUsada;
  final String tipoEfecto;

  factory RewardRedeemResultModel.fromJson(Map<String, dynamic> json) {
    return RewardRedeemResultModel(
      raw: Map<String, dynamic>.from(json),
      cartaUsada: readLeagueBool(json, const ['cartaUsada', 'carta_usada']),
      tipoEfecto: readLeagueString(json, const ['tipoEfecto', 'tipo_efecto']),
    );
  }

  int? _int(List<String> keys) => _readOptInt(raw, keys);

  String? _str(List<String> keys) {
    final s = readLeagueString(raw, keys);
    return s.trim().isEmpty ? null : s;
  }

  double? _dbl(List<String> keys) => _readOptDouble(raw, keys);

  String? get nombreJugador => _str(const ['nombreJugador', 'nombre_jugador']);

  int? get idLigaJugador =>
      _int(const ['idLigaJugador', 'id_liga_jugador']);

  int? get valorBase => _int(const ['valorBase', 'valor_base']);

  double? get multiplicadorVenta => _dbl(const [
        'multiplicadorVenta',
        'multiplicador_venta',
      ]);

  int? get cantidadRecibida =>
      _int(const ['cantidadRecibida', 'cantidad_recibida']);

  int? get nuevoDineroLiga =>
      _int(const ['nuevoDineroLiga', 'nuevo_dinero_liga']);

  int? get valorMercadoEfectivo =>
      _int(const ['valorMercadoEfectivo', 'valor_mercado_efectivo']);

  double? get porcentajeModificadorValorActivo => _dbl(const [
        'porcentajeModificadorValorActivo',
        'porcentaje_modificador_valor_activo',
      ]);

  int? get idUsuarioPropietarioAnterior => _int(const [
        'idUsuarioPropietarioAnterior',
        'id_usuario_propietario_anterior',
      ]);

  String? get nicknamePropietarioAnterior => _str(const [
        'nicknamePropietarioAnterior',
        'nickname_propietario_anterior',
      ]);

  int? get idUsuarioNuevoPropietario => _int(const [
        'idUsuarioNuevoPropietario',
        'id_usuario_nuevo_propietario',
      ]);

  String? get nicknameNuevoPropietario => _str(const [
        'nicknameNuevoPropietario',
        'nickname_nuevo_propietario',
      ]);

  int? get valorJugadorClausula =>
      _int(const ['valorJugadorClausula', 'valor_jugador_clausula']);

  int? get pagadoPorAtacante =>
      _int(const ['pagadoPorAtacante', 'pagado_por_atacante']);

  int? get recibidoPorPropietario =>
      _int(const ['recibidoPorPropietario', 'recibido_por_propietario']);

  int? get nuevoDineroAtacante =>
      _int(const ['nuevoDineroAtacante', 'nuevo_dinero_atacante']);

  int? get nuevoDineroPropietario =>
      _int(const ['nuevoDineroPropietario', 'nuevo_dinero_propietario']);

  int? get idJornadaInicioProteccion => _int(const [
        'idJornadaInicioProteccion',
        'id_jornada_inicio_proteccion',
      ]);

  int? get idJornadaFinProteccion => _int(const [
        'idJornadaFinProteccion',
        'id_jornada_fin_proteccion',
      ]);

  int? get numeroJornadaFinProteccion => _int(const [
        'numeroJornadaFinProteccion',
        'numero_jornada_fin_proteccion',
      ]);

  bool? get proteccionHastaFinTemporada {
    final v = raw['proteccionHastaFinTemporada'] ??
        raw['proteccion_hasta_fin_temporada'];
    if (v == null) return null;
    if (v is bool) return v;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true') return true;
      if (t == 'false') return false;
    }
    return null;
  }

  int? get puntosAnadidos =>
      _int(const ['puntosAnadidos', 'puntos_anadidos']);

  int? get totalBonusAcumulado =>
      _int(const ['totalBonusAcumulado', 'total_bonus_acumulado']);

  int? get puntosFantasyLiga =>
      _int(const ['puntosFantasyLiga', 'puntos_fantasy_liga']);

  int? get puntosTotalesEfectivos =>
      _int(const ['puntosTotalesEfectivos', 'puntos_totales_efectivos']);

  int? get valorAnterior =>
      _int(const ['valorAnterior', 'valor_anterior']);

  double? get porcentajeRecuperacion => _dbl(const [
        'porcentajeRecuperacion',
        'porcentaje_recuperacion',
      ]);

  int? get valorTemporal =>
      _int(const ['valorTemporal', 'valor_temporal']);

  int? get idJornadaExpiracion =>
      _int(const ['idJornadaExpiracion', 'id_jornada_expiracion']);

  int? get numeroJornadaExpiracion => _int(const [
        'numeroJornadaExpiracion',
        'numero_jornada_expiracion',
        'numeroJornadaExpiracionPreview',
        'numero_jornada_expiracion_preview',
      ]);
}

int? _readOptInt(Map<String, dynamic> json, List<String> keys) {
  if (!_hasKey(json, keys)) return null;
  return readLeagueInt(json, keys);
}

double? _readOptDouble(Map<String, dynamic> json, List<String> keys) {
  if (!_hasKey(json, keys)) return null;
  return readLeagueDouble(json, keys);
}

bool _hasKey(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) return true;
  }
  return false;
}
