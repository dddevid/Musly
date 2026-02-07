import 'dart:convert';

class CastMediaVolume {
  ///optional Current stream volume level as
  /// a value between 0.0 and 1.0 where 1.0
  ///  is the maximum volume.
  num? level;

  ///optional Whether the Cast device is muted
  ///, independent of the volume level
  bool? muted;
  CastMediaVolume(this.level, this.muted)
      : assert(
          level == null || (level >= 0 && level <= 1),
          'level must be between 0 and 1',
        );

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'muted': muted,
    };
  }

  factory CastMediaVolume.fromMap(Map<String, dynamic> map) {
    return CastMediaVolume(
      map['level'],
      map['muted'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CastMediaVolume.fromJson(String source) =>
      CastMediaVolume.fromMap(json.decode(source));
}
