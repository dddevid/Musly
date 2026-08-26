import 'dart:math';

class FormatUtils {
  FormatUtils._();

  static String formatDuration(Duration? duration) {
    if (duration == null || duration.inMilliseconds < 0) {
      return '0:00';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatSeconds(int? seconds) {
    if (seconds == null || seconds < 0) {
      return '0:00';
    }
    return formatDuration(Duration(seconds: seconds));
  }

  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final unitIndex =
        (log(bytes) / log(1024)).floor().clamp(0, suffixes.length - 1);
    final formattedSize = bytes / pow(1024, unitIndex);

    return '${formattedSize.toStringAsFixed(decimals)} ${suffixes[unitIndex]}';
  }

  static String formatDurationSummary(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return minutes > 0 ? '$hours hr $minutes min' : '$hours hr';
    }

    return '$minutes min';
  }
}
