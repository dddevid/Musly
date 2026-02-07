import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_chrome_cast/common/text_track_font_style.dart';
import 'package:flutter_chrome_cast/common/text_track_window_type.dart';

import 'font_generic_family.dart';

///Describes style information for a text track. Colors
///are represented as strings “#RRGGBBAA” where XX are
///the two hexadecimal symbols that represent the
/// 0-255 value for the specific channel/color.
///  It follows CSS 8-digit hex color notation.
///  (See http://dev.w3.org/csswg/css-color/#hex-notation).
class TextTrackStyle {
  ///Background RGBA color, represented as "#RRGGBBAA".
  /// The alpha channel should be used for
  /// transparent backgrounds.

  final Color? backgroundColor;

  ///Custom application data.
  final Map<String, dynamic>? customData;

  ///RGBA color for the edge, represented as
  /// "#RRGGBBAA". This value will be
  ///  ignored if edgeType is NONE.

  final Color? edgeColor;

  final TextTrackStyle? edgeType;

  /// If the font is not available in the receiver the fontGenericFamily will be used.

  final String? fontFamily;

  final TextTrackFontGenericFamily? fontGenericFamily;

  ///The font scaling factor for the text track (the default is 1.0).
  final int? fontScale;

  final TextTrackFontStyle? fontStyle;

  ///Foreground RGBA color, represented as "#RRGGBBAA".
  final Color? foregroundColor;

  ///RGBA color for the window, represented as
  ///"#RRGGBBAA". This value will be
  ///ignored if windowType is NONE.
  final Color? windowColor;

  ///Rounded corner radius absolute value in pixels (px).
  /// This value will be ignored if windowType
  /// is not ROUNDED_CORNERS.
  final double? windowRoundedCornerRadius;

  ///The window concept is defined in CEA-608 and CEA-708,
  /// See http://goo.gl/M3ea0X. In WebVTT is called a region.

  final TextTrackWindowType? windowType;
  TextTrackStyle({
    this.backgroundColor,
    this.customData,
    this.edgeColor,
    this.edgeType,
    this.fontFamily,
    this.fontGenericFamily,
    this.fontScale,
    this.fontStyle,
    this.foregroundColor,
    this.windowColor,
    this.windowRoundedCornerRadius,
    this.windowType,
  });

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor?.hexColor,
      'customData': customData,
      'edgeColor': edgeColor?.hexColor,
      'edgeType': edgeType?.toMap(),
      'fontFamily': fontFamily,
      'fontGenericFamily': fontGenericFamily?.name,
      'fontScale': fontScale,
      'fontStyle': fontStyle?.name,
      'foregroundColor': foregroundColor?.hexColor,
      'windowColor': windowColor?.hexColor,
      'windowRoundedCornerRadius': windowRoundedCornerRadius,
      'windowType': windowType?.name,
    };
  }

  factory TextTrackStyle.fromMap(Map<String, dynamic> map) {
    return TextTrackStyle(
      backgroundColor: map['backgroundColor'] != null
          ? HColor.fromHex(map['backgroundColor'])
          : null,
      customData: Map<String, dynamic>.from(map['customData']),
      edgeColor:
          map['edgeColor'] != null ? HColor.fromHex(map['edgeColor']) : null,
      edgeType: map['edgeType'] != null
          ? TextTrackStyle.fromMap(map['edgeType'])
          : null,
      fontFamily: map['fontFamily'],
      fontGenericFamily: map['fontGenericFamily'] != null
          ? TextTrackFontGenericFamily.fromMap(map['fontGenericFamily'])
          : null,
      fontScale: map['fontScale']?.toInt(),
      fontStyle: map['fontStyle'] != null
          ? TextTrackFontStyle.fromMap(map['fontStyle'])
          : null,
      foregroundColor: map['foregroundColor'] != null
          ? HColor.fromHex(map['foregroundColor'])
          : null,
      windowColor: map['windowColor'] != null
          ? HColor.fromHex(map['windowColor'])
          : null,
      windowRoundedCornerRadius: map['windowRoundedCornerRadius']?.toDouble(),
      windowType: map['windowType'] != null
          ? TextTrackWindowType.fromMap(map['windowType'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TextTrackStyle.fromJson(String source) =>
      TextTrackStyle.fromMap(json.decode(source));
}

extension HColor on Color {
  String get hexColor {
    return '#${this.value.toRadixString(16).padLeft(8, '0')}';
  }

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
