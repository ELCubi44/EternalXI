/// Ajustes locales de sync Clash (Fase 79).
class ClashSyncSettings {
  const ClashSyncSettings({this.autoCheckEnabledOnClashOpen = false});

  final bool autoCheckEnabledOnClashOpen;

  ClashSyncSettings copyWith({bool? autoCheckEnabledOnClashOpen}) {
    return ClashSyncSettings(
      autoCheckEnabledOnClashOpen:
          autoCheckEnabledOnClashOpen ?? this.autoCheckEnabledOnClashOpen,
    );
  }
}
