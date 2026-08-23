import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/album.dart';
import '../../services/subsonic_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/screen_helper.dart';
import '../../widgets/widgets.dart';
import '../detail/album_screen.dart';

enum AlbumCollectionType {
  recent,
  newest,
  topRated,
  starred,
  custom,
}

/// Unified, responsive screen for displaying collections of albums (New Releases, Top Rated, Starred, Recent, etc.)
class AlbumCollectionScreen extends StatefulWidget {
  final AlbumCollectionType type;
  final String? customTitle;
  final List<Album>? initialAlbums;
  final Future<List<Album>> Function(BuildContext context)? customFetcher;

  const AlbumCollectionScreen({
    super.key,
    required this.type,
    this.customTitle,
    this.initialAlbums,
    this.customFetcher,
  });

  /// Factory constructor for New Releases
  const AlbumCollectionScreen.newReleases({super.key})
      : type = AlbumCollectionType.newest,
        customTitle = null,
        initialAlbums = null,
        customFetcher = null;

  /// Factory constructor for Top Rated
  const AlbumCollectionScreen.topRated({super.key})
      : type = AlbumCollectionType.topRated,
        customTitle = null,
        initialAlbums = null,
        customFetcher = null;

  /// Factory constructor for Starred / Liked Albums
  const AlbumCollectionScreen.starred({super.key})
      : type = AlbumCollectionType.starred,
        customTitle = null,
        initialAlbums = null,
        customFetcher = null;

  /// Factory constructor for Recent Albums
  const AlbumCollectionScreen.recent({super.key})
      : type = AlbumCollectionType.recent,
        customTitle = null,
        initialAlbums = null,
        customFetcher = null;

  @override
  State<AlbumCollectionScreen> createState() => _AlbumCollectionScreenState();
}

class _AlbumCollectionScreenState extends State<AlbumCollectionScreen> {
  List<Album>? _albums;
  List<Album>? _filteredAlbums;
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAlbums != null) {
      _albums = widget.initialAlbums;
      _filteredAlbums = widget.initialAlbums;
      _isLoading = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAlbums();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbums() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Album> albums = [];
      if (widget.customFetcher != null) {
        albums = await widget.customFetcher!(context);
      } else {
        final subsonic = Provider.of<SubsonicService>(context, listen: false);

        switch (widget.type) {
          case AlbumCollectionType.newest:
            albums = await subsonic.getAlbumList(type: 'newest', size: 60);
            break;
          case AlbumCollectionType.topRated:
            albums = await subsonic.getAlbumList(type: 'highest', size: 60);
            break;
          case AlbumCollectionType.starred:
            final starred = await subsonic.getStarred();
            albums = starred.albums;
            break;
          case AlbumCollectionType.recent:
            albums = await subsonic.getAlbumList(type: 'recent', size: 60);
            break;
          case AlbumCollectionType.custom:
            albums = widget.initialAlbums ?? [];
            break;
        }
      }

      if (mounted) {
        setState(() {
          _albums = albums;
          _applyFilter(_searchQuery);
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

  void _applyFilter(String query) {
    _searchQuery = query;
    if (_albums == null) {
      _filteredAlbums = null;
      return;
    }
    if (query.trim().isEmpty) {
      _filteredAlbums = List.from(_albums!);
    } else {
      final q = query.toLowerCase();
      _filteredAlbums = _albums!.where((a) {
        return a.name.toLowerCase().contains(q) ||
            (a.artist?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
  }

  String _getTitle(BuildContext context) {
    if (widget.customTitle != null && widget.customTitle!.isNotEmpty) {
      return widget.customTitle!;
    }
    final l10n = AppLocalizations.of(context);
    switch (widget.type) {
      case AlbumCollectionType.newest:
        return l10n?.categoryNewReleases ?? 'New Releases';
      case AlbumCollectionType.topRated:
        return l10n?.topRated ?? 'Top Rated';
      case AlbumCollectionType.starred:
        return l10n?.likedAlbums ?? 'Liked Albums';
      case AlbumCollectionType.recent:
        return l10n?.albums ?? 'Albums';
      case AlbumCollectionType.custom:
        return 'Albums';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _getTitle(context);
    final isDesktop = ScreenHelper.isDesktop(context);

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadAlbums,
            child: CustomScrollView(
              controller: _scrollController,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    titlePadding: EdgeInsets.only(
                      left: isDesktop ? 64 : 52,
                      bottom: 16,
                    ),
                  ),
                ),
                if (_isLoading)
                  _buildLoadingGrid(context)
                else if (_error != null)
                  _buildErrorState(theme)
                else if (_filteredAlbums == null || _filteredAlbums!.isEmpty)
                  _buildEmptyState(theme)
                else
                  _buildAlbumGrid(context),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          if (!_isLoading && _filteredAlbums != null && _filteredAlbums!.length >= 8)
            _buildAlphabetSidebar(context),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid(BuildContext context) {
    final columns = _getColumnCount(context);
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const AlbumCardShimmer(size: double.infinity),
          childCount: columns * 4,
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.lightSecondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading albums',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadAlbums,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.album_outlined,
              size: 64,
              color: AppTheme.lightSecondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              'No albums found',
              style: theme.textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumGrid(BuildContext context) {
    final columns = _getColumnCount(context);
    final albums = _filteredAlbums!;

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.76,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final album = albums[index];
            return AlbumCard(
              album: album,
              size: double.infinity,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumScreen(albumId: album.id),
                  ),
                );
              },
            );
          },
          childCount: albums.length,
        ),
      ),
    );
  }

  int _getColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 900) return 5;
    if (width > 600) return 3;
    return 2;
  }

  void _scrollToLetter(String letter) {
    if (_filteredAlbums == null || _filteredAlbums!.isEmpty) return;

    int targetIndex = -1;
    if (letter == '#') {
      targetIndex = _filteredAlbums!.indexWhere((a) {
        final first = a.name.trim().isNotEmpty ? a.name.trim()[0].toUpperCase() : '';
        return first.isNotEmpty && !RegExp(r'[A-Z]').hasMatch(first);
      });
    } else {
      targetIndex = _filteredAlbums!.indexWhere((a) {
        return a.name.trim().toUpperCase().startsWith(letter);
      });
    }

    if (targetIndex >= 0 && _scrollController.hasClients) {
      final columns = _getColumnCount(context);
      final width = MediaQuery.of(context).size.width;
      final itemWidth = (width - 32 - (columns - 1) * 16) / columns;
      final itemHeight = itemWidth / 0.76 + 16;
      final row = targetIndex ~/ columns;
      final targetOffset = (row * itemHeight).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildAlphabetSidebar(BuildContext context) {
    final alphabet = List.generate(26, (i) => String.fromCharCode(65 + i))..add('#');

    return Positioned(
      right: 4,
      top: 130,
      bottom: 90,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: alphabet.map((letter) {
                return InkWell(
                  onTap: () => _scrollToLetter(letter),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 4),
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility wrapper for LikedAlbumsScreen
class LikedAlbumsScreen extends StatelessWidget {
  const LikedAlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlbumCollectionScreen.starred();
  }
}

/// Backward compatibility wrapper for NewReleasesScreen
class NewReleasesScreen extends StatelessWidget {
  const NewReleasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlbumCollectionScreen.newReleases();
  }
}

/// Backward compatibility wrapper for TopRatedScreen
class TopRatedScreen extends StatelessWidget {
  const TopRatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlbumCollectionScreen.topRated();
  }
}

/// Backward compatibility wrapper for AlbumsScreen
class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlbumCollectionScreen.recent();
  }
}
