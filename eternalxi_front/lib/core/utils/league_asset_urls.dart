import 'package:eternal_xi/core/constants/api_constants.dart';

/// URLs centralizadas de assets de liga (jugadores, equipos, temporadas).
abstract final class LeagueAssetUrls {
  LeagueAssetUrls._();

  static const String _apiV1Prefix = '/api/v1';

  static String get _normalizedBase {
    final base = ApiConstants.baseUrl;
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  static String get _origin => Uri.parse(ApiConstants.baseUrl).origin;

  /// Ruta de filesystem del servidor (`/opt/eternalxi/...`) — nunca debe convertirse en HTTP.
  static bool isUnsafeFilesystemMediaPath(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) {
      return false;
    }
    final n = t.replaceAll(r'\', '/').toLowerCase();
    if (n.contains('/opt/') || n.contains('/eternalxi/')) {
      return true;
    }
    if (RegExp(r'^[a-z]:/', caseSensitive: false).hasMatch(n) &&
        n.contains('eternalxi')) {
      return true;
    }
    return false;
  }

  /// Resuelve una ruta/URL de imagen del backend a URL absoluta segura para [Image.network].
  ///
  /// Reglas:
  /// - `http(s)://...` → sin cambios
  /// - `/assets/...` o `assets/...` → [ApiConstants.baseUrl] + ruta bajo `/assets`
  /// - `/api/v1/assets/...` o `api/v1/assets/...` → quita `/api/v1` y usa [ApiConstants.baseUrl] + `/assets/...`
  /// - Otros `/api/v1/...` (p. ej. foto de usuario) → origin + ruta completa
  ///
  /// Nunca concatena [ApiConstants.baseUrl] con un path que ya incluye `/api/v1`.
  static String? buildBackendImageUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final value = raw.trim();
    if (isUnsafeFilesystemMediaPath(value)) {
      return null;
    }

    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/opt/')) {
      return null;
    }

    final assetPath = _extractAssetsPath(value);
    if (assetPath != null) {
      return '$_normalizedBase$assetPath';
    }

    final apiPath = _extractApiV1Path(value);
    if (apiPath != null) {
      return '$_origin$apiPath';
    }

    return null;
  }

  /// Devuelve `/assets/...` si [value] describe un asset de liga, o null.
  static String? _extractAssetsPath(String value) {
    final path = _stripApiV1Prefix(value);
    if (path == null) {
      return null;
    }
    if (path.startsWith('/assets/')) {
      return path;
    }
    if (path.startsWith('assets/')) {
      return '/$path';
    }
    return null;
  }

  /// Devuelve `/api/v1/...` para endpoints no-asset bajo la API, o null.
  static String? _extractApiV1Path(String value) {
    if (value.startsWith('$_apiV1Prefix/')) {
      return value;
    }
    if (value.startsWith('api/v1/')) {
      return '/$value';
    }
    return null;
  }

  /// Quita el prefijo `/api/v1` dejando el resto (p. ej. `/assets/teams/15`).
  static String? _stripApiV1Prefix(String value) {
    if (value.startsWith('$_apiV1Prefix/')) {
      return value.substring(_apiV1Prefix.length);
    }
    if (value.startsWith('api/v1/')) {
      return '/${value.substring('api/v1'.length)}';
    }
    if (value.startsWith('/assets/') || value.startsWith('assets/')) {
      return value.startsWith('/') ? value : '/$value';
    }
    return null;
  }

  /// Escudo de equipo: API path seguro o `GET /assets/teams/{idEquipo}`.
  static String? resolveTeamBadgeUrl({
    required int idEquipo,
    String? rawFoto,
  }) {
    final fromApi = buildBackendImageUrl(rawFoto);
    if (fromApi != null) {
      return fromApi;
    }
    if (idEquipo > 0) {
      return teamBadge(idEquipo).toString();
    }
    return null;
  }

  /// Foto de jugador: API path seguro o `GET /assets/players/{idJugador}`.
  static String? resolvePlayerPhotoUrl({
    required int idJugador,
    String? rawFoto,
  }) {
    final fromApi = buildBackendImageUrl(rawFoto);
    if (fromApi != null) {
      return fromApi;
    }
    if (idJugador > 0) {
      return playerPhoto(idJugador).toString();
    }
    return null;
  }

  /// Entrenador: siempre preferir id cuando existe.
  static String? resolveManagerPhotoUrl({
    required int? idEntrenador,
    String? rawFoto,
  }) {
    final id = idEntrenador;
    if (id != null && id > 0) {
      return managerPhoto(id).toString();
    }
    return buildBackendImageUrl(rawFoto);
  }

  /// Cedido en préstamo: API path seguro o `GET /assets/loan-players/{id}`.
  static String? resolveLoanPlayerPhotoUrl({
    required int idJugadorCedidoTemporada,
    String? rawFoto,
  }) {
    final fromApi = buildBackendImageUrl(rawFoto);
    if (fromApi != null) {
      return fromApi;
    }
    if (idJugadorCedidoTemporada > 0) {
      return loanPlayerPhoto(idJugadorCedidoTemporada).toString();
    }
    return null;
  }

  /// Valida URL candidata antes de [Image.network]; devuelve null si es insegura.
  static String? sanitizeNetworkImageUrl(String? candidate) {
    return buildBackendImageUrl(candidate);
  }

  static Uri playerPhoto(int idJugador) {
    return Uri.parse('$_normalizedBase/assets/players/$idJugador');
  }

  static Uri loanPlayerPhoto(int idJugadorCedidoTemporada) {
    return Uri.parse(
      '$_normalizedBase/assets/loan-players/$idJugadorCedidoTemporada',
    );
  }

  static Uri teamBadge(int idEquipo) {
    return Uri.parse('$_normalizedBase/assets/teams/$idEquipo');
  }

  static Uri seasonCover(int idTemporada) {
    return Uri.parse('$_normalizedBase/assets/seasons/$idTemporada');
  }

  static Uri managerPhoto(int idEntrenador) {
    return Uri.parse('$_normalizedBase/assets/managers/$idEntrenador');
  }
}
