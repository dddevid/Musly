import 'dart:convert';

class GoogleCastImage {
  ///url 	URI 	URI for the image
  final Uri url;

  ///height 	integer 	optional Height of the image
  final int? height;

  ///width 	integer 	optional Width of the image
  final int? width;
  GoogleCastImage({
    required this.url,
    this.height,
    this.width,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url.toString(),
      'height': height,
      'width': width,
    };
  }

  factory GoogleCastImage.fromMap(Map<String, dynamic> map) {
    return GoogleCastImage(
      url: Uri.parse(map['url']),
      height: map['height']?.toInt(),
      width: map['width']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory GoogleCastImage.fromJson(String source) =>
      GoogleCastImage.fromMap(json.decode(source));
}
