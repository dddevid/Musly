import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/recommendation_service.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Song> _recentSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final recommendationService = Provider.of<RecommendationService>(
      context,
      listen: false,
    );
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    if (!recommendationService.enabled ||
        libraryProvider.cachedAllSongs.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final profiles = recommendationService.profiles;
    final allSongs = libraryProvider.cachedAllSongs;

    final songMap = {for (var s in allSongs) s.id: s};

    final playedSongs = profiles.entries
        .where((e) => e.value.playCount > 0 && songMap.containsKey(e.key))
        .map((e) => MapEntry(songMap[e.key]!, e.value.lastPlayed))
        .toList();

    playedSongs.sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _recentSongs = playedSongs.map((e) => e.key).take(100).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      bottomNavigationBar: const MiniPlayer(),
      appBar: AppBar(title: const Text('Listening History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recentSongs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Listening History',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Songs you play will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkSecondaryText
                          : AppTheme.lightSecondaryText,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _recentSongs.length,
              itemBuilder: (context, index) {
                return SongTile(
                  song: _recentSongs[index],
                  playlist: _recentSongs,
                  index: index,
                  showAlbum: true,
                );
              },
            ),
    );
  }
}
