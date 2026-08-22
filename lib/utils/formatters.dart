import 'dart:math';

/// Utility class for formatting durations, byte sizes, and timestamps across Musly.
class FormatUtils {
  FormatUtils._();

  /// Formats a [Duration] or seconds into mm:ss or hh:mm:ss.
  /// Example: Duration(seconds: 125) -> "2:05", Duration(seconds: 3665) -> "1:01:05"
  static String formatDuration(Duration? duration) {
    if (duration == null || duration.inMilliseconds < 0) {
      return '0:00';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Formats integer seconds into mm:ss or hh:mm:ss.
  static String formatSeconds(int? seconds) {
    if (seconds == null || seconds < 0) {
      return '0:00';
    }
    return formatDuration(Duration(seconds: seconds));
  }

  /// Formats byte size into human-readable representation (e.g. 1.5 MB, 320 KB, 2.1 GB).
  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor().clamp(0, suffixes.length - 1);
    final size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Formats duration into a localized human-readable summary (e.g., "1 hr 15 min" or "45 min").
  static String formatDurationSummary(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      if (minutes > 0) {
        return '$hours hr $minutes min';
      }
      return '$hours hr';
    }
    return '$minutes min';
  }
}
