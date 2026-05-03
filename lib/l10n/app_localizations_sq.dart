// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Albanian (`sq`).
class AppLocalizationsSq extends AppLocalizations {
  AppLocalizationsSq([String locale = 'sq']) : super(locale);

  @override
  String get appName => 'Musly';

  @override
  String get goodMorning => 'Mirëmëngjes';

  @override
  String get goodAfternoon => 'Mirëdita';

  @override
  String get goodEvening => 'Mirëmbrëma';

  @override
  String get forYou => 'Për ty';

  @override
  String get quickPicks => 'Zgjedhje të shpejta';

  @override
  String get discoverMix => 'Mix i zbulimit';

  @override
  String get recentlyPlayed => 'Dëgjuar së fundmi';

  @override
  String get yourPlaylists => 'Listat e tua për dëgjim';

  @override
  String get favoritePlaylists => 'Favorite Playlists';

  @override
  String get madeForYou => 'Krijuar për ty';

  @override
  String get topRated => 'Më të vlerësuarit';

  @override
  String get noContentAvailable => 'Nuk ka përmbajtje në dispozicion';

  @override
  String get tryRefreshing =>
      'Provoni të rifreskoni faqen ose kontrolloni lidhjen me serverin';

  @override
  String get refresh => 'Rifresko';

  @override
  String get errorLoadingSongs => 'Gabim gjatë ngarkimit të këngëve';

  @override
  String get noSongsInGenre => 'Nuk ka këngë në këtë zhanër';

  @override
  String get errorLoadingAlbums => 'Gabim gjatë ngarkimit të albumeve';

  @override
  String get noTopRatedAlbums => 'Asnjë album me vlerësim të lartë.';

  @override
  String get login => 'Hyr në llogari';

  @override
  String get serverUrl => 'URL-ja e serverit';

  @override
  String get username => 'Emri i përdoruesit';

  @override
  String get password => 'Password';

  @override
  String get selectCertificate => 'Zgjidhni certifikatën TLS/SSL';

  @override
  String failedToSelectCertificate(String error) {
    return 'Dështoi zgjedhja e certifikatës: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'URL-ja e serverit duhet të fillojë me http:// ose https://';

  @override
  String get failedToConnect => 'Lidhja dështoi';

  @override
  String get library => 'Biblioteka';

  @override
  String get search => 'Kërko';

  @override
  String get settings => 'Cilësimet';

  @override
  String get albums => 'Albume';

  @override
  String get artists => 'Artistët';

  @override
  String get songs => 'Këngët';

  @override
  String get playlists => 'Listat e dëgjimit';

  @override
  String get genres => 'Zhanret';

  @override
  String get favorites => 'Të preferuarat';

  @override
  String get nowPlaying => 'Tani duke u luajtur';

  @override
  String get queue => 'Radha';

  @override
  String get lyrics => 'Tekstet e këngës';

  @override
  String get play => 'Luaj';

  @override
  String get pause => 'Pauzë';

  @override
  String get next => 'Tjetra';

  @override
  String get previous => 'E mëparshmja';

  @override
  String get shuffle => 'Përzje';

  @override
  String get repeat => 'Përsërit';

  @override
  String get repeatOne => 'Përsërit njërën';

  @override
  String get repeatOff => 'Çaktivizo përsëritjen';

  @override
  String get addToPlaylist => 'Shto në listën e dëgjimit';

  @override
  String get removeFromPlaylist => 'Hiqe nga lista e dëgjimit';

  @override
  String get addToFavorites => 'Shto tek të preferuarat';

  @override
  String get removeFromFavorites => 'Hiqe nga të preferuarat';

  @override
  String get download => 'Shkarko';

  @override
  String get delete => 'Fshi';

  @override
  String get cancel => 'Anulo';

  @override
  String get ok => 'Në rregull';

  @override
  String get save => 'Ruaj';

  @override
  String get close => 'Mbyll';

  @override
  String get general => 'Përgjithshme';

  @override
  String get appearance => 'Pamja';

  @override
  String get playback => 'Riprodhimi';

  @override
  String get storage => 'Hapësira e ruajtjes';

  @override
  String get about => 'Rreth';

  @override
  String get darkMode => 'Mënyra e errët';

  @override
  String get language => 'Gjuha';

  @override
  String get version => 'Versioni';

  @override
  String get madeBy => 'Krijuar nga dddevid';

  @override
  String get githubRepository => 'Depoja në GitHub';

  @override
  String get reportIssue => 'Raporto një problem';

  @override
  String get joinDiscord => 'Bashkohu në komunitetin Discord';

  @override
  String get unknownArtist => 'Artist i panjohur';

  @override
  String get unknownAlbum => 'Album i panjohur';

  @override
  String get playAll => 'Riprodhi të gjitha';

  @override
  String get shuffleAll => 'Përziej të gjitha';

  @override
  String get sortBy => 'Rendit sipas';

  @override
  String get sortByName => 'Emri';

  @override
  String get sortByArtist => 'Artist';

  @override
  String get sortByAlbum => 'Album';

  @override
  String get sortByDate => 'Data';

  @override
  String get sortByDuration => 'Kohëzgjatja';

  @override
  String get ascending => 'Rritëse';

  @override
  String get descending => 'Zbritëse';

  @override
  String get noLyricsAvailable => 'Nuk ka tekst këngësh në dispozicion';

  @override
  String get loading => 'Duke u ngarkuar...';

  @override
  String get error => 'Gabim';

  @override
  String get retry => 'Provo përsëri';

  @override
  String get noResults => 'Nuk u gjet asnjë rezultat';

  @override
  String get searchHint => 'Kërko për këngë, albume, artistë...';

  @override
  String get allSongs => 'Të gjitha këngët';

  @override
  String get allAlbums => 'Të gjithë albumet';

  @override
  String get allArtists => 'Të gjithë artistët';

  @override
  String trackNumber(int number) {
    return 'Kënga $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count këngë',
      one: '1 këngë',
      zero: 'Asnjë këngë',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albume',
      one: '1 album',
      zero: 'Asnjë album',
    );
    return '$_temp0';
  }

  @override
  String get logout => 'Çlogohu';

  @override
  String get confirmLogout => 'A jeni të sigurt që dëshironi të çlogoheni?';

  @override
  String get yes => 'Po';

  @override
  String get no => 'Jo';

  @override
  String get offlineMode => 'Mënyra pa internet';

  @override
  String get radio => 'Radio';

  @override
  String get changelog => 'Changelog';

  @override
  String get platform => 'Platforma';

  @override
  String get server => 'Serveri';

  @override
  String get display => 'Ekrani';

  @override
  String get playerInterface => 'Ndërfaqja e luajtësit';

  @override
  String get smartRecommendations => 'Sugjerime inteligjente';

  @override
  String get showVolumeSlider => 'Shfaq rregulluesin e volumit';

  @override
  String get showVolumeSliderSubtitle =>
      'Shfaq kontrollin e volumit në ekranin \"Duke u luajtur\"';

  @override
  String get showStarRatings => 'Shfaq vlerësimet me yje';

  @override
  String get showStarRatingsSubtitle =>
      'Vlerësoni këngët dhe shikoni vlerësimet';

  @override
  String get showMiniPlayerHeart => 'Show Heart Button';

  @override
  String get showMiniPlayerHeartSubtitle => 'Add to favorites from mini player';

  @override
  String get showMiniPlayerRepeat => 'Show Repeat Button';

  @override
  String get showMiniPlayerRepeatSubtitle =>
      'Toggle repeat mode from mini player';

  @override
  String get showMiniPlayerShuffle => 'Show Shuffle Button';

  @override
  String get showMiniPlayerShuffleSubtitle => 'Toggle shuffle from mini player';

  @override
  String get enableRecommendations => 'Aktivizo sugjerimet';

  @override
  String get enableRecommendationsSubtitle =>
      'Merrni sugjerime muzikore të personalizuara';

  @override
  String get listeningData => 'Të dhënat e dëgjimit';

  @override
  String totalPlays(int count) {
    return '$count dëgjime gjithsej';
  }

  @override
  String get clearListeningHistory => 'Pastro historikun e dëgjimit';

  @override
  String get confirmClearHistory =>
      'Kjo do të fshijë të gjitha të dhënat tuaja të dëgjimit dhe sugjerimet. A jeni të sigurt?';

  @override
  String get historyCleared => 'Historiku i dëgjimit u fshi';

  @override
  String get discordStatus => 'Statusi në Discord';

  @override
  String get discordStatusSubtitle =>
      'Shfaq këngën që po dëgjohet në profilin e Discord';

  @override
  String get selectLanguage => 'Zgjidhni gjuhën';

  @override
  String get systemDefault => 'Parazgjedhja e sistemit';

  @override
  String get communityTranslations => 'Përkthimet nga komuniteti';

  @override
  String get communityTranslationsSubtitle =>
      'Ndihmoni në përkthimin e Musly në Crowdin';

  @override
  String get yourLibrary => 'Libraria juaj';

  @override
  String get filterAll => 'Të gjitha';

  @override
  String get faves => 'Faves';

  @override
  String get filterPlaylists => 'Lista e këngëve';

  @override
  String get filterAlbums => 'Albume';

  @override
  String get filterArtists => 'Artisti';

  @override
  String get likedSongs => 'Këngët e pëlqyera';

  @override
  String get likedAlbums => 'Liked Albums';

  @override
  String get noLikedAlbums => 'No liked albums yet';

  @override
  String get localMusicLibrary => 'Local Music Library';

  @override
  String get mergeLocalLibrary => 'Merge with Server Library';

  @override
  String get mergeLocalLibrarySubtitle =>
      'Show local music alongside your server library';

  @override
  String get localMusicStats => 'Local Music Files';

  @override
  String get addMusicFolder => 'Add Music Folder';

  @override
  String get rescanLocalMusic => 'Rescan Local Music';

  @override
  String get radioStations => 'Stazioni Radio';

  @override
  String get playlist => 'Playlist';

  @override
  String get internetRadio => 'Radio Internet';

  @override
  String get newPlaylist => 'Playlisti e re';

  @override
  String get playlistName => 'Emri i listës t\'kngve';

  @override
  String get create => 'Krijo';

  @override
  String get deletePlaylist => 'Fshije listën t\'kngve';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'A jeni t\'sigurt qi doni me fshi listën e kngve \"$name\"?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Lista e kngve \"$name\" u fshi';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Gabim gjatë krijimit t\'listës t\'kngve: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Gabim gjatë fshirjes t\'listës t\'kngve: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Lista e kngve \"$name\" u kriju';
  }

  @override
  String get searchTitle => 'Kërko';

  @override
  String get searchPlaceholder => 'Artistët, Kangët, Albumet';

  @override
  String get tryDifferentSearch => 'Provo nji kërkim tjetër';

  @override
  String get noSuggestions => 'S\'ka sugjerime';

  @override
  String get browseCategories => 'Shfleto Kategoritë';

  @override
  String get liveSearchSection => 'Kërko';

  @override
  String get liveSearch => 'Kërkim Live';

  @override
  String get liveSearchSubtitle =>
      'Përditëso rezultatet n\'kohë reale kuer t\'shkrush n\'vend se me qit nji listë t\'poshtme';

  @override
  String get categoryMadeForYou => 'Kriju për ty';

  @override
  String get categoryNewReleases => 'Shtimet e reja';

  @override
  String get categoryTopRated => 'Më të vlerësuarat';

  @override
  String get categoryGenres => 'Zhanret';

  @override
  String get categoryFavorites => 'Të preferuarat';

  @override
  String get categoryRadio => 'Radio';

  @override
  String get settingsTitle => 'Cilësimet';

  @override
  String get tabPlayback => 'Riprodhimi';

  @override
  String get tabStorage => 'Magazina e të dhënave';

  @override
  String get tabServer => 'Serveri';

  @override
  String get tabDisplay => 'Ekrani';

  @override
  String get tabSupport => 'Support';

  @override
  String get tabAbout => 'Rreth';

  @override
  String get sectionAutoDj => 'AUTO DJ';

  @override
  String get autoDjMode => 'Mënyra Auto DJ';

  @override
  String songsToAdd(int count) {
    return 'Këngë për t\'u shtuar: $count';
  }

  @override
  String get sectionReplayGain => 'NORMALIZIMI I VOLUMIT (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Mënyra';

  @override
  String preamp(String value) {
    return 'Parapërforcimi: $value dB';
  }

  @override
  String get preventClipping => 'Parandalo Shformimin (Clipping)';

  @override
  String fallbackGain(String value) {
    return 'Përforcimi i Rezervës (Fallback Gain): $value dB';
  }

  @override
  String get sectionStreamingQuality => 'CILËSIA E STRIMIMIT';

  @override
  String get enableTranscoding => 'Aktivizo Transkodimin';

  @override
  String get qualityWifi => 'Cilësia në WiFi';

  @override
  String get qualityMobile => 'Cilësia në Rrjetin Celular';

  @override
  String get format => 'Formati';

  @override
  String get transcodingSubtitle =>
      'Redukto përdorimin e të dhënave me cilësi më të ulët';

  @override
  String get modeOff => 'Joaktivizuar';

  @override
  String get modeTrack => 'Kënga';

  @override
  String get modeAlbum => 'Album';

  @override
  String get sectionServerConnection => 'LIDHJA ME SERVERIN';

  @override
  String get serverType => 'Lloji i Serverit';

  @override
  String get notConnected => 'Nuk është lidhur';

  @override
  String get unknown => 'I panjohur';

  @override
  String get sectionMusicFolders => 'DOSJET E MUZIKËS';

  @override
  String get musicFolders => 'Dosjet e Muzikës';

  @override
  String get noMusicFolders => 'Nuk u gjet asnjë dosje muzike';

  @override
  String get sectionSavedProfiles => 'SAVED PROFILES';

  @override
  String get switchProfile => 'Switch Profile';

  @override
  String get switchServer => 'Switch Server';

  @override
  String get addProfile => 'Add Profile';

  @override
  String switchProfileConfirmation(String profile) {
    return 'Connect to \"$profile\"?';
  }

  @override
  String get sectionAccount => 'LLOGARIA';

  @override
  String get logoutConfirmation =>
      'A jeni të sigurt që dëshironi të shkëputeni? Kjo do të fshijë gjithashtu të gjitha të dhënat e ruajtura (cache).';

  @override
  String get sectionCacheSettings => 'PARAMETRAT E CACHE';

  @override
  String get imageCache => 'Cache i imazheve';

  @override
  String get musicCache => 'Cache i muzikës';

  @override
  String get bpmCache => 'Cache i BPM-ve';

  @override
  String get saveAlbumCovers => 'Ruaj kopertinat e albumeve në pajisje';

  @override
  String get saveSongMetadata =>
      'Ruaj të dhënat e këngëve (metadata) në pajisje';

  @override
  String get saveBpmAnalysis => 'Ruaj analizën e BPM-ve në pajisje';

  @override
  String get sectionCacheCleanup => 'PASTRIMI I CACHE';

  @override
  String get clearAllCache => 'Pastro të gjithë Cache-in';

  @override
  String get allCacheCleared => 'Gjithë cache-i u pastrua';

  @override
  String get sectionOfflineDownloads => 'SHKARKIMET OFFLINE';

  @override
  String get downloadedSongs => 'Këngët e shkarkuara';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Duke shkarkuar bibliotekën... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Shkarko të gjithë bibliotekën';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Kjo do të shkarkojë $count këngë në pajisjen tuaj. Kjo mund të marrë pak kohë dhe të përdorë hapësirë të konsiderueshme ruajtjeje.\n\nVazhdo?';
  }

  @override
  String get keepScreenOnDuringDownload => 'Keep Screen On';

  @override
  String get keepScreenOnDuringDownloadSubtitle =>
      'Prevents download from failing when device locks';

  @override
  String get parallelDownloads => 'Parallel Downloads';

  @override
  String get parallelDownloadsSubtitle =>
      'Download multiple songs simultaneously';

  @override
  String get downloadSingular => 'download';

  @override
  String get downloadPlural => 'downloads';

  @override
  String get slowerButStable => 'Slower but more stable';

  @override
  String get fasterButMoreData => 'Faster but uses more data';

  @override
  String get libraryDownloadStarted => 'Shkarkimi i bibliotekës filloi';

  @override
  String get deleteDownloads => 'Fshi të gjitha shkarkimet';

  @override
  String get downloadsDeleted => 'Të gjitha shkarkimet u fshinë';

  @override
  String get noSongsAvailable =>
      'Nuk u gjet asnjë këngë. Ju lutem ngarkoni bibliotekën tuaj fillimisht.';

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
  String get expand => 'Expand';

  @override
  String get createPlaylist => 'Create playlist';

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
  String get addedArtistToQueue => 'Added artist to Queue';

  @override
  String get addedArtistToQueueError => 'Failed adding artist to Queue';

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

  @override
  String get errorLoadingGenres => 'Error loading genres';

  @override
  String get noGenresFound => 'No genres found';

  @override
  String get noAlbumsInGenre => 'No albums in this genre';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount songs • $albumCount albums';
  }

  @override
  String get sectionJukebox => 'JUKEBOX MODE';

  @override
  String get jukeboxMode => 'Jukebox Mode';

  @override
  String get jukeboxModeSubtitle =>
      'Play audio through the server instead of this device';

  @override
  String get openJukeboxController => 'Open Jukebox Controller';

  @override
  String get jukeboxClearQueue => 'Clear Queue';

  @override
  String get jukeboxShuffleQueue => 'Shuffle Queue';

  @override
  String get jukeboxQueueEmpty => 'No songs in queue';

  @override
  String get jukeboxNowPlaying => 'Now Playing';

  @override
  String get jukeboxQueue => 'Queue';

  @override
  String get jukeboxVolume => 'Volume';

  @override
  String get playOnJukebox => 'Play on Jukebox';

  @override
  String get addToJukeboxQueue => 'Add to Jukebox Queue';

  @override
  String get jukeboxNotSupported =>
      'Jukebox mode is not supported by this server. Enable it in your server configuration (e.g. EnableJukebox = true in Navidrome).';

  @override
  String get musicFoldersDialogTitle => 'Select Music Folders';

  @override
  String get musicFoldersHint =>
      'Leave all enabled to use all folders (default).';

  @override
  String get musicFoldersSaved => 'Music folder selection saved';

  @override
  String get artworkStyleSection => 'Artwork Style';

  @override
  String get artworkCornerRadius => 'Corner Radius';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Adjust how round the corners of album covers appear';

  @override
  String get artworkCornerRadiusNone => 'None';

  @override
  String get artworkShape => 'Shape';

  @override
  String get artworkShapeRounded => 'Rounded';

  @override
  String get artworkShapeCircle => 'Circle';

  @override
  String get artworkShapeSquare => 'Square';

  @override
  String get artworkShadow => 'Shadow';

  @override
  String get artworkShadowNone => 'None';

  @override
  String get artworkShadowSoft => 'Soft';

  @override
  String get artworkShadowMedium => 'Medium';

  @override
  String get artworkShadowStrong => 'Strong';

  @override
  String get artworkShadowColor => 'Shadow Color';

  @override
  String get artworkShadowColorBlack => 'Black';

  @override
  String get artworkShadowColorAccent => 'Accent';

  @override
  String get artworkPreview => 'Preview';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '${value}px';
  }

  @override
  String get noArtwork => 'No artwork';

  @override
  String get serverUnreachableTitle => 'Cannot reach server';

  @override
  String get serverUnreachableSubtitle =>
      'Check your connection or server settings.';

  @override
  String get openOfflineMode => 'Open in offline mode';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeLabel => 'Theme';

  @override
  String get accentColorLabel => 'Accent color';

  @override
  String get circularDesignLabel => 'Circular Design';

  @override
  String get circularDesignSubtitle =>
      'Floating, rounded UI with translucent panels and glass-blur effect on the player and navigation bar.';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get liveLabel => 'LIVE';

  @override
  String get discordStatusText => 'Discord status text';

  @override
  String get discordStatusTextSubtitle =>
      'Second line shown in Discord activity';

  @override
  String get discordRpcStyleArtist => 'Artist name';

  @override
  String get discordRpcStyleSong => 'Song title';

  @override
  String get discordRpcStyleApp => 'App name (Musly)';

  @override
  String get sectionVolumeNormalization => 'VOLUME NORMALIZATION (REPLAYGAIN)';

  @override
  String get replayGainModeOff => 'Off';

  @override
  String get replayGainModeTrack => 'Track';

  @override
  String get replayGainModeAlbum => 'Album';

  @override
  String replayGainPreamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get replayGainPreventClipping => 'Prevent Clipping';

  @override
  String replayGainFallbackGain(String value) {
    return 'Fallback Gain: $value dB';
  }

  @override
  String autoDjSongsToAdd(int count) {
    return 'Songs to Add: $count';
  }

  @override
  String get transcodingEnable => 'Enable Transcoding';

  @override
  String get transcodingEnableSubtitle =>
      'Reduce data usage with lower quality';

  @override
  String get smartTranscoding => 'Smart Transcoding';

  @override
  String get smartTranscodingSubtitle =>
      'Automatically adjusts quality based on your connection (WiFi vs mobile data)';

  @override
  String get smartTranscodingDetectedNetwork => 'Detected network: ';

  @override
  String smartTranscodingActiveBitrate(String bitrate) {
    return 'Active bitrate: $bitrate';
  }

  @override
  String get transcodingWifiQuality => 'WiFi Quality';

  @override
  String get transcodingWifiQualitySubtitleSmart =>
      'Used automatically on WiFi';

  @override
  String get transcodingWifiQualitySubtitle => 'Bitrate when on WiFi';

  @override
  String get transcodingMobileQuality => 'Mobile Quality';

  @override
  String get transcodingMobileQualitySubtitleSmart =>
      'Used automatically on cellular data';

  @override
  String get transcodingMobileQualitySubtitle => 'Bitrate when on mobile data';

  @override
  String get transcodingFormat => 'Format';

  @override
  String get transcodingFormatSubtitle => 'Audio codec used for streaming';

  @override
  String get transcodingBitrateOriginal => 'Original (No Transcoding)';

  @override
  String get transcodingFormatOriginal => 'Original';

  @override
  String get imageCacheTitle => 'Image Cache';

  @override
  String get imageCacheSubtitle => 'Save album covers locally';

  @override
  String get musicCacheTitle => 'Music Cache';

  @override
  String get musicCacheSubtitle => 'Save song metadata locally';

  @override
  String get bpmCacheTitle => 'BPM Cache';

  @override
  String get bpmCacheSubtitle => 'Save BPM analysis locally';

  @override
  String get sectionAboutInformation => 'INFORMATION';

  @override
  String get sectionAboutDeveloper => 'DEVELOPER';

  @override
  String get sectionAboutLinks => 'LINKS';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutPlatform => 'Platform';

  @override
  String get aboutMadeBy => 'Made by dddevid';

  @override
  String get aboutGitHub => 'github.com/dddevid';

  @override
  String get aboutLinkGitHub => 'GitHub Repository';

  @override
  String get aboutLinkChangelog => 'Changelog';

  @override
  String get aboutLinkReportIssue => 'Report Issue';

  @override
  String get aboutLinkDiscord => 'Join Discord Community';

  @override
  String get sectionAnalyticsPrivacy => 'Analytics & Privacy';

  @override
  String get anonymousAnalytics => 'Anonymous Analytics';

  @override
  String get anonymousAnalyticsSubtitle =>
      'Help improve Musly with anonymous crash reports and usage stats';

  @override
  String get deviceId => 'Device ID';

  @override
  String deviceIdAnonymous(String id) {
    return 'Anonymous ID: $id';
  }

  @override
  String get deviceIdDisabled =>
      'Enable analytics to see your anonymous device ID';

  @override
  String get aboutDeviceId => 'About Device ID';

  @override
  String get aboutDeviceIdSubtitle =>
      'This is an anonymous identifier generated by the app. It cannot be linked to your personal identity and is used only for analytics.';

  @override
  String get supportGreeting => 'Hey there! 👋';

  @override
  String get supportParagraph1 =>
      'I\'m Devid, the developer behind Musly. I built this app because I love music and believe everyone deserves a beautiful, free music player.';

  @override
  String get supportParagraph2 =>
      'Musly is completely free and open-source. No ads and no subscription fees. I work on it in my free time because I genuinely enjoy making something useful for people like you.';

  @override
  String get supportParagraph3 =>
      'But servers, development tools, and coffee aren\'t free 😅 If Musly has become a part of your daily life and you\'d like to say \"thanks,\" a small donation would mean the world to me. It helps cover costs and keeps me motivated to add new features.';

  @override
  String get supportParagraph4 =>
      'No pressure at all though - your enjoyment of the app is already the best reward! 💙';

  @override
  String get supportDonationTitle => 'Support with a Donation';

  @override
  String get supportDonationSubtitle => 'via Revolut - any amount helps!';

  @override
  String get supportDiscordTitle => 'Join our Discord';

  @override
  String get supportDiscordSubtitle =>
      'Get help, suggest features, or just chat';

  @override
  String get supportWaysTitle => 'Other ways to support';

  @override
  String get supportWayRate => 'Leave a rating on the app store';

  @override
  String get supportWayShare => 'Tell your friends about Musly';

  @override
  String get supportWayBugs => 'Report bugs or suggest features';

  @override
  String get supportWayEnjoy => 'Just enjoy the music! 🎵';

  @override
  String get supportMadeWithLove => 'Made with 💙 in Italy';
}
