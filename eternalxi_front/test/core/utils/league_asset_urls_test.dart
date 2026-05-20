import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedBase = ApiConstants.baseUrl;
  final origin = Uri.parse(ApiConstants.baseUrl).origin;

  group('isUnsafeFilesystemMediaPath', () {
    test('detecta /opt/eternalxi y rutas eternalxi', () {
      expect(
        LeagueAssetUrls.isUnsafeFilesystemMediaPath(
          '/opt/eternalxi/teams/42.png',
        ),
        isTrue,
      );
      expect(
        LeagueAssetUrls.isUnsafeFilesystemMediaPath(
          r'C:\opt\eternalxi\players\1.jpg',
        ),
        isTrue,
      );
      expect(
        LeagueAssetUrls.isUnsafeFilesystemMediaPath(
          'http://host/api/v1/opt/eternalxi/teams/1.png',
        ),
        isTrue,
      );
    });

    test('permite rutas API y assets', () {
      expect(
        LeagueAssetUrls.isUnsafeFilesystemMediaPath('/api/v1/assets/teams/1'),
        isFalse,
      );
      expect(
        LeagueAssetUrls.isUnsafeFilesystemMediaPath('/assets/players/5'),
        isFalse,
      );
    });
  });

  group('buildBackendImageUrl', () {
    test('1. /assets/teams/15 => baseUrl + /assets/teams/15', () {
      expect(
        LeagueAssetUrls.buildBackendImageUrl('/assets/teams/15'),
        '$expectedBase/assets/teams/15',
      );
    });

    test('2. /api/v1/assets/teams/15 => baseUrl + /assets/teams/15 (sin duplicar api/v1)', () {
      expect(
        LeagueAssetUrls.buildBackendImageUrl('/api/v1/assets/teams/15'),
        '$expectedBase/assets/teams/15',
      );
    });

    test('3. http(s) absoluta se deja igual', () {
      const absolute = 'https://cdn.example.com/img/team.png';
      expect(
        LeagueAssetUrls.buildBackendImageUrl(absolute),
        absolute,
      );
      expect(
        LeagueAssetUrls.buildBackendImageUrl(
          'http://217.154.184.202:8080/api/v1/assets/teams/15',
        ),
        'http://217.154.184.202:8080/api/v1/assets/teams/15',
      );
    });

    test('api/v1/assets sin barra inicial no duplica /api/v1', () {
      expect(
        LeagueAssetUrls.buildBackendImageUrl('api/v1/assets/teams/15'),
        '$expectedBase/assets/teams/15',
      );
    });

    test('assets/players sin barra inicial', () {
      expect(
        LeagueAssetUrls.buildBackendImageUrl('assets/players/7'),
        '$expectedBase/assets/players/7',
      );
    });

    test('no concatena baseUrl con /opt/...', () {
      expect(
        LeagueAssetUrls.buildBackendImageUrl('/opt/eternalxi/teams/7.png'),
        isNull,
      );
    });

    test('rechaza rutas absolutas arbitrarias', () {
      expect(
        LeagueAssetUrls.buildBackendImageUrl('/teams/foo.png'),
        isNull,
      );
    });

    test('otros endpoints /api/v1 usan origin + path completo', () {
      expect(
        LeagueAssetUrls.buildBackendImageUrl('/api/v1/users/2/photo'),
        '$origin/api/v1/users/2/photo',
      );
    });

    test('managers y loan-players bajo /api/v1', () {
      expect(
        LeagueAssetUrls.buildBackendImageUrl('/api/v1/assets/managers/3'),
        '$expectedBase/assets/managers/3',
      );
      expect(
        LeagueAssetUrls.buildBackendImageUrl('/api/v1/assets/loan-players/9'),
        '$expectedBase/assets/loan-players/9',
      );
    });
  });

  group('resolveTeamBadgeUrl', () {
    test('4. /opt/eternalxi/teams/x.png + idEquipo => assets/teams/{idEquipo}', () {
      expect(
        LeagueAssetUrls.resolveTeamBadgeUrl(
          idEquipo: 15,
          rawFoto: '/opt/eternalxi/teams/x.png',
        ),
        '$expectedBase/assets/teams/15',
      );
    });

    test('usa idEquipo cuando foto es filesystem', () {
      expect(
        LeagueAssetUrls.resolveTeamBadgeUrl(
          idEquipo: 99,
          rawFoto: '/opt/eternalxi/teams/99.png',
        ),
        '$expectedBase/assets/teams/99',
      );
    });
  });

  group('resolvePlayerPhotoUrl', () {
    test('usa idJugador cuando foto es filesystem', () {
      expect(
        LeagueAssetUrls.resolvePlayerPhotoUrl(
          idJugador: 12,
          rawFoto: '/opt/eternalxi/players/12.png',
        ),
        '$expectedBase/assets/players/12',
      );
    });
  });

  group('resolveManagerPhotoUrl', () {
    test('prefiere idEntrenador sobre raw', () {
      expect(
        LeagueAssetUrls.resolveManagerPhotoUrl(
          idEntrenador: 5,
          rawFoto: '/api/v1/assets/managers/99',
        ),
        '$expectedBase/assets/managers/5',
      );
    });
  });

  group('resolveLoanPlayerPhotoUrl', () {
    test('usa id cuando foto es filesystem', () {
      expect(
        LeagueAssetUrls.resolveLoanPlayerPhotoUrl(
          idJugadorCedidoTemporada: 22,
          rawFoto: '/opt/eternalxi/loan-players/22.png',
        ),
        '$expectedBase/assets/loan-players/22',
      );
    });
  });

  group('canonical asset URIs', () {
    test('teamBadge, playerPhoto, managerPhoto, loanPlayerPhoto', () {
      expect(
        LeagueAssetUrls.teamBadge(15).toString(),
        '$expectedBase/assets/teams/15',
      );
      expect(
        LeagueAssetUrls.playerPhoto(8).toString(),
        '$expectedBase/assets/players/8',
      );
      expect(
        LeagueAssetUrls.managerPhoto(3).toString(),
        '$expectedBase/assets/managers/3',
      );
      expect(
        LeagueAssetUrls.loanPlayerPhoto(11).toString(),
        '$expectedBase/assets/loan-players/11',
      );
    });
  });
}
