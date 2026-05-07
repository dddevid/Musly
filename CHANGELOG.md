# Changelog

All notable changes to Musly will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.12] - 2026-05-07

### Added
- **Persistent Queue Across Restarts** ([#156](https://github.com/dddevid/Musly/issues/156))
  - Queue state (songs, current index, current song ID) saved to SharedPreferences
  - Automatically restores queue on app launch without auto-playing
  - Validates local file paths exist before restoring
  - Debounced save (200ms) to avoid excessive writes
  - Clears persisted data on explicit queue clear
- **Artist Play Enhancement** ([#151](https://github.com/dddevid/Musly/pull/151))
  - "Play" button on artist screens now appends rest of artist's songs to their top songs
  - Provides fuller artist experience when pressing play

### Fixed
- **History Screen Loading** - Improved history loading and listener management
- **Library Refresh** ([#152](https://github.com/dddevid/Musly/issues/152))
  - Refresh button now forces full re-sync by bypassing 6-hour cooldown
  - Fixes stale library content after user clicks refresh
- **Accent Color Consistency** ([#158](https://github.com/dddevid/Musly/issues/158))
  - Play/Shuffle buttons now use theme accent color instead of hardcoded red
  - Applied to album, artist, and playlist screens
- **Emby/Jellyfin Library Sync** ([#160](https://github.com/dddevid/Musly/issues/160))
  - Added `getAllSongs()` to JellyfinService for O(1) API call
  - SubsonicService proxy for Jellyfin compatibility
  - Fixed albumId and artistId fallbacks in item parsing
  - Fixed pagination loop early-break issue
- **Play/Shuffle Button Design** ([#157](https://github.com/dddevid/Musly/issues/157))
  - Consistent pill-shaped design across artist, album, and playlist screens
  - Play/Shuffle row added below artist header
- **Now Playing Screen**
  - Replaced AnimatedMeshGradient with reliable radial gradient blobs
  - Fixed lyrics scroll-to-current when ListView items are unbuilt
  - Added lyrics slide-up/fade transition
  - Fixed ReorderableListView null crash with drag handle
- **Local Files UX**
  - Folder cover art fallback
  - Smart sorting with genre/year filters
  - Added Radio Stations to mobile Library screen
- **Localization** - Updated l10n keys for empty states and scan actions

### Changed
- **Android Build** - Bumped version to 1.0.12+1 for update support ([#148](https://github.com/dddevid/Musly/issues/148))
- **MusicService** - Cleaned up comments and streamlined code
- **Artwork Loading** - Optimized loading and metadata updates in MusicService
- **Recommendation Service** - Enhanced with improved data handling and caching

## [1.0.11] - 2026-05-04

### Added
- **Pitch Control & Speed Adjustment** ([#145](https://github.com/dddevid/Musly/issues/145))
  - Independent pitch slider (0.5× – 2.0×) in the speed bottom sheet
  - "Preserve pitch" toggle: keeps original pitch when changing playback speed (time-stretching)
  - When disabled, pitch follows speed like a vinyl record
  - Native ExoPlayer bridge on Android via reflection for real pitch control
  - iOS stub ready for future AVAudioEngine integration
- **iPhone SE / Small Screen Compatibility**
  - Responsive layouts for 375×667 pt screens (iPhone SE, iPhone 8)
  - Reduced padding, font sizes, and control sizes across Now Playing, Login, Album, and Mini Player
  - `ScreenHelper` utility for adaptive sizing based on screen width

### Fixed
- **Listening History Blank** ([#146](https://github.com/dddevid/Musly/issues/146))
  - History screen was empty when recommendations were disabled
  - `trackSongPlay`, `trackSkip`, `trackSongRating`, and `trackStarred` now always record listening data regardless of recommendation toggle
- **Emulator Detection (Pixel 9+)**
  - Replaced `device_info_plus` string-matching with `safe_device: ^1.3.10`
  - Pixel 9+ devices were falsely blocked as emulators due to "google"/"generic" strings in device info
- **Speed/Pitch Race Condition**
  - Fixed bug where changing playback speed reset pitch to 1.0
  - Unified `setPlaybackParameters(speed, pitch)` call applied atomically to ExoPlayer
  - Eliminates race between `just_audio.setSpeed()` and custom pitch reflection

### Changed
- **CI/CD**: Android release builds now produce a universal APK instead of split-per-ABI
  - Fixes issue where installing a new APK over an old one required uninstalling first

## [1.0.10] - 2026-05-04

### Added
- **Live Activities / Lyrics on Lock Screen** (iOS 16.1+ & Android)
  - Replaced custom `iOSLyricsPlugin` with `live_activities: ^2.4.9` package
  - iOS: Native Live Activity with Dynamic Island showing current lyrics line
  - Android: Live Activity-style notification via RemoteViews
  - Unified API for both platforms in `LockScreenLyricsService`
- **Multiple Server Profiles**: Switch between different Subsonic/Navidrome servers
- **Local Music Libraries**: Play music files stored on device with auto-scanning
- **Parallel Downloads**: Download multiple songs simultaneously in library
- **Heart/Repeat/Shuffle in Mini Player**: Quick action buttons in collapsed player
- **Android Auto Improvements**: Enhanced UI, animations, and Navidrome content support
- **SMTC Windows Lyrics & Bluetooth Lyrics**: Show lyrics in Windows notification and Bluetooth devices
- **Emulator Detection**: Block app on emulators for mobile builds
- **Arabic & Dutch Language Support**

### Changed
- **iOS Minimum Version**: Bumped to 16.1 for ActivityKit support
- **audio_service**: Updated to ^0.18.18 for better iOS Now Playing artwork
- **Donation Popup Timing**: Reduced from 25 min to 8 min usage
- **Playing Next Section**: Improved styling and tap-to-collapse behavior
- **Library Page Reorganization**: Better layout and filtering

### Fixed
- **iOS Build Error**: "Cannot find iOSLyricsPlugin" resolved by updating deployment target
- **iOS Audio Stopping**: Song no longer stops when closing fullscreen player
- **iOS Now Playing Artwork**: High-quality 1200px artwork from server
- **Self-Signed Certificates**: Eliminated UI freeze during TLS setup (async file reads)
- **Image Decompression Crash**: Fixed on Android low-memory devices
- **Background Download**: GrapheneOS compatibility fixes
- **Android Auto Artwork**: Proper loading and display
- **Logout Null Check**: Error when logging out from settings
- **Support Dialog**: Usability fixes on small screens
- **Album Screen Navigation**: Fixed from now-playing flow above artist page

## [1.0.9] - 2026-05-02

### Added
- **CI/CD Auto-Release**: Fully automated GitHub Actions workflow
  - Automated builds and releases for Android, iOS, Windows, Linux, and macOS
  - Windows NSIS installer (`musly-setup.exe`) automatically generated
  - Fixed ALSA dependency for Linux builds
  - Automatic artifact upload and GitHub Release creation
- **Privacy Policy Dialog**: Implemented dialog for privacy policy acceptance
- **Multi-Artist Support**: Support for multiple artists from Navidrome
  - Correct display of multiple artists for single songs
  - Multi-artist picker in song context menu
- **Album Download Button**: Button to download entire album from album screen
- **Swipe Gesture**: Swipe gesture to change songs in player
  - Carousel animation with haptic feedback
  - Forward/backward swipe navigation between tracks
- **Artist to Queue**: Added "Add artist to queue" button on artist screens
- **Tap Cover for Lyrics**: Tap album cover in player to show lyrics
- **Analytics**: Countly Analytics and crash reports (https://musly.devid.lol/privacy)

### Changed
- **Flutter 3.41.7**: Updated Flutter to version 3.41.7
- **Dart SDK Constraint**: Updated constraint to `>=3.0.0 <4.0.0`
- **Code Quality**: Refactored duplicate `_` variables in callbacks for Dart 3 compatibility
- **iOS Cleanup**: Removed unnecessary iOS example files

### Fixed
- **UPnP Volume Overlay**: Fixed UPnP hardware volume jump
- **UPnP Auto-Disconnect**: Automatic renderer disconnection after 30s of connection loss
- **Shuffle History**: Back button tracks playback history with shuffle active
- **UPnP Remote Playback**: Fixed UPnP remote playback state management and UI routing
- **Recently Added Sort**: Fixed "Recently Added" sorting by server creation date
- **Download Library Bug**: Fixed partially persisted library bug during refresh
- **Context Menu**: Fixed stale context and scrollable artists sheet
- **Playlist Creation**: Library refresh after playlist creation from "now playing" menu

### Improved
- **Translations**: Crowdin translation updates (more languages supported)

## [1.0.8] - 2026-03-08

### Added
- **Smart Transcoding**: New automatic quality mode that switches bitrate in real time based on active network
  - Detects WiFi vs mobile data via `connectivity_plus`
  - Configure separate bitrates for WiFi and mobile; the app picks the right one automatically
  - Live connection badge (WiFi / Mobile pill) in Settings → Playback while smart mode is active
  - Smart mode toggle persists across restarts
- **Dynamic & Custom Accent Colors**: The accent color now propagates everywhere in the app
  - On Android 12+ the wallpaper-derived Material You palette is used automatically (via `dynamic_color`)
  - On all other platforms any color picked in Settings → Display is applied to every widget
  - Eliminated all hardcoded `AppTheme.appleMusicRed` references in settings tabs, mini player, song tiles, cast button, and album artwork shadow
- **iOS Control Center player**: Fixed the player widget shown in the iOS Control Center and Lock Screen
  - Disabled the podcast-style ±15 s skip buttons that were hiding the standard ⏮ ▶/⏸ ⏭ controls
  - Added `MPNowPlayingInfoPropertyMediaType = .audio` and `MPNowPlayingInfoPropertyDefaultPlaybackRate` for correct system content categorization
  - Fixed an artwork caching race condition: concurrent 1-second position updates no longer restart artwork downloads already in progress
- **Server connection retry**: `AuthProvider._verifyConnection()` now retries the ping up to 3 times (2 s backoff) before declaring the server unreachable — handles slow mobile network initialization on launch
- **Retry button on the server-unreachable screen**: A "Retry" button lets users re-attempt the connection without restarting the app (`AuthProvider.retryConnection()`)
- **Localization — Settings strings**: All hardcoded strings in the five Settings tabs are now in `app_en.arb` (~100 new keys covering Playback, Storage, About, Display, and Server sections)

### Changed
- **Loading screen**: The app no longer flashes the login screen while checking the server on startup; `AuthState.authenticating` now shows a centered `CircularProgressIndicator` on a black background
- **Home screen desktop layout**: Improved density and alignment for macOS/Windows/Linux
  - Wider horizontal padding (32 px), larger section headers and album cards (180 px)
  - Song lists render as a compact table (`_DesktopSongRow`) instead of full `SongTile` cards
  - Recent albums (6) and playlists (3) shown instead of 4 and 2
- **Error messages**: Improved error string formatting in `AuthProvider._formatError()` — strips `Exception:`, `Network error:`, and verbose library boilerplate for cleaner display
- **Connection timeout**: Server ping timeout increased from 6 s to 10 s
- **Now Playing screen**: Matrix transforms updated to Flutter 3.41-compatible `scaleByDouble`/`translateByDouble` signatures; `.withOpacity()` replaced with `.withValues(alpha:)` throughout

### Fixed
- **`seekForward`/`seekBackward` events from iOS Control Center**: Added `onSeekForward`/`onSeekBackward` callbacks to `AndroidSystemService` and registered handlers in `PlayerProvider` (clamping backward seeks to `Duration.zero`)
- **Settings tab indicator color hardcoded**: `indicatorColor` and `labelColor` in `settings_screen.dart` now use `Theme.of(context).colorScheme.primary`
- **`DjMixerService` removed**: Deleted unused `dj_mixer_service.dart` that was included by mistake; `services.dart` barrel still intact

### Dependencies
- Added `connectivity_plus: ^7.0.0` — network type detection for Smart Transcoding
- Added `dynamic_color: ^1.7.0` — Material You wallpaper color extraction on Android 12+
- Added `path: ^1.9.0`

## [1.0.7] - 2026-02-22

### Added
- **Spotify-style Desktop UX**: Complete redesign of the PC layout
  - New collapsible sidebar (`DesktopNavigationSidebar`) with 260 px expanded / 72 px collapsed states
  - Sidebar sections: Home, Search, Your Library (scrollable playlist list with Liked Songs shortcut), Settings, Collapse/Expand toggle
  - Settings navigation item restored directly in the sidebar
  - All sidebar strings localised via ARB (`expand`, `createPlaylist`)
- **Artwork Style Editor**: Full custom editor in Settings → Display → Artwork Style
  - **Shape**: Rounded rectangle, Circle, or Square
  - **Corner Radius**: slider (0–24 px), only visible when shape is *Rounded*
  - **Shadow intensity**: None, Soft, Medium, Strong
  - **Shadow color**: Black or Accent (Musly red)
  - Live 108 px animated preview updates in real-time
  - All options persisted to `SharedPreferences` and restored on next launch (awaited before `runApp`)
- **No-artwork placeholder in mobile player**: Songs without cover art now show a clean dark gradient tile with a music note icon and localised "No artwork" label instead of an infinite shimmer loader. Shimmer is still used while the image is actually fetching.

### Changed
- **Desktop player bar accent colors**: All active-state indicators (shuffle, repeat, progress slider, volume slider, favorite heart, lyrics button) now use Musly red
- **Update dialog colors**: Header gradient and download button changed from purple/blue (`#6C5CE7 → #00B4D8`) to Musly red/pink (`appleMusicRed → appleMusicPink`)
- **Desktop lyrics**: Lyrics view now uses `rootNavigator: true` so it covers the full window (sidebar + content + player bar); close button pops from the root navigator correctly
- **React marketing website**: Version number and release date in Hero and Download sections are now fetched live from the GitHub public API (`/repos/dddevid/Musly/releases/latest`) with a 10-minute session cache — no auth token required

### Fixed
- **Library list alignment**: Album/artist tiles in the Library screen now use an explicit `InkWell → Padding → Row` layout so artwork and text align with section headers on all platforms
- **Artwork settings not persisting**: `PlayerUiSettingsService.initialize()` is now `await`-ed before `runApp`, guaranteeing saved values are loaded into notifiers before any widget builds

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

## [1.0.1] - 2026-01-15

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
