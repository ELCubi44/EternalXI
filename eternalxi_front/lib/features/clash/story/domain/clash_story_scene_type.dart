/// Formato de una escena narrativa Clash.
enum ClashStorySceneType {
  dialogue,
  comic,
  fullScreenImage,
  narration;

  static ClashStorySceneType fromJson(String raw) {
    return switch (raw) {
      'dialogue' => ClashStorySceneType.dialogue,
      'comic' => ClashStorySceneType.comic,
      'fullScreenImage' => ClashStorySceneType.fullScreenImage,
      'narration' => ClashStorySceneType.narration,
      _ => throw FormatException('Tipo de escena desconocido: $raw'),
    };
  }

  String toJson() => name;
}
