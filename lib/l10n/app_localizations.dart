import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
    Locale('zh'),
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

  /// Placeholder for unknown artist
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

  /// Retry button label
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
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
    'that was used.',
  );
}
