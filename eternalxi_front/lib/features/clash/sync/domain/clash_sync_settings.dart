/// Ajustes locales de sync Clash (Fase 79–83).
class ClashSyncSettings {
  const ClashSyncSettings({
    this.autoCheckEnabledOnClashOpen = false,
    this.onlineClaimsEnabled = false,
  });

  final bool autoCheckEnabledOnClashOpen;
  final bool onlineClaimsEnabled;

  ClashSyncSettings copyWith({
    bool? autoCheckEnabledOnClashOpen,
    bool? onlineClaimsEnabled,
  }) {
    return ClashSyncSettings(
      autoCheckEnabledOnClashOpen:
          autoCheckEnabledOnClashOpen ?? this.autoCheckEnabledOnClashOpen,
      onlineClaimsEnabled: onlineClaimsEnabled ?? this.onlineClaimsEnabled,
    );
  }
}
