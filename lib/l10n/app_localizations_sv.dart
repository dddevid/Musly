// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appName => 'Musly';

  @override
  String get goodMorning => 'God morgon';

  @override
  String get goodAfternoon => 'God eftermiddag';

  @override
  String get goodEvening => 'God kväll';

  @override
  String get forYou => 'För Dig';

  @override
  String get quickPicks => 'Snabba Val';

  @override
  String get discoverMix => 'Discover Mix';

  @override
  String get recentlyPlayed => 'Nyligen spelade';

  @override
  String get yourPlaylists => 'Dina Spellistor';

  @override
  String get favoritePlaylists => 'Favorite Playlists';

  @override
  String get madeForYou => 'Skapat För Dig';

  @override
  String get topRated => 'Top Rated';

  @override
  String get noContentAvailable => 'Inget innehåll tillgängligt';

  @override
  String get tryRefreshing =>
      'Försök ladda om eller kontrollera din servers anslutning';

  @override
  String get refresh => 'Ladda om';

  @override
  String get errorLoadingSongs => 'Fel vid laddning av låtar';

  @override
  String get noSongsInGenre => 'Inga låtar i detta genre';

  @override
  String get errorLoadingAlbums => 'Fel vid laddning av album';

  @override
  String get noTopRatedAlbums => 'Inga högst rankade album';

  @override
  String get login => 'Logga in';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get username => 'Användarnamn';

  @override
  String get password => 'Lösenord';

  @override
  String get selectCertificate => 'Välj TLS/SSL Certifikat';

  @override
  String failedToSelectCertificate(String error) {
    return 'Misslyckades välja certifikat: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'Server URL måste starta med http:// eller https://';

  @override
  String get failedToConnect => 'Misslyckades ansluta';

  @override
  String get library => 'Bibliotek';

  @override
  String get search => 'Sök';

  @override
  String get settings => 'Inställningar';

  @override
  String get albums => 'Album';

  @override
  String get artists => 'Artister';

  @override
  String get songs => 'Låtar';

  @override
  String get playlists => 'Spellistor';

  @override
  String get genres => 'Genrer';

  @override
  String get years => 'Years';

  @override
  String get favorites => 'Favoriter';

  @override
  String get nowPlaying => 'Spelas Nu';

  @override
  String get queue => 'Kö';

  @override
  String get lyrics => 'Låttext';

  @override
  String get play => 'Spela';

  @override
  String get pause => 'Pausa';

  @override
  String get next => 'Nästa';

  @override
  String get previous => 'Förra';

  @override
  String get shuffle => 'Blanda';

  @override
  String get repeat => 'Upprepa';

  @override
  String get repeatOne => 'Upprepa en gång';

  @override
  String get repeatOff => 'Upprepning av';

  @override
  String get addToPlaylist => 'Lägg till Spellista';

  @override
  String get removeFromPlaylist => 'Ta bort från Spellista';

  @override
  String get addToFavorites => 'Lägg till Favoriter';

  @override
  String get removeFromFavorites => 'Ta bort från Favoriter';

  @override
  String get download => 'Ladda ner';

  @override
  String get delete => 'Ta bort';

  @override
  String get cancel => 'Avbryt';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Spara';

  @override
  String get close => 'Stäng';

  @override
  String get general => 'Allmän';

  @override
  String get appearance => 'Utseende';

  @override
  String get playback => 'Uppspelning';

  @override
  String get storage => 'Lagring';

  @override
  String get about => 'Om';

  @override
  String get darkMode => 'Mörkt Läge';

  @override
  String get language => 'Språk';

  @override
  String get version => 'Version';

  @override
  String get madeBy => 'Gjord av dddevid';

  @override
  String get githubRepository => 'Github Repository';

  @override
  String get reportIssue => 'Rapportera Problem';

  @override
  String get joinDiscord => 'Gå med Discord Community:t';

  @override
  String get unknownArtist => 'Okänd Artist';

  @override
  String get unknownAlbum => 'Okänt Album';

  @override
  String get playAll => 'Spela Alla';

  @override
  String get shuffleAll => 'Blanda Alla';

  @override
  String get sortBy => 'Sortera efter';

  @override
  String get sortByName => 'Namn';

  @override
  String get sortByArtist => 'Artist';

  @override
  String get sortByAlbum => 'Album';

  @override
  String get sortByDate => 'Datum';

  @override
  String get sortByDuration => 'Längd';

  @override
  String get ascending => 'Stigande ordning';

  @override
  String get descending => 'Fallande ordning';

  @override
  String get noLyricsAvailable => 'Ingen låttext tillgänglig';

  @override
  String get loading => 'Laddar...';

  @override
  String get error => 'Fel';

  @override
  String get retry => 'Försök igen';

  @override
  String get noResults => 'Inga resultat';

  @override
  String get searchHint => 'Sök efter låt, album, artist...';

  @override
  String get allSongs => 'Alla Låtar';

  @override
  String get allAlbums => 'Alla Album';

  @override
  String get allArtists => 'Alla Artister';

  @override
  String trackNumber(int number) {
    return 'Låt $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count låtar',
      one: '1 låt',
      zero: 'Inga låtar',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count album',
      one: '1 album',
      zero: 'Inga album',
    );
    return '$_temp0';
  }

  @override
  String get logout => 'Logga ut';

  @override
  String get confirmLogout => 'Är du säker på att du vill logga ut?';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nej';

  @override
  String get offlineMode => 'Offline Läge';

  @override
  String get radio => 'Radio';

  @override
  String get changelog => 'Ändringslogg';

  @override
  String get platform => 'Plattform';

  @override
  String get server => 'Server';

  @override
  String get display => 'Display';

  @override
  String get playerInterface => 'Spelargränsnitt';

  @override
  String get smartRecommendations => 'Smarta Rekommendationer';

  @override
  String get showVolumeSlider => 'Visa Volym Slider';

  @override
  String get showVolumeSliderSubtitle =>
      'Visa volymkontroll i Spelas Nu skärmen';

  @override
  String get showStarRatings => 'Visa Stjärnbetyg';

  @override
  String get showStarRatingsSubtitle => 'Betygsätt låtar och visa betyg';

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
  String get enableRecommendations => 'Aktivera Rekommendationer';

  @override
  String get enableRecommendationsSubtitle => 'Få personliga musikförslag';

  @override
  String get listeningData => 'Lyssningsdata';

  @override
  String totalPlays(int count) {
    return '$count uppspelningar';
  }

  @override
  String get clearListeningHistory => 'Rensa lyssningshistorik';

  @override
  String get confirmClearHistory =>
      'Detta kommer nollställa all din lyssningsdata och rekommendationer. Är du säker?';

  @override
  String get historyCleared => 'Lyssningshistorik rensad';

  @override
  String get discordStatus => 'Discord Status';

  @override
  String get discordStatusSubtitle => 'Visa låt som spelas på Discord profil';

  @override
  String get selectLanguage => 'Välj Språk';

  @override
  String get systemDefault => 'Systemets Standard';

  @override
  String get communityTranslations => 'Översättningar av Community:t';

  @override
  String get communityTranslationsSubtitle =>
      'Hjälp översätta Musly på Crowdin';

  @override
  String get yourLibrary => 'Ditt Bibliotek';

  @override
  String get filterAll => 'Alla';

  @override
  String get faves => 'Faves';

  @override
  String get filterPlaylists => 'Spellistor';

  @override
  String get filterAlbums => 'Album';

  @override
  String get filterArtists => 'Artister';

  @override
  String get likedSongs => 'Gillade Låtar';

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
  String get localLibraryEmpty => 'Your library is empty';

  @override
  String get localLibraryEmptySubtitle =>
      'No local music files were found. Tap the button below to scan again.';

  @override
  String get libraryEmpty => 'Your library is empty';

  @override
  String get libraryEmptySubtitle => 'Add some songs to get started.';

  @override
  String get scanForMusic => 'Scan for Music';

  @override
  String get radioStations => 'Radio Stationer';

  @override
  String get playlist => 'Spellista';

  @override
  String get internetRadio => 'Internet Radio';

  @override
  String get newPlaylist => 'Ny Spellista';

  @override
  String get playlistName => 'Spellistans Namn';

  @override
  String get create => 'Skapa';

  @override
  String get deletePlaylist => 'Ta bort Spellista';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Är du säker på att du vill ta port spellistan \"$name\"?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Spellista \"$name\" borttagen';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Fel uppstod vid skapandet av spellista: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Fel uppstod vid borttagning av spellista: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Spellista \"$name\" skapad';
  }

  @override
  String get searchTitle => 'Sök';

  @override
  String get searchPlaceholder => 'Artister, Låtar, Album';

  @override
  String get tryDifferentSearch => 'Försök söka någonting annat';

  @override
  String get noSuggestions => 'Inga förslag';

  @override
  String get browseCategories => 'Bläddra Kategorier';

  @override
  String get liveSearchSection => 'Sök';

  @override
  String get liveSearch => 'Livesökning';

  @override
  String get liveSearchSubtitle =>
      'Uppdatera resultat medan du skriver istället för att visa en lista';

  @override
  String get categoryMadeForYou => 'Skapad För Dig';

  @override
  String get categoryNewReleases => 'Nytt Släpp';

  @override
  String get categoryTopRated => 'Högst rankade';

  @override
  String get categoryGenres => 'Genrer';

  @override
  String get categoryFavorites => 'Favoriter';

  @override
  String get categoryRadio => 'Radio';

  @override
  String get settingsTitle => 'Inställningar';

  @override
  String get tabPlayback => 'Uppspelning';

  @override
  String get tabStorage => 'Lagring';

  @override
  String get tabServer => 'Server';

  @override
  String get tabDisplay => 'Display';

  @override
  String get tabSupport => 'Support';

  @override
  String get tabAbout => 'Om';

  @override
  String get sectionAutoDj => 'AUTO DJ';

  @override
  String get autoDjMode => 'Auto DJ läge';

  @override
  String songsToAdd(int count) {
    return 'Låtar att lägga till: $count';
  }

  @override
  String get sectionReplayGain => 'VOLYM NORMALISERING (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Läge';

  @override
  String preamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get preventClipping => 'Förhindra Ljudklippning';

  @override
  String fallbackGain(String value) {
    return 'Fallback Gain: $value dB';
  }

  @override
  String get sectionStreamingQuality => 'STREAMING KVALITET';

  @override
  String get enableTranscoding => 'Aktivera Transkodning';

  @override
  String get qualityWifi => 'WiFi Kvalité';

  @override
  String get qualityMobile => 'Mobil Kvalité';

  @override
  String get format => 'Format';

  @override
  String get transcodingSubtitle => 'Minska dataanvändning med sämre kvalité';

  @override
  String get modeOff => 'Av';

  @override
  String get modeTrack => 'Låt';

  @override
  String get modeAlbum => 'Album';

  @override
  String get sectionServerConnection => 'SERVER ANSLUTNING';

  @override
  String get serverType => 'Server Typ';

  @override
  String get notConnected => 'Inte ansluten';

  @override
  String get unknown => 'Okänd';

  @override
  String get sectionMusicFolders => 'MUSIK MAPPAR';

  @override
  String get musicFolders => 'Musik Mappar';

  @override
  String get noMusicFolders => 'Inga musik mappar hittades';

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
  String get sectionAccount => 'KONTO';

  @override
  String get logoutConfirmation =>
      'Är du säker på att du vill logga ut? Detta kommer även rensa all cachelagrad data.';

  @override
  String get sectionCacheSettings => 'CACHE INSTÄLLNINGAR';

  @override
  String get imageCache => 'Bild Cache';

  @override
  String get musicCache => 'Musik Cache';

  @override
  String get bpmCache => 'BPM Cache';

  @override
  String get saveAlbumCovers => 'Spara albumomslag lokalt';

  @override
  String get saveSongMetadata => 'Spara låt metadata lokalt';

  @override
  String get saveBpmAnalysis => 'Spara BPM analys lokalt';

  @override
  String get sectionCacheCleanup => 'CACHE RENSNING';

  @override
  String get clearAllCache => 'Rensa all cache';

  @override
  String get allCacheCleared => 'Alla cacher rensade';

  @override
  String get sectionOfflineDownloads => 'OFFLINE NERLADDNINGAR';

  @override
  String get downloadedSongs => 'Nedladdade Låtar';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Laddar ner Bibliotek... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Ladda ner Hela Biblioteket';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Detta kommer att ladda ner $count låtar till din enhet. Detta kan ta ett tag och använda en del lagringsutrymme.\n\nFortsätt?';
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
  String get libraryDownloadStarted => 'Nerladdning av bibliotek startad';

  @override
  String get deleteDownloads => 'Radera Alla Nedladdningar';

  @override
  String get downloadsDeleted => 'Alla nerladdningar raderades';

  @override
  String get noSongsAvailable =>
      'Inga låtar tillgängliga. Ladda ditt bibliotek först.';

  @override
  String get sectionBpmAnalysis => 'BPM ANALYS';

  @override
  String get cachedBpms => 'Cachade BPM:ar';

  @override
  String get cacheAllBpms => 'Cacha alla BPM:ar';

  @override
  String get clearBpmCache => 'Rensa BPM Cache';

  @override
  String get bpmCacheCleared => 'BPM cache rensad';

  @override
  String downloadedStats(int count, String size) {
    return '$count låtar • $size';
  }

  @override
  String get sectionInformation => 'INFORMATION';

  @override
  String get sectionDeveloper => 'UTVECKLARE';

  @override
  String get sectionLinks => 'LÄNKAR';

  @override
  String get githubRepo => 'GitHub Repository';

  @override
  String get playingFrom => 'SPELAR FRÅN';

  @override
  String get live => 'LIVE';

  @override
  String get streamingLive => 'Sänder Live';

  @override
  String get stopRadio => 'Stoppa Radio';

  @override
  String get removeFromLiked => 'Ta bort från Gillade Låtar';

  @override
  String get addToLiked => 'Lägg till Gillade låtar';

  @override
  String get playNext => 'Spela Nästa';

  @override
  String get addToQueue => 'Lägg till i Kö';

  @override
  String get goToAlbum => 'Gå till Album';

  @override
  String get goToArtist => 'Gå till Artist';

  @override
  String get rateSong => 'Betygsätt Låt';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Betygsätt Låt ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Betyg borttaget';

  @override
  String rated(int rating, String stars) {
    return 'Betygsatt $rating $stars';
  }

  @override
  String get removeRating => 'Ta bort Betyg';

  @override
  String get downloaded => 'Nerladdad';

  @override
  String downloading(int percent) {
    return 'Laddar ner... $percent%';
  }

  @override
  String get removeDownload => 'Ta bort Nerladdning';

  @override
  String get removeDownloadConfirm =>
      'Ta bort den här låten från offline lagring?';

  @override
  String get downloadRemoved => 'Nerladdning borttagen';

  @override
  String downloadedTitle(String title) {
    return 'Laddade ner \"$title\"';
  }

  @override
  String get downloadFailed => 'Nerladdning misslyckades';

  @override
  String downloadError(Object error) {
    return 'Nerladdningsfel: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Lade till \"$title\" till $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Fel vid tillägg till spellista: $error';
  }

  @override
  String get noPlaylists => 'Inga spellistor tillgängliga';

  @override
  String get createNewPlaylist => 'Skapa Ny Spellista';

  @override
  String artistNotFound(String name) {
    return 'Artist \"$name\" hittades inte';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Fel vid sökning av artist: $error';
  }

  @override
  String get selectArtist => 'Välj Artist';

  @override
  String get removedFromFavorites => 'Ta bort från Favoriter';

  @override
  String get addedToFavorites => 'Lades till i Favoriter';

  @override
  String get star => 'stjärna';

  @override
  String get stars => 'stjärnor';

  @override
  String get albumNotFound => 'Albumet hittades inte';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours HR $minutes MIN';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get topSongs => 'Topplåtar';

  @override
  String get connected => 'Ansluten';

  @override
  String get noSongPlaying => 'Ingen låt spelas';

  @override
  String get internetRadioUppercase => 'INTERNET RADIO';

  @override
  String get playingNext => 'Spelar Nästa';

  @override
  String get createPlaylistTitle => 'Skapa Spellista';

  @override
  String get playlistNameHint => 'Spellista namn';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Skapad spellista \"$name\" med den här låten';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Fel vid laddning av spellistor: $error';
  }

  @override
  String get playlistNotFound => 'Spellistan hittades inte';

  @override
  String get noSongsInPlaylist => 'Inga låtar i den här spellistan';

  @override
  String get noFavoriteSongsYet => 'Inga favoritlåtar än';

  @override
  String get noFavoriteAlbumsYet => 'Inga favoritalbum än';

  @override
  String get listeningHistory => 'Lyssnings Historik';

  @override
  String get noListeningHistory => 'Ingen Lyssningshistorik';

  @override
  String get songsWillAppearHere => 'Låtar du spelar visas här';

  @override
  String get sortByTitleAZ => 'Titel (A-Ö)';

  @override
  String get sortByTitleZA => 'Titel (Ö-A)';

  @override
  String get sortByArtistAZ => 'Artist (A-Ö)';

  @override
  String get sortByArtistZA => 'Artist (Ö-A)';

  @override
  String get sortByAlbumAZ => 'Album (A-Ö)';

  @override
  String get sortByAlbumZA => 'Album (Ö-A)';

  @override
  String get recentlyAdded => 'Nyligen tillagda';

  @override
  String get noSongsFound => 'Inga låtar hittades';

  @override
  String get noAlbumsFound => 'Inget album hittades';

  @override
  String get noHomepageUrl => 'Ingen hemsida URL tillgänglig';

  @override
  String get playStation => 'Play Station';

  @override
  String get openHomepage => 'Öppna Hemsida';

  @override
  String get copyStreamUrl => 'Kopiera Stream URL';

  @override
  String get failedToLoadRadioStations =>
      'Misslyckades att ladda radiostationer';

  @override
  String get noRadioStations => 'Inga Radiostationer';

  @override
  String get noRadioStationsHint =>
      'Lägg till radiostationer i dina Navidrome serverinställningar för att se dem här.';

  @override
  String get connectToServerSubtitle => 'Anslut till din Subsonic server';

  @override
  String get pleaseEnterServerUrl => 'Ange server URL';

  @override
  String get invalidUrlFormat => 'URL måste börja med http:// eller https://';

  @override
  String get pleaseEnterUsername => 'Ange användarnamn';

  @override
  String get pleaseEnterPassword => 'Ange lösenord';

  @override
  String get legacyAuthentication => 'Legacy Autentisering';

  @override
  String get legacyAuthSubtitle => 'Använd för äldre Subsonic servrar';

  @override
  String get allowSelfSignedCerts => 'Tillåt självsignerade certifikat';

  @override
  String get allowSelfSignedSubtitle =>
      'För servrar med anpassade TLS/SSL certifikat';

  @override
  String get advancedOptions => 'Avancerade Inställningar';

  @override
  String get customTlsCertificate => 'Anpassad TLS/SSL Certifikat';

  @override
  String get customCertificateSubtitle =>
      'Ladda upp ett anpassat certifikat för servrar med icke-standard CA';

  @override
  String get selectCertificateFile => 'Välj Certifikat';

  @override
  String get clientCertificate => 'Klientcertifikat (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Autentisera denna klient med ett certifikat (kräver mTLS-aktiverad server)';

  @override
  String get selectClientCertificate => 'Välj Klientcertifikat';

  @override
  String get clientCertPassword => 'Lösenord för certifikat (valfritt)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Misslyckades välja klientcertifikat: $error';
  }

  @override
  String get connect => 'Anslut';

  @override
  String get or => 'ELLER';

  @override
  String get useLocalFiles => 'Använd Lokala Filer';

  @override
  String get startingScan => 'Startar skanning...';

  @override
  String get storagePermissionRequired =>
      'Lagringsbehörighet krävs för att skanna lokala filer';

  @override
  String get noMusicFilesFound => 'Inga musikfiler hittades på din enhet';

  @override
  String get remove => 'Ta bort';

  @override
  String failedToSetRating(Object error) {
    return 'Misslyckades att ange betyg: $error';
  }

  @override
  String get home => 'Hem';

  @override
  String get playlistsSection => 'SPELLISTOR';

  @override
  String get collapse => 'Kollapsa';

  @override
  String get expand => 'Expandera';

  @override
  String get createPlaylist => 'Skapa spellista';

  @override
  String get likedSongsSidebar => 'Gillade Låtar';

  @override
  String playlistSongsCount(int count) {
    return 'Spellista • $count låtar';
  }

  @override
  String get failedToLoadLyrics => 'Misslyckades ladda låttext';

  @override
  String get lyricsNotFoundSubtitle =>
      'Låttext för denna låt kunde inte hittas';

  @override
  String get backToCurrent => 'Tillbaka till nuvarande';

  @override
  String get exitFullscreen => 'Avsluta Helskärmsläge';

  @override
  String get fullscreen => 'Helskärmsläge';

  @override
  String get noLyrics => 'Ingen låttext';

  @override
  String get internetRadioMiniPlayer => 'Internet Radio';

  @override
  String get liveBadge => 'LIVE';

  @override
  String get localFilesModeBanner => 'Lokalt Filläge';

  @override
  String get offlineModeBanner =>
      'Offline-läge – Endast uppspelning av nerladdad musik';

  @override
  String get updateAvailable => 'Uppdatering Tillgänglig';

  @override
  String get updateAvailableSubtitle =>
      'En ny version av Musly finns tillgänglig!';

  @override
  String updateCurrentVersion(String version) {
    return 'Nuvarande: v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Senaste: v$version';
  }

  @override
  String get whatsNew => 'Nyheter';

  @override
  String get downloadUpdate => 'Ladda ner';

  @override
  String get remindLater => 'Senare';

  @override
  String get seeAll => 'Se Alla';

  @override
  String get artistDataNotFound => 'Artist hittades inte';

  @override
  String get addedArtistToQueue => 'Added artist to Queue';

  @override
  String get addedArtistToQueueError => 'Failed adding artist to Queue';

  @override
  String get casting => 'Castar';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Cast / DLNA (Beta)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Koppla ifrån';

  @override
  String get searchingDevices => 'Söker efter enheter';

  @override
  String get castWifiHint =>
      'Se till att din Cast / DLNA-enhet\när kopplad till samma Wi-Fi nätverk';

  @override
  String connectedToDevice(String name) {
    return 'Ansluten till $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Misslyckades att ansluta till $name';
  }

  @override
  String get removedFromLikedSongs => 'Borttagen från Gillade Låtar';

  @override
  String get addedToLikedSongs => 'Lades till i Gillade Låtar';

  @override
  String get enableShuffle => 'Aktivera Blandning';

  @override
  String get enableRepeat => 'Aktivera Upprepning';

  @override
  String get connecting => 'Ansluter';

  @override
  String get closeLyrics => 'Stäng Låttext';

  @override
  String errorStartingDownload(Object error) {
    return 'Fel vid start av nerladdning: $error';
  }

  @override
  String get errorLoadingGenres => 'Fel vid laddning av genrer';

  @override
  String get noGenresFound => 'Inga genrer hittades';

  @override
  String get noAlbumsInGenre => 'Inga album i denna genre';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount låtar • $albumCount album';
  }

  @override
  String get sectionJukebox => 'JUKEBOXLÄGE';

  @override
  String get jukeboxMode => 'Jukeboxläge';

  @override
  String get jukeboxModeSubtitle =>
      'Spela upp ljud genom servern istället för denna enhet';

  @override
  String get openJukeboxController => 'Öppna Jukeboxkontroll';

  @override
  String get jukeboxClearQueue => 'Rensa Kö';

  @override
  String get jukeboxShuffleQueue => 'Blanda Kö';

  @override
  String get jukeboxQueueEmpty => 'Inga låtar i kö';

  @override
  String get jukeboxNowPlaying => 'Spelas Nu';

  @override
  String get jukeboxQueue => 'Kö';

  @override
  String get jukeboxVolume => 'Volym';

  @override
  String get playOnJukebox => 'Spela på Jukebox';

  @override
  String get addToJukeboxQueue => 'Lägg till i Jukeboxkön';

  @override
  String get jukeboxNotSupported =>
      'Jukeboxläget stöds inte av denna server. Aktivera det i din serverkonfiguration (t.ex. EnableJukebox = true in Navidrome).';

  @override
  String get musicFoldersDialogTitle => 'Välj Musikmappar';

  @override
  String get musicFoldersHint =>
      'Lämna alla aktiverade för att använda alla mappar (standard).';

  @override
  String get musicFoldersSaved => 'Val av musikmappar sparad';

  @override
  String get artworkStyleSection => 'Konststil';

  @override
  String get artworkCornerRadius => 'Hörnradie';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Justera hur runda hörnen på albumomslag ser ut';

  @override
  String get artworkCornerRadiusNone => 'Ingen';

  @override
  String get artworkShape => 'Form';

  @override
  String get artworkShapeRounded => 'Avrundad';

  @override
  String get artworkShapeCircle => 'Cirkel';

  @override
  String get artworkShapeSquare => 'Kvadrat';

  @override
  String get artworkShadow => 'Skugga';

  @override
  String get artworkShadowNone => 'Ingen';

  @override
  String get artworkShadowSoft => 'Mjuk';

  @override
  String get artworkShadowMedium => 'Medium';

  @override
  String get artworkShadowStrong => 'Stark';

  @override
  String get artworkShadowColor => 'Skuggfärg';

  @override
  String get artworkShadowColorBlack => 'Svart';

  @override
  String get artworkShadowColorAccent => 'Accentfärg';

  @override
  String get artworkPreview => 'Förhandsgranskning';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '${value}px';
  }

  @override
  String get noArtwork => 'Ingen bild';

  @override
  String get serverUnreachableTitle => 'Kan inte nå servern';

  @override
  String get serverUnreachableSubtitle =>
      'Kontrollera din anslutning eller dina serverinställningar.';

  @override
  String get openOfflineMode => 'Öppna i offline läge';

  @override
  String get appearanceSection => 'Utseende';

  @override
  String get themeLabel => 'Tema';

  @override
  String get accentColorLabel => 'Accentfärg';

  @override
  String get circularDesignLabel => 'Cirkulär Design';

  @override
  String get circularDesignSubtitle =>
      'Flytande, avrundat UI med genomskinliga paneler och glass-blur effekt på spelaren och navigationsfältet.';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Ljust';

  @override
  String get themeModeDark => 'Mörkt';

  @override
  String get liveLabel => 'LIVE';

  @override
  String get discordStatusText => 'Discord statustext';

  @override
  String get discordStatusTextSubtitle =>
      'Andra raden visas i Discord-aktivitet';

  @override
  String get discordRpcStyleArtist => 'Artistnamn';

  @override
  String get discordRpcStyleSong => 'Låttitel';

  @override
  String get discordRpcStyleApp => 'Appnamn (Musly)';

  @override
  String get sectionVolumeNormalization => 'VOLYM NORMALISERING (REPLAYGAIN)';

  @override
  String get replayGainModeOff => 'Av';

  @override
  String get replayGainModeTrack => 'Låt';

  @override
  String get replayGainModeAlbum => 'Album';

  @override
  String replayGainPreamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get replayGainPreventClipping => 'Förhindra Ljudklippning';

  @override
  String replayGainFallbackGain(String value) {
    return 'Fallback Gain: $value dB';
  }

  @override
  String autoDjSongsToAdd(int count) {
    return 'Låtar att tillägga: $count';
  }

  @override
  String get transcodingEnable => 'Aktivera Transkodning';

  @override
  String get transcodingEnableSubtitle =>
      'Minska dataanvändningen med lägre kvalitet';

  @override
  String get smartTranscoding => 'Smart Transkodning';

  @override
  String get smartTranscodingSubtitle =>
      'Justerar kvaliteten automatiskt baserat på din anslutning (WiFi vs mobildata)';

  @override
  String get smartTranscodingDetectedNetwork => 'Upptäckt nätverk: ';

  @override
  String smartTranscodingActiveBitrate(String bitrate) {
    return 'Aktiv bithastighet: $bitrate';
  }

  @override
  String get transcodingWifiQuality => 'WiFi Kvalité';

  @override
  String get transcodingWifiQualitySubtitleSmart =>
      'Används automatiskt på WiFi';

  @override
  String get transcodingWifiQualitySubtitle =>
      'Bithastighet vid användning av WiFi';

  @override
  String get transcodingMobileQuality => 'Mobildata Kvalité';

  @override
  String get transcodingMobileQualitySubtitleSmart =>
      'Används automatiskt på mobildata';

  @override
  String get transcodingMobileQualitySubtitle =>
      'Bithastighet vid användning av mobildata';

  @override
  String get transcodingFormat => 'Format';

  @override
  String get transcodingFormatSubtitle => 'Ljudkodek som används för streaming';

  @override
  String get transcodingBitrateOriginal => 'Original (Ingen Omkodning)';

  @override
  String get transcodingFormatOriginal => 'Original';

  @override
  String get imageCacheTitle => 'Bildcache';

  @override
  String get imageCacheSubtitle => 'Spara albumomslag lokalt';

  @override
  String get musicCacheTitle => 'Musikcache';

  @override
  String get musicCacheSubtitle => 'Spara låt metadata lokalt';

  @override
  String get bpmCacheTitle => 'BPM-cache';

  @override
  String get bpmCacheSubtitle => 'Spara BPM analys lokalt';

  @override
  String get sectionAboutInformation => 'INFORMATION';

  @override
  String get sectionAboutDeveloper => 'UTVECKLARE';

  @override
  String get sectionAboutLinks => 'LÄNKAR';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutPlatform => 'Plattform';

  @override
  String get aboutMadeBy => 'Gjord av dddevid';

  @override
  String get aboutGitHub => 'github.com/dddevid';

  @override
  String get aboutLinkGitHub => 'GitHub Repository';

  @override
  String get aboutLinkChangelog => 'Ändringshistorik';

  @override
  String get aboutLinkReportIssue => 'Rapportera Problem';

  @override
  String get aboutLinkDiscord => 'Gå med Discord-communityn';

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

  @override
  String get playbackSpeed => 'Playback Speed';

  @override
  String get normalSpeed => 'Normal (1×)';

  @override
  String get preservePitch => 'Preserve pitch';

  @override
  String get preservePitchSubtitle => 'Keep original pitch when changing speed';

  @override
  String get pitch => 'Pitch';

  @override
  String get pitchPreserved => 'pitch preserved';

  @override
  String speedTooltipWithPitch(String speed, String pitch) {
    return 'Speed $speed · pitch $pitch×';
  }

  @override
  String speedTooltipPitchPreserved(String speed) {
    return 'Speed $speed · pitch preserved';
  }

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String get sleepTimerActive => 'Sleep timer active';

  @override
  String get fadeOut => 'Fade out';

  @override
  String fadeOutSubtitle(int seconds) {
    return 'Gradually lower volume in the last $seconds s';
  }

  @override
  String get finishCurrentSong => 'Finish current song';

  @override
  String get finishCurrentSongSubtitle => 'Stop after the current track ends';

  @override
  String sleepTimerMinutes(int count) {
    return '$count min';
  }

  @override
  String sleepTimerHours(int count) {
    return '$count hour';
  }

  @override
  String sleepTimerSetFor(String duration) {
    return 'Sleep timer set for $duration';
  }

  @override
  String get customDuration => 'Custom duration…';

  @override
  String get cancelTimer => 'Cancel timer';

  @override
  String get customSleepTimer => 'Custom Sleep Timer';

  @override
  String get set => 'Set';

  @override
  String get addToPlaylistTitle => 'Add to Playlist';

  @override
  String get yourPlaylistsLabel => 'Your Playlists';

  @override
  String get enableLrcLibFallback => 'Fetch lyrics from LRCLIB';

  @override
  String get lrcLibFallbackSubtitle =>
      'Automatically search LRCLIB for lyrics when your server does not provide them';
}
