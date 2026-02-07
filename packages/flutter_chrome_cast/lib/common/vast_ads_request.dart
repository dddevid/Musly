import 'dart:convert';

///VAST ad request configuration.
class VastAdsRequest {
  /// Specifies a VAST document to be used as
  /// the ads response instead of making a request
  /// via an ad tag URL. This can be useful for debugging
  /// and other situations where a VAST
  ///  response is already available.

  final String? adsResponse;

  /// URL for VAST file.

  final String? adTagUrl;
  VastAdsRequest({
    this.adsResponse,
    this.adTagUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'adsResponse': adsResponse,
      'adTagUrl': adTagUrl,
    };
  }

  factory VastAdsRequest.fromMap(Map<String, dynamic> map) {
    return VastAdsRequest(
      adsResponse: map['adsResponse'],
      adTagUrl: map['adTagUrl'],
    );
  }

  String toJson() => json.encode(toMap());

  factory VastAdsRequest.fromJson(String source) =>
      VastAdsRequest.fromMap(json.decode(source));
}
