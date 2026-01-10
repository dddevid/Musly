import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../widgets/widgets.dart';
import '../widgets/mini_player.dart';
import 'album_screen.dart';
import 'artist_screen.dart';
import 'genres_screen.dart';
import 'new_releases_screen.dart';
import 'made_for_you_screen.dart';
import 'top_rated_screen.dart';
import 'favorites_screen.dart';
import 'radio_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  SearchResult? _searchResult;
  SearchResult? _autocompleteSuggestions;
  bool _isSearching = false;
  bool _isLoadingSuggestions = false;
  bool _showSuggestions = false;
  String _query = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAutocomplete(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _autocompleteSuggestions = null;
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _showSuggestions = true;
    });

    try {
      final libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );
      final result = await libraryProvider.search(query);
      if (mounted && _searchController.text.trim() == query.trim()) {
        setState(() {
          _autocompleteSuggestions = result;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    if (value.isEmpty) {
      setState(() {
        _searchResult = null;
        _autocompleteSuggestions = null;
        _showSuggestions = false;
        _query = '';
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadAutocomplete(value);
    });
  }

  void _selectSuggestion(String query) {
    _searchController.text = query;
    setState(() {
      _showSuggestions = false;
    });
    _search(query);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResult = null;
        _query = '';
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _query = query;
      _showSuggestions = false;
    });

    try {
      final libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );
      final result = await libraryProvider.search(query);
      if (mounted && _query == query) {
        setState(() {
          _searchResult = result;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Search',
                    style: theme.appBarTheme.titleTextStyle,
                  ),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 60),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      placeholder: 'Artists, Songs, Albums',
                      style: theme.textTheme.bodyLarge,
                      backgroundColor: isDark
                          ? AppTheme.darkCard
                          : AppTheme.lightBackground,
                      onChanged: _onSearchChanged,
                      onSubmitted: (value) {
                        setState(() => _showSuggestions = false);
                        _search(value);
                      },
                    ),
                  ),
                ),
              ),
              if (_isSearching)
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              'Albums',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      HorizontalShimmerList(
                        count: 3,
                        child: const AlbumCardShimmer(size: 150),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              'Songs',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...List.generate(5, (_) => const SongTileShimmer()),
                    ],
                  ),
                )
              else if (_searchResult != null && !_searchResult!.isEmpty)
                SliverToBoxAdapter(child: _buildSearchResults())
              else if (_query.isNotEmpty && _searchResult?.isEmpty == true)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 64,
                          color: AppTheme.lightSecondaryText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Results',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(child: _buildBrowseCategories()),
            ],
          ),
          // Autocomplete suggestions overlay
          if (_showSuggestions && _searchController.text.isNotEmpty)
            Positioned(
              top: 120 + 56 + 8,
              left: 16,
              right: 16,
              child: _buildAutocompleteOverlay(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final result = _searchResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.artists.isNotEmpty) ...[
          const SectionHeader(title: 'Artists'),
          ...result.artists
              .take(5)
              .map(
                (artist) => ArtistTile(
                  artist: artist,
                  onTap: () => NavigationHelper.push(
                    context,
                    ArtistScreen(artistId: artist.id),
                  ),
                ),
              ),
          const SizedBox(height: 16),
        ],

        if (result.albums.isNotEmpty) ...[
          HorizontalScrollSection(
            title: 'Albums',
            children: result.albums
                .take(10)
                .map(
                  (album) => AlbumCard(
                    album: album,
                    size: 150,
                    onTap: () => NavigationHelper.push(
                      context,
                      AlbumScreen(albumId: album.id),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        if (result.songs.isNotEmpty) ...[
          const SectionHeader(title: 'Songs'),
          ...result.songs.asMap().entries.map(
            (entry) => SongTile(
              song: entry.value,
              playlist: result.songs,
              index: entry.key,
              showArtist: true,
              showAlbum: true,
            ),
          ),
        ],

        const SizedBox(height: 150),
      ],
    );
  }

  Widget _buildBrowseCategories() {
    final categories = [
      _CategoryItem(
        'Made For You',
        Icons.person_outline_rounded,
        [Colors.purple, Colors.pink],
        () => NavigationHelper.push(context, const MadeForYouScreen()),
      ),
      _CategoryItem(
        'New Releases',
        Icons.album_rounded,
        [Colors.orange, Colors.red],
        () => NavigationHelper.push(context, const NewReleasesScreen()),
      ),
      _CategoryItem(
        'Top Rated',
        Icons.star_rounded,
        [Colors.amber, Colors.orange],
        () => NavigationHelper.push(context, const TopRatedScreen()),
      ),
      _CategoryItem(
        'Genres',
        Icons.library_music_rounded,
        [Colors.green, Colors.teal],
        () => NavigationHelper.push(context, const GenresScreen()),
      ),
      _CategoryItem(
        'Favorites',
        Icons.favorite_rounded,
        [Colors.red, Colors.pink],
        () => NavigationHelper.push(context, const FavoritesScreen()),
      ),
      _CategoryItem(
        'Radio',
        Icons.radio_rounded,
        [Colors.blue, Colors.indigo],
        () => NavigationHelper.push(context, const RadioScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Browse Categories'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(category: category);
            },
          ),
        ),
        const SizedBox(height: 150),
      ],
    );
  }

  Widget _buildAutocompleteOverlay(bool isDark) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: isDark ? AppTheme.darkCard : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            width: 1,
          ),
        ),
        child: _isLoadingSuggestions
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : _autocompleteSuggestions == null ||
                  _autocompleteSuggestions!.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No suggestions',
                    style: TextStyle(
                      color: AppTheme.lightSecondaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_autocompleteSuggestions!.artists.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          'Artists',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightSecondaryText,
                          ),
                        ),
                      ),
                      ..._autocompleteSuggestions!.artists.map(
                        (artist) => ListTile(
                          dense: true,
                          leading: Icon(
                            CupertinoIcons.person,
                            size: 20,
                            color: AppTheme.appleMusicRed,
                          ),
                          title: Text(
                            artist.name,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            setState(() => _showSuggestions = false);
                            NavigationHelper.push(
                              context,
                              ArtistScreen(artistId: artist.id),
                            );
                          },
                        ),
                      ),
                    ],
                    if (_autocompleteSuggestions!.albums.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          'Albums',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightSecondaryText,
                          ),
                        ),
                      ),
                      ..._autocompleteSuggestions!.albums.map(
                        (album) => ListTile(
                          dense: true,
                          leading: Icon(
                            CupertinoIcons.music_albums,
                            size: 20,
                            color: AppTheme.appleMusicRed,
                          ),
                          title: Text(
                            album.name,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: album.artist != null
                              ? Text(
                                  album.artist!,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () {
                            setState(() => _showSuggestions = false);
                            NavigationHelper.push(
                              context,
                              AlbumScreen(albumId: album.id),
                            );
                          },
                        ),
                      ),
                    ],
                    if (_autocompleteSuggestions!.songs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          'Songs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightSecondaryText,
                          ),
                        ),
                      ),
                      ..._autocompleteSuggestions!.songs.map(
                        (song) => ListTile(
                          dense: true,
                          leading: Icon(
                            CupertinoIcons.music_note,
                            size: 20,
                            color: AppTheme.appleMusicRed,
                          ),
                          title: Text(
                            song.title,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: song.artist != null
                              ? Text(
                                  song.artist!,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () {
                            setState(() => _showSuggestions = false);
                            final playerProvider = Provider.of<PlayerProvider>(
                              context,
                              listen: false,
                            );
                            playerProvider.playSong(
                              song,
                              playlist: _autocompleteSuggestions!.songs,
                              startIndex: _autocompleteSuggestions!.songs
                                  .indexOf(song),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CategoryItem {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  _CategoryItem(this.title, this.icon, this.colors, this.onTap);
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: category.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: category.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(category.icon, color: Colors.white, size: 24),
                const Spacer(),
                Text(
                  category.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
