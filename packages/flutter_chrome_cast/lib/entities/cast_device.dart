class GoogleCastDevice {
  final String deviceID;
  final String friendlyName;
  final String? modelName;
  final String? statusText;
  final String deviceVersion;
  final bool isOnLocalNetwork;
  final String category;
  final String uniqueID;

  GoogleCastDevice({
    required this.deviceID,
    required this.friendlyName,
    required this.modelName,
    required this.statusText,
    required this.deviceVersion,
    required this.isOnLocalNetwork,
    required this.category,
    required this.uniqueID,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GoogleCastDevice && other.deviceID == deviceID;
  }

  @override
  int get hashCode {
    return deviceID.hashCode ^
        friendlyName.hashCode ^
        modelName.hashCode ^
        statusText.hashCode ^
        deviceVersion.hashCode ^
        isOnLocalNetwork.hashCode ^
        category.hashCode ^
        uniqueID.hashCode;
  }
}
