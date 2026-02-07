enum CastStatusType {
  mediaStatus('MEDIA_STATUS'),
  receiverStatus('RECEIVER_STATUS'),
  unknow('UNKNOW');

  final String rawValue;
  const CastStatusType(this.rawValue);

  factory CastStatusType.fromString(String name) {
    return CastStatusType.values.firstWhere(
        (element) => element.rawValue == name,
        orElse: () => CastStatusType.unknow);
  }
}

class CastMessageEvent {
  final CastStatusType type;
  CastMessageEvent({
    required this.type,
  });
}
