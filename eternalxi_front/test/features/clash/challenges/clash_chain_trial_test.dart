import 'package:eternal_xi/features/clash/challenges/data/clash_trials_local_datasource.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_chain_draw_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ClashChainDrawEngine default draw count', () {
    expect(ClashChainDrawEngine.defaultDrawCount, 3);
  });

  test('trials.json carga 4 torres con 5 pisos', () async {
    final raw = await rootBundle.loadString('assets/data/clash/trials.json');
    final trials = ClashTrialsLocalDataSource().parseTrialsJson(raw);
    expect(trials, hasLength(4));
    for (final trial in trials) {
      expect(trial.floors, hasLength(5));
      expect(trial.line.positions, isNotEmpty);
    }
  });
}
