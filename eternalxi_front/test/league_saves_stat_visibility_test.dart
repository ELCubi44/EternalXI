import 'package:eternal_xi/features/leagues/utils/league_saves_stat_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('leagueParadasStatDisplayValue', () {
    test('sin puntos oficiales solo muestra el dato bruto', () {
      expect(leagueParadasStatDisplayValue(6), '6');
      expect(
        leagueParadasStatDisplayValue(6, officialPoints: null),
        '6',
      );
    });

    test('con puntos oficiales del backend', () {
      expect(
        leagueParadasStatDisplayValue(8, officialPoints: 4),
        '8 · +4 pts',
      );
    });
  });
}
