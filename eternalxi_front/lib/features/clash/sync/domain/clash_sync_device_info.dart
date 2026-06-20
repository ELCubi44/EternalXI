/// Metadatos opcionales del dispositivo emisor (Fase 65).
class ClashSyncDeviceInfo {
  const ClashSyncDeviceInfo({this.deviceId, this.platform});

  final String? deviceId;
  final String? platform;

  ClashSyncDeviceInfo copyWith({String? deviceId, String? platform}) {
    return ClashSyncDeviceInfo(
      deviceId: deviceId ?? this.deviceId,
      platform: platform ?? this.platform,
    );
  }

  Map<String, dynamic> toJson() => {
    if (deviceId != null) 'deviceId': deviceId,
    if (platform != null) 'platform': platform,
  };

  factory ClashSyncDeviceInfo.fromJson(Map<String, dynamic> json) {
    return ClashSyncDeviceInfo(
      deviceId: json['deviceId']?.toString(),
      platform: json['platform']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSyncDeviceInfo &&
        other.deviceId == deviceId &&
        other.platform == platform;
  }

  @override
  int get hashCode => Object.hash(deviceId, platform);
}
