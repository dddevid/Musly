import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:musly/models/models.dart';
import 'package:musly/providers/library_provider.dart';
import 'package:musly/providers/player_provider.dart';
import 'package:musly/providers/auth_provider.dart';
import 'package:musly/services/subsonic_service.dart';
import 'package:musly/theme/app_theme.dart';
import 'package:musly/utils/navigation_helper.dart';
import 'package:musly/widgets/widgets.dart';
import 'package:musly/screens/detail/album_screen.dart';
import 'package:musly/screens/detail/artist_screen.dart';
import 'package:musly/screens/detail/playlist_screen.dart';
import 'package:musly/screens/media/genres_screen.dart';
import 'package:musly/screens/media/album_collection_screen.dart';
import 'package:musly/screens/media/song_collection_screen.dart';
import 'package:musly/screens/media/favorites_screen.dart';
import 'package:musly/screens/media/radio_screen.dart';
import 'package:musly/services/player_ui_settings_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  SearchResult? _searchResult;
  bool _isSearching = false;
  String _selectedFilter = 'All'; // 'All' | 'Songs' | 'Artists' | 'Albums' | 'Playlists'
  Timer? _debounceTimer;
  final List<String> _recentQueries = [];

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    PlayerUiSettingsService().liveSearchNotifier.addListener(_onLiveSearchChanged);
  }

  void _onLiveSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    PlayerUiSettingsService().liveSearchNotifier.removeListener(_onLiveSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _searchResult = null;
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _performSearch(value.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      final result = await libraryProvider.search(query);

      if (mounted && _searchController.text.trim() == query) {
        setState(() {
          _searchResult = result;
          _isSearching = false;
          if (!_recentQueries.contains(query)) {
            _recentQueries.insert(0, query);
            if (_recentQueries.length > 8) _recentQueries.removeLast();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResult = null;
      _isSearching = false;
    });
  }

  void _playSong(Song song, [List<Song>? queue]) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    if (subsonic.isYoutube || playerProvider.autoDjService.isEnabled) {
      playerProvider.playSongWithRadio(song);
    } else {
      playerProvider.playSong(song, playlist: [song], startIndex: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = _isDesktop ? 32.0 : 16.0;
    final query = _searchController.text.trim();
    final hasResults = _searchResult != null && query.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Spotify Large Search Header
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            floating: false,
            expandedHeight: 140,
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: hPad, bottom: 62),
              title: Text(
                'Search',
                style: TextStyle(
                  fontSize: _isDesktop ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    onSubmitted: (v) => _performSearch(v.trim()),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What do you want to play?',
                      hintStyle: TextStyle(
                        color: Colors.black.withValues(alpha: 0.6),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        CupertinoIcons.search,
                        color: Colors.black87,
                        size: 22,
                      ),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(CupertinoIcons.clear_circled_solid, color: Colors.black54, size: 20),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Search Filter Pills (When Results are Active)
          if (hasResults)
            SliverToBoxAdapter(
              child: Container(
                height: 44,
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFilterChip('All', 'All', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Songs', 'Songs', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Artists', 'Artists', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Albums', 'Albums', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Playlists', 'Playlists', isDark),
                  ],
                ),
              ),
            ),

          // Body Content
          SliverToBoxAdapter(
            child: _isSearching
                ? _buildSearchingState()
                : hasResults
                    ? _buildSearchResults(hPad, isDark)
                    : _buildBrowseAllSection(hPad, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1DB954)
              : (isDark ? const Color(0xFF282828) : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1DB954),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildBrowseAllSection(double hPad, bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context);
    final subsonicService = Provider.of<SubsonicService>(context);
    final isYoutube = subsonicService.isYoutube || authProvider.config?.isYoutube == true;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches if any
          if (_recentQueries.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent searches',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _recentQueries.clear()),
                  child: const Text('Clear', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentQueries.map((q) {
                return InputChip(
                  label: Text(q),
                  onPressed: () {
                    _searchController.text = q;
                    _performSearch(q);
                  },
                  onDeleted: () => setState(() => _recentQueries.remove(q)),
                  backgroundColor: isDark ? const Color(0xFF282828) : Colors.grey[200],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // "Browse all" Title
          const Text(
            'Browse all',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // 2-Column Responsive Spotify Grid of Angled Category Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = _isDesktop ? 4 : 2;
              final spacing = 12.0;
              final cardWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: SpotifyBrowseCard(
                      title: 'Made For You',
                      gradientColors: const [Color(0xFF1E3264), Color(0xFF283EA3)],
                      icon: CupertinoIcons.sparkles,
                      onTap: () => NavigationHelper.push(context, const MadeForYouScreen()),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SpotifyBrowseCard(
                      title: 'New Releases',
                      gradientColors: const [Color(0xFFE8115B), Color(0xFFFF4081)],
                      icon: CupertinoIcons.flame_fill,
                      onTap: () => NavigationHelper.push(context, const NewReleasesScreen()),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SpotifyBrowseCard(
                      title: 'Top Rated',
                      gradientColors: const [Color(0xFF8D67AB), Color(0xFFBA68C8)],
                      icon: CupertinoIcons.star_fill,
                      onTap: () => NavigationHelper.push(context, const TopRatedScreen()),
                    ),
                  ),
                  if (!isYoutube)
                    SizedBox(
                      width: cardWidth,
                      child: SpotifyBrowseCard(
                        title: 'Radio Stations',
                        gradientColors: const [Color(0xFF148A08), Color(0xFF43A047)],
                        icon: CupertinoIcons.antenna_radiowaves_left_right,
                        onTap: () => NavigationHelper.push(context, const RadioScreen()),
                      ),
                    ),
                  SizedBox(
                    width: cardWidth,
                    child: SpotifyBrowseCard(
                      title: 'Genres & Moods',
                      gradientColors: const [Color(0xFFE91429), Color(0xFFFF5252)],
                      icon: CupertinoIcons.music_albums_fill,
                      onTap: () => NavigationHelper.push(context, const GenresScreen()),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SpotifyBrowseCard(
                      title: 'Liked Songs',
                      gradientColors: const [Color(0xFF450AF5), Color(0xFF8E8EE5)],
                      icon: CupertinoIcons.heart_fill,
                      onTap: () => NavigationHelper.push(context, const FavoritesScreen()),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SpotifyBrowseCard(
                      title: 'Pop & Hits',
                      gradientColors: const [Color(0xFF006450), Color(0xFF00897B)],
                      icon: CupertinoIcons.music_mic,
                      onTap: () {
                        _searchController.text = 'Pop';
                        _performSearch('Pop');
                      },
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SpotifyBrowseCard(
                      title: 'Hip-Hop & Rap',
                      gradientColors: const [Color(0xFFBC5900), Color(0xFFFB8C00)],
                      icon: CupertinoIcons.speaker_3_fill,
                      onTap: () {
                        _searchController.text = 'Hip-Hop';
                        _performSearch('Hip-Hop');
                      },
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SpotifyBrowseCard(
                      title: 'Rock & Alt',
                      gradientColors: const [Color(0xFF7358FF), Color(0xFF9575CD)],
                      icon: CupertinoIcons.guitars,
                      onTap: () {
                        _searchController.text = 'Rock';
                        _performSearch('Rock');
                      },
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: SpotifyBrowseCard(
                      title: 'Chill & Relax',
                      gradientColors: const [Color(0xFF503750), Color(0xFF8E24AA)],
                      icon: CupertinoIcons.moon_stars_fill,
                      onTap: () {
                        _searchController.text = 'Chill';
                        _performSearch('Chill');
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(double hPad, bool isDark) {
    final result = _searchResult!;
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final subsonicService = Provider.of<SubsonicService>(context, listen: false);

    final query = _searchController.text.toLowerCase().trim();
    final songs = result.songs;
    final artists = result.artists;
    final albums = result.albums;
    final playlists = libraryProvider.playlists
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();

    if (songs.isEmpty && artists.isEmpty && albums.isEmpty && playlists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: Column(
            children: [
              const Icon(CupertinoIcons.search, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'No results found for "${_searchController.text}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please check your spelling or try another query.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Result Card (Signature Spotify Search feature)
          if (_selectedFilter == 'All' || _selectedFilter == 'Songs') ...[
            if (songs.isNotEmpty || artists.isNotEmpty || albums.isNotEmpty) ...[
              const Text(
                'Top result',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (artists.isNotEmpty && (_selectedFilter == 'All' || _selectedFilter == 'Artists'))
                _buildArtistTopResult(artists.first, subsonicService)
              else if (songs.isNotEmpty)
                _buildSongTopResult(songs.first, songs, subsonicService)
              else if (albums.isNotEmpty)
                _buildAlbumTopResult(albums.first, subsonicService),

              const SizedBox(height: 24),
            ],
          ],

          // 2. Songs List
          if ((_selectedFilter == 'All' || _selectedFilter == 'Songs') && songs.isNotEmpty) ...[
            const Text(
              'Songs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...songs.take(_selectedFilter == 'All' ? 5 : 20).map((song) {
              return SongTile(
                song: song,
                onTap: () => _playSong(song, songs),
              );
            }),
            const SizedBox(height: 24),
          ],

          // 3. Artists Carousel (Circular Avatars)
          if ((_selectedFilter == 'All' || _selectedFilter == 'Artists') && artists.isNotEmpty) ...[
            HorizontalScrollSection(
              title: 'Artists',
              padding: EdgeInsets.zero,
              cardSize: _isDesktop ? 160 : 140,
              children: artists.map((artist) {
                final coverArt = artist.coverArt ??
                    artist.artistImageUrl ??
                    (artist.id.isNotEmpty ? 'ar-${artist.id}' : null);
                return SpotifyLikeCard(
                  title: artist.name,
                  subtitle: 'Artist',
                  coverArt: coverArt,
                  isRound: true,
                  size: _isDesktop ? 160 : 140,
                  onTap: () => NavigationHelper.push(
                    context,
                    ArtistScreen(artistId: artist.id),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // 4. Albums Grid / Carousel
          if ((_selectedFilter == 'All' || _selectedFilter == 'Albums') && albums.isNotEmpty) ...[
            HorizontalScrollSection(
              title: 'Albums',
              padding: EdgeInsets.zero,
              cardSize: _isDesktop ? 175 : 150,
              children: albums.map((album) {
                return SpotifyLikeCard(
                  title: album.name,
                  subtitle: album.artist,
                  coverArt: album.coverArt,
                  size: _isDesktop ? 175 : 150,
                  onTap: () => NavigationHelper.push(
                    context,
                    AlbumScreen(albumId: album.id),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // 5. Playlists
          if ((_selectedFilter == 'All' || _selectedFilter == 'Playlists') && playlists.isNotEmpty) ...[
            HorizontalScrollSection(
              title: 'Playlists',
              padding: EdgeInsets.zero,
              cardSize: _isDesktop ? 175 : 150,
              children: playlists.map((playlist) {
                return SpotifyLikeCard(
                  title: playlist.name,
                  subtitle: 'Playlist • Musly',
                  coverArt: playlist.coverArt,
                  size: _isDesktop ? 175 : 150,
                  onTap: () => NavigationHelper.push(
                    context,
                    PlaylistScreen(playlistId: playlist.id, playlistName: playlist.name),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSongTopResult(Song song, List<Song> queue, SubsonicService subsonicService) {
    return SpotifyTopResultCard(
      title: song.title,
      subtitle: song.artist ?? 'Unknown Artist',
      typeLabel: 'Song',
      imageUrl: song.coverArt,
      onTap: () => _playSong(song, queue),
      onPlayPressed: () => _playSong(song, queue),
    );
  }

  Widget _buildArtistTopResult(Artist artist, SubsonicService subsonicService) {
    final coverArt = artist.coverArt ??
        artist.artistImageUrl ??
        (artist.id.isNotEmpty ? 'ar-${artist.id}' : null);
    return SpotifyTopResultCard(
      title: artist.name,
      subtitle: 'Artist',
      typeLabel: 'Artist',
      isArtist: true,
      imageUrl: coverArt,
      onTap: () => NavigationHelper.push(
        context,
        ArtistScreen(artistId: artist.id),
      ),
      onPlayPressed: () => NavigationHelper.push(
        context,
        ArtistScreen(artistId: artist.id),
      ),
    );
  }

  Widget _buildAlbumTopResult(Album album, SubsonicService subsonicService) {
    return SpotifyTopResultCard(
      title: album.name,
      subtitle: 'Album • ${album.artist}',
      typeLabel: 'Album',
      imageUrl: album.coverArt,
      onTap: () => NavigationHelper.push(
        context,
        AlbumScreen(albumId: album.id),
      ),
      onPlayPressed: () => NavigationHelper.push(
        context,
        AlbumScreen(albumId: album.id),
      ),
    );
  }
}