import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AirPlayButton extends StatelessWidget {
  final Color tintColor;
  final double size;

  const AirPlayButton({
    super.key,
    this.tintColor = Colors.white,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) return const SizedBox.shrink();

    final colorInt = tintColor.toARGB32();

    return SizedBox(
      width: size + 16, 
      height: size + 16,
      child: UiKitView(
        viewType: 'musly/airplay_button',
        layoutDirection: TextDirection.ltr,
        creationParams: {'tintColor': colorInt},
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
