import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../widgets/widgets.dart';
import 'artist_screen.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    await libraryProvider.loadArtists();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Artists')),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.only(bottom: 150),
              itemCount: 10,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ArtistCardShimmer(size: 60),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [SizedBox(height: 8)],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : libraryProvider.artists.isEmpty
          ? const Center(child: Text('No artists found'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 150),
              itemCount: libraryProvider.artists.length,
              itemBuilder: (context, index) {
                final artist = libraryProvider.artists[index];
                return ArtistTile(
                  artist: artist,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArtistScreen(artistId: artist.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}