import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../models/song.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/screen_helper.dart';
import '../../utils/ui_feedback.dart';
import '../modals/song_options_modal.dart';
import '../common/album_artwork.dart';

class QueueView extends StatefulWidget {
  const QueueView({super.key});

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  final ScrollController _scrollController = ScrollController();

  /// Only attached to the current song until the initial scroll is done: the
  /// reorder drag proxy rebuilds its item, which would duplicate the key.
  final GlobalKey _currentItemKey = GlobalKey();
  bool _initialScrollDone = false;
  double _headerClearance = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent([int attempt = 0]) {
    if (!mounted) return;
    final provider = Provider.of<PlayerProvider>(context, listen: false);
    if (provider.currentIndex <= 0 ||
        attempt > 3 ||
        !_scrollController.hasClients) {
      setState(() => _initialScrollDone = true);
      return;
    }

    final position = _scrollController.position;
    final itemContext = _currentItemKey.currentContext;
    if (itemContext == null) {
      // The list is lazy: jump close to the current song, using the list's
      // own estimate of its tile extent, so that its tile gets built.
      final extent = (position.maxScrollExtent + position.viewportDimension) /
          provider.queue.length;
      _scrollController.jumpTo((provider.currentIndex * extent)
          .clamp(0.0, position.maxScrollExtent));
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToCurrent(attempt + 1));
      return;
    }

    // Align the current song right below the header overlay.
    Scrollable.ensureVisible(itemContext);
    _scrollController.jumpTo((position.pixels - _headerClearance)
        .clamp(0.0, position.maxScrollExtent));
    setState(() => _initialScrollDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isApple = ScreenHelper.isApple(context);

    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final queue = provider.queue;
        final currentIndex = provider.currentIndex;

        if (queue.isEmpty) {
          final seed = provider.currentSong;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isApple
                        ? CupertinoIcons.music_note_list
                        : Icons.queue_music_rounded,
                    size: 48,
                    color: Colors.white30,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noSongsInQueue,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  if (seed != null) ...[
                    const SizedBox(height: 16),
                    _buildGenerateSongsButton(context, provider, l10n, seed),
                  ],
                ],
              ),
            ),
          );
        }

        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final view = View.of(context);
        final viewPadding = MediaQueryData.fromView(view).padding;
        final mediaQueryPadding = MediaQuery.of(context).padding;
        final topPadding =
            viewPadding.top > 0 ? viewPadding.top : mediaQueryPadding.top;
        final headerClearance = topPadding > 0
            ? topPadding + (isLandscape ? 44.0 : 64.0)
            : (isLandscape ? 48.0 : 56.0);
        _headerClearance = headerClearance;

        return SafeArea(
          top: false,
          child: ReorderableListView.builder(
            scrollController: _scrollController,
            buildDefaultDragHandles: false,
            padding: EdgeInsets.only(
              top: headerClearance,
              bottom: 40,
              left: 24,
              right: 24,
            ),
            header: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, left: 8.0),
              child: Text(
                l10n.upNext,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            footer: (queue.length == 1)
                ? _buildGenerateSongsButton(context, provider, l10n, queue.first)
                : null,
            itemCount: queue.length,
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              provider.reorderQueue(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final song = queue[index];
              final isPlaying = index == currentIndex;
              final isPast = index < currentIndex;

              return Dismissible(
                key: ValueKey('queue_item_${song.id}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF453A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        l10n.removeFromQueue,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isApple
                            ? CupertinoIcons.trash
                            : Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                onDismissed: (_) {
                  HapticFeedback.mediumImpact();
                  provider.removeFromQueue(index);
                },
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: KeyedSubtree(
                    key: isPlaying && !_initialScrollDone
                        ? _currentItemKey
                        : null,
                    child: AlbumArtwork(
                      coverArt: song.coverArt,
                      size: 48,
                      borderRadius: 8,
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      color: isPlaying
                          ? Theme.of(context).colorScheme.primary
                          : (isPast ? Colors.white38 : Colors.white),
                      fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist ?? l10n.unknownArtist,
                    style: TextStyle(
                      color: isPlaying
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.8)
                          : (isPast ? Colors.white24 : Colors.white70),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPlaying)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.equalizer_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          isApple
                              ? CupertinoIcons.minus_circle
                              : Icons.remove_circle_outline_rounded,
                          color: Colors.white60,
                          size: 20,
                        ),
                        tooltip: l10n.removeFromQueue,
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          provider.removeFromQueue(index);
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => SongOptionsModal.show(context, song),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 4, right: 2),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: Colors.white38,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    provider.skipToIndex(index);
                  },
                  onLongPress: () {
                    SongOptionsModal.show(context, song);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGenerateSongsButton(
    BuildContext context,
    PlayerProvider provider,
    AppLocalizations l10n,
    Song seedSong,
  ) {
    final theme = Theme.of(context);
    final isApple = ScreenHelper.isApple(context);
    final accentColor = theme.colorScheme.primary;
    final isLoading = provider.isGeneratingSimilarSongs;

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 20.0),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: const Cubic(0.23, 1, 0.32, 1),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      final added = await provider.generateSimilarSongs(
                        seedSong: seedSong,
                      );
                      if (context.mounted) {
                        if (added > 0) {
                          UiFeedback.showSuccess(
                            context,
                            l10n.similarSongsAdded(added),
                          );
                        } else {
                          UiFeedback.showInfo(
                            context,
                            l10n.noSimilarSongsFound,
                          );
                        }
                      }
                    },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: accentColor.withValues(alpha: 0.14),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(
                          isApple
                              ? CupertinoIcons.sparkles
                              : Icons.auto_awesome_rounded,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                    Text(
                      isLoading
                          ? l10n.generatingSimilarSongs
                          : l10n.generateMoreSongs,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
