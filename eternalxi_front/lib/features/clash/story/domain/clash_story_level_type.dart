/// Tipo de contenido jugable de un nivel de historia Clash.
enum ClashStoryLevelType {
  story,
  match,
  mixed;

  static ClashStoryLevelType fromJson(String raw) {
    return switch (raw) {
      'story' => ClashStoryLevelType.story,
      'match' => ClashStoryLevelType.match,
      'mixed' => ClashStoryLevelType.mixed,
      _ => throw FormatException('Tipo de nivel desconocido: $raw'),
    };
  }

  String toJson() => name;
}
