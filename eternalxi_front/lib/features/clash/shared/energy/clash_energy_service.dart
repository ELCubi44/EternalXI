import 'package:shared_preferences/shared_preferences.dart';

/// Energía Clash con regeneración temporal (cabecera).
class ClashEnergyWallet {
  ClashEnergyWallet({
    required this.current,
    required this.max,
    required this.nextRegenAt,
  });

  final int current;
  final int max;
  final DateTime? nextRegenAt;

  static const maxEnergy = 100;
  static const regenInterval = Duration(minutes: 6);

  String get fractionLabel => '$current/$max';

  Duration? get timeUntilNext {
    final at = nextRegenAt;
    if (at == null || current >= max) return null;
    final left = at.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  String get countdownLabel {
    final left = timeUntilNext;
    if (left == null) return '';
    final m = left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class ClashEnergyService {
  ClashEnergyService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _keyCurrent = 'clash_energy_current_v1';
  static const _keyNextAt = 'clash_energy_next_at_ms_v1';

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<ClashEnergyWallet> load() async {
    final prefs = await _ensurePrefs();
    var current = prefs.getInt(_keyCurrent) ?? ClashEnergyWallet.maxEnergy;
    final nextMs = prefs.getInt(_keyNextAt);
    var nextAt = nextMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(nextMs);

    final now = DateTime.now();
    if (current < ClashEnergyWallet.maxEnergy && nextAt != null) {
      while (current < ClashEnergyWallet.maxEnergy &&
          !now.isBefore(nextAt!)) {
        current++;
        nextAt = nextAt.add(ClashEnergyWallet.regenInterval);
      }
      if (current >= ClashEnergyWallet.maxEnergy) {
        nextAt = null;
      }
      await prefs.setInt(_keyCurrent, current);
      if (nextAt == null) {
        await prefs.remove(_keyNextAt);
      } else {
        await prefs.setInt(_keyNextAt, nextAt.millisecondsSinceEpoch);
      }
    }

    return ClashEnergyWallet(
      current: current.clamp(0, ClashEnergyWallet.maxEnergy),
      max: ClashEnergyWallet.maxEnergy,
      nextRegenAt: nextAt,
    );
  }

  /// Intenta gastar [amount]. Devuelve la wallet resultante o `null` si no hay suficiente.
  Future<ClashEnergyWallet?> trySpend(int amount) async {
    if (amount <= 0) {
      return load();
    }
    final prefs = await _ensurePrefs();
    final wallet = await load();
    if (wallet.current < amount) {
      return null;
    }
    final nextCurrent = wallet.current - amount;
    var nextAt = wallet.nextRegenAt;
    if (nextCurrent < ClashEnergyWallet.maxEnergy && nextAt == null) {
      nextAt = DateTime.now().add(ClashEnergyWallet.regenInterval);
    }
    await prefs.setInt(_keyCurrent, nextCurrent);
    if (nextAt == null) {
      await prefs.remove(_keyNextAt);
    } else {
      await prefs.setInt(_keyNextAt, nextAt.millisecondsSinceEpoch);
    }
    return ClashEnergyWallet(
      current: nextCurrent,
      max: ClashEnergyWallet.maxEnergy,
      nextRegenAt: nextAt,
    );
  }
}

