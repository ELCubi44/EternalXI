/// Requisitos de acceso a un nivel de historia Clash.
class ClashStoryLevelRequirements {
  const ClashStoryLevelRequirements({
    this.clashTeamUnlocked = false,
    this.completeActiveLineup = false,
  });

  final bool clashTeamUnlocked;
  final bool completeActiveLineup;

  factory ClashStoryLevelRequirements.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ClashStoryLevelRequirements();
    }
    return ClashStoryLevelRequirements(
      clashTeamUnlocked: json['clashTeamUnlocked'] == true,
      completeActiveLineup: json['completeActiveLineup'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'clashTeamUnlocked': clashTeamUnlocked,
    'completeActiveLineup': completeActiveLineup,
  };
}
