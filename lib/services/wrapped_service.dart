import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/recommendation_service.dart';
import '../services/usage_time_service.dart';

class GenreStat {
  final String name;
  final int playCount;
  final double percentage;
  final Color accentColor;

  const GenreStat({
    required this.name,
    required this.playCount,
    required this.percentage,
    required this.accentColor,
  });
}

class PersonalityArchetype {
  final String id;
  final String name;
  final String emoji;
  final String badge;
  final String title;
  final String description;
  final List<String> traits;
  final List<Color> gradientColors;

  const PersonalityArchetype({
    required this.id,
    required this.name,
    required this.emoji,
    required this.badge,
    required this.title,
    required this.description,
    required this.traits,
    required this.gradientColors,
  });
}

class WrappedData {
  final int year;
  final int totalMinutesListened;
  final int totalUniqueTracks;
  final int totalUniqueArtists;
  final List<SongRank> topSongs;
  final List<ArtistRank> topArtists;
  final String topGenre;
  final List<GenreStat> topGenres;
  final String listeningPersonality;
  final String personalityDescription;
  final PersonalityArchetype archetype;
  final String percentileText;
  final String chronotypeId;
  final String chronotypeName;
  final String chronotypeDescription;
  final int topArtistPlayCount;
  final String topArtistSuperfanBadge;

  WrappedData({
    required this.year,
    required this.totalMinutesListened,
    required this.totalUniqueTracks,
    required this.totalUniqueArtists,
    required this.topSongs,
    required this.topArtists,
    required this.topGenre,
    required this.topGenres,
    required this.listeningPersonality,
    required this.personalityDescription,
    required this.archetype,
    required this.percentileText,
    required this.chronotypeId,
    required this.chronotypeName,
    required this.chronotypeDescription,
    required this.topArtistPlayCount,
    required this.topArtistSuperfanBadge,
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

class WrappedService {
  static final WrappedService _instance = WrappedService._internal();
  factory WrappedService() => _instance;
  WrappedService._internal();

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

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

    if (month == 11 && day >= 24) return true;

    if (month == 12) return true;

    if (month == 1 && day <= 15) return true;

    return false;
  }

  static int getWrappedYear([DateTime? customDate]) {
    final now = customDate ?? DateTime.now();
    if (now.month == 1) {
      return now.year - 1;
    }
    return now.year;
  }

  Future<WrappedData> computeWrappedData({
    required RecommendationService recommendationService,
    required List<Song> allLibrarySongs,
  }) async {
    final year = getWrappedYear();
    final profiles = recommendationService.profiles;

    final usageSeconds = UsageTimeService().accumulatedSeconds;
    int songPlayDurationSeconds = 0;
    for (final p in profiles.values) {
      songPlayDurationSeconds += p.totalListenTime;
    }

    final effectiveSeconds = usageSeconds > songPlayDurationSeconds
        ? usageSeconds
        : songPlayDurationSeconds;
    final totalMinutes = (effectiveSeconds / 60).round();

    final songMap = <String, Song>{};
    for (final s in allLibrarySongs) {
      songMap[s.id] = s;
    }

    final sortedProfiles = profiles.values.toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));

    final topSongs = <SongRank>[];
    int rankIndex = 1;
    for (final p in sortedProfiles.take(10)) {
      Song song;
      if (songMap.containsKey(p.songId)) {
        song = songMap[p.songId]!;
      } else {
        final cover =
            p.coverArt ?? (p.albumId != null ? 'al-${p.albumId}' : p.songId);
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

    if (topSongs.isEmpty && allLibrarySongs.isNotEmpty) {
      int mockRank = 1;
      for (final s in allLibrarySongs.take(5)) {
        topSongs.add(
          SongRank(
            rank: mockRank,
            song: s,
            playCount: 15 - mockRank * 2,
            totalMinutes: (15 - mockRank * 2) * 3,
          ),
        );
        mockRank++;
      }
    }

    final artistCounts = <String, int>{};
    final artistCovers = <String, String?>{};
    for (final p in profiles.values) {
      if (p.artist != null && p.artist!.isNotEmpty) {
        artistCounts[p.artist!] = (artistCounts[p.artist!] ?? 0) + p.playCount;
        final cover = songMap[p.songId]?.coverArt ??
            p.coverArt ??
            (p.albumId != null ? 'al-${p.albumId}' : p.songId);
        if (cover.isNotEmpty) {
          artistCovers.putIfAbsent(p.artist!, () => cover);
        }
      }
    }

    if (artistCounts.isEmpty && allLibrarySongs.isNotEmpty) {
      for (final s in allLibrarySongs.take(5)) {
        final art = s.artist ?? 'Featured Artist';
        artistCounts[art] = (artistCounts[art] ?? 0) + 10;
        if (s.coverArt != null && s.coverArt!.isNotEmpty) {
          artistCovers[art] = s.coverArt;
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

    if (genreCounts.isEmpty) {
      genreCounts['Pop'] = 45;
      genreCounts['Hip-Hop & R&B'] = 30;
      genreCounts['Indie / Alternative'] = 15;
      genreCounts['Electronic'] = 10;
    }

    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalGenrePlays =
        sortedGenres.fold<int>(0, (sum, e) => sum + e.value);
    final topGenre =
        sortedGenres.isNotEmpty ? sortedGenres.first.key : 'Eclectic Mix';

    final genrePalette = [
      const Color(0xFFFA243C),
      const Color(0xFF00C6FF),
      const Color(0xFFFF8C00),
      const Color(0xFF8E2DE2),
      const Color(0xFF10B981),
    ];

    final topGenres = <GenreStat>[];
    int colorIdx = 0;
    for (final entry in sortedGenres.take(5)) {
      final percentage =
          totalGenrePlays > 0 ? (entry.value / totalGenrePlays) : 0.2;
      topGenres.add(
        GenreStat(
          name: entry.key,
          playCount: entry.value,
          percentage: percentage,
          accentColor: genrePalette[colorIdx % genrePalette.length],
        ),
      );
      colorIdx++;
    }

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

    String chronotypeId = 'midnight_wanderer';
    String chronotypeName = 'Midnight Wanderer 🌙';
    String chronotypeDesc =
        'Your deepest music moments unfold late at night when the world is quiet.';

    if (morningPlays >= nightPlays &&
        morningPlays >= afternoonPlays &&
        morningPlays >= eveningPlays &&
        morningPlays > 0) {
      chronotypeId = 'sunrise_harmonizer';
      chronotypeName = 'Sunrise Harmonizer ☀️';
      chronotypeDesc =
          'You kickstart every morning with rhythm, setting the soundtrack for the entire day.';
    } else if (afternoonPlays >= nightPlays &&
        afternoonPlays >= eveningPlays &&
        afternoonPlays > 0) {
      chronotypeId = 'afternoon_flow';
      chronotypeName = 'Afternoon Flow ⚡';
      chronotypeDesc =
          'Midday is your prime listening peak, powering through your momentum with high-energy sound.';
    } else if (eveningPlays >= nightPlays && eveningPlays > 0) {
      chronotypeId = 'twilight_lounger';
      chronotypeName = 'Twilight Lounger 🌆';
      chronotypeDesc =
          'Evenings are made for unwinding and losing yourself in immersive album journeys.';
    }

    final totalSongs = profiles.isNotEmpty ? profiles.length : topSongs.length;
    final totalArtists =
        artistCounts.isNotEmpty ? artistCounts.length : topArtists.length;
    final repeatRatio = totalSongs > 0
        ? (effectiveSeconds / (totalSongs * 180)).clamp(0.5, 10.0)
        : 1.0;

    PersonalityArchetype archetype;
    if (totalArtists > 20 && sortedGenres.length >= 4) {
      archetype = const PersonalityArchetype(
        id: 'luminary',
        name: 'The Luminary',
        emoji: '✨',
        badge: 'SONIC EXPLORER',
        title: 'The Luminary',
        description:
            'You shine light on diverse genres and constantly seek out fresh musical horizons.',
        traits: ['Eclectic Taste', 'Genre Fluid', 'High Discovery'],
        gradientColors: [
          Color(0xFFFF007A),
          Color(0xFF7928CA),
          Color(0xFF00DFD8)
        ],
      );
    } else if (repeatRatio > 3.0 ||
        (topArtists.isNotEmpty && topArtists.first.playCount > 25)) {
      archetype = const PersonalityArchetype(
        id: 'devotee',
        name: 'The Devotee',
        emoji: '💎',
        badge: 'SUPERFAN',
        title: 'The Devotee',
        description:
            'When you love an artist or album, you listen on repeat with unmatched dedication.',
        traits: ['Deep Loyalty', 'Album Listener', 'Emotional Bond'],
        gradientColors: [
          Color(0xFFFA243C),
          Color(0xFFFF8C00),
          Color(0xFFFFE600)
        ],
      );
    } else if (nightPlays > (morningPlays + afternoonPlays) * 0.8) {
      archetype = const PersonalityArchetype(
        id: 'night_owl',
        name: 'The Night Owl',
        emoji: '🌙',
        badge: 'NOCTURNAL VIBES',
        title: 'The Night Owl',
        description:
            'Your soul belongs to midnight soundscapes, atmospheric chords, and starry listening sessions.',
        traits: ['Atmospheric', 'Introspective', 'Late-Night Flow'],
        gradientColors: [
          Color(0xFF4A00E0),
          Color(0xFF8E2DE2),
          Color(0xFF00C6FF)
        ],
      );
    } else if (morningPlays > afternoonPlays) {
      archetype = const PersonalityArchetype(
        id: 'sunrise_harmonizer',
        name: 'The Sunrise Harmonizer',
        emoji: '☀️',
        badge: 'ENERGY CATALYST',
        title: 'The Sunrise Harmonizer',
        description:
            'You wake up the world with high vibrations and let optimistic melodies spark your day.',
        traits: ['Uplifting', 'Morning Energy', 'Rhythmic Drive'],
        gradientColors: [
          Color(0xFFFF512F),
          Color(0xFFDD2476),
          Color(0xFFFF9472)
        ],
      );
    } else {
      archetype = const PersonalityArchetype(
        id: 'alchemist',
        name: 'The Sonic Alchemist',
        emoji: '🔮',
        badge: 'VIBE CURATOR',
        title: 'The Sonic Alchemist',
        description:
            'You transmute everyday moments into cinematic experiences with perfectly curated soundtracks.',
        traits: ['Curator Instinct', 'Cinematic Vibe', 'Mood Master'],
        gradientColors: [
          Color(0xFF11998E),
          Color(0xFF38EF7D),
          Color(0xFF00C6FF)
        ],
      );
    }

    final effectiveMinutes = totalMinutes > 0 ? totalMinutes : 420;
    String percentileText;
    if (effectiveMinutes >= 15000) {
      percentileText = 'Top 0.5% Global Listener';
    } else if (effectiveMinutes >= 8000) {
      percentileText = 'Top 1% Global Listener';
    } else if (effectiveMinutes >= 4000) {
      percentileText = 'Top 5% Global Listener';
    } else if (effectiveMinutes >= 1500) {
      percentileText = 'Top 10% Global Listener';
    } else {
      percentileText = 'Top Music Aficionado';
    }

    final topArtistPlays =
        topArtists.isNotEmpty ? topArtists.first.playCount : 15;
    final superfanBadge = topArtistPlays >= 30
        ? 'Top 0.1% Superfan'
        : (topArtistPlays >= 15 ? 'Top 1% Fan' : 'Top 5% Fan');

    return WrappedData(
      year: year,
      totalMinutesListened: effectiveMinutes,
      totalUniqueTracks: totalSongs > 0 ? totalSongs : 24,
      totalUniqueArtists: totalArtists > 0 ? totalArtists : 8,
      topSongs: topSongs,
      topArtists: topArtists,
      topGenre: topGenre,
      topGenres: topGenres,
      listeningPersonality: archetype.title,
      personalityDescription: archetype.description,
      archetype: archetype,
      percentileText: percentileText,
      chronotypeId: chronotypeId,
      chronotypeName: chronotypeName,
      chronotypeDescription: chronotypeDesc,
      topArtistPlayCount: topArtistPlays,
      topArtistSuperfanBadge: superfanBadge,
    );
  }
}
