import 'clash_card.dart';

/// Suma la potencia de un conjunto de cartas (sin bonus de alineación ni estilos).
int calculateClashTeamPower(Iterable<ClashCard> cards) {
  var total = 0;
  for (final card in cards) {
    total += card.power;
  }
  return total;
}
