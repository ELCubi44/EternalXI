/// Estado efectivo para UI: prioriza [estadoVisible] del backend si viene.
String leaguePlayerEffectiveEstado({
  required String estado,
  String? estadoVisible,
}) {
  final visible = estadoVisible?.trim();
  if (visible != null && visible.isNotEmpty) {
    return visible;
  }
  return estado.trim();
}
