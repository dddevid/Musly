import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';
import 'artist_screen.dart';
import 'genres_screen.dart';
import 'new_releases_screen.dart';
import 'made_for_you_screen.dart';
import 'top_rated_screen.dart';
import 'favorites_screen.dart';

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
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResult = null;
        _query = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _query = query;
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Search', style: theme.appBarTheme.titleTextStyle),
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
                  onChanged: (value) {
                    if (value.isEmpty) {
                      setState(() {
                        _searchResult = null;
                        _query = '';
                      });
                    }
                  },
                  onSubmitted: _search,
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
                    Text('No Results', style: theme.textTheme.headlineMedium),
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArtistScreen(artistId: artist.id),
                    ),
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlbumScreen(albumId: album.id),
                      ),
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
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MadeForYouScreen()),
        ),
      ),
      _CategoryItem(
        'New Releases',
        Icons.album_rounded,
        [Colors.orange, Colors.red],
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewReleasesScreen()),
        ),
      ),
      _CategoryItem(
        'Top Rated',
        Icons.star_rounded,
        [Colors.amber, Colors.orange],
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TopRatedScreen()),
        ),
      ),
      _CategoryItem(
        'Genres',
        Icons.library_music_rounded,
        [Colors.green, Colors.teal],
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GenresScreen()),
        ),
      ),
      _CategoryItem(
        'Favorites',
        Icons.favorite_rounded,
        [Colors.red, Colors.pink],
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
        ),
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