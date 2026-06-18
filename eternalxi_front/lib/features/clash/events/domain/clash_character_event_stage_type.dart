enum ClashCharacterEventStageType {
  story,
  match;

  static ClashCharacterEventStageType fromJson(Object? value) {
    final raw = value?.toString().trim();
    return switch (raw) {
      'match' => ClashCharacterEventStageType.match,
      _ => ClashCharacterEventStageType.story,
    };
  }

  String toJson() => switch (this) {
    ClashCharacterEventStageType.story => 'story',
    ClashCharacterEventStageType.match => 'match',
  };
}
