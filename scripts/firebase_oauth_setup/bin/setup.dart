import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

const _projectId = 'myapplication-e71bb962';
const _projectNumber = '580436038307';
const _androidAppId = '1:580436038307:android:c8492d256ba5493656a516';
const _packageName = 'es.eternalxi.app';
const _releaseSha1 = 'E7:FB:77:46:5D:80:77:C7:65:C5:B5:A8:0E:C0:9B:41:FB:ED:0C:22';

Future<void> main(List<String> args) async {
  final repoRoot = _repoRoot();
  final saPath = args.isNotEmpty
      ? args[0]
      : '${repoRoot.path}/.local/firebase-service-account.json';
  final saFile = File(saPath);
  if (!saFile.existsSync()) {
    stderr.writeln('No existe service account: $saPath');
    exit(1);
  }

  final credentials = ServiceAccountCredentials.fromJson(
    jsonDecode(saFile.readAsStringSync()),
  );

  final client = await clientViaServiceAccount(credentials, [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/firebase',
    'https://www.googleapis.com/auth/identitytoolkit',
  ]);

  try {
    await _ensureSha1Registered(client);
    await _ensureGoogleSignInEnabled(client);
    await _waitForOAuthClients(client);

    final config = await _fetchAndroidConfig(client);
    final appClient = ((config['client'] as List?) ?? []).firstWhere(
      (c) => c is Map,
      orElse: () => null,
    ) as Map?;
    final oauthClients = (appClient?['oauth_client'] as List?) ?? [];
    stdout.writeln('OAuth clients en config: ${oauthClients.length}');

    String? webClientId;
    String? androidClientId;
    for (final c in oauthClients) {
      if (c is! Map) continue;
      final type = c['client_type']?.toString() ?? '';
      final id = c['client_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      if (type == '3') {
        webClientId = id;
        stdout.writeln('Web client: $id');
      } else if (type == '1') {
        androidClientId = id;
        stdout.writeln('Android client: $id');
      }
    }

    if (webClientId == null || webClientId.isEmpty) {
      stderr.writeln(
        'No hay Web Client ID. Habilita Google en Firebase Console '
        '(Authentication > Sign-in method > Google) y vuelve a ejecutar.',
      );
      exit(2);
    }

    await _writeAppConfig(repoRoot, webClientId, config);
    stdout.writeln(
      'Backend oauthGoogleClientIds: ${[
        webClientId,
        if (androidClientId != null && androidClientId.isNotEmpty) androidClientId,
      ].join(',')}',
    );
    stdout.writeln('OK');
  } finally {
    client.close();
  }
}

Directory _repoRoot() {
  final cwd = Directory.current;
  if (cwd.path.contains('firebase_oauth_setup')) {
    return Directory('${cwd.parent.parent.path}');
  }
  return cwd;
}

Future<void> _ensureSha1Registered(http.Client client) async {
  final listUrl =
      'https://firebase.googleapis.com/v1beta1/projects/$_projectId/androidApps/$_androidAppId/sha';
  final listRes = await client.get(Uri.parse(listUrl));
  if (listRes.statusCode == 200) {
    final json = jsonDecode(listRes.body) as Map<String, dynamic>;
    final hashes = (json['shaHashes'] as List?) ?? [];
    for (final h in hashes) {
      if (h is Map && h['shaHash']?.toString() == _releaseSha1) {
        stdout.writeln('SHA-1 release ya registrado');
        return;
      }
    }
  }

  final createUrl =
      'https://firebase.googleapis.com/v1beta1/projects/$_projectId/androidApps/$_androidAppId/sha';
  final createRes = await client.post(
    Uri.parse(createUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'shaHash': _releaseSha1,
      'certType': 'SHA_1',
    }),
  );
  if (createRes.statusCode >= 200 && createRes.statusCode < 300) {
    stdout.writeln('SHA-1 release registrado en Firebase');
    return;
  }
  stdout.writeln(
    'Aviso SHA-1 (${createRes.statusCode}): ${createRes.body}',
  );
}

Future<void> _ensureGoogleSignInEnabled(http.Client client) async {
  final getUrl =
      'https://identitytoolkit.googleapis.com/admin/v2/projects/$_projectId/defaultSupportedIdpConfigs/google.com';
  final getRes = await client.get(Uri.parse(getUrl));
  if (getRes.statusCode == 200) {
    final json = jsonDecode(getRes.body) as Map<String, dynamic>;
    if (json['enabled'] == true) {
      stdout.writeln('Google Sign-In ya habilitado');
      return;
    }
  }

  final postUrl =
      'https://identitytoolkit.googleapis.com/admin/v2/projects/$_projectId/defaultSupportedIdpConfigs?idpId=google.com';
  final postRes = await client.post(
    Uri.parse(postUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': 'projects/$_projectId/defaultSupportedIdpConfigs/google.com',
      'enabled': true,
    }),
  );
  if (postRes.statusCode >= 200 && postRes.statusCode < 300) {
    stdout.writeln('Google Sign-In habilitado');
    return;
  }

  stdout.writeln(
    'Aviso enable Google (${postRes.statusCode}): ${postRes.body}',
  );
}

Future<void> _waitForOAuthClients(http.Client client) async {
  for (var i = 0; i < 6; i++) {
    final config = await _fetchAndroidConfig(client);
    final clients = (config['client'] as List?) ?? [];
    if (clients.isNotEmpty) return;
    stdout.writeln('Esperando OAuth clients... (${i + 1}/6)');
    await Future<void>.delayed(const Duration(seconds: 5));
  }
}

Future<Map<String, dynamic>> _fetchAndroidConfig(http.Client client) async {
  final url =
      'https://firebase.googleapis.com/v1beta1/projects/$_projectId/androidApps/$_androidAppId/config';
  final res = await client.get(Uri.parse(url));
  if (res.statusCode != 200) {
    throw StateError(
      'No se pudo leer config Android (${res.statusCode}): ${res.body}',
    );
  }
  final payload = jsonDecode(res.body) as Map<String, dynamic>;
  final encoded = payload['configFileContents']?.toString();
  if (encoded != null && encoded.isNotEmpty) {
    final decoded = utf8.decode(base64Decode(encoded));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }
  return payload;
}

Future<void> _writeAppConfig(
  Directory repoRoot,
  String webClientId,
  Map<String, dynamic> config,
) async {
  final oauthJson =
      File('${repoRoot.path}/eternalxi_front/assets/app/oauth_config.json');
  oauthJson.parent.createSync(recursive: true);
  oauthJson.writeAsStringSync(
    '${JsonEncoder.withIndent('  ').convert({'googleWebClientId': webClientId})}\n',
  );
  stdout.writeln('Actualizado: ${oauthJson.path}');

  final gsPath =
      '${repoRoot.path}/eternalxi_front/android/app/google-services.json';
  File(gsPath).writeAsStringSync(
    '${JsonEncoder.withIndent('  ').convert(config)}\n',
  );
  stdout.writeln('Actualizado: $gsPath');
}
