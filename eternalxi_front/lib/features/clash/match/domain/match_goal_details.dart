import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Metadatos de un gol para objetivos y historial (Fase 16).
class MatchGoalDetails {
  const MatchGoalDetails({
    required this.scorer,
    this.usedTechnique = false,
    this.techniqueType,
    this.techniqueId,
    this.techniqueName,
    this.styleAdvantage = false,
    this.sameStyleTechnique = false,
  });

  final MatchTeamSide scorer;
  final bool usedTechnique;
  final ClashTechniqueType? techniqueType;
  final String? techniqueId;
  final String? techniqueName;
  final bool styleAdvantage;
  final bool sameStyleTechnique;
}
