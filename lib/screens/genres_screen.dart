import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/genre.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import 'genre_screen.dart';

class GenresScreen extends StatefulWidget {
  const GenresScreen({super.key});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  List<Genre>? _genres;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    try {
      final libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );
      await libraryProvider.loadGenres();
      if (mounted) {
        setState(() {
          _genres = libraryProvider.richGenres;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(l10n.genres, style: theme.appBarTheme.titleTextStyle),
              titlePadding: const EdgeInsets.only(left: 52, bottom: 16),
            ),
          ),
          if (_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    12,
                    (_) => Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.lightDivider,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.lightSecondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.errorLoadingGenres,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        _loadGenres();
                      },
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            )
          else if (_genres == null || _genres!.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_music,
                      size: 64,
                      color: AppTheme.lightSecondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noGenresFound,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _genres!
                      .map((genre) => _GenreChip(genre: genre))
                      .toList(),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final Genre genre;

  const _GenreChip({required this.genre});

  Color _getGenreColor(String value) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];
    final index = value.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGenreColor(genre.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: l10n.genreTooltip(genre.songCount, genre.albumCount),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            NavigationHelper.push(context, GenreScreen(genre: genre.value));
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  genre.value,
                  style: TextStyle(
                    color: isDark ? color.withValues(alpha: 0.9) : color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (genre.songCount > 0)
                  Text(
                    l10n.songsCount(genre.songCount),
                    style: TextStyle(
                      color: (isDark ? color.withValues(alpha: 0.9) : color)
                          .withValues(alpha: 0.7),
                      fontSize: 11,
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
