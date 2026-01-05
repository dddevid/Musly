import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

class AllSongsScreen extends StatefulWidget {
  const AllSongsScreen({super.key});

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {}

  Future<void> _loadCachedData() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    setState(() {
      _songs = libraryProvider.cachedAllSongs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      bottomNavigationBar: const MiniPlayer(),
      appBar: AppBar(
        title: const Text('All Songs'),
        backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
        actions: [
          if (_songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shuffle),
              onPressed: () {},
              tooltip: 'Shuffle all',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No songs found',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_songs.length} songs',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      return SongTile(
                        song: _songs[index],
                        playlist: _songs,
                        index: index,
                        showAlbum: true,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
