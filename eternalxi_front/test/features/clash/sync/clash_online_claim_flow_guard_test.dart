import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Clash online claim flow guard Fase 83', () {
    const flowFiles = [
      'lib/features/clash/gifts/data/clash_gifts_repository.dart',
      'lib/features/clash/missions/data/clash_daily_missions_repository.dart',
      'lib/features/clash/missions/data/clash_weekly_missions_repository.dart',
      'lib/features/clash/achievements/data/clash_achievements_repository.dart',
      'lib/features/clash/shop/data/clash_shop_repository.dart',
      'lib/features/clash/events/data/clash_character_events_repository.dart',
      'lib/features/clash/story/data/repositories/clash_story_repository.dart',
    ];

    test('flujos reales no importan ClashOnlineClaimRegistrar', () {
      final forbidden = <String>[];

      for (final path in flowFiles) {
        final file = File(path);
        if (!file.existsSync()) {
          continue;
        }
        final content = file.readAsStringSync();
        if (content.contains('ClashOnlineClaimRegistrar') ||
            content.contains('clash_online_claim_registrar.dart')) {
          forbidden.add(path);
        }
      }

      expect(forbidden, isEmpty);
    });
  });
}
