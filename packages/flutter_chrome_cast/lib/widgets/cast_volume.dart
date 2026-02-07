import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_chrome_cast/_session_manager/cast_session_manager.dart';

class GoogleCastVolume extends StatefulWidget {
  const GoogleCastVolume({
    Key? key,
  }) : super(key: key);

  @override
  State<GoogleCastVolume> createState() => _GoogleCastVolumeState();
}

class _GoogleCastVolumeState extends State<GoogleCastVolume> {
  @override
  void initState() {
    GoogleCastSessionManager.instance.currentSessionStream.listen((event) {
      volumeLevel.value = event?.currentDeviceVolume ?? 0;
      volumeMuted.value = event?.currentDeviceMuted ?? false;
    });
    super.initState();
  }

  final volumeLevel = 0.5.obs;
  final volumeMuted = false.obs;
  bool isSliderTapDown = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      icon: StreamBuilder(
          stream: volumeMuted.stream,
          builder: (context, snapshot) {
            return Icon(
              volumeMuted.value || volumeLevel.value == 0
                  ? Icons.volume_off
                  : Icons.volume_up,
              color: Colors.white,
              size: 44,
            );
          }),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            enabled: false,
            child: StreamBuilder(
              stream: volumeLevel.stream,
              builder: (context, snapshot) {
                return Slider(
                  value: volumeLevel.value,
                  onChanged: _onVolumeChanged,
                  onChangeStart: _onVolumeChangedStart,
                  onChangeEnd: _onVolumeChangedEnd,
                );
              },
            ),
          ),
        ];
      },
    );
  }

  void _onVolumeChangedEnd(double value) {
    isSliderTapDown = false;
    GoogleCastSessionManager.instance.setDeviceVolume(value);
  }

  void _onVolumeChangedStart(double value) {
    isSliderTapDown = true;
  }

  void _onVolumeChanged(double value) {
    volumeLevel.value = value;
  }
}
