import 'dart:io';

/// Fase 71: clientes HTTP en `sync/data/`; el resto del módulo sync sigue sin Dio.
const clashSyncHttpClientBasenames = {
  'clash_save_api_client.dart',
  'clash_claim_api_client.dart',
  'http_clash_sync_client.dart',
};

bool isClashSyncAllowedHttpFile(String path) {
  final segments = path.split(RegExp(r'[/\\]'));
  return segments.isNotEmpty &&
      clashSyncHttpClientBasenames.contains(segments.last);
}

List<String> findForbiddenHttpImportsInSyncLayer() {
  final syncDir = Directory('lib/features/clash/sync');
  final forbidden = <String>[];

  for (final entity in syncDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    if (isClashSyncAllowedHttpFile(entity.path)) {
      continue;
    }
    final content = entity.readAsStringSync();
    if (content.contains("import 'package:http/") ||
        content.contains('import "package:http/') ||
        content.contains('package:dio/') ||
        content.contains('ClashApiClient') ||
        content.contains('http.get(') ||
        content.contains('http.post(')) {
      forbidden.add(entity.path);
    }
  }

  return forbidden;
}
