import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/recommendation_service.dart';
import '../services/usage_time_service.dart';

/// Data model representing a user's computed annual listening stats.
class WrappedData {
  final int year;
  final int totalMinutesListened;
  final int totalUniqueTracks;
  final int totalUniqueArtists;
  final List<SongRank> topSongs;
  final List<ArtistRank> topArtists;
  final String topGenre;
  final String listeningPersonality;
  final String personalityDescription;

  WrappedData({
    required this.year,
    required this.totalMinutesListened,
    required this.totalUniqueTracks,
    required this.totalUniqueArtists,
    required this.topSongs,
    required this.topArtists,
    required this.topGenre,
    required this.listeningPersonality,
    required this.personalityDescription,
  });
}

class SongRank {
  final int rank;
  final Song song;
  final int playCount;
  final int totalMinutes;

  SongRank({
    required this.rank,
    required this.song,
    required this.playCount,
    required this.totalMinutes,
  });
}

class ArtistRank {
  final int rank;
  final String name;
  final String? coverArt;
  final int playCount;
  final double affinity;

  ArtistRank({
    required this.rank,
    required this.name,
    this.coverArt,
    required this.playCount,
    required this.affinity,
  });
}

/// Service managing calculation and seasonal availability for Musly Wrapped.
class WrappedService {
  static final WrappedService _instance = WrappedService._internal();
  factory WrappedService() => _instance;
  WrappedService._internal();

  /// Whether current running platform is desktop (Windows, macOS, Linux).
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Returns true if currently within the seasonal window:
  /// - Excluded on Desktop (mobile only)
  /// - Unlocks during the last week of November (Nov 24) through December
  /// - Stays accessible through mid-January (Jan 15)
  /// - Becomes inactive / locked from Jan 16 through Nov 23
  static bool isWrappedSeason({
    bool devPreview = false,
    DateTime? customDate,
    bool checkPlatform = true,
  }) {
    if (checkPlatform && isDesktop && !devPreview) {
      return false;
    }
    if (devPreview) return true;
    final now = customDate ?? DateTime.now();
    final month = now.month;
    final day = now.day;

    // Late November (Nov 24 - Nov 30)
    if (month == 11 && day >= 24) return true;
    // Entire month of December (Dec 1 - Dec 31)
    if (month == 12) return true;
    // Mid-January (Jan 1 - Jan 15)
    if (month == 1 && day <= 15) return true;

    return false;
  }

  /// Calculates the relevant Wrapped year.
  /// If viewed in January, it reflects the year that just ended.
  static int getWrappedYear([DateTime? customDate]) {
    final now = customDate ?? DateTime.now();
    if (now.month == 1) {
      return now.year - 1;
    }
    return now.year;
  }

  /// Aggregates all local on-device metrics to build the WrappedData object.
  Future<WrappedData> computeWrappedData({
    required RecommendationService recommendationService,
    required List<Song> allLibrarySongs,
  }) async {
    final year = getWrappedYear();
    final profiles = recommendationService.profiles;

    // 1. Total Listening Time
    final usageSeconds = UsageTimeService().accumulatedSeconds;
    int songPlayDurationSeconds = 0;
    for (final p in profiles.values) {
      songPlayDurationSeconds += p.totalListenTime;
    }
    // Take the max of recorded usage timer and accumulated song listen times
    final effectiveSeconds = usageSeconds > songPlayDurationSeconds
        ? usageSeconds
        : songPlayDurationSeconds;
    final totalMinutes = (effectiveSeconds / 60).round();

    // Map song ID to Song object from library
    final songMap = <String, Song>{};
    for (final s in allLibrarySongs) {
      songMap[s.id] = s;
    }

    // 2. Top Songs
    final sortedProfiles = profiles.values.toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));

    final topSongs = <SongRank>[];
    int rankIndex = 1;
    for (final p in sortedProfiles.take(10)) {
      Song song;
      if (songMap.containsKey(p.songId)) {
        song = songMap[p.songId]!;
      } else {
        final cover = p.coverArt ?? (p.albumId != null ? 'al-${p.albumId}' : p.songId);
        song = Song(
          id: p.songId,
          title: p.title,
          artist: p.artist,
          albumId: p.albumId,
          coverArt: cover,
          genre: p.genre,
          duration: p.duration,
        );
      }
      topSongs.add(
        SongRank(
          rank: rankIndex++,
          song: song,
          playCount: p.playCount,
          totalMinutes: (p.totalListenTime / 60).round(),
        ),
      );
    }

    // 3. Top Artists
    final artistCounts = <String, int>{};
    final artistCovers = <String, String?>{};
    for (final p in profiles.values) {
      if (p.artist != null && p.artist!.isNotEmpty) {
        artistCounts[p.artist!] = (artistCounts[p.artist!] ?? 0) + p.playCount;
        final cover = songMap[p.songId]?.coverArt ??
            p.coverArt ??
            (p.albumId != null ? 'al-${p.albumId}' : p.songId);
        if (cover != null && cover.isNotEmpty) {
          artistCovers.putIfAbsent(p.artist!, () => cover);
        }
      }
    }

    final sortedArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topArtists = <ArtistRank>[];
    int artistRank = 1;
    for (final entry in sortedArtists.take(5)) {
      topArtists.add(
        ArtistRank(
          rank: artistRank++,
          name: entry.key,
          coverArt: artistCovers[entry.key],
          playCount: entry.value,
          affinity: entry.value.toDouble(),
        ),
      );
    }

    // 4. Top Genre
    final genreCounts = <String, int>{};
    final hourCounts = <int, int>{};

    for (final p in profiles.values) {
      if (p.genre != null && p.genre!.isNotEmpty) {
        genreCounts[p.genre!] = (genreCounts[p.genre!] ?? 0) + p.playCount;
      }
      p.hourlyPlays.forEach((h, count) {
        hourCounts[h] = (hourCounts[h] ?? 0) + count;
      });
    }

    String topGenre = 'Eclectic Mix';
    if (genreCounts.isNotEmpty) {
      final sortedGenres = genreCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topGenre = sortedGenres.first.key;
    }

    // 5. Personality trait based on listening time of day
    int nightPlays = 0;
    int morningPlays = 0;
    int afternoonPlays = 0;
    int eveningPlays = 0;

    hourCounts.forEach((hour, count) {
      if (hour >= 22 || hour < 6) {
        nightPlays += count;
      } else if (hour >= 6 && hour < 12) {
        morningPlays += count;
      } else if (hour >= 12 && hour < 18) {
        afternoonPlays += count;
      } else {
        eveningPlays += count;
      }
    });

    String personality = 'The Sonic Wanderer';
    String desc = 'You listen across all times of day and love exploring a wide variety of sounds.';

    if (nightPlays >= morningPlays && nightPlays >= afternoonPlays && nightPlays >= eveningPlays && nightPlays > 0) {
      personality = 'The Night Owl 🌙';
      desc = 'Your best music sessions happen under the stars when the rest of the world is asleep.';
    } else if (morningPlays >= afternoonPlays && morningPlays >= eveningPlays && morningPlays > 0) {
      personality = 'The Sunrise Harmonizer ☀️';
      desc = 'You start your days energized with great tunes and morning coffee.';
    } else if (afternoonPlays >= eveningPlays && afternoonPlays > 0) {
      personality = 'The Afternoon Flow ⚡';
      desc = 'Music keeps your energy and momentum going throughout the busy day.';
    } else if (eveningPlays > 0) {
      personality = 'The Twilight Lounger 🌆';
      desc = 'You unwind and reflect in the evenings with your favorite albums.';
    }

    return WrappedData(
      year: year,
      totalMinutesListened: totalMinutes > 0 ? totalMinutes : 42,
      totalUniqueTracks: profiles.length,
      totalUniqueArtists: artistCounts.length,
      topSongs: topSongs,
      topArtists: topArtists,
      topGenre: topGenre,
      listeningPersonality: personality,
      personalityDescription: desc,
    );
  }
}
