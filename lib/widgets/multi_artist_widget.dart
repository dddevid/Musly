import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/artist_ref.dart';
import '../screens/artist_screen.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';
import 'album_artwork.dart';

/// Displays a list of artists as "Artist 1, Artist 2, …".
///
/// Behavior differs by platform:
/// - **Desktop**: each artist name is an individually-clickable underlined link.
/// - **Mobile / single artist**: tapping the whole row opens a bottom sheet
///   (for multiple artists) or navigates directly (for a single artist).
///
/// Falls back gracefully when [artists] is null (non-Navidrome Subsonic servers):
/// the [artistFallback] string is shown as a single clickable item that
/// navigates via [artistIdFallback].
class MultiArtistWidget extends StatelessWidget {
  /// Parsed artist list from Navidrome's `participants` field. Optional.
  final List<ArtistRef>? artists;

  /// The raw artist string from the standard Subsonic `artist` field.
  /// Used when [artists] is null.
  final String? artistFallback;

  /// The primary `artistId` from the Subsonic response, used as navigation
  /// target when [artists] is null.
  final String? artistIdFallback;

  /// Text style applied to artist names.
  final TextStyle? style;

  /// Called synchronously just before navigating away (e.g. to pop a modal
  /// screen before pushing the artist screen).
  final VoidCallback? onBeforeNavigate;

  const MultiArtistWidget({
    super.key,
    this.artists,
    this.artistFallback,
    this.artistIdFallback,
    this.style,
    this.onBeforeNavigate,
  });

  static bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  List<ArtistRef> _effectiveArtists() {
    if (artists != null && artists!.isNotEmpty) return artists!;
    final name = artistFallback;
    final id = artistIdFallback;
    if (name != null || id != null) {
      return [ArtistRef(id: id ?? '', name: name ?? '')];
    }
    return [];
  }

  void _navigate(BuildContext context, ArtistRef artist) {
    if (artist.id.isNotEmpty) {
      final navigator = Navigator.of(context);
      onBeforeNavigate?.call();
      navigator.push(MaterialPageRoute(
        builder: (_) => ArtistScreen(artistId: artist.id),
      ));
    } else if (artist.name.isNotEmpty) {
      _searchAndNavigate(context, artist.name);
    }
  }

  Future<void> _searchAndNavigate(BuildContext context, String name) async {
    final navigator = Navigator.of(context);
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    try {
      final result = await subsonic.search(
        name,
        artistCount: 5,
        albumCount: 0,
        songCount: 0,
      );
      if (!context.mounted) return;
      if (result.artists.isNotEmpty) {
        final matched = result.artists.firstWhere(
          (a) => a.name.toLowerCase() == name.toLowerCase(),
          orElse: () => result.artists.first,
        );
        onBeforeNavigate?.call();
        navigator.push(MaterialPageRoute(
          builder: (_) => ArtistScreen(artistId: matched.id),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.artistNotFound(name),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorSearchingArtist(e),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showArtistsSheet(BuildContext context, List<ArtistRef> artistList) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ArtistsBottomSheet(
        artists: artistList,
        onArtistTap: (artist) {
          Navigator.pop(ctx);
          _navigate(context, artist);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveArtists = _effectiveArtists();

    if (effectiveArtists.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.unknownArtist,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (effectiveArtists.length == 1) {
      final artist = effectiveArtists.first;
      final clickable = artist.id.isNotEmpty || artist.name.isNotEmpty;
      return MouseRegion(
        cursor: clickable ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: clickable ? () => _navigate(context, artist) : null,
          child: Text(
            artist.name,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // Multiple artists
    if (_isDesktop) {
      return Wrap(
        children: [
          for (int i = 0; i < effectiveArtists.length; i++) ...[
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _navigate(context, effectiveArtists[i]),
                child: Text(
                  effectiveArtists[i].name,
                  style: style?.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: (style?.color ?? Colors.white)
                        .withValues(alpha: 0.45),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (i < effectiveArtists.length - 1) Text(', ', style: style),
          ],
        ],
      );
    }

    // Mobile: whole line opens bottom sheet
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showArtistsSheet(context, effectiveArtists),
        child: Text(
          effectiveArtists.map((a) => a.name).join(', '),
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class ArtistsBottomSheet extends StatelessWidget {
  final List<ArtistRef> artists;
  final void Function(ArtistRef) onArtistTap;

  const ArtistsBottomSheet({
    super.key,
    required this.artists,
    required this.onArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.artists,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: artists.length,
                itemBuilder: (_, i) {
                  final artist = artists[i];
                  return ListTile(
                    leading: SizedBox(
                      width: 46,
                      height: 46,
                      child: ClipOval(
                        child: AlbumArtwork(
                          coverArt: artist.effectiveCoverArt,
                          size: 46,
                          borderRadius: 23,
                          shadow: const BoxShadow(color: Colors.transparent),
                        ),
                      ),
                    ),
                    title: Text(
                      artist.name,
                      style: theme.textTheme.bodyLarge,
                    ),
                    onTap: () => onArtistTap(artist),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
