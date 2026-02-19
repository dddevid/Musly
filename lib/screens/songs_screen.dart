import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/widgets.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    await libraryProvider.loadRandomSongs();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.songs),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            onPressed: () {
              final songs = libraryProvider.randomSongs;
              if (songs.isNotEmpty) {
                final playerProvider = Provider.of<PlayerProvider>(
                  context,
                  listen: false,
                );
                final shuffled = List<Song>.from(songs)..shuffle();
                playerProvider.playSong(
                  shuffled.first,
                  playlist: shuffled,
                  startIndex: 0,
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : libraryProvider.randomSongs.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.noSongsFound))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 150),
              itemCount: libraryProvider.randomSongs.length,
              itemBuilder: (context, index) {
                final song = libraryProvider.randomSongs[index];
                return SongTile(
                  song: song,
                  playlist: libraryProvider.randomSongs,
                  index: index,
                  showArtist: true,
                  showAlbum: true,
                );
              },
            ),
    );
  }
}
