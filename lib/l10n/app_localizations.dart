import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ga.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_no.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sq.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_te.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('fr'),
    Locale('ga'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('nl'),
    Locale('no'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sq'),
    Locale('sv'),
    Locale('te'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Musly'**
  String get appName;

  /// Morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// Afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// Evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// For You section title
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYou;

  /// Quick Picks section title
  ///
  /// In en, this message translates to:
  /// **'Quick Picks'**
  String get quickPicks;

  /// Discover Mix section title
  ///
  /// In en, this message translates to:
  /// **'Discover Mix'**
  String get discoverMix;

  /// Recently played section title
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get recentlyPlayed;

  /// Your playlists section title
  ///
  /// In en, this message translates to:
  /// **'Your Playlists'**
  String get yourPlaylists;

  /// Favorite playlists section title on home screen
  ///
  /// In en, this message translates to:
  /// **'Favorite Playlists'**
  String get favoritePlaylists;

  /// Made for you section title
  ///
  /// In en, this message translates to:
  /// **'Made For You'**
  String get madeForYou;

  /// Top rated albums title
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get topRated;

  /// Message when no content is available
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;

  /// Message to try refreshing
  ///
  /// In en, this message translates to:
  /// **'Try refreshing or check your server connection'**
  String get tryRefreshing;

  /// Refresh button label
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Error message when songs fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading songs'**
  String get errorLoadingSongs;

  /// Message when genre has no songs
  ///
  /// In en, this message translates to:
  /// **'No songs in this genre'**
  String get noSongsInGenre;

  /// Error message when albums fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading albums'**
  String get errorLoadingAlbums;

  /// Message when there are no top rated albums
  ///
  /// In en, this message translates to:
  /// **'No top rated albums'**
  String get noTopRatedAlbums;

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Server URL field label
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Certificate selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select TLS/SSL Certificate'**
  String get selectCertificate;

  /// Error message when certificate selection fails
  ///
  /// In en, this message translates to:
  /// **'Failed to select certificate: {error}'**
  String failedToSelectCertificate(String error);

  /// Error message for invalid server URL
  ///
  /// In en, this message translates to:
  /// **'Server URL must start with http:// or https://'**
  String get serverUrlMustStartWith;

  /// Error message when connection fails
  ///
  /// In en, this message translates to:
  /// **'Failed to connect'**
  String get failedToConnect;

  /// Library tab label
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// Search tab label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Settings tab label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Albums section label
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albums;

  /// Artists section label
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artists;

  /// Songs section label
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songs;

  /// Playlists section label
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// Genres section label
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genres;

  /// Years filter tab label
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get years;

  /// Favorites section label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Now playing screen title
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlaying;

  /// Queue section label
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// Lyrics section label
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// Play button label
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Pause button label
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Next button label
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Previous button label
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Shuffle button label
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// Repeat button label
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// Repeat one button label
  ///
  /// In en, this message translates to:
  /// **'Repeat One'**
  String get repeatOne;

  /// Repeat off button label
  ///
  /// In en, this message translates to:
  /// **'Repeat Off'**
  String get repeatOff;

  /// Add to playlist option
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylist;

  /// Remove from playlist option
  ///
  /// In en, this message translates to:
  /// **'Remove from Playlist'**
  String get removeFromPlaylist;

  /// Add to favorites option
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// Remove from favorites option
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// Download button label
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// General settings section
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Appearance settings section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Playback settings section
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// Storage settings section
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// About settings section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Version info label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Developer credit
  ///
  /// In en, this message translates to:
  /// **'Made by dddevid'**
  String get madeBy;

  /// GitHub repository link label
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get githubRepository;

  /// Report issue link label
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// Discord community link label
  ///
  /// In en, this message translates to:
  /// **'Join Discord Community'**
  String get joinDiscord;

  /// Fallback displayed when a song has no artist
  ///
  /// In en, this message translates to:
  /// **'Unknown Artist'**
  String get unknownArtist;

  /// Placeholder for unknown album
  ///
  /// In en, this message translates to:
  /// **'Unknown Album'**
  String get unknownAlbum;

  /// Play all button label
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAll;

  /// Shuffle all button label
  ///
  /// In en, this message translates to:
  /// **'Shuffle All'**
  String get shuffleAll;

  /// Sort by label
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Sort by name option
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// Sort by artist option
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get sortByArtist;

  /// Sort by album option
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get sortByAlbum;

  /// Sort by date option
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortByDate;

  /// Sort by duration option
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sortByDuration;

  /// Ascending sort order
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// Descending sort order
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// Message when lyrics are not available
  ///
  /// In en, this message translates to:
  /// **'No lyrics available'**
  String get noLyricsAvailable;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Button to retry a failed server connection
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No search results message
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// Search field hint text
  ///
  /// In en, this message translates to:
  /// **'Search for songs, albums, artists...'**
  String get searchHint;

  /// All songs title
  ///
  /// In en, this message translates to:
  /// **'All Songs'**
  String get allSongs;

  /// All albums title
  ///
  /// In en, this message translates to:
  /// **'All Albums'**
  String get allAlbums;

  /// All artists title
  ///
  /// In en, this message translates to:
  /// **'All Artists'**
  String get allArtists;

  /// Track number label
  ///
  /// In en, this message translates to:
  /// **'Track {number}'**
  String trackNumber(int number);

  /// Songs count with plural support
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No songs} =1{1 song} other{{count} songs}}'**
  String songsCount(int count);

  /// Albums count with plural support
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No albums} =1{1 album} other{{count} albums}}'**
  String albumsCount(int count);

  /// Logout button label
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// Yes button label
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button label
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Offline mode label
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// Radio section label
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get radio;

  /// Changelog link label
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelog;

  /// Platform info label
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// Server settings section
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// Display settings section
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// Player Interface settings section
  ///
  /// In en, this message translates to:
  /// **'Player Interface'**
  String get playerInterface;

  /// Smart Recommendations settings section title
  ///
  /// In en, this message translates to:
  /// **'Smart Recommendations'**
  String get smartRecommendations;

  /// Show Volume Slider toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Volume Slider'**
  String get showVolumeSlider;

  /// Show Volume Slider toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Display volume control in Now Playing screen'**
  String get showVolumeSliderSubtitle;

  /// Show Star Ratings toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Star Ratings'**
  String get showStarRatings;

  /// Show Star Ratings toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Rate songs and view ratings'**
  String get showStarRatingsSubtitle;

  /// Show Heart button in mini player toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Heart Button'**
  String get showMiniPlayerHeart;

  /// Show Heart button in mini player toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Add to favorites from mini player'**
  String get showMiniPlayerHeartSubtitle;

  /// Show Repeat button in mini player toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Repeat Button'**
  String get showMiniPlayerRepeat;

  /// Show Repeat button in mini player toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Toggle repeat mode from mini player'**
  String get showMiniPlayerRepeatSubtitle;

  /// Show Shuffle button in mini player toggle label
  ///
  /// In en, this message translates to:
  /// **'Show Shuffle Button'**
  String get showMiniPlayerShuffle;

  /// Show Shuffle button in mini player toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Toggle shuffle from mini player'**
  String get showMiniPlayerShuffleSubtitle;

  /// Enable Recommendations toggle label
  ///
  /// In en, this message translates to:
  /// **'Enable Recommendations'**
  String get enableRecommendations;

  /// Enable Recommendations toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Get personalized music suggestions'**
  String get enableRecommendationsSubtitle;

  /// Listening Data section label
  ///
  /// In en, this message translates to:
  /// **'Listening Data'**
  String get listeningData;

  /// Total plays count
  ///
  /// In en, this message translates to:
  /// **'{count} total plays'**
  String totalPlays(int count);

  /// Clear Listening History button label
  ///
  /// In en, this message translates to:
  /// **'Clear Listening History'**
  String get clearListeningHistory;

  /// Confirmation dialog for clearing history
  ///
  /// In en, this message translates to:
  /// **'This will reset all your listening data and recommendations. Are you sure?'**
  String get confirmClearHistory;

  /// SnackBar message when history is cleared
  ///
  /// In en, this message translates to:
  /// **'Listening history cleared'**
  String get historyCleared;

  /// Discord RPC toggle label
  ///
  /// In en, this message translates to:
  /// **'Discord Status'**
  String get discordStatus;

  /// Discord RPC toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Show playing song on Discord profile'**
  String get discordStatusSubtitle;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// System default language option
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// Community translations credit label
  ///
  /// In en, this message translates to:
  /// **'Translations by Community'**
  String get communityTranslations;

  /// Community translations credit subtitle
  ///
  /// In en, this message translates to:
  /// **'Help translate Musly on Crowdin'**
  String get communityTranslationsSubtitle;

  /// No description provided for @yourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your Library'**
  String get yourLibrary;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @faves.
  ///
  /// In en, this message translates to:
  /// **'Faves'**
  String get faves;

  /// No description provided for @filterPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get filterPlaylists;

  /// No description provided for @filterAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get filterAlbums;

  /// No description provided for @filterArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get filterArtists;

  /// No description provided for @likedSongs.
  ///
  /// In en, this message translates to:
  /// **'Liked Songs'**
  String get likedSongs;

  /// No description provided for @likedAlbums.
  ///
  /// In en, this message translates to:
  /// **'Liked Albums'**
  String get likedAlbums;

  /// No description provided for @noLikedAlbums.
  ///
  /// In en, this message translates to:
  /// **'No liked albums yet'**
  String get noLikedAlbums;

  /// No description provided for @localMusicLibrary.
  ///
  /// In en, this message translates to:
  /// **'Local Music Library'**
  String get localMusicLibrary;

  /// No description provided for @mergeLocalLibrary.
  ///
  /// In en, this message translates to:
  /// **'Merge with Server Library'**
  String get mergeLocalLibrary;

  /// No description provided for @mergeLocalLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show local music alongside your server library'**
  String get mergeLocalLibrarySubtitle;

  /// No description provided for @localMusicStats.
  ///
  /// In en, this message translates to:
  /// **'Local Music Files'**
  String get localMusicStats;

  /// No description provided for @addMusicFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Music Folder'**
  String get addMusicFolder;

  /// No description provided for @rescanLocalMusic.
  ///
  /// In en, this message translates to:
  /// **'Rescan Local Music'**
  String get rescanLocalMusic;

  /// No description provided for @localLibraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get localLibraryEmpty;

  /// No description provided for @localLibraryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No local music files were found. Tap the button below to scan again.'**
  String get localLibraryEmptySubtitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get libraryEmpty;

  /// No description provided for @libraryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add some songs to get started.'**
  String get libraryEmptySubtitle;

  /// No description provided for @scanForMusic.
  ///
  /// In en, this message translates to:
  /// **'Scan for Music'**
  String get scanForMusic;

  /// No description provided for @radioStations.
  ///
  /// In en, this message translates to:
  /// **'Radio Stations'**
  String get radioStations;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// Subtitle shown in the mini player and player bar when a radio station is playing
  ///
  /// In en, this message translates to:
  /// **'Internet Radio'**
  String get internetRadio;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get newPlaylist;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get playlistName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// No description provided for @deletePlaylistConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the playlist \"{name}\"?'**
  String deletePlaylistConfirmation(String name);

  /// No description provided for @playlistDeleted.
  ///
  /// In en, this message translates to:
  /// **'Playlist \"{name}\" deleted'**
  String playlistDeleted(String name);

  /// No description provided for @errorCreatingPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Error creating playlist: {error}'**
  String errorCreatingPlaylist(Object error);

  /// No description provided for @errorDeletingPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Error deleting playlist: {error}'**
  String errorDeletingPlaylist(Object error);

  /// No description provided for @playlistCreated.
  ///
  /// In en, this message translates to:
  /// **'Playlist \"{name}\" created'**
  String playlistCreated(String name);

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Artists, Songs, Albums'**
  String get searchPlaceholder;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search'**
  String get tryDifferentSearch;

  /// No description provided for @noSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No suggestions'**
  String get noSuggestions;

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse Categories'**
  String get browseCategories;

  /// No description provided for @liveSearchSection.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get liveSearchSection;

  /// No description provided for @liveSearch.
  ///
  /// In en, this message translates to:
  /// **'Live Search'**
  String get liveSearch;

  /// No description provided for @liveSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update results as you type instead of showing a dropdown'**
  String get liveSearchSubtitle;

  /// No description provided for @categoryMadeForYou.
  ///
  /// In en, this message translates to:
  /// **'Made For You'**
  String get categoryMadeForYou;

  /// No description provided for @categoryNewReleases.
  ///
  /// In en, this message translates to:
  /// **'New Releases'**
  String get categoryNewReleases;

  /// No description provided for @categoryTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get categoryTopRated;

  /// No description provided for @categoryGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get categoryGenres;

  /// No description provided for @categoryFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get categoryFavorites;

  /// No description provided for @categoryRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get categoryRadio;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @tabPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get tabPlayback;

  /// No description provided for @tabStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get tabStorage;

  /// No description provided for @tabServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get tabServer;

  /// No description provided for @tabDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get tabDisplay;

  /// No description provided for @tabSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get tabSupport;

  /// No description provided for @tabAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get tabAbout;

  /// Playback settings section header for Auto DJ
  ///
  /// In en, this message translates to:
  /// **'AUTO DJ'**
  String get sectionAutoDj;

  /// No description provided for @autoDjMode.
  ///
  /// In en, this message translates to:
  /// **'Auto DJ Mode'**
  String get autoDjMode;

  /// No description provided for @songsToAdd.
  ///
  /// In en, this message translates to:
  /// **'Songs to Add: {count}'**
  String songsToAdd(int count);

  /// No description provided for @sectionReplayGain.
  ///
  /// In en, this message translates to:
  /// **'VOLUME NORMALIZATION (REPLAYGAIN)'**
  String get sectionReplayGain;

  /// Label for the ReplayGain mode selector
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get replayGainMode;

  /// No description provided for @preamp.
  ///
  /// In en, this message translates to:
  /// **'Preamp: {value} dB'**
  String preamp(String value);

  /// No description provided for @preventClipping.
  ///
  /// In en, this message translates to:
  /// **'Prevent Clipping'**
  String get preventClipping;

  /// No description provided for @fallbackGain.
  ///
  /// In en, this message translates to:
  /// **'Fallback Gain: {value} dB'**
  String fallbackGain(String value);

  /// Playback settings section header for transcoding / streaming quality
  ///
  /// In en, this message translates to:
  /// **'STREAMING QUALITY'**
  String get sectionStreamingQuality;

  /// No description provided for @enableTranscoding.
  ///
  /// In en, this message translates to:
  /// **'Enable Transcoding'**
  String get enableTranscoding;

  /// No description provided for @qualityWifi.
  ///
  /// In en, this message translates to:
  /// **'WiFi Quality'**
  String get qualityWifi;

  /// No description provided for @qualityMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile Quality'**
  String get qualityMobile;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @transcodingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reduce data usage with lower quality'**
  String get transcodingSubtitle;

  /// No description provided for @modeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get modeOff;

  /// No description provided for @modeTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get modeTrack;

  /// No description provided for @modeAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get modeAlbum;

  /// No description provided for @sectionServerConnection.
  ///
  /// In en, this message translates to:
  /// **'SERVER CONNECTION'**
  String get sectionServerConnection;

  /// No description provided for @serverType.
  ///
  /// In en, this message translates to:
  /// **'Server Type'**
  String get serverType;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @sectionMusicFolders.
  ///
  /// In en, this message translates to:
  /// **'MUSIC FOLDERS'**
  String get sectionMusicFolders;

  /// No description provided for @musicFolders.
  ///
  /// In en, this message translates to:
  /// **'Music Folders'**
  String get musicFolders;

  /// No description provided for @noMusicFolders.
  ///
  /// In en, this message translates to:
  /// **'No music folders found'**
  String get noMusicFolders;

  /// No description provided for @sectionSavedProfiles.
  ///
  /// In en, this message translates to:
  /// **'SAVED PROFILES'**
  String get sectionSavedProfiles;

  /// No description provided for @switchProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch Profile'**
  String get switchProfile;

  /// No description provided for @switchServer.
  ///
  /// In en, this message translates to:
  /// **'Switch Server'**
  String get switchServer;

  /// No description provided for @addProfile.
  ///
  /// In en, this message translates to:
  /// **'Add Profile'**
  String get addProfile;

  /// No description provided for @switchProfileConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Connect to \"{profile}\"?'**
  String switchProfileConfirmation(String profile);

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get sectionAccount;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout? This will also clear all cached data.'**
  String get logoutConfirmation;

  /// Storage settings section header
  ///
  /// In en, this message translates to:
  /// **'CACHE SETTINGS'**
  String get sectionCacheSettings;

  /// No description provided for @imageCache.
  ///
  /// In en, this message translates to:
  /// **'Image Cache'**
  String get imageCache;

  /// No description provided for @musicCache.
  ///
  /// In en, this message translates to:
  /// **'Music Cache'**
  String get musicCache;

  /// No description provided for @bpmCache.
  ///
  /// In en, this message translates to:
  /// **'BPM Cache'**
  String get bpmCache;

  /// No description provided for @saveAlbumCovers.
  ///
  /// In en, this message translates to:
  /// **'Save album covers locally'**
  String get saveAlbumCovers;

  /// No description provided for @saveSongMetadata.
  ///
  /// In en, this message translates to:
  /// **'Save song metadata locally'**
  String get saveSongMetadata;

  /// No description provided for @saveBpmAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Save BPM analysis locally'**
  String get saveBpmAnalysis;

  /// Storage settings section header for cache cleanup
  ///
  /// In en, this message translates to:
  /// **'CACHE CLEANUP'**
  String get sectionCacheCleanup;

  /// Button to clear all cached data
  ///
  /// In en, this message translates to:
  /// **'Clear All Cache'**
  String get clearAllCache;

  /// No description provided for @allCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'All cache cleared'**
  String get allCacheCleared;

  /// Storage settings section header for offline downloads
  ///
  /// In en, this message translates to:
  /// **'OFFLINE DOWNLOADS'**
  String get sectionOfflineDownloads;

  /// No description provided for @downloadedSongs.
  ///
  /// In en, this message translates to:
  /// **'Downloaded Songs'**
  String get downloadedSongs;

  /// No description provided for @downloadingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Downloading Library... {progress}/{total}'**
  String downloadingLibrary(int progress, int total);

  /// No description provided for @downloadAllLibrary.
  ///
  /// In en, this message translates to:
  /// **'Download All Library'**
  String get downloadAllLibrary;

  /// No description provided for @downloadLibraryConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will download {count} songs to your device. This may take a while and use significant storage space.\n\nContinue?'**
  String downloadLibraryConfirm(int count);

  /// Toggle to keep screen on during library download
  ///
  /// In en, this message translates to:
  /// **'Keep Screen On'**
  String get keepScreenOnDuringDownload;

  /// Subtitle explaining why to keep screen on during download
  ///
  /// In en, this message translates to:
  /// **'Prevents download from failing when device locks'**
  String get keepScreenOnDuringDownloadSubtitle;

  /// No description provided for @parallelDownloads.
  ///
  /// In en, this message translates to:
  /// **'Parallel Downloads'**
  String get parallelDownloads;

  /// No description provided for @parallelDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download multiple songs simultaneously'**
  String get parallelDownloadsSubtitle;

  /// No description provided for @downloadSingular.
  ///
  /// In en, this message translates to:
  /// **'download'**
  String get downloadSingular;

  /// No description provided for @downloadPlural.
  ///
  /// In en, this message translates to:
  /// **'downloads'**
  String get downloadPlural;

  /// No description provided for @slowerButStable.
  ///
  /// In en, this message translates to:
  /// **'Slower but more stable'**
  String get slowerButStable;

  /// No description provided for @fasterButMoreData.
  ///
  /// In en, this message translates to:
  /// **'Faster but uses more data'**
  String get fasterButMoreData;

  /// No description provided for @libraryDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Library download started'**
  String get libraryDownloadStarted;

  /// No description provided for @deleteDownloads.
  ///
  /// In en, this message translates to:
  /// **'Delete All Downloads'**
  String get deleteDownloads;

  /// No description provided for @downloadsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All downloads deleted'**
  String get downloadsDeleted;

  /// No description provided for @noSongsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No songs available. Please load your library first.'**
  String get noSongsAvailable;

  /// Storage settings section header for BPM analysis
  ///
  /// In en, this message translates to:
  /// **'BPM ANALYSIS'**
  String get sectionBpmAnalysis;

  /// No description provided for @cachedBpms.
  ///
  /// In en, this message translates to:
  /// **'Cached BPMs'**
  String get cachedBpms;

  /// No description provided for @cacheAllBpms.
  ///
  /// In en, this message translates to:
  /// **'Cache All BPMs'**
  String get cacheAllBpms;

  /// No description provided for @clearBpmCache.
  ///
  /// In en, this message translates to:
  /// **'Clear BPM Cache'**
  String get clearBpmCache;

  /// No description provided for @bpmCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'BPM cache cleared'**
  String get bpmCacheCleared;

  /// No description provided for @downloadedStats.
  ///
  /// In en, this message translates to:
  /// **'{count} songs • {size}'**
  String downloadedStats(int count, String size);

  /// No description provided for @sectionInformation.
  ///
  /// In en, this message translates to:
  /// **'INFORMATION'**
  String get sectionInformation;

  /// No description provided for @sectionDeveloper.
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER'**
  String get sectionDeveloper;

  /// No description provided for @sectionLinks.
  ///
  /// In en, this message translates to:
  /// **'LINKS'**
  String get sectionLinks;

  /// No description provided for @githubRepo.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get githubRepo;

  /// No description provided for @playingFrom.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM'**
  String get playingFrom;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @streamingLive.
  ///
  /// In en, this message translates to:
  /// **'Streaming Live'**
  String get streamingLive;

  /// No description provided for @stopRadio.
  ///
  /// In en, this message translates to:
  /// **'Stop Radio'**
  String get stopRadio;

  /// No description provided for @removeFromLiked.
  ///
  /// In en, this message translates to:
  /// **'Remove from Liked Songs'**
  String get removeFromLiked;

  /// No description provided for @addToLiked.
  ///
  /// In en, this message translates to:
  /// **'Add to Liked Songs'**
  String get addToLiked;

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play Next'**
  String get playNext;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to Queue'**
  String get addToQueue;

  /// No description provided for @goToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Go to Album'**
  String get goToAlbum;

  /// No description provided for @goToArtist.
  ///
  /// In en, this message translates to:
  /// **'Go to Artist'**
  String get goToArtist;

  /// No description provided for @rateSong.
  ///
  /// In en, this message translates to:
  /// **'Rate Song'**
  String get rateSong;

  /// No description provided for @rateSongValue.
  ///
  /// In en, this message translates to:
  /// **'Rate Song ({rating} {stars})'**
  String rateSongValue(int rating, String stars);

  /// No description provided for @ratingRemoved.
  ///
  /// In en, this message translates to:
  /// **'Rating removed'**
  String get ratingRemoved;

  /// No description provided for @rated.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} {stars}'**
  String rated(int rating, String stars);

  /// No description provided for @removeRating.
  ///
  /// In en, this message translates to:
  /// **'Remove Rating'**
  String get removeRating;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading... {percent}%'**
  String downloading(int percent);

  /// No description provided for @removeDownload.
  ///
  /// In en, this message translates to:
  /// **'Remove Download'**
  String get removeDownload;

  /// No description provided for @removeDownloadConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this song from offline storage?'**
  String get removeDownloadConfirm;

  /// No description provided for @downloadRemoved.
  ///
  /// In en, this message translates to:
  /// **'Download removed'**
  String get downloadRemoved;

  /// No description provided for @downloadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded \"{title}\"'**
  String downloadedTitle(String title);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @downloadError.
  ///
  /// In en, this message translates to:
  /// **'Download error: {error}'**
  String downloadError(Object error);

  /// No description provided for @addedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to {playlist}'**
  String addedToPlaylist(String title, String playlist);

  /// No description provided for @errorAddingToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Error adding to playlist: {error}'**
  String errorAddingToPlaylist(Object error);

  /// No description provided for @noPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists available'**
  String get noPlaylists;

  /// No description provided for @createNewPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create New Playlist'**
  String get createNewPlaylist;

  /// No description provided for @artistNotFound.
  ///
  /// In en, this message translates to:
  /// **'Artist \"{name}\" not found'**
  String artistNotFound(String name);

  /// No description provided for @errorSearchingArtist.
  ///
  /// In en, this message translates to:
  /// **'Error searching for artist: {error}'**
  String errorSearchingArtist(Object error);

  /// No description provided for @selectArtist.
  ///
  /// In en, this message translates to:
  /// **'Select Artist'**
  String get selectArtist;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @star.
  ///
  /// In en, this message translates to:
  /// **'star'**
  String get star;

  /// No description provided for @stars.
  ///
  /// In en, this message translates to:
  /// **'stars'**
  String get stars;

  /// Message when album data is not available
  ///
  /// In en, this message translates to:
  /// **'Album not found'**
  String get albumNotFound;

  /// Album duration in hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{hours} HR {minutes} MIN'**
  String durationHoursMinutes(int hours, int minutes);

  /// Album duration in minutes only
  ///
  /// In en, this message translates to:
  /// **'{minutes} MIN'**
  String durationMinutes(int minutes);

  /// Top songs section header on artist screen
  ///
  /// In en, this message translates to:
  /// **'Top Songs'**
  String get topSongs;

  /// Server connection status — connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Placeholder when no song is loaded in the player
  ///
  /// In en, this message translates to:
  /// **'No song playing'**
  String get noSongPlaying;

  /// Uppercase badge shown in the now-playing radio player
  ///
  /// In en, this message translates to:
  /// **'INTERNET RADIO'**
  String get internetRadioUppercase;

  /// Title of the queue / playing-next bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Playing Next'**
  String get playingNext;

  /// Title of the create-new-playlist dialog
  ///
  /// In en, this message translates to:
  /// **'Create Playlist'**
  String get createPlaylistTitle;

  /// Hint text for the playlist name input field
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistNameHint;

  /// Snackbar shown after creating a playlist with the current song
  ///
  /// In en, this message translates to:
  /// **'Created playlist \"{name}\" with this song'**
  String playlistCreatedWithSong(String name);

  /// Snackbar shown when playlists fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading playlists: {error}'**
  String errorLoadingPlaylists(Object error);

  /// Message when a playlist cannot be found
  ///
  /// In en, this message translates to:
  /// **'Playlist not found'**
  String get playlistNotFound;

  /// Empty state message for a playlist with no songs
  ///
  /// In en, this message translates to:
  /// **'No songs in this playlist'**
  String get noSongsInPlaylist;

  /// Empty state for the favorite songs list
  ///
  /// In en, this message translates to:
  /// **'No favorite songs yet'**
  String get noFavoriteSongsYet;

  /// Empty state for the favorite albums list
  ///
  /// In en, this message translates to:
  /// **'No favorite albums yet'**
  String get noFavoriteAlbumsYet;

  /// Title of the listening history screen
  ///
  /// In en, this message translates to:
  /// **'Listening History'**
  String get listeningHistory;

  /// Empty state headline on the history screen
  ///
  /// In en, this message translates to:
  /// **'No Listening History'**
  String get noListeningHistory;

  /// Empty state subtitle on the history screen
  ///
  /// In en, this message translates to:
  /// **'Songs you play will appear here'**
  String get songsWillAppearHere;

  /// Sort option: title ascending
  ///
  /// In en, this message translates to:
  /// **'Title (A-Z)'**
  String get sortByTitleAZ;

  /// Sort option: title descending
  ///
  /// In en, this message translates to:
  /// **'Title (Z-A)'**
  String get sortByTitleZA;

  /// Sort option: artist ascending
  ///
  /// In en, this message translates to:
  /// **'Artist (A-Z)'**
  String get sortByArtistAZ;

  /// Sort option: artist descending
  ///
  /// In en, this message translates to:
  /// **'Artist (Z-A)'**
  String get sortByArtistZA;

  /// Sort option: album ascending
  ///
  /// In en, this message translates to:
  /// **'Album (A-Z)'**
  String get sortByAlbumAZ;

  /// Sort option: album descending
  ///
  /// In en, this message translates to:
  /// **'Album (Z-A)'**
  String get sortByAlbumZA;

  /// Sort option: recently added
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get recentlyAdded;

  /// Empty state when no songs match a filter
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get noSongsFound;

  /// Empty state when no albums match a filter
  ///
  /// In en, this message translates to:
  /// **'No albums found'**
  String get noAlbumsFound;

  /// Snackbar when a radio station has no homepage URL
  ///
  /// In en, this message translates to:
  /// **'No homepage URL available'**
  String get noHomepageUrl;

  /// Context menu option to play a radio station
  ///
  /// In en, this message translates to:
  /// **'Play Station'**
  String get playStation;

  /// Context menu option to open a radio station's homepage
  ///
  /// In en, this message translates to:
  /// **'Open Homepage'**
  String get openHomepage;

  /// Context menu option to copy a radio station stream URL
  ///
  /// In en, this message translates to:
  /// **'Copy Stream URL'**
  String get copyStreamUrl;

  /// Error state message on the radio screen
  ///
  /// In en, this message translates to:
  /// **'Failed to load radio stations'**
  String get failedToLoadRadioStations;

  /// Empty state headline on the radio screen
  ///
  /// In en, this message translates to:
  /// **'No Radio Stations'**
  String get noRadioStations;

  /// Empty state subtitle on the radio screen
  ///
  /// In en, this message translates to:
  /// **'Add radio stations in your Navidrome server settings to see them here.'**
  String get noRadioStationsHint;

  /// Subtitle below the app name on the login screen
  ///
  /// In en, this message translates to:
  /// **'Connect to your Subsonic server'**
  String get connectToServerSubtitle;

  /// Validation message when server URL is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter server URL'**
  String get pleaseEnterServerUrl;

  /// Validation message when server URL format is invalid
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get invalidUrlFormat;

  /// Validation message when username is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter username'**
  String get pleaseEnterUsername;

  /// Validation message when password is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// Toggle label for legacy Subsonic authentication
  ///
  /// In en, this message translates to:
  /// **'Legacy Authentication'**
  String get legacyAuthentication;

  /// Subtitle for the legacy authentication toggle
  ///
  /// In en, this message translates to:
  /// **'Use for older Subsonic servers'**
  String get legacyAuthSubtitle;

  /// Toggle label to allow self-signed TLS certificates
  ///
  /// In en, this message translates to:
  /// **'Allow Self-Signed Certificates'**
  String get allowSelfSignedCerts;

  /// Subtitle for the self-signed certificate toggle
  ///
  /// In en, this message translates to:
  /// **'For servers with custom TLS/SSL certificates'**
  String get allowSelfSignedSubtitle;

  /// Expandable section label for advanced login options
  ///
  /// In en, this message translates to:
  /// **'Advanced Options'**
  String get advancedOptions;

  /// Label for the custom certificate upload section
  ///
  /// In en, this message translates to:
  /// **'Custom TLS/SSL Certificate'**
  String get customTlsCertificate;

  /// Subtitle for the custom certificate upload section
  ///
  /// In en, this message translates to:
  /// **'Upload a custom certificate for servers with non-standard CA'**
  String get customCertificateSubtitle;

  /// Button label to open the certificate file picker
  ///
  /// In en, this message translates to:
  /// **'Select Certificate File'**
  String get selectCertificateFile;

  /// Label for the mutual TLS client certificate section
  ///
  /// In en, this message translates to:
  /// **'Client Certificate (mTLS)'**
  String get clientCertificate;

  /// Subtitle for the client certificate (mTLS) section
  ///
  /// In en, this message translates to:
  /// **'Authenticate this client using a certificate (requires mTLS-enabled server)'**
  String get clientCertificateSubtitle;

  /// Button label to open the client certificate file picker
  ///
  /// In en, this message translates to:
  /// **'Select Client Certificate'**
  String get selectClientCertificate;

  /// Hint text for the PKCS12 client certificate password field
  ///
  /// In en, this message translates to:
  /// **'Certificate password (optional)'**
  String get clientCertPassword;

  /// Error message when client certificate selection fails
  ///
  /// In en, this message translates to:
  /// **'Failed to select client certificate: {error}'**
  String failedToSelectClientCert(String error);

  /// Login submit button label
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Divider label between Connect and Use Local Files
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// Button label to start local-files mode
  ///
  /// In en, this message translates to:
  /// **'Use Local Files'**
  String get useLocalFiles;

  /// Initial status message when a local file scan begins
  ///
  /// In en, this message translates to:
  /// **'Starting scan...'**
  String get startingScan;

  /// Snackbar when storage permission is denied
  ///
  /// In en, this message translates to:
  /// **'Storage permission required to scan local files'**
  String get storagePermissionRequired;

  /// Snackbar when a local scan finds no audio files
  ///
  /// In en, this message translates to:
  /// **'No music files found on your device'**
  String get noMusicFilesFound;

  /// Generic remove / delete confirm button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Snackbar shown when setting a star rating fails
  ///
  /// In en, this message translates to:
  /// **'Failed to set rating: {error}'**
  String failedToSetRating(Object error);

  /// Home navigation item label in the desktop sidebar
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Uppercase section header for playlists in the desktop sidebar
  ///
  /// In en, this message translates to:
  /// **'PLAYLISTS'**
  String get playlistsSection;

  /// Tooltip/label for the sidebar collapse button
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// Tooltip/label for the sidebar expand button
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// Tooltip/label for the create-playlist button in the sidebar library header
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get createPlaylist;

  /// Liked Songs item label in the desktop sidebar
  ///
  /// In en, this message translates to:
  /// **'Liked Songs'**
  String get likedSongsSidebar;

  /// Subtitle for a playlist item in the desktop sidebar
  ///
  /// In en, this message translates to:
  /// **'Playlist • {count} songs'**
  String playlistSongsCount(int count);

  /// Error state message when lyrics cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Failed to load lyrics'**
  String get failedToLoadLyrics;

  /// Empty/error subtitle in the lyrics view
  ///
  /// In en, this message translates to:
  /// **'Lyrics for this song couldn\'t be found'**
  String get lyricsNotFoundSubtitle;

  /// Button to scroll the lyrics view back to the current line
  ///
  /// In en, this message translates to:
  /// **'Back to current'**
  String get backToCurrent;

  /// Tooltip for the exit-fullscreen button in lyrics view
  ///
  /// In en, this message translates to:
  /// **'Exit Fullscreen'**
  String get exitFullscreen;

  /// Tooltip for the enter-fullscreen button in lyrics view
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// Fallback text when no lyrics controller is available
  ///
  /// In en, this message translates to:
  /// **'No lyrics'**
  String get noLyrics;

  /// Subtitle shown in the mini player when streaming internet radio
  ///
  /// In en, this message translates to:
  /// **'Internet Radio'**
  String get internetRadioMiniPlayer;

  /// Badge text shown in the mini player for live radio streams
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveBadge;

  /// Banner shown at the top of the screen in local-files mode
  ///
  /// In en, this message translates to:
  /// **'Local Files Mode'**
  String get localFilesModeBanner;

  /// Banner shown at the top of the screen in offline mode
  ///
  /// In en, this message translates to:
  /// **'Offline Mode – Playing downloaded music only'**
  String get offlineModeBanner;

  /// Title of the update available dialog
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// Subtitle in the update dialog
  ///
  /// In en, this message translates to:
  /// **'A new version of Musly is available!'**
  String get updateAvailableSubtitle;

  /// Current version label in the update dialog
  ///
  /// In en, this message translates to:
  /// **'Current: v{version}'**
  String updateCurrentVersion(String version);

  /// Latest version label in the update dialog
  ///
  /// In en, this message translates to:
  /// **'Latest: v{version}'**
  String updateLatestVersion(String version);

  /// Section header for the changelog in the update dialog
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whatsNew;

  /// Primary button in the update dialog that opens the release page
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadUpdate;

  /// Dismiss button in the update dialog
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get remindLater;

  /// See All button in horizontal scroll sections
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// Error state on the artist screen when artist data fails to load
  ///
  /// In en, this message translates to:
  /// **'Artist not found'**
  String get artistDataNotFound;

  /// Snackbar when user adds artist to queue
  ///
  /// In en, this message translates to:
  /// **'Added artist to Queue'**
  String get addedArtistToQueue;

  /// Error shown in snackbar when adding artist to queue fails
  ///
  /// In en, this message translates to:
  /// **'Failed adding artist to Queue'**
  String get addedArtistToQueueError;

  /// Title shown in the Chromecast control dialog when actively casting
  ///
  /// In en, this message translates to:
  /// **'Casting'**
  String get casting;

  /// Title shown in the DLNA control dialog when connected
  ///
  /// In en, this message translates to:
  /// **'DLNA'**
  String get dlna;

  /// Title of the Cast/DLNA device picker dialog
  ///
  /// In en, this message translates to:
  /// **'Cast / DLNA (Beta)'**
  String get castDlnaBeta;

  /// Section header for Chromecast devices in the device picker
  ///
  /// In en, this message translates to:
  /// **'Chromecast'**
  String get chromecast;

  /// Section header for DLNA/UPnP devices in the device picker
  ///
  /// In en, this message translates to:
  /// **'DLNA / UPnP'**
  String get dlnaUpnp;

  /// Button to clear server credentials and go back to login
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Loading message in the device picker when no devices have been found yet
  ///
  /// In en, this message translates to:
  /// **'Searching for devices'**
  String get searchingDevices;

  /// Hint shown while searching for cast/DLNA devices
  ///
  /// In en, this message translates to:
  /// **'Make sure your Cast / DLNA device\nis on the same Wi-Fi network'**
  String get castWifiHint;

  /// Snackbar shown after successfully connecting to a cast/DLNA device
  ///
  /// In en, this message translates to:
  /// **'Connected to {name}'**
  String connectedToDevice(String name);

  /// Snackbar shown when connecting to a cast/DLNA device fails
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to {name}'**
  String failedToConnectDevice(String name);

  /// Snackbar shown after un-liking a song in the song tile menu
  ///
  /// In en, this message translates to:
  /// **'Removed from Liked Songs'**
  String get removedFromLikedSongs;

  /// Snackbar shown after liking a song in the song tile menu
  ///
  /// In en, this message translates to:
  /// **'Added to Liked Songs'**
  String get addedToLikedSongs;

  /// Tooltip for the shuffle toggle button in the desktop player bar
  ///
  /// In en, this message translates to:
  /// **'Enable shuffle'**
  String get enableShuffle;

  /// Tooltip for the repeat toggle button in the desktop player bar
  ///
  /// In en, this message translates to:
  /// **'Enable repeat'**
  String get enableRepeat;

  /// Tooltip for the cast button when connecting to a device
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// Tooltip for the lyrics button when lyrics panel is open
  ///
  /// In en, this message translates to:
  /// **'Close Lyrics'**
  String get closeLyrics;

  /// Snackbar shown when the library background download fails to start
  ///
  /// In en, this message translates to:
  /// **'Error starting download: {error}'**
  String errorStartingDownload(Object error);

  /// Error message when the genre list fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading genres'**
  String get errorLoadingGenres;

  /// Empty state when no genres are returned from the server
  ///
  /// In en, this message translates to:
  /// **'No genres found'**
  String get noGenresFound;

  /// Empty state on the Albums tab of the genre screen
  ///
  /// In en, this message translates to:
  /// **'No albums in this genre'**
  String get noAlbumsInGenre;

  /// Tooltip shown when hovering a genre chip, showing song and album counts
  ///
  /// In en, this message translates to:
  /// **'{songCount} songs • {albumCount} albums'**
  String genreTooltip(int songCount, int albumCount);

  /// Section header for the jukebox settings in the Server tab
  ///
  /// In en, this message translates to:
  /// **'JUKEBOX MODE'**
  String get sectionJukebox;

  /// Toggle label for enabling jukebox mode
  ///
  /// In en, this message translates to:
  /// **'Jukebox Mode'**
  String get jukeboxMode;

  /// Subtitle for the jukebox mode toggle
  ///
  /// In en, this message translates to:
  /// **'Play audio through the server instead of this device'**
  String get jukeboxModeSubtitle;

  /// List tile label to navigate to the jukebox controller screen
  ///
  /// In en, this message translates to:
  /// **'Open Jukebox Controller'**
  String get openJukeboxController;

  /// Action label to clear the jukebox playback queue
  ///
  /// In en, this message translates to:
  /// **'Clear Queue'**
  String get jukeboxClearQueue;

  /// Action label to shuffle the jukebox playback queue
  ///
  /// In en, this message translates to:
  /// **'Shuffle Queue'**
  String get jukeboxShuffleQueue;

  /// Empty state when the jukebox queue has no songs
  ///
  /// In en, this message translates to:
  /// **'No songs in queue'**
  String get jukeboxQueueEmpty;

  /// Section header for the now-playing area in the jukebox controller
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get jukeboxNowPlaying;

  /// Section header for the queue list in the jukebox controller
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get jukeboxQueue;

  /// Label for the volume slider in the jukebox controller
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get jukeboxVolume;

  /// Option to replace the jukebox queue with this song and start playback
  ///
  /// In en, this message translates to:
  /// **'Play on Jukebox'**
  String get playOnJukebox;

  /// Option to append a song to the jukebox queue
  ///
  /// In en, this message translates to:
  /// **'Add to Jukebox Queue'**
  String get addToJukeboxQueue;

  /// Error shown when the server returns 501 for jukebox API calls
  ///
  /// In en, this message translates to:
  /// **'Jukebox mode is not supported by this server. Enable it in your server configuration (e.g. EnableJukebox = true in Navidrome).'**
  String get jukeboxNotSupported;

  /// Title of the music folders selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Music Folders'**
  String get musicFoldersDialogTitle;

  /// Hint text in the music folders selection dialog
  ///
  /// In en, this message translates to:
  /// **'Leave all enabled to use all folders (default).'**
  String get musicFoldersHint;

  /// Snackbar shown after saving music folder selection
  ///
  /// In en, this message translates to:
  /// **'Music folder selection saved'**
  String get musicFoldersSaved;

  /// Display settings section header for artwork customisation
  ///
  /// In en, this message translates to:
  /// **'Artwork Style'**
  String get artworkStyleSection;

  /// Label for the album art corner radius slider
  ///
  /// In en, this message translates to:
  /// **'Corner Radius'**
  String get artworkCornerRadius;

  /// Subtitle for the album art corner radius slider
  ///
  /// In en, this message translates to:
  /// **'Adjust how round the corners of album covers appear'**
  String get artworkCornerRadiusSubtitle;

  /// Label shown when corner radius is set to 0 (no rounded corners)
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get artworkCornerRadiusNone;

  /// Label for the artwork shape selector
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get artworkShape;

  /// Rounded rectangle artwork shape option
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get artworkShapeRounded;

  /// Circle artwork shape option
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get artworkShapeCircle;

  /// Square (no rounding) artwork shape option
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get artworkShapeSquare;

  /// Label for the artwork shadow intensity selector
  ///
  /// In en, this message translates to:
  /// **'Shadow'**
  String get artworkShadow;

  /// No shadow option for artwork
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get artworkShadowNone;

  /// Soft shadow option for artwork
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get artworkShadowSoft;

  /// Medium shadow option for artwork
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get artworkShadowMedium;

  /// Strong shadow option for artwork
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get artworkShadowStrong;

  /// Label for the artwork shadow color selector
  ///
  /// In en, this message translates to:
  /// **'Shadow Color'**
  String get artworkShadowColor;

  /// Black shadow color option
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get artworkShadowColorBlack;

  /// Accent color shadow (matches app accent color)
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get artworkShadowColorAccent;

  /// Label shown above the live artwork style preview
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get artworkPreview;

  /// Formatted corner radius value label
  ///
  /// In en, this message translates to:
  /// **'{value}px'**
  String artworkCornerRadiusLabel(int value);

  /// Placeholder label shown in the player when a song has no cover art
  ///
  /// In en, this message translates to:
  /// **'No artwork'**
  String get noArtwork;

  /// Title on the server-unreachable screen
  ///
  /// In en, this message translates to:
  /// **'Cannot reach server'**
  String get serverUnreachableTitle;

  /// Subtitle on the server-unreachable screen
  ///
  /// In en, this message translates to:
  /// **'Check your connection or server settings.'**
  String get serverUnreachableSubtitle;

  /// Button to enter offline mode from the server-unreachable screen
  ///
  /// In en, this message translates to:
  /// **'Open in offline mode'**
  String get openOfflineMode;

  /// Display settings section header for theme / appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// Label for the theme mode selector (System / Light / Dark)
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// Label for the accent color picker
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColorLabel;

  /// Label for the Circular Design (glass-blur UI) toggle
  ///
  /// In en, this message translates to:
  /// **'Circular Design'**
  String get circularDesignLabel;

  /// Subtitle describing the Circular Design visual style
  ///
  /// In en, this message translates to:
  /// **'Floating, rounded UI with translucent panels and glass-blur effect on the player and navigation bar.'**
  String get circularDesignSubtitle;

  /// Theme mode option that follows the OS setting
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// Light theme mode option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// Dark theme mode option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// Badge shown next to a live radio stream
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveLabel;

  /// Settings label for the Discord Rich Presence second-line style
  ///
  /// In en, this message translates to:
  /// **'Discord status text'**
  String get discordStatusText;

  /// Subtitle for the Discord status text setting
  ///
  /// In en, this message translates to:
  /// **'Second line shown in Discord activity'**
  String get discordStatusTextSubtitle;

  /// Discord RPC state style option: show artist name
  ///
  /// In en, this message translates to:
  /// **'Artist name'**
  String get discordRpcStyleArtist;

  /// Discord RPC state style option: show song title
  ///
  /// In en, this message translates to:
  /// **'Song title'**
  String get discordRpcStyleSong;

  /// Discord RPC state style option: show app name
  ///
  /// In en, this message translates to:
  /// **'App name (Musly)'**
  String get discordRpcStyleApp;

  /// Playback settings section header for ReplayGain
  ///
  /// In en, this message translates to:
  /// **'VOLUME NORMALIZATION (REPLAYGAIN)'**
  String get sectionVolumeNormalization;

  /// ReplayGain mode: disabled
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get replayGainModeOff;

  /// ReplayGain mode: per-track normalization
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get replayGainModeTrack;

  /// ReplayGain mode: album-level normalization
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get replayGainModeAlbum;

  /// ReplayGain preamp slider label
  ///
  /// In en, this message translates to:
  /// **'Preamp: {value} dB'**
  String replayGainPreamp(String value);

  /// Toggle label for ReplayGain prevent-clipping option
  ///
  /// In en, this message translates to:
  /// **'Prevent Clipping'**
  String get replayGainPreventClipping;

  /// ReplayGain fallback gain slider label
  ///
  /// In en, this message translates to:
  /// **'Fallback Gain: {value} dB'**
  String replayGainFallbackGain(String value);

  /// Auto DJ slider label showing how many songs to add
  ///
  /// In en, this message translates to:
  /// **'Songs to Add: {count}'**
  String autoDjSongsToAdd(int count);

  /// Toggle label to enable transcoding
  ///
  /// In en, this message translates to:
  /// **'Enable Transcoding'**
  String get transcodingEnable;

  /// Subtitle for the enable transcoding toggle
  ///
  /// In en, this message translates to:
  /// **'Reduce data usage with lower quality'**
  String get transcodingEnableSubtitle;

  /// Toggle label for smart (auto) transcoding mode
  ///
  /// In en, this message translates to:
  /// **'Smart Transcoding'**
  String get smartTranscoding;

  /// Subtitle for the smart transcoding toggle
  ///
  /// In en, this message translates to:
  /// **'Automatically adjusts quality based on your connection (WiFi vs mobile data)'**
  String get smartTranscodingSubtitle;

  /// Label shown before the live network type badge
  ///
  /// In en, this message translates to:
  /// **'Detected network: '**
  String get smartTranscodingDetectedNetwork;

  /// Shows the currently active transcoding bitrate
  ///
  /// In en, this message translates to:
  /// **'Active bitrate: {bitrate}'**
  String smartTranscodingActiveBitrate(String bitrate);

  /// Label for WiFi bitrate selector
  ///
  /// In en, this message translates to:
  /// **'WiFi Quality'**
  String get transcodingWifiQuality;

  /// WiFi quality subtitle when smart mode is on
  ///
  /// In en, this message translates to:
  /// **'Used automatically on WiFi'**
  String get transcodingWifiQualitySubtitleSmart;

  /// WiFi quality subtitle when smart mode is off
  ///
  /// In en, this message translates to:
  /// **'Bitrate when on WiFi'**
  String get transcodingWifiQualitySubtitle;

  /// Label for mobile data bitrate selector
  ///
  /// In en, this message translates to:
  /// **'Mobile Quality'**
  String get transcodingMobileQuality;

  /// Mobile quality subtitle when smart mode is on
  ///
  /// In en, this message translates to:
  /// **'Used automatically on cellular data'**
  String get transcodingMobileQualitySubtitleSmart;

  /// Mobile quality subtitle when smart mode is off
  ///
  /// In en, this message translates to:
  /// **'Bitrate when on mobile data'**
  String get transcodingMobileQualitySubtitle;

  /// Label for the transcoding format selector
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get transcodingFormat;

  /// Subtitle for the transcoding format selector
  ///
  /// In en, this message translates to:
  /// **'Audio codec used for streaming'**
  String get transcodingFormatSubtitle;

  /// Transcoding bitrate option: no transcoding, use original
  ///
  /// In en, this message translates to:
  /// **'Original (No Transcoding)'**
  String get transcodingBitrateOriginal;

  /// Transcoding format option: original (no conversion)
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get transcodingFormatOriginal;

  /// Toggle title for image (album art) cache
  ///
  /// In en, this message translates to:
  /// **'Image Cache'**
  String get imageCacheTitle;

  /// Subtitle for image cache toggle
  ///
  /// In en, this message translates to:
  /// **'Save album covers locally'**
  String get imageCacheSubtitle;

  /// Toggle title for music metadata cache
  ///
  /// In en, this message translates to:
  /// **'Music Cache'**
  String get musicCacheTitle;

  /// Subtitle for music cache toggle
  ///
  /// In en, this message translates to:
  /// **'Save song metadata locally'**
  String get musicCacheSubtitle;

  /// Toggle title for BPM analysis cache
  ///
  /// In en, this message translates to:
  /// **'BPM Cache'**
  String get bpmCacheTitle;

  /// Subtitle for BPM cache toggle
  ///
  /// In en, this message translates to:
  /// **'Save BPM analysis locally'**
  String get bpmCacheSubtitle;

  /// About screen section header
  ///
  /// In en, this message translates to:
  /// **'INFORMATION'**
  String get sectionAboutInformation;

  /// About screen developer section header
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER'**
  String get sectionAboutDeveloper;

  /// About screen links section header
  ///
  /// In en, this message translates to:
  /// **'LINKS'**
  String get sectionAboutLinks;

  /// About screen version row title
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// About screen platform row title
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get aboutPlatform;

  /// Developer credit text in the about tab
  ///
  /// In en, this message translates to:
  /// **'Made by dddevid'**
  String get aboutMadeBy;

  /// Developer GitHub handle shown as subtitle
  ///
  /// In en, this message translates to:
  /// **'github.com/dddevid'**
  String get aboutGitHub;

  /// Link tile title for the GitHub repo
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get aboutLinkGitHub;

  /// Link tile title for the app changelog
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get aboutLinkChangelog;

  /// Link tile title for reporting a bug
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get aboutLinkReportIssue;

  /// Link tile title for the Discord server
  ///
  /// In en, this message translates to:
  /// **'Join Discord Community'**
  String get aboutLinkDiscord;

  /// Analytics and Privacy section header
  ///
  /// In en, this message translates to:
  /// **'Analytics & Privacy'**
  String get sectionAnalyticsPrivacy;

  /// Title for anonymous analytics toggle
  ///
  /// In en, this message translates to:
  /// **'Anonymous Analytics'**
  String get anonymousAnalytics;

  /// Subtitle explaining anonymous analytics
  ///
  /// In en, this message translates to:
  /// **'Help improve Musly with anonymous crash reports and usage stats'**
  String get anonymousAnalyticsSubtitle;

  /// Title for device ID row
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceId;

  /// Shows the anonymous device ID
  ///
  /// In en, this message translates to:
  /// **'Anonymous ID: {id}'**
  String deviceIdAnonymous(String id);

  /// Shown when analytics is disabled
  ///
  /// In en, this message translates to:
  /// **'Enable analytics to see your anonymous device ID'**
  String get deviceIdDisabled;

  /// Title for device ID explanation
  ///
  /// In en, this message translates to:
  /// **'About Device ID'**
  String get aboutDeviceId;

  /// Explanation of what device ID is
  ///
  /// In en, this message translates to:
  /// **'This is an anonymous identifier generated by the app. It cannot be linked to your personal identity and is used only for analytics.'**
  String get aboutDeviceIdSubtitle;

  /// No description provided for @supportGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hey there! 👋'**
  String get supportGreeting;

  /// No description provided for @supportParagraph1.
  ///
  /// In en, this message translates to:
  /// **'I\'m Devid, the developer behind Musly. I built this app because I love music and believe everyone deserves a beautiful, free music player.'**
  String get supportParagraph1;

  /// No description provided for @supportParagraph2.
  ///
  /// In en, this message translates to:
  /// **'Musly is completely free and open-source. No ads and no subscription fees. I work on it in my free time because I genuinely enjoy making something useful for people like you.'**
  String get supportParagraph2;

  /// No description provided for @supportParagraph3.
  ///
  /// In en, this message translates to:
  /// **'But servers, development tools, and coffee aren\'t free 😅 If Musly has become a part of your daily life and you\'d like to say \"thanks,\" a small donation would mean the world to me. It helps cover costs and keeps me motivated to add new features.'**
  String get supportParagraph3;

  /// No description provided for @supportParagraph4.
  ///
  /// In en, this message translates to:
  /// **'No pressure at all though - your enjoyment of the app is already the best reward! 💙'**
  String get supportParagraph4;

  /// No description provided for @supportDonationTitle.
  ///
  /// In en, this message translates to:
  /// **'Support with a Donation'**
  String get supportDonationTitle;

  /// No description provided for @supportDonationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'via Revolut - any amount helps!'**
  String get supportDonationSubtitle;

  /// No description provided for @supportDiscordTitle.
  ///
  /// In en, this message translates to:
  /// **'Join our Discord'**
  String get supportDiscordTitle;

  /// No description provided for @supportDiscordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help, suggest features, or just chat'**
  String get supportDiscordSubtitle;

  /// No description provided for @supportWaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Other ways to support'**
  String get supportWaysTitle;

  /// No description provided for @supportWayRate.
  ///
  /// In en, this message translates to:
  /// **'Leave a rating on the app store'**
  String get supportWayRate;

  /// No description provided for @supportWayShare.
  ///
  /// In en, this message translates to:
  /// **'Tell your friends about Musly'**
  String get supportWayShare;

  /// No description provided for @supportWayBugs.
  ///
  /// In en, this message translates to:
  /// **'Report bugs or suggest features'**
  String get supportWayBugs;

  /// No description provided for @supportWayEnjoy.
  ///
  /// In en, this message translates to:
  /// **'Just enjoy the music! 🎵'**
  String get supportWayEnjoy;

  /// No description provided for @supportMadeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with 💙 in Italy'**
  String get supportMadeWithLove;

  /// Title of the playback speed bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// Label for 1× (normal) playback speed option
  ///
  /// In en, this message translates to:
  /// **'Normal (1×)'**
  String get normalSpeed;

  /// Toggle label to keep original pitch when changing speed
  ///
  /// In en, this message translates to:
  /// **'Preserve pitch'**
  String get preservePitch;

  /// Subtitle for the preserve-pitch toggle
  ///
  /// In en, this message translates to:
  /// **'Keep original pitch when changing speed'**
  String get preservePitchSubtitle;

  /// Label for the pitch slider in the speed dialog
  ///
  /// In en, this message translates to:
  /// **'Pitch'**
  String get pitch;

  /// Tooltip fragment shown when pitch correction is on
  ///
  /// In en, this message translates to:
  /// **'pitch preserved'**
  String get pitchPreserved;

  /// Tooltip for the speed button showing speed and pitch values
  ///
  /// In en, this message translates to:
  /// **'Speed {speed} · pitch {pitch}×'**
  String speedTooltipWithPitch(String speed, String pitch);

  /// Tooltip for the speed button when pitch is preserved
  ///
  /// In en, this message translates to:
  /// **'Speed {speed} · pitch preserved'**
  String speedTooltipPitchPreserved(String speed);

  /// Title of the sleep timer bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// Tooltip for the sleep timer button when a timer is running
  ///
  /// In en, this message translates to:
  /// **'Sleep timer active'**
  String get sleepTimerActive;

  /// Toggle label for the fade-out option in the sleep timer dialog
  ///
  /// In en, this message translates to:
  /// **'Fade out'**
  String get fadeOut;

  /// Subtitle for the fade-out toggle, showing fade duration in seconds
  ///
  /// In en, this message translates to:
  /// **'Gradually lower volume in the last {seconds} s'**
  String fadeOutSubtitle(int seconds);

  /// Toggle label to stop after the current track finishes
  ///
  /// In en, this message translates to:
  /// **'Finish current song'**
  String get finishCurrentSong;

  /// Subtitle for the finish-current-song toggle
  ///
  /// In en, this message translates to:
  /// **'Stop after the current track ends'**
  String get finishCurrentSongSubtitle;

  /// Sleep timer option label for a duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String sleepTimerMinutes(int count);

  /// Sleep timer option label for a duration in hours
  ///
  /// In en, this message translates to:
  /// **'{count} hour'**
  String sleepTimerHours(int count);

  /// Snackbar shown after setting the sleep timer
  ///
  /// In en, this message translates to:
  /// **'Sleep timer set for {duration}'**
  String sleepTimerSetFor(String duration);

  /// List tile label to open the custom sleep timer dialog
  ///
  /// In en, this message translates to:
  /// **'Custom duration…'**
  String get customDuration;

  /// List tile label to cancel the active sleep timer
  ///
  /// In en, this message translates to:
  /// **'Cancel timer'**
  String get cancelTimer;

  /// Title of the custom sleep timer dialog
  ///
  /// In en, this message translates to:
  /// **'Custom Sleep Timer'**
  String get customSleepTimer;

  /// Confirm button label in the custom sleep timer dialog
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// Title of the add-to-playlist bottom sheet (distinct from the menu action)
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylistTitle;

  /// Section heading inside the add-to-playlist bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Your Playlists'**
  String get yourPlaylistsLabel;

  /// Toggle label for enabling LRCLIB lyrics fallback when the Subsonic server has no lyrics
  ///
  /// In en, this message translates to:
  /// **'Fetch lyrics from LRCLIB'**
  String get enableLrcLibFallback;

  /// Subtitle explaining the LRCLIB fallback toggle
  ///
  /// In en, this message translates to:
  /// **'Automatically search LRCLIB for lyrics when your server does not provide them'**
  String get lrcLibFallbackSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bn',
        'da',
        'de',
        'el',
        'en',
        'es',
        'fi',
        'fr',
        'ga',
        'hi',
        'id',
        'it',
        'nl',
        'no',
        'pl',
        'pt',
        'ro',
        'ru',
        'sq',
        'sv',
        'te',
        'tr',
        'uk',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'ga':
      return AppLocalizationsGa();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
    case 'no':
      return AppLocalizationsNo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sq':
      return AppLocalizationsSq();
    case 'sv':
      return AppLocalizationsSv();
    case 'te':
      return AppLocalizationsTe();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
