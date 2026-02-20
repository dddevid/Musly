# Changelog

All notable changes to Musly will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.6] - 2026-02-20

### Added
- **Jukebox Mode** ([#41](https://github.com/dddevid/Musly/issues/41)): Server-side audio playback via the Subsonic jukebox API
  - New `JukeboxService` wrapping all jukebox API calls (`get`, `start`, `stop`, `skip`, `set`, `add`, `clear`, `shuffle`, `remove`, `setGain`)
  - Dedicated `JukeboxScreen` remote-control UI with now-playing artwork, playback controls, volume slider, and queue list
  - Toggle in Settings → Server to enable/disable jukebox mode
  - "Play on Jukebox" and "Add to Jukebox Queue" options in the song long-press context menu (shown only when jukebox is enabled)
  - Auto-refresh on screen open + 5-second polling to stay in sync with current server state
  - Friendly error screen when the server returns 501 (jukebox not enabled), with setup instructions
- **Genre Support**: Enhanced genre browsing
  - Genres screen now shows song count per genre and a tooltip
  - Genre screen rebuilt with two tabs: Songs and Albums
- **Easter Egg**: Fanta-bounce screensaver triggered by tapping the search button 11 times in quick succession

### Fixed
- **[#29](https://github.com/dddevid/Musly/issues/29) Offline Playlists**: Playlists are now correctly restored from local cache when the server is unreachable
- **[#37](https://github.com/dddevid/Musly/issues/37) Music Folder Selection**: Fixed the music folder selection dialog in Server settings
- **[#44](https://github.com/dddevid/Musly/issues/44) Album Art Aspect Ratio**: Album artwork now preserves its original aspect ratio (`BoxFit.contain`) instead of stretching

### Improved
- **Localizations**: Removed duplicate keys from `app_en.arb`; cleaned non-English ARB files of orphaned section markers and English fallback strings

## [1.0.5] - 2026-02-19

### Added
- **Internationalization (i18n)**: Full app translation support via Flutter's `flutter_localizations`
  - 24 languages: Bengali, Danish, German, Greek, Spanish, Finnish, French, Irish, Hindi, Indonesian, Italian, Norwegian, Polish, Portuguese, Romanian, Russian, Albanian, Swedish, Telugu, Turkish, Ukrainian, Vietnamese, Chinese (Simplified), and English as base
  - Crowdin integration for community-driven translations with GitHub Actions auto-sync
  - Added `TRANSLATIONS.md` guide for contributors
  - Added `LocaleService` for runtime language switching
- **Google Cast / Chromecast Support**: Stream music to Cast-compatible devices
  - New `CastService` managing session lifecycle and media loading
  - New `CastButton` widget displayed in the player and mini-player
  - Album art shown on the TV/receiver as a video-style visualization (1280×720)
  - Integrated `flutter_chrome_cast` package (bundled under `packages/`)
  - UPnP device discovery via new `UPnPService` as a fallback discovery layer
- **mTLS Client Certificate Authentication**: Secure mutual TLS for self-hosted servers
  - Certificate file picker on the login screen (`.p12` / `.pfx`)
  - Optional password field for password-protected certificates
  - `ServerConfig` model extended with `clientCertPath` and `clientCertPassword` fields
  - `SubsonicService` now configures the HTTP client with the chosen certificate
- **Discord Rich Presence**: Show currently playing song in Discord status
  - New `DiscordRpcService` wired into the player pipeline
- **Auto-Update Service**: New `UpdateService` that checks GitHub Releases for newer versions and prompts the user
- **Windows NSIS Installer**: Packaged installer (`installer.nsi`) with dynamic version injection via `/D` flag from the CI pipeline
- **Linux Platform Support**: Full Linux desktop build configuration added
- **Star Rating Widget**: Visual 1–5 star picker widget used in the song options menu
- **React Marketing Website**: Added under `react-website/`, deployed to GitHub Pages via Actions workflow

### Improved
- **Google Cast Display**: Receiver now shows album art like Spotify
  - Switched from raw audio streaming to a video-style Cast session with artwork
  - Uses `GenericMediaMetadata` for broader Cast receiver compatibility
- **Support Dialog**: Streamlined post-login dialog
  - Removed 5-second wait timer; close button is immediately available
  - Added "Don't show again" checkbox
  - Removed BuyMeACoffee and donation links
- **Build System**: Upgraded to Gradle 8.0 for Java 21 compatibility
  - `flutter_chrome_cast` uses Gradle 8.0.2 and Kotlin 1.9.0
  - `compileSdk` bumped to 34, Java compatibility set to `VERSION_11`
  - Resolves _"Unsupported class file major version 65"_ build error
- **CI/CD Pipeline**: Overhauled GitHub Actions release workflow
  - Flutter dependency caching enabled to speed up builds
  - Updated all action versions to current releases
  - Removed hardcoded Flutter version pin for better forward compatibility
  - Removed AAB (Android App Bundle) artifact from release builds
- **Code Quality**: Cleaned up Dart lint warnings across the codebase
  - Removed unused imports, variables, and dead code
  - Fixed impossible null checks
  - Replaced deprecated API usages

### Fixed
- **Android Boot Crash**: Removed `AutoStartReceiver` that caused crashes on device startup
  - App no longer requests `RECEIVE_BOOT_COMPLETED` permission
- **Android 16 / Media3 Playback Bug**: Implemented workaround for a Media3 regression introduced in Android 16 that prevented playback from starting correctly
- **Low Power Device Crashes**: Optimized image caching and rendering pipeline to avoid OOM crashes on constrained hardware
- **Flutter 3.41.1 Compatibility**: Hid `RepeatMode` re-export from `cupertino.dart` to resolve a symbol conflict introduced in Flutter 3.41.1
- **Cast Service Resource Leaks**: Added proper `dispose()` and `disconnect()` methods; `loadMedia()` now returns a success/failure boolean
- **installer.nsi not tracked**: Removed `installer.nsi` from `.gitignore` so the Windows installer script is included in the repository

### Removed
- **Donation popup**: Support dialog no longer shows BuyMeACoffee or cryptocurrency donation options
- **`AutoStartReceiver`**: Android boot-start receiver removed entirely
- **`DOCUMENTATION.md`**: Replaced by inline code documentation and README improvements

## [1.0.4] - 2026-01-17

### Added
- **Support Dialog After Login**: Shows after each successful login
  - Discord community invite link (optional)
  - Donation options: Buy Me a Coffee, Bitcoin, Solana
  - 5-second timer before close button enables
  - Copy buttons for cryptocurrency addresses
- **Discord Integration in Settings**: Added Discord community link to Settings → About → LINKS
- **Discord Community Section in README**: Added dedicated section with Discord badge and invite link

### Improved
- **Landscape Lyrics Display**: Significantly improved lyrics viewing in landscape mode
  - Lyrics now occupy right 60% of screen while album art stays on left 40%
  - Created `CompactLyricsView` widget specifically optimized for landscape
  - Portrait mode keeps fullscreen lyrics overlay
  - Fixed overflow issues in lyrics dialog
- **Playlist Duration Calculation**: Enhanced playlist screen with accurate total duration
  - Total duration now calculated from actual song lengths
  - Displays formatted duration (e.g., "12 songs • 1 hr 23 min")

### Fixed
- **Homepage Loading Issue on Windows**: Fixed infinite skeleton loading
  - Added 5-second timeout to server initialization calls in `LibraryProvider`
  - App now continues in local mode if server doesn't respond
  - Improved error handling for missing server configuration
- **Windows SMTC Error Handling**: Improved error messages for RustLib initialization
  - App continues normally even if SMTC (Windows System Media Transport Controls) fails to initialize
  - Added informative debug messages explaining SMTC will be disabled

## [Unreleased] - 2026-01-17

### Added
- **[#27](https://github.com/dddevid/Musly/issues/27) Star Rating System**: Added 1-5 star rating support for songs
  - Rate songs via the song options menu (three-dot menu)
  - Rating dialog with visual star picker
  - Shows current rating in menu title
  - Uses Subsonic `setRating` API endpoint
  - Added `userRating` field to Song model

- **Landscape Mode for Full Player**: New horizontal layout when device is rotated
  - Album artwork displayed on the left (40% width)
  - Song info and controls on the right (60% width)
  - Lyrics toggle replaces controls with synced lyrics on right side
  - Automatic layout switch based on screen orientation
  - Created `CompactLyricsView` widget optimized for landscape mode

### Improved
- **Playlist & Album Screens**: Enhanced with calculated total duration
  - Playlist screen now shows total duration calculated from songs (e.g., "12 songs • 1 hr 23 min")
  - More accurate duration display based on actual song lengths

### Changed
- **Performance Optimizations**: Migrated synced lyrics view to `flutter_lyric` package (v3.0.2)
  - Reduced blur effects from sigma 80 to 40 for better GPU performance
  - Added `RepaintBoundary` around animated backgrounds
  - Implemented position update throttling (100ms intervals)
  - Reduced image cache sizes for lower memory usage
- **Widget Optimization**: Replaced `Consumer` and `Provider.of` with `Selector` pattern
  - `SongTile`: Now only rebuilds when current song changes
  - `DesktopPlayerBar`: Optimized controls, progress bar, and volume slider
  - Reduced unnecessary widget rebuilds across the app

### Fixed
- **Synced lyrics assertion error**: `selectionAutoResumeDuration` must be less than `activeAutoResumeDuration`
- **Library "Local" filter removed**: Cleaned up unused local music filter from library screen
- **Storage permissions for Android 13+**: Added `READ_MEDIA_AUDIO` and `READ_MEDIA_IMAGES` permissions
- **Server not configured errors**: LibraryProvider now gracefully handles local-only mode without server errors

---

## [1.1.0] - 2026-01-15

### Added

- **Premium Equalizer**: 10-band EQ with presets (Rock, Pop, Jazz, Classical, Bass Boost, Treble Boost, Vocal, Electronic, Hip Hop) and custom preset saving
- **Settings Categories**: Reorganized settings into 5 tabs (Playback, Storage, Server, Display, About)
- **Local File Support**: Play music files stored on device with automatic library scanning
- **Transcoding/Streaming Quality**: Configure WiFi and Mobile bitrate settings with format selection (MP3, Opus, AAC)
- **Offline Mode**: Automatic fallback to downloaded music when server is unreachable
- **Offline Playback Indicator**: Orange banner shows when in offline mode

### Improved

- **Synced Lyrics Display**: 
  - Added blur effect for non-active lines (distance-based)
  - Added glow shadow for active line
  - Improved scale animations (1.15x-1.18x for active)
  - Enhanced line spacing and visual hierarchy
  - Applied to mobile, desktop, and fullscreen views

- **Shuffle Functionality**: Now properly shuffles playlist regardless of current playback state
- **Artists Tab**: Now correctly displays artists when "Artists" filter is selected
- **Homepage Empty State**: Added fallback message and refresh button when no content

### Fixed

- **[#26](https://github.com/dddevid/Musly/issues/26)**: Transcoding/streaming quality settings
  - Added WiFi and Mobile bitrate configuration in Server settings
  - Support for format selection (MP3, Opus, AAC)
  - Bitrate options from 64kbps to 320kbps or original quality

- **[#25](https://github.com/dddevid/Musly/issues/25)**: Library search now works on all items, not just playlists
  - Implemented `LibrarySearchDelegate` that searches across playlists, albums, and artists
  
- **[#24](https://github.com/dddevid/Musly/issues/24)**: Artists tab now displays content
  - Fixed `_getFilteredItems` to properly filter and return artists list
  
- **[#22](https://github.com/dddevid/Musly/issues/22)**: Homepage shows fallback when no content available
  - Added empty state widget with refresh button when no albums/songs loaded
  
- **[#20](https://github.com/dddevid/Musly/issues/20)**: Shuffle button now always shuffles instead of acting as play/pause
  - Modified shuffle logic to always shuffle the playlist, even when already playing
  
- **[#19](https://github.com/dddevid/Musly/issues/19)**: Download button in playlist now downloads all songs
  - Implemented batch download functionality in playlist screen
  
- **[#18](https://github.com/dddevid/Musly/issues/18)**: Play/Pause state now correctly shows only for the active playlist
  - Fixed playlist header to compare current playing context
  
- **[#17](https://github.com/dddevid/Musly/issues/17)**: Lyrics scroll now uses smooth animations without line-break changes
  - Used fixed font size for all lines to prevent layout shifts
  
- **[#16](https://github.com/dddevid/Musly/issues/16)**: Library search button now works
  - Connected search icon to `LibrarySearchDelegate`
  
- **[#15](https://github.com/dddevid/Musly/issues/15)**: Swipe down to minimize player implemented
  - Added gesture detector for vertical swipe to dismiss full player
  
- **[#14](https://github.com/dddevid/Musly/issues/14)**: Option to hide volume bar from player
  - Added toggle in Display settings to show/hide volume slider
  
- **[#13](https://github.com/dddevid/Musly/issues/13)**: Click on album/artist name navigates to respective screen
  - Made album and artist names tappable in now playing screen
  
- **[#12](https://github.com/dddevid/Musly/issues/12)**: Internet radio station support
  - Added `RadioScreen` with server radio stations
  - Support for streaming internet radio URLs
  
- **[#11](https://github.com/dddevid/Musly/issues/11)**: All Songs view with sort options and playback
  - Added `AllSongsScreen` with play/shuffle buttons
  
- **[#10](https://github.com/dddevid/Musly/issues/10)**: Auto-DJ feature for queue
  - Implemented smart queue that adds similar songs when queue ends
  
- **[#9](https://github.com/dddevid/Musly/issues/9)**: ReplayGain support
  - Added ReplayGain toggle in Playback settings
  
- **[#8](https://github.com/dddevid/Musly/issues/8)**: Progress bar freezes on rewind
  - Fixed position stream subscription to properly update on seek
  
- **[#7](https://github.com/dddevid/Musly/issues/7)**: Custom TLS/SSL certificates 
  - Added option to allow self-signed certificates in login
  - Added custom certificate file picker in Advanced Options
  
- **[#5](https://github.com/dddevid/Musly/issues/5)**: Lyrics text stability
  - Fixed line break changes during playback by using consistent font sizing
  
- **[#4](https://github.com/dddevid/Musly/issues/4)**: Music Folders support
  - Added music folder selection in Server settings
  
- **[#3](https://github.com/dddevid/Musly/issues/3)**: Error messages for incorrect URL
  - Added proper error handling and snackbar messages for connection failures
  
- **[#1](https://github.com/dddevid/Musly/issues/1)**: Miniplayer persists
  - Implemented nested navigator architecture to maintain miniplayer state