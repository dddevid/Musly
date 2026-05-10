import 'package:flutter/material.dart';

/// Configuration for background styling in Now Playing screen
class BackgroundConfig {
  final String type; // 'solid', 'gradient', 'dynamic_blur'
  final List<String> colors; // Hex color strings
  final double opacity;
  final double blurSigma;

  const BackgroundConfig({
    this.type = 'dynamic_blur',
    this.colors = const ['#1a1a2e', '#16213e'],
    this.opacity = 1.0,
    this.blurSigma = 20.0,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'colors': colors,
        'opacity': opacity,
        'blur_sigma': blurSigma,
      };

  factory BackgroundConfig.fromJson(Map<String, dynamic> json) =>
      BackgroundConfig(
        type: json['type'] as String? ?? 'dynamic_blur',
        colors: (json['colors'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['#1a1a2e', '#16213e'],
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        blurSigma: (json['blur_sigma'] as num?)?.toDouble() ?? 20.0,
      );

  Color getColor(int index) {
    if (index >= colors.length) return Colors.black;
    final hex = colors[index].replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

/// Text styling configuration for a single text element
class TextStyleConfig {
  final String color;
  final double fontSize;
  final String fontWeight; // 'normal', 'bold', 'w100'-'w900'
  final String? fontFamily;

  const TextStyleConfig({
    this.color = '#FFFFFF',
    this.fontSize = 16.0,
    this.fontWeight = 'normal',
    this.fontFamily,
  });

  Map<String, dynamic> toJson() => {
        'color': color,
        'font_size': fontSize,
        'font_weight': fontWeight,
        if (fontFamily != null) 'font_family': fontFamily,
      };

  factory TextStyleConfig.fromJson(Map<String, dynamic> json) =>
      TextStyleConfig(
        color: json['color'] as String? ?? '#FFFFFF',
        fontSize: (json['font_size'] as num?)?.toDouble() ?? 16.0,
        fontWeight: json['font_weight'] as String? ?? 'normal',
        fontFamily: json['font_family'] as String?,
      );

  Color getColor() {
    final hex = color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  FontWeight getFontWeight() {
    switch (fontWeight) {
      case 'bold':
        return FontWeight.bold;
      case 'w100':
        return FontWeight.w100;
      case 'w200':
        return FontWeight.w200;
      case 'w300':
        return FontWeight.w300;
      case 'w400':
        return FontWeight.w400;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
        return FontWeight.w700;
      case 'w800':
        return FontWeight.w800;
      case 'w900':
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }
}

/// Text configuration for all text elements
class TextConfig {
  final TextStyleConfig title;
  final TextStyleConfig artist;
  final TextStyleConfig album;
  final TextStyleConfig duration;

  const TextConfig({
    this.title = const TextStyleConfig(fontSize: 24.0, fontWeight: 'bold'),
    this.artist = const TextStyleConfig(fontSize: 16.0, color: '#FFFFFFB3'),
    this.album = const TextStyleConfig(fontSize: 14.0, color: '#FFFFFF99'),
    this.duration = const TextStyleConfig(fontSize: 13.0, color: '#FFFFFFB3'),
  });

  Map<String, dynamic> toJson() => {
        'title': title.toJson(),
        'artist': artist.toJson(),
        'album': album.toJson(),
        'duration': duration.toJson(),
      };

  factory TextConfig.fromJson(Map<String, dynamic> json) => TextConfig(
        title: TextStyleConfig.fromJson(
          json['title'] as Map<String, dynamic>? ?? {},
        ),
        artist: TextStyleConfig.fromJson(
          json['artist'] as Map<String, dynamic>? ?? {},
        ),
        album: TextStyleConfig.fromJson(
          json['album'] as Map<String, dynamic>? ?? {},
        ),
        duration: TextStyleConfig.fromJson(
          json['duration'] as Map<String, dynamic>? ?? {},
        ),
      );
}

/// Artwork configuration
class ArtworkConfig {
  final String shape; // 'square', 'circle', 'rounded_rect'
  final double sizeFactor; // 0.0 - 1.0
  final double cornerRadius;
  final bool shadow;
  final bool rotation;

  const ArtworkConfig({
    this.shape = 'rounded_rect',
    this.sizeFactor = 0.8,
    this.cornerRadius = 12.0,
    this.shadow = true,
    this.rotation = false,
  });

  Map<String, dynamic> toJson() => {
        'shape': shape,
        'size_factor': sizeFactor,
        'corner_radius': cornerRadius,
        'shadow': shadow,
        'rotation': rotation,
      };

  factory ArtworkConfig.fromJson(Map<String, dynamic> json) => ArtworkConfig(
        shape: json['shape'] as String? ?? 'rounded_rect',
        sizeFactor: (json['size_factor'] as num?)?.toDouble() ?? 0.8,
        cornerRadius: (json['corner_radius'] as num?)?.toDouble() ?? 12.0,
        shadow: json['shadow'] as bool? ?? true,
        rotation: json['rotation'] as bool? ?? false,
      );
}

/// Progress bar configuration
class ProgressBarConfig {
  final String activeColor;
  final String inactiveColor;
  final double height;
  final String shape; // 'rounded', 'square'
  final bool thumbVisible;
  final String thumbColor;

  const ProgressBarConfig({
    this.activeColor = '#FFFFFF',
    this.inactiveColor = '#FFFFFF40',
    this.height = 3.0,
    this.shape = 'rounded',
    this.thumbVisible = true,
    this.thumbColor = '#FFFFFF',
  });

  Map<String, dynamic> toJson() => {
        'active_color': activeColor,
        'inactive_color': inactiveColor,
        'height': height,
        'shape': shape,
        'thumb_visible': thumbVisible,
        'thumb_color': thumbColor,
      };

  factory ProgressBarConfig.fromJson(Map<String, dynamic> json) =>
      ProgressBarConfig(
        activeColor: json['active_color'] as String? ?? '#FFFFFF',
        inactiveColor: json['inactive_color'] as String? ?? '#FFFFFF40',
        height: (json['height'] as num?)?.toDouble() ?? 3.0,
        shape: json['shape'] as String? ?? 'rounded',
        thumbVisible: json['thumb_visible'] as bool? ?? true,
        thumbColor: json['thumb_color'] as String? ?? '#FFFFFF',
      );

  Color getActiveColor() {
    final hex = activeColor.replaceFirst('#', '');
    return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
  }

  Color getInactiveColor() {
    final hex = inactiveColor.replaceFirst('#', '');
    return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
  }

  Color getThumbColor() {
    final hex = thumbColor.replaceFirst('#', '');
    return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
  }
}

/// Controls configuration
class ControlsConfig {
  final String playShape; // 'circle', 'rounded_rect'
  final String color;
  final double size;
  final String playButtonColor;
  final String playButtonShape;

  const ControlsConfig({
    this.playShape = 'circle',
    this.color = '#FFFFFF',
    this.size = 56.0,
    this.playButtonColor = '#000000',
    this.playButtonShape = 'circle',
  });

  Map<String, dynamic> toJson() => {
        'play_shape': playShape,
        'color': color,
        'size': size,
        'play_button_color': playButtonColor,
        'play_button_shape': playButtonShape,
      };

  factory ControlsConfig.fromJson(Map<String, dynamic> json) => ControlsConfig(
        playShape: json['play_shape'] as String? ?? 'circle',
        color: json['color'] as String? ?? '#FFFFFF',
        size: (json['size'] as num?)?.toDouble() ?? 56.0,
        playButtonColor: json['play_button_color'] as String? ?? '#000000',
        playButtonShape: json['play_button_shape'] as String? ?? 'circle',
      );

  Color getColor() {
    final hex = color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Color getPlayButtonColor() {
    final hex = playButtonColor.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

/// Layout element position
class LayoutElement {
  final String id; // 'artwork', 'title', 'artist', 'controls', etc.
  final double x; // 0.0 - 1.0 normalized
  final double y; // 0.0 - 1.0 normalized
  final int zIndex;
  final bool visible;

  const LayoutElement({
    required this.id,
    this.x = 0.5,
    this.y = 0.5,
    this.zIndex = 1,
    this.visible = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'z_index': zIndex,
        'visible': visible,
      };

  factory LayoutElement.fromJson(Map<String, dynamic> json) => LayoutElement(
        id: json['id'] as String,
        x: (json['x'] as num?)?.toDouble() ?? 0.5,
        y: (json['y'] as num?)?.toDouble() ?? 0.5,
        zIndex: json['z_index'] as int? ?? 1,
        visible: json['visible'] as bool? ?? true,
      );
}

/// Layout configuration
class LayoutConfig {
  final List<LayoutElement> elements;

  const LayoutConfig({this.elements = const []});

  Map<String, dynamic> toJson() => {
        'elements': elements.map((e) => e.toJson()).toList(),
      };

  factory LayoutConfig.fromJson(Map<String, dynamic> json) => LayoutConfig(
        elements: (json['elements'] as List<dynamic>?)
                ?.map((e) => LayoutElement.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// Animation configuration
class AnimationConfig {
  final bool coverRotation;
  final bool pulse;
  final bool fadeIn;

  const AnimationConfig({
    this.coverRotation = false,
    this.pulse = false,
    this.fadeIn = true,
  });

  Map<String, dynamic> toJson() => {
        'cover_rotation': coverRotation,
        'pulse': pulse,
        'fade_in': fadeIn,
      };

  factory AnimationConfig.fromJson(Map<String, dynamic> json) =>
      AnimationConfig(
        coverRotation: json['cover_rotation'] as bool? ?? false,
        pulse: json['pulse'] as bool? ?? false,
        fadeIn: json['fade_in'] as bool? ?? true,
      );
}

/// Custom Flutter widget definition
class CustomWidget {
  final String id;
  final String name;
  final String dartCode;
  final List<String> dependencies;
  final double x;
  final double y;
  final int zIndex;

  const CustomWidget({
    required this.id,
    required this.name,
    this.dartCode = '',
    this.dependencies = const [],
    this.x = 0.5,
    this.y = 0.5,
    this.zIndex = 10,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dart_code': dartCode,
        'dependencies': dependencies,
        'position': {
          'x': x,
          'y': y,
          'z_index': zIndex,
        },
      };

  factory CustomWidget.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>? ?? {};
    return CustomWidget(
      id: json['id'] as String,
      name: json['name'] as String,
      dartCode: json['dart_code'] as String? ?? '',
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      x: (position['x'] as num?)?.toDouble() ?? 0.5,
      y: (position['y'] as num?)?.toDouble() ?? 0.5,
      zIndex: (position['z_index'] as int?) ?? 10,
    );
  }
}

/// Custom Flutter code configuration
class CustomFlutterCode {
  final bool enabled;
  final List<CustomWidget> widgets;

  const CustomFlutterCode({
    this.enabled = false,
    this.widgets = const [],
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'widgets': widgets.map((w) => w.toJson()).toList(),
      };

  factory CustomFlutterCode.fromJson(Map<String, dynamic> json) =>
      CustomFlutterCode(
        enabled: json['enabled'] as bool? ?? false,
        widgets: (json['widgets'] as List<dynamic>?)
                ?.map((e) => CustomWidget.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// Complete theme configuration for Now Playing screen
class NowPlayingTheme {
  final String id;
  final String themeName;
  final String author;
  final String version;
  final DateTime createdAt;
  final BackgroundConfig background;
  final TextConfig text;
  final ArtworkConfig artwork;
  final ProgressBarConfig progressBar;
  final ControlsConfig controls;
  final LayoutConfig layout;
  final AnimationConfig animations;
  final CustomFlutterCode customFlutterCode;
  final bool safeMode; // If true, ignore custom code

  const NowPlayingTheme({
    required this.id,
    required this.themeName,
    this.author = 'Unknown',
    this.version = '1.0.0',
    required this.createdAt,
    this.background = const BackgroundConfig(),
    this.text = const TextConfig(),
    this.artwork = const ArtworkConfig(),
    this.progressBar = const ProgressBarConfig(),
    this.controls = const ControlsConfig(),
    this.layout = const LayoutConfig(),
    this.animations = const AnimationConfig(),
    this.customFlutterCode = const CustomFlutterCode(),
    this.safeMode = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'theme_name': themeName,
        'author': author,
        'version': version,
        'created_at': createdAt.toIso8601String(),
        'safe_mode': safeMode,
        'style': {
          'background': background.toJson(),
          'text': text.toJson(),
          'artwork': artwork.toJson(),
          'progress_bar': progressBar.toJson(),
          'controls': controls.toJson(),
          'layout': layout.toJson(),
          'animations': animations.toJson(),
        },
        'custom_flutter_code': customFlutterCode.toJson(),
      };

  factory NowPlayingTheme.fromJson(Map<String, dynamic> json) {
    final style = json['style'] as Map<String, dynamic>? ?? {};
    return NowPlayingTheme(
      id: json['id'] as String? ?? '',
      themeName: json['theme_name'] as String? ?? 'Unnamed Theme',
      author: json['author'] as String? ?? 'Unknown',
      version: json['version'] as String? ?? '1.0.0',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      safeMode: json['safe_mode'] as bool? ?? false,
      background: BackgroundConfig.fromJson(
        style['background'] as Map<String, dynamic>? ?? {},
      ),
      text: TextConfig.fromJson(
        style['text'] as Map<String, dynamic>? ?? {},
      ),
      artwork: ArtworkConfig.fromJson(
        style['artwork'] as Map<String, dynamic>? ?? {},
      ),
      progressBar: ProgressBarConfig.fromJson(
        style['progress_bar'] as Map<String, dynamic>? ?? {},
      ),
      controls: ControlsConfig.fromJson(
        style['controls'] as Map<String, dynamic>? ?? {},
      ),
      layout: LayoutConfig.fromJson(
        style['layout'] as Map<String, dynamic>? ?? {},
      ),
      animations: AnimationConfig.fromJson(
        style['animations'] as Map<String, dynamic>? ?? {},
      ),
      customFlutterCode: CustomFlutterCode.fromJson(
        json['custom_flutter_code'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// Validate theme structure and return list of errors
  List<String> validate() {
    final errors = <String>[];

    if (themeName.isEmpty) {
      errors.add('Theme name cannot be empty');
    }

    if (background.colors.isEmpty) {
      errors.add('Background must have at least one color');
    }

    if (artwork.sizeFactor < 0.1 || artwork.sizeFactor > 1.0) {
      errors.add('Artwork size factor must be between 0.1 and 1.0');
    }

    if (progressBar.height < 1.0 || progressBar.height > 20.0) {
      errors.add('Progress bar height must be between 1.0 and 20.0');
    }

    if (controls.size < 20.0 || controls.size > 100.0) {
      errors.add('Control size must be between 20.0 and 100.0');
    }

    // Validate custom widgets
    if (customFlutterCode.enabled) {
      for (final widget in customFlutterCode.widgets) {
        if (widget.id.isEmpty) {
          errors.add('Custom widget ID cannot be empty');
        }
        if (widget.name.isEmpty) {
          errors.add('Custom widget name cannot be empty');
        }
      }
    }

    return errors;
  }

  NowPlayingTheme copyWith({
    String? id,
    String? themeName,
    String? author,
    String? version,
    DateTime? createdAt,
    BackgroundConfig? background,
    TextConfig? text,
    ArtworkConfig? artwork,
    ProgressBarConfig? progressBar,
    ControlsConfig? controls,
    LayoutConfig? layout,
    AnimationConfig? animations,
    CustomFlutterCode? customFlutterCode,
    bool? safeMode,
  }) {
    return NowPlayingTheme(
      id: id ?? this.id,
      themeName: themeName ?? this.themeName,
      author: author ?? this.author,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      background: background ?? this.background,
      text: text ?? this.text,
      artwork: artwork ?? this.artwork,
      progressBar: progressBar ?? this.progressBar,
      controls: controls ?? this.controls,
      layout: layout ?? this.layout,
      animations: animations ?? this.animations,
      customFlutterCode: customFlutterCode ?? this.customFlutterCode,
      safeMode: safeMode ?? this.safeMode,
    );
  }

  /// Create a default theme matching current Now Playing appearance
  static NowPlayingTheme createDefault() {
    return NowPlayingTheme(
      id: 'default',
      themeName: 'Default',
      author: 'Musly',
      version: '1.0.0',
      createdAt: DateTime.now(),
      background: const BackgroundConfig(
        type: 'dynamic_blur',
        colors: ['#1a1a2e', '#16213e'],
        opacity: 1.0,
        blurSigma: 20.0,
      ),
      text: const TextConfig(
        title: TextStyleConfig(
          fontSize: 24.0,
          fontWeight: 'bold',
          color: '#FFFFFF',
        ),
        artist: TextStyleConfig(
          fontSize: 16.0,
          color: '#FFFFFFB3',
        ),
        album: TextStyleConfig(
          fontSize: 14.0,
          color: '#FFFFFF99',
        ),
        duration: TextStyleConfig(
          fontSize: 13.0,
          color: '#FFFFFFB3',
        ),
      ),
      artwork: const ArtworkConfig(
        shape: 'rounded_rect',
        sizeFactor: 0.8,
        cornerRadius: 12.0,
        shadow: true,
        rotation: false,
      ),
      progressBar: const ProgressBarConfig(
        activeColor: '#FFFFFF',
        inactiveColor: '#FFFFFF40',
        height: 3.0,
        shape: 'rounded',
        thumbVisible: true,
        thumbColor: '#FFFFFF',
      ),
      controls: const ControlsConfig(
        playShape: 'circle',
        color: '#FFFFFF',
        size: 56.0,
        playButtonColor: '#000000',
        playButtonShape: 'circle',
      ),
      animations: const AnimationConfig(
        coverRotation: false,
        pulse: false,
        fadeIn: true,
      ),
      customFlutterCode: const CustomFlutterCode(
        enabled: false,
        widgets: [],
      ),
      safeMode: false,
    );
  }
}
