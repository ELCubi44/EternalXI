/// Elección de acción en un duelo: normal o supertécnica concreta.
class ClashDuelActionChoice {
  const ClashDuelActionChoice.normal() : techniqueId = null;

  const ClashDuelActionChoice.technique(this.techniqueId);

  final String? techniqueId;

  bool get isNormal => techniqueId == null;

  bool get usesTechnique => techniqueId != null;
}
