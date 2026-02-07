// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Musly';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get forYou => 'For You';

  @override
  String get quickPicks => 'Quick Picks';

  @override
  String get discoverMix => 'Discover Mix';

  @override
  String get recentlyPlayed => 'Recently Played';

  @override
  String get yourPlaylists => 'Your Playlists';

  @override
  String get madeForYou => 'Made For You';

  @override
  String get topRated => 'Top Rated';

  @override
  String get noContentAvailable => 'No content available';

  @override
  String get tryRefreshing => 'Try refreshing or check your server connection';

  @override
  String get refresh => 'Refresh';

  @override
  String get errorLoadingSongs => 'Error loading songs';

  @override
  String get noSongsInGenre => 'No songs in this genre';

  @override
  String get errorLoadingAlbums => 'Error loading albums';

  @override
  String get noTopRatedAlbums => 'No top rated albums';

  @override
  String get login => 'Login';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get selectCertificate => 'Select TLS/SSL Certificate';

  @override
  String failedToSelectCertificate(String error) {
    return 'Failed to select certificate: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'Server URL must start with http:// or https://';

  @override
  String get failedToConnect => 'Failed to connect';

  @override
  String get library => 'Library';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String get albums => 'Albums';

  @override
  String get artists => 'Artists';

  @override
  String get songs => 'Songs';

  @override
  String get playlists => 'Playlists';

  @override
  String get genres => 'Genres';

  @override
  String get favorites => 'Favorites';

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get queue => 'Queue';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatOne => 'Repeat One';

  @override
  String get repeatOff => 'Repeat Off';

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get removeFromPlaylist => 'Remove from Playlist';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get download => 'Download';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get general => 'General';

  @override
  String get appearance => 'Appearance';

  @override
  String get playback => 'Playback';

  @override
  String get storage => 'Storage';

  @override
  String get about => 'About';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get version => 'Version';

  @override
  String get madeBy => 'Made by dddevid';

  @override
  String get githubRepository => 'GitHub Repository';

  @override
  String get reportIssue => 'Report Issue';

  @override
  String get joinDiscord => 'Join Discord Community';

  @override
  String get unknownArtist => 'Unknown Artist';

  @override
  String get unknownAlbum => 'Unknown Album';

  @override
  String get playAll => 'Play All';

  @override
  String get shuffleAll => 'Shuffle All';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByArtist => 'Artist';

  @override
  String get sortByAlbum => 'Album';

  @override
  String get sortByDate => 'Date';

  @override
  String get sortByDuration => 'Duration';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get noLyricsAvailable => 'No lyrics available';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get noResults => 'No results';

  @override
  String get searchHint => 'Search for songs, albums, artists...';

  @override
  String get allSongs => 'All Songs';

  @override
  String get allAlbums => 'All Albums';

  @override
  String get allArtists => 'All Artists';

  @override
  String trackNumber(int number) {
    return 'Track $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
      zero: 'No songs',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
      zero: 'No albums',
    );
    return '$_temp0';
  }

  @override
  String get logout => 'Logout';

  @override
  String get confirmLogout => 'Are you sure you want to logout?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get radio => 'Radio';

  @override
  String get changelog => 'Changelog';

  @override
  String get platform => 'Platform';

  @override
  String get server => 'Server';

  @override
  String get display => 'Display';
}
