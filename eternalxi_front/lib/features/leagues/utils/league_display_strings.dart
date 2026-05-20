/// Textos legibles para la feature de ligas (sin IDs visibles).
abstract final class LeagueDisplayStrings {
  LeagueDisplayStrings._();

  static String shortNickname(String raw, {int maxLen = 14}) {
    final t = raw.trim();
    if (t.isEmpty) {
      return '';
    }
    if (t.length <= maxLen) {
      return t;
    }
    return '${t.substring(0, maxLen - 1)}…';
  }

  static String playerShortName({
    required String pila,
    required String nombre,
  }) {
    final nick = pila.trim();
    if (nick.isNotEmpty) {
      return nick;
    }
    final n = nombre.trim();
    if (n.isEmpty) {
      return 'Jugador';
    }
    final parts = n.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : n;
  }
}
