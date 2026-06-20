/// Genera `claimId` estables para registro online idempotente (Fase 83).
///
/// Fechas de misiones diarias: componentes de calendario en UTC
/// (`year`, `month`, `day` del [DateTime] recibido, sin hora).
class ClashClaimIdBuilder {
  const ClashClaimIdBuilder._();

  static String gift(String giftId) =>
      'gift:${_requireNonEmpty(giftId, 'giftId')}';

  static String achievement(String achievementId) =>
      'achievement:${_requireNonEmpty(achievementId, 'achievementId')}';

  static String dailyMission(String missionId, DateTime date) =>
      'mission:daily:${_requireNonEmpty(missionId, 'missionId')}:${_formatUtcDate(date)}';

  static String weeklyMission(String missionId, String weekKey) =>
      'mission:weekly:${_requireNonEmpty(missionId, 'missionId')}:${_requireNonEmpty(weekKey, 'weekKey')}';

  static String eventFirstClear(String eventId, String stageId) =>
      'event:${_requireNonEmpty(eventId, 'eventId')}:${_requireNonEmpty(stageId, 'stageId')}:firstClear';

  static String eventRepeat(String eventId, String stageId, String attemptId) =>
      'event:${_requireNonEmpty(eventId, 'eventId')}:${_requireNonEmpty(stageId, 'stageId')}:repeat:${_requireNonEmpty(attemptId, 'attemptId')}';

  static String shop(String productId, String attemptId) =>
      'shop:${_requireNonEmpty(productId, 'productId')}:${_requireNonEmpty(attemptId, 'attemptId')}';

  static String storyFirstClear(String chapterId, String stageId) =>
      'story:${_requireNonEmpty(chapterId, 'chapterId')}:${_requireNonEmpty(stageId, 'stageId')}:firstClear';

  static String storyObjective(
    String chapterId,
    String stageId,
    String objectiveId,
  ) =>
      'story:${_requireNonEmpty(chapterId, 'chapterId')}:${_requireNonEmpty(stageId, 'stageId')}:objective:${_requireNonEmpty(objectiveId, 'objectiveId')}';

  static String _formatUtcDate(DateTime date) {
    final utc = DateTime.utc(date.year, date.month, date.day);
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}-$month-$day';
  }

  static String _requireNonEmpty(String value, String fieldName) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be empty');
    }
    return trimmed;
  }
}
