import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:musly/l10n/app_localizations.dart';
import 'package:musly/services/discovery_service.dart';
import 'package:musly/services/lidarr_service.dart';

class DiscoverySheet extends StatefulWidget {
  final String artistName;
  final String? songTitle;

  const DiscoverySheet({
    super.key,
    required this.artistName,
    this.songTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String artistName,
    String? songTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiscoverySheet(
        artistName: artistName,
        songTitle: songTitle,
      ),
    );
  }

  @override
  State<DiscoverySheet> createState() => _DiscoverySheetState();
}

class _DiscoverySheetState extends State<DiscoverySheet> {
  final DiscoveryService _discovery = DiscoveryService();
  final LidarrService _lidarr = LidarrService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  String _currentArtist = '';
  List<DiscoveryArtist> _similarArtists = [];
  List<DiscoveryRelease> _releases = [];
  final Set<String> _addingToLidarrIds = {};
  final Set<String> _addedToLidarrIds = {};

  @override
  void initState() {
    super.initState();
    _currentArtist = widget.artistName;
    _searchCtrl.text = _currentArtist;
    _loadRecommendations(_currentArtist);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations(String artist) async {
    if (artist.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _currentArtist = artist.trim();
    });

    try {
      final data = await _discovery.getRecommendationsForArtist(_currentArtist);
      var releases = (data['recommendedReleases'] as List?)
              ?.cast<DiscoveryRelease>() ??
          [];

      // If no recommended releases found from similar artists, search direct releases
      if (releases.isEmpty) {
        releases = await _discovery.searchMusicBrainzReleases(_currentArtist);
      }

      if (mounted) {
        setState(() {
          _similarArtists = (data['similarArtists'] as List?)
                  ?.cast<DiscoveryArtist>() ??
              [];
          _releases = releases;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchCustom(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final releases = await _discovery.searchMusicBrainzReleases(query);
      final artists = await _discovery.searchMusicBrainzArtists(query);
      if (mounted) {
        setState(() {
          _releases = releases;
          _similarArtists = artists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendToLidarr(DiscoveryRelease release) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!_lidarr.isEnabled || _lidarr.apiKey.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.failedToSendToLidarr ??
                'Please configure Lidarr in Server Settings first',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _addingToLidarrIds.add(release.id));

    final albumPayload = {
      'foreignAlbumId': release.id,
      'title': release.title,
      'artistName': release.artist,
      'artist': {
        'artistName': release.artist,
      },
    };

    final result = await _lidarr.addAlbumToLidarr(albumPayload);

    if (mounted) {
      setState(() {
        _addingToLidarrIds.remove(release.id);
        if (result['success'] == true) {
          _addedToLidarrIds.add(release.id);
        }
      });

      final message = result['success'] == true
          ? (l10n?.sentToLidarr ?? 'Added to Lidarr! Starting search...')
          : '${l10n?.failedToSendToLidarr ?? "Error"}: ${result["error"]}';

      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.discoverSimilar ?? 'Music Discovery',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'MusicBrainz & ListenBrainz',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search artist or album...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  onPressed: () => _searchCustom(_searchCtrl.text),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
              onSubmitted: _searchCustom,
            ),
          ),
          if (_similarArtists.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n?.similarArtists ?? 'Similar Artists',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.hintColor,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _similarArtists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final artist = _similarArtists[idx];
                  final isSelected = artist.name.toLowerCase() ==
                      _currentArtist.toLowerCase();
                  return ActionChip(
                    label: Text(artist.name),
                    backgroundColor: isSelected
                        ? theme.colorScheme.primary
                        : theme.cardColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onPressed: () {
                      _searchCtrl.text = artist.name;
                      _loadRecommendations(artist.name);
                    },
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _releases.isEmpty
                    ? Center(
                        child: Text(
                          l10n?.noReleasesFound ?? 'No releases found',
                          style: TextStyle(color: theme.hintColor),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _releases.length,
                        itemBuilder: (context, index) {
                          final item = _releases[index];
                          final isAdding = _addingToLidarrIds.contains(item.id);
                          final isAdded = _addedToLidarrIds.contains(item.id);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 0,
                            color: theme.cardColor.withValues(alpha: 0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: item.coverUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: item.coverUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              Container(
                                            color: theme.colorScheme.surface,
                                            child: const Icon(
                                              Icons.album_rounded,
                                              size: 24,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: theme.colorScheme.surface,
                                          child: const Icon(
                                            Icons.album_rounded,
                                            size: 24,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${item.artist}${item.releaseDate != null ? " • ${item.releaseDate!.split('-').first}" : ""}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isAdded
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : theme.colorScheme.primary
                                          .withValues(alpha: 0.15),
                                  foregroundColor: isAdded
                                      ? Colors.green
                                      : theme.colorScheme.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                icon: isAdding
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        isAdded
                                            ? Icons.check_circle_rounded
                                            : Icons.cloud_download_rounded,
                                        size: 16,
                                      ),
                                label: Text(
                                  isAdded
                                      ? 'Added'
                                      : (l10n?.sendToLidarr ?? 'Lidarr'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: (isAdding || isAdded)
                                    ? null
                                    : () => _handleSendToLidarr(item),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
