# Changelog

All notable changes to Musly will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.2] - 2026-08-26

### Added

- **Material 3 Dynamic Theme Color (Material You / Pixel OS / OneUI)**
  - Added support for dynamic wallpaper-based accent colors on Android 12+ / Pixel / OneUI devices via Material 3 / `dynamic_color`.
  - Added interactive dynamic color option with dedicated Material 3 palette indicator in Display Settings (`_AccentColorPicker`).
  - Extended `AccentColor` enum with `dynamicColor` (`'dynamic'`) and fallback mechanism for platforms without system dynamic schemes.

- **Language Selector & Community Translation Progress**
  - Resolved an issue where selecting "System Default" would erroneously display "English" regardless of the device's actual system language; it now resolves and displays the active system language name (e.g. `System Default (Italiano)`).
  - Added Crowdin community translation attribution in the language picker header and dynamic completion percentage tags (`%`) for each supported language.

- **Now Playing Star Ratings & Direct Favorite Button**
  - Added interactive 5-star rating bar (`NowPlayingStarRating`) in the fullscreen Now Playing screen (in both portrait and landscape layouts) that dynamically respects the "Show Star Ratings" toggle and syncs directly to Subsonic/Navidrome servers.
  - Added dedicated Heart/Favorite toggle button in the Now Playing metadata row for instant 1-tap favoriting alongside the Add to Playlist button.

- **Search Radio Queue Generation & Continuous Auto-Refill**
  - When playing a song directly from search results, Musly dynamically creates a radio queue populated with similar songs (matching genre, artist top tracks, and recommendations) instead of playing consecutive unrelated search query results.
  - Added continuous automatic queue replenishment: when an automatic queue or AutoDJ queue is nearing the end (<= 3 songs remaining) or finishes, Musly automatically discovers and appends more similar tracks to the queue and audio source so continuous playback never stops.

- **Musly Wrapped & Year in Review Redesign & Localization**
  - Completely revamped Musly Wrapped UI with high-end glassmorphic cards (`BackdropFilter`), glowing radial aura meshes, and interactive floating particles.
  - Added hero centerpiece cards for #1 Top Song with real-time animated equalizer bars (`_EqualizerBars`) and #1 Top Artist with glowing circular avatars.
  - Added formatted number statistics (e.g. `12,450` mins) and long-press story pause feedback indicator.
  - Fully localized all user interface texts, story slides (Intro, Minutes, Chronotypes, Genre Galaxy, Top Songs & Countdown, Top Artists, and Personality Archetypes), metrics, badges, and home banners into English, Italian, and all supported languages via `AppLocalizations`.

### Fixed

- **Library Scrolling Performance & Viewport Virtualization**
  - Replaced unvirtualized `SliverToBoxAdapter` containing full `Column` / `Wrap` with lazy `SliverList.builder` and `SliverGrid.builder`, eliminating scroll stutter and jank by rendering only visible items.
  - Added `RepaintBoundary` wrappers to individual library list and grid item tiles to prevent unneeded full-screen repainting while scrolling.
  - Tuned `CustomScrollView.cacheExtent` to `600.0` with `AlwaysScrollableScrollPhysics` for silky-smooth 60/120 FPS scrolling across both list and grid view modes.

- **UPnP / DLNA & Google Cast Playback Controls & Track Skipping**
  - Fixed pausing and seeking from the phone when connected to a UPnP / DLNA or Google Cast device by immediately updating local playback and position state and eliminating race-condition jitter. Added automatic fallback to `Stop` when a UPnP renderer does not support the `Pause` SOAP action.
  - Fixed skipping to next/previous songs from both the phone and the UPnP device:
    - Bypassed the local `ConcatenatingAudioSource` check when rendering remotely so queue skips stream the new track to the remote renderer.
    - Implemented `SetNextAVTransportURI` support in `UpnpService` to pre-queue upcoming tracks on UPnP renderers.
    - Handled track progression when skipped directly from the UPnP renderer (supporting `STOPPED`, `NO_MEDIA_PRESENT`, and renderer automatic `TrackURI` transitions).

- **Live Lyrics Under Artwork Multiline Wrapping**
  - Removed single-line truncation (`maxLines: 1`, `TextOverflow.ellipsis`) in the live lyric pill under the Now Playing album artwork, allowing long lyric lines to wrap naturally across multiple lines without being cut off by ellipses.

- **Settings ListTile Ink Splash & Material Hierarchy**
  - Replaced intermediate `Container(decoration: BoxDecoration(...))` with `Material(color: ..., borderRadius: ..., clipBehavior: Clip.antiAlias)` in `SettingsSectionCard` and `ServerSwitcherSheet`, resolving the Flutter framework assertion regarding hidden ink splashes and tile background effects.

- **Now Playing Queue Reordering & Song Options Menu (#236)**
  - Replaced static `ListView` in `QueueView` with interactive `ReorderableListView.builder` allowing users to drag and drop songs to reorder the upcoming queue.
  - Connected queue drag-and-drop to `PlayerProvider.reorderQueue()`, properly updating playback order, active playback index, and persistent queue state.
  - Added dedicated 3-dot options button (`Icons.more_vert_rounded`) and long-press gesture handling on each queue song to open `SongOptionsModal` (add to playlist, play next, view album/artist, download, etc.).

- **UI Theme Color Consistency Across Components**
  - Standardized UI elements (play buttons, chips, sliders, floating play controls, active indicators, badges, and checkboxes) across the entire app to dynamically follow the user-selected Accent Color / Theme Color instead of hardcoded colors.
  - Updated `MediaPlayButton`, `MediaFloatingPlayButton`, `SongTile`, `SwipeableSongTile`, `MiniPlayer`, `DesktopPlayerBar`, `CastButton`, `RightSidebar`, `TopResultCard`, `QuickAccessTile`, `LibraryScreen`, `SearchScreen`, `HomeScreen`, `MainScreen`, `ConnectDevicesModal`, `JukeboxScreen`, `RadioScreen`, `PlaylistsScreen`, `DownloadPlaylistStatusScreen`, `PlaylistScreen`, `AlbumScreen`, and `LoginScreen`.

- **Google Cast Playback & Session State Management (#235)**
  - Fixed an issue on Android where connecting to a Google Cast device immediately stopped playback and prevented tracks from playing on the cast device.
  - Resolved an infinite reload loop in `PlayerProvider` by properly tracking Cast connection transitions (`_castWasConnected`), preventing position and status ticks from resetting playback.
  - Added synchronized position and duration streaming, volume control, and natural track completion detection (`GoogleCastMediaIdleReason.finished`) to automatically advance through the queue.
  - Implemented seamless playback handover passing the current track position (`playPosition`) when connecting to a Cast device.
  - Improved media loading resilience with enhanced MIME type resolution supporting query parameters (e.g. Subsonic/Navidrome stream URLs) and safe cover art URL validation.

## [2.0.1] - 2026-08-25

### Added

- **Multi-Language Support & Internationalization (i18n / l10n)**
  - Integrated official Flutter internationalization framework (`flutter_localizations` with ARB resource bundles).
  - Multi-language catalog supporting 27 languages with automatic system locale matching and fallback mechanisms.
  - In-app Language Selector in Display Settings for seamless runtime language switching without restarting the app.
  - Added automated Crowdin synchronization workflows (`crowdin-sync.yml` and `crowdin.yml`) to keep community translations continuously updated.

- **Complete UI String Localization & Hardcoded Text Elimination**
  - Systematic audit and extraction of all hardcoded strings across the entire codebase into `.arb` catalogs.
  - Fully localized onboarding walkthrough, feature cards, navigation controls, and slide transitions.
  - Fully localized modals and dialogs: Milestone Celebration dialog, Privacy Policy dialog, Server Switcher menu actions, and Sleep Timer selector.
  - Fully localized media collection screens (All Songs, Albums, Playlists, Favorites, Radio Stations, Downloads) including sorting menus, empty states, and batch download confirmations.
  - Fully localized Desktop UI components: Player bar controls, playback device picker, and right queue sidebar.
  - Fully localized search view (input placeholders, query suggestions, recent searches) and server authentication / connection forms.
  - Complete Italian (`it`) translation coverage for all existing and newly added localization keys.

### Fixed

- **Now Playing Screen Landscape Layout (#234)**
  - Resolved layout distortion and RenderFlex overflow on Android and mobile devices when rotating the Now Playing view into landscape mode.
  - Implemented responsive 2-column landscape presentation with album artwork and live lyrics on the left, and metadata, seek slider, playback controls, volume slider, and bottom actions on the right.
  - Made Now Playing sheet constraints, drag handle, lyrics header, and queue list padding adapt smoothly to landscape orientation.

- **Album Screen Cover Art Alignment (#233)**
  - Fixed visual misalignment and app bar overlap where album artwork in the Album detail screen clashed with navigation and action icons.
  - Replaced unpinned expanded stack with a pinned dynamic `LayoutBuilder` flexible space that centers the artwork cleanly below the toolbar and provides smooth scaling and fade transitions on scroll.

## [2.0.0] - 2026-08-23

### Added

- **Musly Connect (Local Network Device Remote & Playback Transfer) (Temporarely Unavailable)**
  - Zero-config LAN P2P UDP discovery and embedded WebSocket control server.
  - Discover nearby Musly devices running on the same server or streaming mode to control playback (Play, Pause, Next, Prev, Seek, Volume) and transfer the active queue and track position with 1 tap.

<!--
- **Musly BeatSync [BETA] (Multi-Device Synchronized Party Audio)**
  - High-precision NTP clock offset synchronization ($<5\text{ms}$ accuracy) inspired by BeatSync.
  - Host party rooms and synchronize multiple phones, computers, and tablets on the same Wi-Fi into a unified surround speaker system with scheduled playback and real-time audio drift phase correction.
  - Manual calibration nudge slider ($\pm 50\text{ms}$) for Bluetooth latency compensation.
-->

- **Spotify-style Swipe to Queue**
  - Smooth horizontal swipe-right gesture on song rows across all lists (Albums, Playlists, Search, Library) to instantly add songs to the playback queue with tactile haptic feedback and an animated queue confirmation pill.

- **Smart Track Crossfade & Transitions**
  - Configurable 0s to 12s seamless crossfade in Playback Settings with automated volume attenuation curves between tracks.

- **Musly Playback (Year-in-Review Retrospective)**
  - 100% on-device, private interactive retrospective story with animated ambient auras.
  - Automatically unlocks during the seasonal window (late November to mid-January) with a prominent `#MuslyPlayback` hero banner on the Home feed.
  - Insights include: total minutes listened, top 5 songs, top 5 artists, musical personality trait, top genre, aesthetic recap card, and one-tap "Play Your Top Songs" button.
  - Developer/tester preview toggle in Settings > About.

- **Live Lyric under Artwork in Fullscreen Player**
  - Optional setting in Display Settings (disabled by default) that displays a sleek frosted pill with the currently singing synced lyric line directly below the album artwork.
  - Tapping the live lyric snippet instantly opens the full lyrics screen.
  - Automatically hides and preserves standard player layout if the song has no synced lyrics.

- **Smart Audio Focus & Auto-Resume with Fade Out**
  - Smooth volume fade-out and auto-pause when external media apps request audio focus (e.g. YouTube, Instagram, TikTok video playback).
  - Progressive volume fade-in and immediate volume restoration when exiting external apps, with full manual playback override support.

- **High-Fidelity 3-Color Album Palette Extraction**
  - Upgraded palette extraction using `PaletteGenerator` to extract the true 3 primary colors (dominant, vibrant, deep accent) from album artwork for the fullscreen player ambient mesh background.

- **Web Stream (Online Music Streaming & Search)**
  - Stream music directly from the web without requiring an active Subsonic or Jellyfin server.
  - Search global songs, albums, and artists with high-resolution artwork, gapless playback, and synchronized lyrics support.
  - Dynamic local caching in SQLite for fast replay and offline readiness.
  - Generates personalized mixes ("Made For You", "Listen Again", "Your Top Hits") based on web stream listening habits.
  - Seamlessly switch between Subsonic, Jellyfin, Local Music, and Web Stream from the server switcher.

- **Smart Recommendations & Taste-Learning Engine (Home & Web Stream)**
  - Algorithmic music taste profiling learning from play counts, ratings, skips, and completion rates with exponential recency decay.
  - Dynamically generated mixes: "Made For You", "Listen Again", "Your Top Hits", Artist Mixes, and Genre Mixes.
  - Intelligent discovery search querying correlated songs based on user affinities.
  - Full local SQLite persistence for stream caching and smart recommendation candidate pools.

- **Custom Download Folder & SD Card Storage (#193)**
  - Select custom storage directories (internal memory or external SD cards) for offline music downloads from Storage Settings.

- **Automatic Octo-Fiesta Integration (#216)**
  - Seamless auto-detection and support for Octo-Fiesta extensions inside Subsonic and Jellyfin servers without creating separate source profiles.

- **Offline Downloader & Dedicated Downloads Section (#226)**
  - Dedicated Downloads screen in the Library.
  - **"Download All" Favorites (#209)** — One-tap download of all starred/favorite songs for offline playback.
  - **"Download All" Artist Tracks (#225)** — Batch download all songs from an artist directly from the artist screen.
  - Durable playlist download state machine with auto-resume, progress indicators, and outline-check badges.
  - Downloaded badges on songs, albums, and playlists (#224).
  - Validation using server `/download` endpoint and file size verification.

- **Dual WAN / LAN Server Support (#187)**
  - Configure separate Local LAN and Remote WAN server URLs with automatic ping latency check and seamless fallback.

- **Multi-Server Profiles (#185, #196)**
  - Store and switch between multiple Subsonic / Jellyfin server accounts and credentials without overwriting previous profiles.

- **Windows System Media Transport Controls (SMTC)**
  - Full native Windows SMTC integration with timeline progress synchronization, cover artwork, and hardware media keys (Play, Pause, Next, Previous, Stop).
  - Set explicit `AppUserModelID` to "Musly" ensuring the OS media overlay displays "Musly" instead of "App sconosciuta".

- **Discord Rich Presence**
  - Live Discord status integration showing song title, artist, album, and precise elapsed/remaining playback timestamps.
  - Configurable subtitle style (Artist, Song title, App name).
  - State-change caching debounce to eliminate log noise and avoid Discord rate limits.

- **A-Z Alphabetical Index Sidebar (#204)**
  - Fast-scroll alphabet navigation bar on album collection screens with haptic feedback and instant letter jump.

- **Synced Lyrics Customization (#184)**
  - Customization options for the time-synced lyrics view including background blur toggle, text alignment, and active lyric glow.

- **Android 13+ Material You Dynamic Themed Icons**
  - Full support for Android 13+ dynamic themed icons (`<monochrome>` adaptive icon mask) adapting automatically to system color palettes on Google Pixel, Samsung One UI, Xiaomi, and other modern Android launchers.

- **Dolby Atmos Audio Stream Support (#188)**
  - Audio stream badge and playback detection for Dolby Atmos content.

- **Artist Biography & Album Actions (#221, #222, #214)**
  - Detailed artist biography lookup from Subsonic API.
  - Like/favorite button on Album screens.
  - Direct navigation to Album details from Favorite Albums list.

- **Immersive Onboarding Tour Experience**
  - High-end introductory welcome tour featuring dynamic ambient gradient auras, fluid slide transitions, and sleek typography.
  - Highlights core Musly capabilities: Lossless self-hosted audio streaming (Subsonic, Jellyfin, Local files), Algorithmic Smart Mixes, and 100% telemetry-free privacy.
  - Replay onboarding anytime from *Settings -> About -> Welcome Tour* with safe modal return that preserves your active login session.

- **Linux & Desktop Window Controls (#208)**
  - Option in settings to toggle native window titlebars and client-side window decorations on Linux.

### Changed & Improved

- **Desktop UI & Window Experience**
  - Enforced minimum window dimensions ($800\times 560$) across Windows, macOS, and Linux to prevent extreme window narrowing and layout deformation.
  - Added responsive scaling (`FittedBox`) and compact density to the desktop player bar right actions, eliminating `RenderFlex` layout overflows on narrow desktop viewports.
  - Closeable Queue right sidebar accessible via close button and toggleable from the desktop player bar.
  - Volume mute/unmute now accurately restores previous volume level instead of resetting.
  - Safe global spacebar shortcut: typing spaces in search and text fields is preserved without toggling Play/Pause.
  - Route deduplication: prevents opening identical screens or windows repeatedly on top of each other.
  - Hidden mobile-only "Circular Design" toggle on desktop platforms.

- **Small-Screen Responsiveness & Accessibility (iPhone SE / Compact Android)**
  - Dynamic scaling of vertical paddings, font sizes, live lyric pill, and album cover constraints in the Fullscreen Player for screens under 720px/620px height.
  - Scrollable fallbacks for all static Musly Playback story slides ensuring complete button and metric accessibility on compact devices.

- **Audio Playback & Scrobbling Quality of Life**
  - **Now Playing Gesture Conflict Fix (#201)**: Restricted horizontal swipe-to-skip strictly to album art, avoiding accidental skips during Android edge-back navigation.
  - **Volume Slider Customization (#200)**: Configurable setting to show or hide the volume slider on the Now Playing screen.
  - **Long Press Consistency (#192)**: Long pressing playlist tracks consistently opens song options menu.
  - **Scrobble on Shuffle (#207)**: Only scrobbles to server after passing the minimum threshold (50% or 4 minutes) to prevent false scrobbles on skip.
  - **Now Playing Notification (#210)**: Sends "Now Playing" status to server on gapless automatic track advance.
  - **Transcoding Settings & URL Parameters (#198, #194)**: Added dedicated options for WiFi vs Mobile streaming and verified `format` / `maxBitRate` stream parameters.
  - Immediate play/pause UI icon synchronization with safe audio fade transitions.
  - Rounded corners and dynamic ambient shadow support for non-1:1 aspect ratio artwork (#206).
  - Sort bottom sheet padding adjusted to remain fully visible above the mini player (#230).
  - Duplicate song prevention warning when adding tracks to an existing playlist (#211).

- **Unified Login & Provider Selection Grid**
  - "Local Files" integrated directly alongside Subsonic, Jellyfin, and Web Stream as a first-class music source.
  - Uniform 2-column grid button layout ensuring identical dimensions across all provider options.
  - Context-aware settings visibility: hides Legacy Authentication for Jellyfin; hides server URL/credentials, Legacy Auth, Self-Signed Certs, and Advanced Options when selecting Local Files or Web Stream.
  - Replaced legacy bottom "Use Local Files" button with clean, inline scanning and access card.

- **iOS Platform Guard & App Store Sandbox Compliance**
  - Completely disabled and concealed Web Stream on iOS across login screens, server switcher sheets, storage profiles, and streaming handlers to strictly comply with iOS guidelines.

- **Privacy-First Architecture**
  - Completely removed Countly SDK, analytics trackers, and remote telemetry. Musly is 100% private with no background telemetry.

- **Localization & Translations**
  - Corrected ICU plural syntax warnings across French, Spanish, Italian, Portuguese, and Russian.
  - Adjusted Italian action button labels to eliminate text truncation and RenderFlex overflows.
  - Added Azerbaijani and Polish translations, localized audio focus denial, and fade in/out notifications.

### Fixed

- **Excessive Cover Art Requests (#199)**: Normalized cover art `cacheKey` in `AlbumArtwork` and disk cache to eliminate redundant duplicate network requests across sessions.
- **Local Music Library Scan UI Freezes (#195)**: Added asynchronous batch micro-yielding and robust error recovery to eliminate UI isolate freezes and Android ANR errors during large local music folder scans.
- **Mini-Player Navigation Visibility (#197)**: Modal bottom sheet now closes before navigating to artists from Now Playing, preserving mini-player visibility.
- **Emby & Jellyfin Library Selection (#188)**: Added `ParentId` and view filtering to prevent audiobooks and non-music collections from mixing with music library.
- **Android TV Remote Navigation (#183)**: Fixed D-Pad focus traversal and dedicated Android TV interface layout.
- **Interactive Login Error Reporting**: Fixed an issue where failed login attempts would reset the screen without displaying the error, now keeping the form mounted and showing categorized diagnostic cards with troubleshooting hints.
- **Desktop Onboarding Navigation**: Fixed `PageController` assertions on desktop and added full keyboard navigation shortcuts (`Arrow keys`, `Space`, `Enter`, `Escape`).
- **mTLS Crash on Connect (#218)**: Handled mutual TLS handshake exceptions gracefully without crashing.
- **Artist Blank Screen (#186)**: Multi-layer fallback lookup strategy for artists with missing ID or metadata.
- **Android Auto Compatibility**: Enhanced Android Auto service metadata resolution, browse tree loading, and focus request timeout handling.
- **Codebase Modernization**: Consolidated file structure, cleaned deprecated Flutter API usages, and eliminated all linter diagnostics.

## [1.0.13] - 2026-05-10

### Added

- **Now Playing Custom Themes** — Complete theme system for personalizing the Now Playing screen
  - Theme manager screen with create, edit, duplicate, export/import, and delete
  - 5 editor tabs: Background, Artwork, Text, Controls, Animations
  - Background types: Solid color, Gradient, Blur, Mesh gradient, Custom Flutter code (with safe mode)
  - Artwork shapes: Circle, Rounded Rectangle (fixed Musly default 12 px radius), Square (configurable corner radius 0–50 px)
  - Shadow intensity, rotation, and size factor controls
  - Cover rotation animation with configurable speed (3–60 seconds per full turn)
  - Pulse effect animation for artwork
  - Text styling for title, artist, album, and duration (font family, color, size, weight)
  - Control styling (color, size, spacing) and progress bar styling (color, height, shape)
  - Real-time animated preview in theme cards
  - All themes persisted to disk and survive app restarts

- **Gapless Playback** — Seamless track-to-track transitions via `ConcatenatingAudioSource`
  - Toggle in Playback settings to enable/disable
  - Preloads next track for instant switching

- **LRCLIB Lyrics Fallback** — Automatic lyrics lookup from LRCLIB when the Subsonic server has no lyrics
  - Toggle in Playback settings
  - Searches by song title and artist name

### Fixed

- **Playback Resume After App Restart** — Correctly restores playback position and prepares the audio source after cold start ([#171](https://github.com/dddevid/Musly/issues/171))
- **Seek with Transcoding** — Fixed broken seeking when using transcoding via `LockCachingAudioSource` ([#170](https://github.com/dddevid/Musly/issues/170))
- **Jukebox Mode UI** — Jukebox controls now properly integrated into the main playback controls ([#173](https://github.com/dddevid/Musly/issues/173))
- **Cache Memory Optimization** — Replaced JSON bulk cache with SQLite to prevent OOM crashes on libraries with 100 000+ items
- **iOS Deployment Target** — Lowered minimum iOS version from 16.1 back to 15.0 (removes Live Activities dependency on iOS)
- **Theme Editor Overflow** — Fixed all `RenderFlex` overflow errors in `ThemePreviewCard` and `ThemeEditorScreen`
- **Theme Editor Layout** — Removed unwanted leading whitespace from `TabBar` in `ThemeEditorScreen`
- **Duplicate Theme Dialog** — Fixed `_dependents.isEmpty` assertion crash when cancelling or swiping away the duplicate dialog
- **Export Theme on Mobile** — `FilePicker.saveFile` now correctly passes `bytes` on Android & iOS, resolving "invalid argument(s): Bytes are required"
- **Rotation Animation State** — Cover rotation animation now pauses when playback stops and resumes when it starts

### Changed

- **Library Cache Backend** — JSON bulk cache replaced by SQLite for significantly lower memory usage on large libraries
- **Theme Strings** — All hardcoded UI strings in the theme editor and preview card moved to ARB localization keys
- **PlayerProvider Lifecycle** — Debounce timer for queue persistence is now cancelled in `dispose()` to avoid timer leaks in tests

## [1.0.12] - 2026-05-09

### Added
- **Persistent Queue Across Restarts** ([#156](https://github.com/dddevid/Musly/issues/156))
  - Queue state (songs, current index, current song ID) saved to SharedPreferences
  - Automatically restores queue on app launch without auto-playing
  - Validates local file paths exist before restoring
  - Debounced save (200ms) to avoid excessive writes
  - Clears persisted data on explicit queue clear
- **Shuffle Persistence** — Shuffled queue order is now persisted alongside the queue, so reopening the app restores the correct shuffled sequence when shuffle mode is enabled
- **Artist Play Enhancement** ([#151](https://github.com/dddevid/Musly/pull/151))
  - "Play" button on artist screens now appends rest of artist's songs to their top songs
  - Provides fuller artist experience when pressing play
- **Collapsible Playlist Cover Art** — `PlaylistScreen` now uses a `SliverAppBar` with `FlexibleSpaceBar`, matching the collapsible behavior of `AlbumScreen`
- **All Songs Entry Restored** — "All Songs" tile added back to Library → Faves tab for quick access to the full song list
- **Comprehensive Test Suite** — Unit, widget, integration, security, and memory-leak tests with configurable Navidrome server support via `test_server_config.json`
- **Android Audio Session Configuration** — Explicit `AudioSession` setup for music playback on Android, ensuring proper audio focus and routing on car head units
- **Lyrics Wake Lock** — Screen stays on while lyrics view is visible to prevent display timeout during active listening
- **modern desktop Desktop UX Redesign** — Complete overhaul of desktop interface emulating Musly's design system
  - **3-Column Layout**: Fixed left sidebar (280px), expandable center content area, optional right sidebar (320px) for queue
  - **modern Dark Mode**: Deep black backgrounds (#000000, #121212, #181818) with consistent color palette
  - **Right Sidebar Queue**: Dedicated sidebar showing current playback queue with song artwork and metadata
  - **Enhanced Player Bar**: Improved 90px fixed bottom bar with Musly color scheme (#181818) and border (#282828)
  - **Micro-Interactions**: Smooth hover effects on all cards (1.04x scale, 16px elevation shadow, 200ms animations)
  - **Green Play Button**: signature green (#1DB954) circular play button appears on hover for albums and artists
  - **Quick Access Grid**: modern desktop quick access tiles with hover states and background transitions
  - **Gradient Header Widget**: Dynamic gradient headers that extract dominant colors from album artwork
  - **Updated Navigation Sidebar**: 280px width (expanded) with improved modern colors and hover states
  - **New Widgets**: `MuslyLikeCard`, `RightSidebar`, `QuickAccessGrid`, `GradientHeader` for reusable modern desktop components

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
  - Fixed syntax error causing build failure in `_buildRadioPlayer`
  - Status-bar icons now forced to white on dark background so they remain visible
- **modern and elegant Sliders** — Progress and volume bars redesigned with Musly aesthetics
  - Invisible thumb on mobile that grows to 28px with smooth animation when dragged
  - Track height animates from 3px to 5px during interaction with white glow effect
  - Desktop: thinner 3px tracks, smaller 5px thumbs, darker inactive track (#3A3A3A)
  - All transitions use 150ms easeOut curves for fluid micro-interactions
- **Android Audio Focus** — Playback now requests audio focus before starting, resolving no-sound issues on Android car head units and during remote playback
- **Android Playback Fix** — Resolved conflict between custom `AndroidSystemPlugin` and `audio_session` plugin that caused songs to start then immediately pause on Android devices
- **Windows Progress Bar** — Added fallback position polling timer for Windows desktop where `just_audio_windows` position stream does not emit reliably; progress bar and SMTC now update correctly during playback
- **Queue Layout** — Prevented queue list from sliding under the navigation bar on devices with gesture navigation
- **All Songs Screen** — Deferred `_loadCachedData` to post-frame callback, eliminating `setState during build` exception
- **Native Service Resilience** — `AuthProvider.logout()`, `PlayerProvider.dispose()`, `DiscordRpcService`, `WindowsSystemService`, and Android system services now gracefully handle missing native plugins in test environments
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
- **modern desktop Desktop UX**: Complete redesign of the PC layout
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
- **Google Cast Display**: Receiver now shows album art like Musly
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
