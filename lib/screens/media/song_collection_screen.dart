import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/recommendation_service.dart';
import '../../services/subsonic_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/widgets.dart';

enum SongCollectionType {
  allSongs,
  madeForYou,
  history,
  custom,
}

enum SongSortOption {
  titleAsc,
  titleDesc,
  artistAsc,
  artistDesc,
  albumAsc,
  albumDesc,
  recentlyAdded,
  duration,
}

class SongCollectionScreen extends StatefulWidget {
  final SongCollectionType type;
  final String? customTitle;
  final List<Song>? initialSongs;
  final Future<List<Song>> Function(BuildContext context)? customFetcher;

  const SongCollectionScreen({
    super.key,
    required this.type,
    this.customTitle,
    this.initialSongs,
    this.customFetcher,
  });

  const SongCollectionScreen.allSongs({super.key})
      : type = SongCollectionType.allSongs,
        customTitle = null,
        initialSongs = null,
        customFetcher = null;

  const SongCollectionScreen.madeForYou({super.key})
      : type = SongCollectionType.madeForYou,
        customTitle = null,
        initialSongs = null,
        customFetcher = null;

  const SongCollectionScreen.history({super.key})
      : type = SongCollectionType.history,
        customTitle = null,
        initialSongs = null,
        customFetcher = null;

  @override
  State<SongCollectionScreen> createState() => _SongCollectionScreenState();
}

class _SongCollectionScreenState extends State<SongCollectionScreen> {
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isLoading = true;
  String? _error;
  final String _searchQuery = '';
  SongSortOption _currentSort = SongSortOption.titleAsc;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSongs != null) {
      _songs = widget.initialSongs!;
      _filteredSongs = List.from(_songs);
      _isLoading = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadSongs();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Song> songs = [];
      if (widget.customFetcher != null) {
        songs = await widget.customFetcher!(context);
      } else {
        switch (widget.type) {
          case SongCollectionType.allSongs:
            final library =
                Provider.of<LibraryProvider>(context, listen: false);
            await library.ensureLibraryLoaded();
            songs = List.from(library.cachedAllSongs);
            break;

          case SongCollectionType.madeForYou:
            final subsonic =
                Provider.of<SubsonicService>(context, listen: false);
            songs = await subsonic.getRandomSongs(size: 50);
            break;

          case SongCollectionType.history:
            final recService =
                Provider.of<RecommendationService>(context, listen: false);
            final library =
                Provider.of<LibraryProvider>(context, listen: false);
            final profiles = recService.profiles;
            final allSongs = library.cachedAllSongs;
            final songMap = {for (var s in allSongs) s.id: s};

            final playedSongs = profiles.entries
                .where(
                    (e) => e.value.playCount > 0 && songMap.containsKey(e.key))
                .map((e) => MapEntry(songMap[e.key]!, e.value.lastPlayed))
                .toList();

            playedSongs.sort((a, b) => b.value.compareTo(a.value));
            songs = playedSongs.map((e) => e.key).take(100).toList();
            break;

          case SongCollectionType.custom:
            songs = widget.initialSongs ?? [];
            break;
        }
      }

      if (mounted) {
        setState(() {
          _songs = songs;
          _applySortAndFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applySortAndFilter() {
    List<Song> result = List.from(_songs);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) {
        return s.title.toLowerCase().contains(q) ||
            (s.artist?.toLowerCase().contains(q) ?? false) ||
            (s.album?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (widget.type == SongCollectionType.allSongs ||
        widget.type == SongCollectionType.custom) {
      switch (_currentSort) {
        case SongSortOption.titleAsc:
          result.sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          break;
        case SongSortOption.titleDesc:
          result.sort(
              (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
          break;
        case SongSortOption.artistAsc:
          result.sort((a, b) => (a.artist ?? '')
              .toLowerCase()
              .compareTo((b.artist ?? '').toLowerCase()));
          break;
        case SongSortOption.artistDesc:
          result.sort((a, b) => (b.artist ?? '')
              .toLowerCase()
              .compareTo((a.artist ?? '').toLowerCase()));
          break;
        case SongSortOption.albumAsc:
          result.sort((a, b) => (a.album ?? '')
              .toLowerCase()
              .compareTo((b.album ?? '').toLowerCase()));
          break;
        case SongSortOption.albumDesc:
          result.sort((a, b) => (b.album ?? '')
              .toLowerCase()
              .compareTo((a.album ?? '').toLowerCase()));
          break;
        case SongSortOption.duration:
          result.sort((a, b) => (b.duration ?? 0).compareTo(a.duration ?? 0));
          break;
        case SongSortOption.recentlyAdded:
          break;
      }
    }

    _filteredSongs = result;
  }

  String _getTitle(BuildContext context) {
    if (widget.customTitle != null && widget.customTitle!.isNotEmpty) {
      return widget.customTitle!;
    }
    final l10n = AppLocalizations.of(context);
    switch (widget.type) {
      case SongCollectionType.allSongs:
        return l10n?.songs ?? 'All Songs';
      case SongCollectionType.madeForYou:
        return 'Made For You';
      case SongCollectionType.history:
        return 'Listening History';
      case SongCollectionType.custom:
        return 'Songs';
    }
  }

  void _playAll({bool shuffle = false}) {
    if (_filteredSongs.isEmpty) return;
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final playlist = List<Song>.from(_filteredSongs);
    if (shuffle) playlist.shuffle();
    player.playSong(playlist.first, playlist: playlist, startIndex: 0);
  }

  Duration _calculateTotalDuration() {
    int totalSeconds = 0;
    for (var s in _filteredSongs) {
      totalSeconds += s.duration ?? 0;
    }
    return Duration(seconds: totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = _getTitle(context);
    final totalDuration = _calculateTotalDuration();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadSongs,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  title,
                  style: theme.appBarTheme.titleTextStyle ??
                      const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                ),
                titlePadding: const EdgeInsets.only(left: 52, bottom: 16),
              ),
              actions: [
                if (widget.type == SongCollectionType.madeForYou)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: AppLocalizations.of(context)!.shuffleNewSelection,
                    onPressed: _loadSongs,
                  ),
                if (widget.type == SongCollectionType.allSongs)
                  PopupMenuButton<SongSortOption>(
                    icon: const Icon(Icons.sort_rounded),
                    tooltip: AppLocalizations.of(context)!.sortBy,
                    onSelected: (opt) {
                      setState(() {
                        _currentSort = opt;
                        _applySortAndFilter();
                      });
                    },
                    itemBuilder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return [
                        PopupMenuItem(
                          value: SongSortOption.titleAsc,
                          child: Text(l10n.sortByTitleAZ),
                        ),
                        PopupMenuItem(
                          value: SongSortOption.titleDesc,
                          child: Text(l10n.sortByTitleZA),
                        ),
                        PopupMenuItem(
                          value: SongSortOption.artistAsc,
                          child: Text(l10n.sortByArtistAZ),
                        ),
                        PopupMenuItem(
                          value: SongSortOption.albumAsc,
                          child: Text(l10n.sortByAlbumAZ),
                        ),
                        PopupMenuItem(
                          value: SongSortOption.duration,
                          child: Text(l10n.sortDurationLongest),
                        ),
                      ];
                    },
                  ),
              ],
            ),
            if (!_isLoading && _error == null && _filteredSongs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      MediaPlayButton(
                        icon: Icons.play_arrow_rounded,
                        label: AppLocalizations.of(context)!.playAll,
                        onTap: () => _playAll(shuffle: false),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _playAll(shuffle: true),
                        icon: const Icon(Icons.shuffle_rounded, size: 20),
                        label: Text(AppLocalizations.of(context)!.shuffle),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${AppLocalizations.of(context)!.songsCount(_filteredSongs.length)} • ${FormatUtils.formatDurationSummary(totalDuration)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildErrorState(theme)
            else if (_filteredSongs.isEmpty)
              _buildEmptyState(theme)
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = _filteredSongs[index];
                      return SongTile(
                        key: ValueKey(song.id),
                        song: song,
                        playlist: _filteredSongs,
                        index: index,
                        showAlbum: true,
                        showArtist: true,
                      );
                    },
                    childCount: _filteredSongs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: AppTheme.lightSecondaryText),
            const SizedBox(height: 16),
            Text(l10n.errorLoadingSongs, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadSongs,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off_outlined,
                size: 64, color: AppTheme.lightSecondaryText),
            const SizedBox(height: 16),
            Text(l10n.noSongsAvailable, style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class AllSongsScreen extends StatelessWidget {
  const AllSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SongCollectionScreen.allSongs();
  }
}

class SongsScreen extends StatelessWidget {
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SongCollectionScreen.madeForYou();
  }
}

class MadeForYouScreen extends StatelessWidget {
  const MadeForYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SongCollectionScreen.madeForYou();
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SongCollectionScreen.history();
  }
}
