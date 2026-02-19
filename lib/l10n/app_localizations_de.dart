// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Musly';

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String get goodAfternoon => 'Guten Nachmittag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String get forYou => 'Für dich';

  @override
  String get quickPicks => 'Quick Picks';

  @override
  String get discoverMix => 'Neues entdecken';

  @override
  String get recentlyPlayed => 'Zuletzt abgespielt';

  @override
  String get yourPlaylists => 'Deine Playlisten';

  @override
  String get madeForYou => 'Für dich gemacht';

  @override
  String get topRated => 'Am besten bewertet';

  @override
  String get noContentAvailable => 'Kein Inhalt verfügbar';

  @override
  String get tryRefreshing =>
      'Versuche es nochmal oder überprüfe die Serververbindung';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get errorLoadingSongs =>
      'Beim Laden der Songs ist ein Fehler aufgetreten';

  @override
  String get noSongsInGenre => 'Keine Songs in diesem Genre verfügbar';

  @override
  String get errorLoadingAlbums =>
      'Beim Laden der Alben ist ein Fehler aufgetreten';

  @override
  String get noTopRatedAlbums => 'Keine bewerteten Alben verfügbar';

  @override
  String get login => 'Anmelden';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get username => 'Benutzername';

  @override
  String get password => 'Passwort';

  @override
  String get selectCertificate => 'TLS/SSL Zertifikat auswählen';

  @override
  String failedToSelectCertificate(String error) {
    return 'Beim Auswählen des Zertifikates ist ein Fehler aufgetreten: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'Die Server URL muss mit http:// oder https:// starten';

  @override
  String get failedToConnect => 'Verbindungsaufbau fehlgeschlagen';

  @override
  String get library => 'Bibliothek';

  @override
  String get search => 'Suchen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get albums => 'Alben';

  @override
  String get artists => 'Künstler*innen';

  @override
  String get songs => 'Songs';

  @override
  String get playlists => 'Playlisten';

  @override
  String get genres => 'Genres';

  @override
  String get favorites => 'Favoriten';

  @override
  String get nowPlaying => 'Jetzt spielt';

  @override
  String get queue => 'Warteschlange';

  @override
  String get lyrics => 'Songtext';

  @override
  String get play => 'Abspielen';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Nächster';

  @override
  String get previous => 'Vorheriger';

  @override
  String get shuffle => 'Mischen';

  @override
  String get repeat => 'Wiederholen';

  @override
  String get repeatOne => 'Einmal wiederholen';

  @override
  String get repeatOff => 'Nicht wiederholen';

  @override
  String get addToPlaylist => 'Zur Playliste hinzufügen';

  @override
  String get removeFromPlaylist => 'Von der Playliste entfernen';

  @override
  String get addToFavorites => 'Zu den Favoriten hinzufügen';

  @override
  String get removeFromFavorites => 'Von den Favoriten entfernen';

  @override
  String get download => 'Herunterladen';

  @override
  String get delete => 'Löschen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'Ok';

  @override
  String get save => 'Speichern';

  @override
  String get close => 'Schließen';

  @override
  String get general => 'Allgemein';

  @override
  String get appearance => 'Aussehen';

  @override
  String get playback => 'Wiedergabe';

  @override
  String get storage => 'Speicher';

  @override
  String get about => 'Über';

  @override
  String get darkMode => 'Dunkel-Modus';

  @override
  String get language => 'Sprache';

  @override
  String get version => 'Version';

  @override
  String get madeBy => 'Hergestellt von dddevid';

  @override
  String get githubRepository => 'GitHub Bibliothek';

  @override
  String get reportIssue => 'Problem melden';

  @override
  String get joinDiscord => 'Trete der Discord-Community bei';

  @override
  String get unknownArtist => 'Unbekannte*r Künstler*in';

  @override
  String get unknownAlbum => 'Unbekanntes Album';

  @override
  String get playAll => 'Alle abspielen';

  @override
  String get shuffleAll => 'Alle mischen';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByArtist => 'Künstler*in';

  @override
  String get sortByAlbum => 'Album';

  @override
  String get sortByDate => 'Datum';

  @override
  String get sortByDuration => 'Dauer';

  @override
  String get ascending => 'Aufsteigend';

  @override
  String get descending => 'Absteigend';

  @override
  String get noLyricsAvailable => 'Keine Songtexte verfügbar';

  @override
  String get loading => 'Lädt...';

  @override
  String get error => 'Fehler';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get searchHint => 'Suche nach Songs, Alben, Künstler*innen...';

  @override
  String get allSongs => 'Alle Songs';

  @override
  String get allAlbums => 'Alle Alben';

  @override
  String get allArtists => 'Alle Künstler*innen';

  @override
  String trackNumber(int number) {
    return 'Titel $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs',
      one: '1 Song',
      zero: 'Keine Songs',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Alben',
      one: '1 Album',
      zero: 'Keine Alben',
    );
    return '$_temp0';
  }

  @override
  String get logout => 'Abmelden';

  @override
  String get confirmLogout => 'Bist du sicher, dass du dich abmelden möchtest?';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get offlineMode => 'Offline-Modus';

  @override
  String get radio => 'Radio';

  @override
  String get changelog => 'Änderungsprotokoll';

  @override
  String get platform => 'Plattform';

  @override
  String get server => 'Server';

  @override
  String get display => 'Display';

  @override
  String get playerInterface => 'Player Interface';

  @override
  String get smartRecommendations => 'Smart Recommendations';

  @override
  String get showVolumeSlider => 'Show Volume Slider';

  @override
  String get showVolumeSliderSubtitle =>
      'Display volume control in Now Playing screen';

  @override
  String get showStarRatings => 'Show Star Ratings';

  @override
  String get showStarRatingsSubtitle => 'Rate songs and view ratings';

  @override
  String get enableRecommendations => 'Enable Recommendations';

  @override
  String get enableRecommendationsSubtitle =>
      'Get personalized music suggestions';

  @override
  String get listeningData => 'Listening Data';

  @override
  String totalPlays(int count) {
    return '$count total plays';
  }

  @override
  String get clearListeningHistory => 'Clear Listening History';

  @override
  String get confirmClearHistory =>
      'This will reset all your listening data and recommendations. Are you sure?';

  @override
  String get historyCleared => 'Listening history cleared';

  @override
  String get discordStatus => 'Discord Status';

  @override
  String get discordStatusSubtitle => 'Show playing song on Discord profile';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get communityTranslations => 'Translations by Community';

  @override
  String get communityTranslationsSubtitle => 'Help translate Musly on Crowdin';

  @override
  String get yourLibrary => 'Your Library';

  @override
  String get filterAll => 'All';

  @override
  String get filterPlaylists => 'Playlists';

  @override
  String get filterAlbums => 'Albums';

  @override
  String get filterArtists => 'Artists';

  @override
  String get likedSongs => 'Liked Songs';

  @override
  String get radioStations => 'Radio Stations';

  @override
  String get playlist => 'Playlist';

  @override
  String get internetRadio => 'Internet Radio';

  @override
  String get newPlaylist => 'New Playlist';

  @override
  String get playlistName => 'Playlist Name';

  @override
  String get create => 'Create';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Are you sure you want to delete the playlist \"$name\"?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Playlist \"$name\" deleted';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Error creating playlist: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Error deleting playlist: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Playlist \"$name\" created';
  }

  @override
  String get searchTitle => 'Search';

  @override
  String get searchPlaceholder => 'Artists, Songs, Albums';

  @override
  String get tryDifferentSearch => 'Try a different search';

  @override
  String get noSuggestions => 'No suggestions';

  @override
  String get browseCategories => 'Browse Categories';

  @override
  String get categoryMadeForYou => 'Made For You';

  @override
  String get categoryNewReleases => 'New Releases';

  @override
  String get categoryTopRated => 'Top Rated';

  @override
  String get categoryGenres => 'Genres';

  @override
  String get categoryFavorites => 'Favorites';

  @override
  String get categoryRadio => 'Radio';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get tabPlayback => 'Playback';

  @override
  String get tabStorage => 'Storage';

  @override
  String get tabServer => 'Server';

  @override
  String get tabDisplay => 'Display';

  @override
  String get tabAbout => 'About';

  @override
  String get sectionAutoDj => 'AUTO DJ';

  @override
  String get autoDjMode => 'Auto DJ Mode';

  @override
  String songsToAdd(int count) {
    return 'Songs to Add: $count';
  }

  @override
  String get sectionReplayGain => 'VOLUME NORMALIZATION (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Mode';

  @override
  String preamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get preventClipping => 'Prevent Clipping';

  @override
  String fallbackGain(String value) {
    return 'Fallback Gain: $value dB';
  }

  @override
  String get sectionStreamingQuality => 'STREAMING QUALITY';

  @override
  String get enableTranscoding => 'Enable Transcoding';

  @override
  String get qualityWifi => 'WiFi Quality';

  @override
  String get qualityMobile => 'Mobile Quality';

  @override
  String get format => 'Format';

  @override
  String get transcodingSubtitle => 'Reduce data usage with lower quality';

  @override
  String get modeOff => 'Off';

  @override
  String get modeTrack => 'Track';

  @override
  String get modeAlbum => 'Album';

  @override
  String get sectionServerConnection => 'SERVER CONNECTION';

  @override
  String get serverType => 'Server Type';

  @override
  String get notConnected => 'Not connected';

  @override
  String get unknown => 'Unknown';

  @override
  String get sectionMusicFolders => 'MUSIC FOLDERS';

  @override
  String get musicFolders => 'Music Folders';

  @override
  String get noMusicFolders => 'No music folders found';

  @override
  String get sectionAccount => 'ACCOUNT';

  @override
  String get logoutConfirmation =>
      'Are you sure you want to logout? This will also clear all cached data.';

  @override
  String get sectionCacheSettings => 'CACHE SETTINGS';

  @override
  String get imageCache => 'Image Cache';

  @override
  String get musicCache => 'Music Cache';

  @override
  String get bpmCache => 'BPM Cache';

  @override
  String get saveAlbumCovers => 'Save album covers locally';

  @override
  String get saveSongMetadata => 'Save song metadata locally';

  @override
  String get saveBpmAnalysis => 'Save BPM analysis locally';

  @override
  String get sectionCacheCleanup => 'CACHE CLEANUP';

  @override
  String get clearAllCache => 'Clear All Cache';

  @override
  String get allCacheCleared => 'All cache cleared';

  @override
  String get sectionOfflineDownloads => 'OFFLINE DOWNLOADS';

  @override
  String get downloadedSongs => 'Downloaded Songs';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Downloading Library... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Download All Library';

  @override
  String downloadLibraryConfirm(int count) {
    return 'This will download $count songs to your device. This may take a while and use significant storage space.\n\nContinue?';
  }

  @override
  String get libraryDownloadStarted => 'Library download started';

  @override
  String get deleteDownloads => 'Delete All Downloads';

  @override
  String get downloadsDeleted => 'All downloads deleted';

  @override
  String get noSongsAvailable =>
      'No songs available. Please load your library first.';

  @override
  String get sectionBpmAnalysis => 'BPM ANALYSIS';

  @override
  String get cachedBpms => 'Cached BPMs';

  @override
  String get cacheAllBpms => 'Cache All BPMs';

  @override
  String get clearBpmCache => 'Clear BPM Cache';

  @override
  String get bpmCacheCleared => 'BPM cache cleared';

  @override
  String downloadedStats(int count, String size) {
    return '$count songs • $size';
  }

  @override
  String get sectionInformation => 'INFORMATION';

  @override
  String get sectionDeveloper => 'DEVELOPER';

  @override
  String get sectionLinks => 'LINKS';

  @override
  String get githubRepo => 'GitHub Repository';

  @override
  String get playingFrom => 'PLAYING FROM';

  @override
  String get live => 'LIVE';

  @override
  String get streamingLive => 'Streaming Live';

  @override
  String get stopRadio => 'Stop Radio';

  @override
  String get removeFromLiked => 'Remove from Liked Songs';

  @override
  String get addToLiked => 'Add to Liked Songs';

  @override
  String get playNext => 'Play Next';

  @override
  String get addToQueue => 'Add to Queue';

  @override
  String get goToAlbum => 'Go to Album';

  @override
  String get goToArtist => 'Go to Artist';

  @override
  String get rateSong => 'Rate Song';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Rate Song ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Rating removed';

  @override
  String rated(int rating, String stars) {
    return 'Rated $rating $stars';
  }

  @override
  String get removeRating => 'Remove Rating';

  @override
  String get downloaded => 'Downloaded';

  @override
  String downloading(int percent) {
    return 'Downloading... $percent%';
  }

  @override
  String get removeDownload => 'Remove Download';

  @override
  String get removeDownloadConfirm => 'Remove this song from offline storage?';

  @override
  String get downloadRemoved => 'Download removed';

  @override
  String downloadedTitle(String title) {
    return 'Downloaded \"$title\"';
  }

  @override
  String get downloadFailed => 'Download failed';

  @override
  String downloadError(Object error) {
    return 'Download error: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Added \"$title\" to $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Error adding to playlist: $error';
  }

  @override
  String get noPlaylists => 'No playlists available';

  @override
  String get createNewPlaylist => 'Create New Playlist';

  @override
  String artistNotFound(String name) {
    return 'Artist \"$name\" not found';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Error searching for artist: $error';
  }

  @override
  String get selectArtist => 'Select Artist';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get star => 'star';

  @override
  String get stars => 'stars';

  @override
  String get albumNotFound => 'Album not found';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours HR $minutes MIN';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get topSongs => 'Top Songs';

  @override
  String get connected => 'Connected';

  @override
  String get noSongPlaying => 'No song playing';

  @override
  String get internetRadioUppercase => 'INTERNET RADIO';

  @override
  String get playingNext => 'Playing Next';

  @override
  String get createPlaylistTitle => 'Create Playlist';

  @override
  String get playlistNameHint => 'Playlist name';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Created playlist \"$name\" with this song';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Error loading playlists: $error';
  }

  @override
  String get playlistNotFound => 'Playlist not found';

  @override
  String get noSongsInPlaylist => 'No songs in this playlist';

  @override
  String get noFavoriteSongsYet => 'No favorite songs yet';

  @override
  String get noFavoriteAlbumsYet => 'No favorite albums yet';

  @override
  String get listeningHistory => 'Listening History';

  @override
  String get noListeningHistory => 'No Listening History';

  @override
  String get songsWillAppearHere => 'Songs you play will appear here';

  @override
  String get sortByTitleAZ => 'Title (A-Z)';

  @override
  String get sortByTitleZA => 'Title (Z-A)';

  @override
  String get sortByArtistAZ => 'Artist (A-Z)';

  @override
  String get sortByArtistZA => 'Artist (Z-A)';

  @override
  String get sortByAlbumAZ => 'Album (A-Z)';

  @override
  String get sortByAlbumZA => 'Album (Z-A)';

  @override
  String get recentlyAdded => 'Recently Added';

  @override
  String get noSongsFound => 'No songs found';

  @override
  String get noAlbumsFound => 'No albums found';

  @override
  String get noHomepageUrl => 'No homepage URL available';

  @override
  String get playStation => 'Play Station';

  @override
  String get openHomepage => 'Open Homepage';

  @override
  String get copyStreamUrl => 'Copy Stream URL';

  @override
  String get failedToLoadRadioStations => 'Failed to load radio stations';

  @override
  String get noRadioStations => 'No Radio Stations';

  @override
  String get noRadioStationsHint =>
      'Add radio stations in your Navidrome server settings to see them here.';

  @override
  String get connectToServerSubtitle => 'Connect to your Subsonic server';

  @override
  String get pleaseEnterServerUrl => 'Please enter server URL';

  @override
  String get invalidUrlFormat => 'URL must start with http:// or https://';

  @override
  String get pleaseEnterUsername => 'Please enter username';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get legacyAuthentication => 'Legacy Authentication';

  @override
  String get legacyAuthSubtitle => 'Use for older Subsonic servers';

  @override
  String get allowSelfSignedCerts => 'Allow Self-Signed Certificates';

  @override
  String get allowSelfSignedSubtitle =>
      'For servers with custom TLS/SSL certificates';

  @override
  String get advancedOptions => 'Advanced Options';

  @override
  String get customTlsCertificate => 'Custom TLS/SSL Certificate';

  @override
  String get customCertificateSubtitle =>
      'Upload a custom certificate for servers with non-standard CA';

  @override
  String get selectCertificateFile => 'Select Certificate File';

  @override
  String get clientCertificate => 'Client Certificate (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Authenticate this client using a certificate (requires mTLS-enabled server)';

  @override
  String get selectClientCertificate => 'Select Client Certificate';

  @override
  String get clientCertPassword => 'Certificate password (optional)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Failed to select client certificate: $error';
  }

  @override
  String get connect => 'Connect';

  @override
  String get or => 'OR';

  @override
  String get useLocalFiles => 'Use Local Files';

  @override
  String get startingScan => 'Starting scan...';

  @override
  String get storagePermissionRequired =>
      'Storage permission required to scan local files';

  @override
  String get noMusicFilesFound => 'No music files found on your device';

  @override
  String get remove => 'Remove';

  @override
  String failedToSetRating(Object error) {
    return 'Failed to set rating: $error';
  }

  @override
  String get home => 'Home';

  @override
  String get playlistsSection => 'PLAYLISTS';

  @override
  String get collapse => 'Collapse';

  @override
  String get likedSongsSidebar => 'Liked Songs';

  @override
  String playlistSongsCount(int count) {
    return 'Playlist • $count songs';
  }

  @override
  String get failedToLoadLyrics => 'Failed to load lyrics';

  @override
  String get lyricsNotFoundSubtitle =>
      'Lyrics for this song couldn\'t be found';

  @override
  String get backToCurrent => 'Back to current';

  @override
  String get exitFullscreen => 'Exit Fullscreen';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get noLyrics => 'No lyrics';

  @override
  String get internetRadioMiniPlayer => 'Internet Radio';

  @override
  String get liveBadge => 'LIVE';

  @override
  String get localFilesModeBanner => 'Local Files Mode';

  @override
  String get offlineModeBanner =>
      'Offline Mode – Playing downloaded music only';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get updateAvailableSubtitle => 'A new version of Musly is available!';

  @override
  String updateCurrentVersion(String version) {
    return 'Current: v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Latest: v$version';
  }

  @override
  String get whatsNew => 'What\'s New';

  @override
  String get downloadUpdate => 'Download';

  @override
  String get remindLater => 'Later';

  @override
  String get seeAll => 'See All';

  @override
  String get artistDataNotFound => 'Artist not found';

  @override
  String get casting => 'Casting';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Cast / DLNA (Beta)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get searchingDevices => 'Searching for devices';

  @override
  String get castWifiHint =>
      'Make sure your Cast / DLNA device\nis on the same Wi-Fi network';

  @override
  String connectedToDevice(String name) {
    return 'Connected to $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Failed to connect to $name';
  }

  @override
  String get removedFromLikedSongs => 'Removed from Liked Songs';

  @override
  String get addedToLikedSongs => 'Added to Liked Songs';

  @override
  String get enableShuffle => 'Enable shuffle';

  @override
  String get enableRepeat => 'Enable repeat';

  @override
  String get connecting => 'Connecting';

  @override
  String get closeLyrics => 'Close Lyrics';

  @override
  String errorStartingDownload(Object error) {
    return 'Error starting download: $error';
  }
}
