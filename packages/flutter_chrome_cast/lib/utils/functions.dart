import '../entities/entities.dart';

double? getPlayerPercentage(
    GoggleCastMediaStatus mediaStatus, Duration? currentDuration) {
  if (currentDuration == null || currentDuration.inSeconds == 0) return null;
  final mediaDuration = mediaStatus.mediaInformation?.duration;
  if (mediaDuration == null || mediaDuration.inSeconds == 0) return null;
  final percentage = currentDuration.inSeconds / mediaDuration.inSeconds;
  if (percentage > 1) return 1;
  return percentage;
}
