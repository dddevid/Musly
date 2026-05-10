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
  String get favoritePlaylists => 'Favorite Playlists';

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
  String get years => 'Years';

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
  String get playerInterface => 'Player-Oberfläche';

  @override
  String get smartRecommendations => 'Smarte Empfehlungen';

  @override
  String get showVolumeSlider => 'Zeige Lautstärkeregler';

  @override
  String get showVolumeSliderSubtitle =>
      'Lautstärkeregler in Wiedergabebildschirm anzeigen';

  @override
  String get showStarRatings => 'Sternbewertungen anzeigen';

  @override
  String get showStarRatingsSubtitle => 'Bewerte Songs und sehe Bewertungen an';

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
  String get enableRecommendations => 'Empfehlungen aktivieren';

  @override
  String get enableRecommendationsSubtitle =>
      'Erhalte personalisierte Musikvorschläge';

  @override
  String get listeningData => 'Hördaten';

  @override
  String totalPlays(int count) {
    return '$count Plays insgesamt';
  }

  @override
  String get clearListeningHistory => 'Hörverlauf löschen';

  @override
  String get confirmClearHistory =>
      'Dies wird all deine Hördaten und Empfehlungen zurücksetzen. Bist du sicher?';

  @override
  String get historyCleared => 'Hörverlauf gelöscht';

  @override
  String get discordStatus => 'Discord Status';

  @override
  String get discordStatusSubtitle =>
      'Spielenden Song in Discord Profil anzeigen';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get systemDefault => 'Standardeinstellung';

  @override
  String get communityTranslations => 'Übersetzungen von der Community';

  @override
  String get communityTranslationsSubtitle =>
      'Hilf Musly bei der Übersetzung auf Crowdin';

  @override
  String get yourLibrary => 'Deine Bibliothek';

  @override
  String get filterAll => 'Alle';

  @override
  String get faves => 'Faves';

  @override
  String get filterPlaylists => 'Playlisten';

  @override
  String get filterAlbums => 'Alben';

  @override
  String get filterArtists => 'Künstler';

  @override
  String get likedSongs => 'Lieblingssongs';

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
  String get radioStations => 'Radiosender';

  @override
  String get playlist => 'Playlist';

  @override
  String get internetRadio => 'Internetradio';

  @override
  String get newPlaylist => 'Neue Playlist';

  @override
  String get playlistName => 'Name der Playlist';

  @override
  String get create => 'Erstellen';

  @override
  String get deletePlaylist => 'Playlist löschen';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Bist du sicher, dass du die Playlist \"$name \" löschen möchtest?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Playlist \"$name\" gelöscht';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Fehler beim Erstellen der Playlist: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Fehler beim Löschen der Playlist: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Playlist \"$name\" erstellt';
  }

  @override
  String get searchTitle => 'Suche';

  @override
  String get searchPlaceholder => 'Künstler, Songs, Alben';

  @override
  String get tryDifferentSearch => 'Versuche es mit einer anderen Suchanfrage';

  @override
  String get noSuggestions => 'Keine Empfehlungen';

  @override
  String get browseCategories => 'Kategorien durchstöbern';

  @override
  String get liveSearchSection => 'Suche';

  @override
  String get liveSearch => 'Live Search';

  @override
  String get liveSearchSubtitle =>
      'Update results as you type instead of showing a dropdown';

  @override
  String get categoryMadeForYou => 'Für dich';

  @override
  String get categoryNewReleases => 'Neuerscheinungen';

  @override
  String get categoryTopRated => 'Top bewertet';

  @override
  String get categoryGenres => 'Genres';

  @override
  String get categoryFavorites => 'Favoriten';

  @override
  String get categoryRadio => 'Radio';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get tabPlayback => 'Wiedergabe';

  @override
  String get tabStorage => 'Speicher';

  @override
  String get tabServer => 'Server';

  @override
  String get tabDisplay => 'Anzeige';

  @override
  String get tabSupport => 'Support';

  @override
  String get tabAbout => 'Über';

  @override
  String get sectionAutoDj => 'AUTO DJ';

  @override
  String get autoDjMode => 'Auto DJ-Modus';

  @override
  String songsToAdd(int count) {
    return 'Zu hinzufügende Songs: $count';
  }

  @override
  String get sectionReplayGain => 'LAUTSTÄRKE NORMALISIEREN ';

  @override
  String get replayGainMode => 'Modus';

  @override
  String preamp(String value) {
    return 'Vorverstärker: $value dB';
  }

  @override
  String get preventClipping => 'Clipping verhindern';

  @override
  String fallbackGain(String value) {
    return 'Fallback-Gain: $value dB';
  }

  @override
  String get sectionStreamingQuality => 'STREAMING QUALITÄT';

  @override
  String get enableTranscoding => 'Transkodierung aktivieren';

  @override
  String get qualityWifi => 'Qualität im Wlan';

  @override
  String get qualityMobile => 'Qualität bei Mobilen Daten';

  @override
  String get format => 'Format';

  @override
  String get transcodingSubtitle =>
      'Datenverbrauch mit niedrigerer Qualität reduzieren';

  @override
  String get modeOff => 'Aus';

  @override
  String get modeTrack => 'Titel';

  @override
  String get modeAlbum => 'Album';

  @override
  String get sectionServerConnection => 'SERVERVERBINDUNG';

  @override
  String get serverType => 'Servertyp';

  @override
  String get notConnected => 'Nicht verbunden';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get sectionMusicFolders => 'MUSIK ORDNER';

  @override
  String get musicFolders => 'Musik Ordner';

  @override
  String get noMusicFolders => 'Keine Musik Ordner gefunden';

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
      'Bist du sicher, dass du dich abmelden möchten? Dies wird alle Daten im Cache löschen.';

  @override
  String get sectionCacheSettings => 'CACHE-EINSTELLUNGEN';

  @override
  String get imageCache => 'Bilder Cache';

  @override
  String get musicCache => 'Musik Cache';

  @override
  String get bpmCache => 'BPM Cache';

  @override
  String get saveAlbumCovers => 'Albumcover lokal speichern';

  @override
  String get saveSongMetadata => 'Song Metadaten lokal speichern';

  @override
  String get saveBpmAnalysis => 'BPM Analyse lokal speichern';

  @override
  String get sectionCacheCleanup => 'CACHE LÖSCHEN';

  @override
  String get clearAllCache => 'Alle Caches löschen';

  @override
  String get allCacheCleared => 'Alle Caches gelöscht';

  @override
  String get sectionOfflineDownloads => 'OFFLINE DOWNLOADS';

  @override
  String get downloadedSongs => 'Heruntergeladene Songs';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Lade Bibliothek herunter... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Gesamte Bibliothek herunterladen';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Dies wird $count Lieder auf dein Gerät herunterladen. Dies kann eine Weile dauern und viel Speicherplatz nutzen.\n\nFortfahren?';
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
  String get libraryDownloadStarted => 'Herunterladen der Bibliothek gestartet';

  @override
  String get deleteDownloads => 'Alle Downloads löschen';

  @override
  String get downloadsDeleted => 'Alle Downloads gelöscht';

  @override
  String get noSongsAvailable =>
      'Keine Songs verfügbar. Bitte laden zuerst deine Bibliothek.';

  @override
  String get sectionBpmAnalysis => 'BPM ANALYSE';

  @override
  String get cachedBpms => 'BPMs im Cache';

  @override
  String get cacheAllBpms => 'Alle BPMs im Cache speichern';

  @override
  String get clearBpmCache => 'BPM Cache leeren';

  @override
  String get bpmCacheCleared => 'BPM Cache gelöscht';

  @override
  String downloadedStats(int count, String size) {
    return '$count Songs • $size';
  }

  @override
  String get sectionInformation => 'INFORMATIONEN';

  @override
  String get sectionDeveloper => 'ENTWICKLER';

  @override
  String get sectionLinks => 'LINKS';

  @override
  String get githubRepo => 'GitHub';

  @override
  String get playingFrom => 'WIEDERGABE AUS';

  @override
  String get live => 'LIVE';

  @override
  String get streamingLive => 'Live Streaming';

  @override
  String get stopRadio => 'Radio stoppen';

  @override
  String get removeFromLiked => 'Aus Lieblingssongs entfernen';

  @override
  String get addToLiked => 'Zu Lieblingssongs hinzufügen';

  @override
  String get playNext => 'Als Nächstes wiedergeben';

  @override
  String get addToQueue => 'Zur Warteschlange hinzufügen';

  @override
  String get goToAlbum => 'Zum Album';

  @override
  String get goToArtist => 'Zum Künstler';

  @override
  String get rateSong => 'Song bewerten';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Song bewerten ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Bewertung entfernt';

  @override
  String rated(int rating, String stars) {
    return 'Bewertet $rating $stars';
  }

  @override
  String get removeRating => 'Bewertung entfernen';

  @override
  String get downloaded => 'Heruntergeladen';

  @override
  String downloading(int percent) {
    return 'Herunterladen... $percent%';
  }

  @override
  String get removeDownload => 'Download entfernen';

  @override
  String get removeDownloadConfirm =>
      'Diesen Song aus dem Offline Speicher löschen?';

  @override
  String get downloadRemoved => 'Download entfernt';

  @override
  String downloadedTitle(String title) {
    return '\"$title \" heruntergeladen';
  }

  @override
  String get downloadFailed => 'Download fehlgeschlagen';

  @override
  String downloadError(Object error) {
    return 'Download-Fehler: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return '\"$title\" zu $playlist hinzugefügt';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Fehler beim Hinzufügen zur Playlist: $error';
  }

  @override
  String get noPlaylists => 'Keine Playlists verfügbar';

  @override
  String get createNewPlaylist => 'Neue Playlist erstellen';

  @override
  String artistNotFound(String name) {
    return 'Künstler \"$name\" nicht gefunden';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Fehler bei der Suche nach Künstler: $error';
  }

  @override
  String get selectArtist => 'Künstler auswählen';

  @override
  String get removedFromFavorites => 'Aus Favoriten entfernt';

  @override
  String get addedToFavorites => 'Zu Favoriten hinzugefügt';

  @override
  String get star => 'Stern';

  @override
  String get stars => 'Sterne';

  @override
  String get albumNotFound => 'Album nicht gefunden';

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
  String get connected => 'Verbunden';

  @override
  String get noSongPlaying => 'Kein Song spielt';

  @override
  String get internetRadioUppercase => 'INTERNET RADIO';

  @override
  String get playingNext => 'Nächste Wiedergabe';

  @override
  String get createPlaylistTitle => 'Playlist erstellen';

  @override
  String get playlistNameHint => 'Playlist name';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Playlist \"$name\" mit diesem Song erstellt';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Fehler beim Laden der Playlists: $error';
  }

  @override
  String get playlistNotFound => 'Playlist nicht gefunden';

  @override
  String get noSongsInPlaylist => 'Keine Songs in dieser Playlist';

  @override
  String get noFavoriteSongsYet => 'Noch keine Lieblingslieder';

  @override
  String get noFavoriteAlbumsYet => 'Noch keine Lieblingsalben';

  @override
  String get listeningHistory => 'Hörverlauf';

  @override
  String get noListeningHistory => 'Kein Hörverlauf';

  @override
  String get songsWillAppearHere =>
      'Songs, die du spielst, werden hier angezeigt';

  @override
  String get sortByTitleAZ => 'Songs (A-Z)';

  @override
  String get sortByTitleZA => 'Songs (A-Z)';

  @override
  String get sortByArtistAZ => 'Künstler (A-Z)';

  @override
  String get sortByArtistZA => 'Künstler (A-Z)';

  @override
  String get sortByAlbumAZ => 'Album (A-Z)';

  @override
  String get sortByAlbumZA => 'Album (A-Z)';

  @override
  String get recentlyAdded => 'Zuletzt hinzugefügt';

  @override
  String get noSongsFound => 'Keine Songs gefunden';

  @override
  String get noAlbumsFound => 'Keine Alben gefunden';

  @override
  String get noHomepageUrl => 'Keine Homepage-URL verfügbar';

  @override
  String get playStation => 'Sender abspielen';

  @override
  String get openHomepage => 'Öffne Homepage';

  @override
  String get copyStreamUrl => 'Stream-URL kopieren';

  @override
  String get failedToLoadRadioStations => 'Fehler beim Laden der Radiosender';

  @override
  String get noRadioStations => 'Keine Radiosender';

  @override
  String get noRadioStationsHint =>
      'Füge Radiosender in den Navidrome Server-Einstellungen ein, um sie hier zu sehen.';

  @override
  String get connectToServerSubtitle =>
      'Verbinde dich mit deinem Subsonic-Server';

  @override
  String get pleaseEnterServerUrl => 'Bitte Server-URL eingeben';

  @override
  String get invalidUrlFormat =>
      'Die URL muss mit http:// oder https:// beginnen';

  @override
  String get pleaseEnterUsername => 'Bitte Benutzername eingeben';

  @override
  String get pleaseEnterPassword => 'Bitte Passwort eingeben';

  @override
  String get legacyAuthentication => 'Legacy Authentifizierung';

  @override
  String get legacyAuthSubtitle => 'Für ältere Subsonic-Server';

  @override
  String get allowSelfSignedCerts => 'Selbstsignierte Zertifikate zulassen';

  @override
  String get allowSelfSignedSubtitle =>
      'Für Server mit benutzerdefinierten TLS/SSL-Zertifikat';

  @override
  String get advancedOptions => 'Erweiterte Einstellungen';

  @override
  String get customTlsCertificate => 'Benutzerdefiniertes TLS/SSL-Zertifikat';

  @override
  String get customCertificateSubtitle =>
      'Ein benutzerdefiniertes Zertifikat für Server mit nicht standardmäßiger CA hochladen';

  @override
  String get selectCertificateFile => 'Zertifikatsdatei auswählen';

  @override
  String get clientCertificate => 'Client Zertifikat (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Authentifiziere diesen Client mit einem Zertifikat (benötigt mTLS-fähigen Server)';

  @override
  String get selectClientCertificate => 'Client Zertifikat auswählen';

  @override
  String get clientCertPassword => 'Zertifikatspasswort (optional)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Beim Auswählen des Zertifikates ist ein Fehler aufgetreten: $error';
  }

  @override
  String get connect => 'Verbinden';

  @override
  String get or => 'ODER';

  @override
  String get useLocalFiles => 'Lokale Dateien verwenden';

  @override
  String get startingScan => 'Scan wird gestartet ...';

  @override
  String get storagePermissionRequired =>
      'Speicherberechtigung erforderlich, um lokale Dateien zu scannen';

  @override
  String get noMusicFilesFound => 'Keine Songdateien auf Ihrem Gerät gefunden';

  @override
  String get remove => 'Entfernen';

  @override
  String failedToSetRating(Object error) {
    return 'Fehler bei der Bewertung: $error';
  }

  @override
  String get home => 'Startseite';

  @override
  String get playlistsSection => 'PLAYLISTS';

  @override
  String get collapse => 'Einklappen';

  @override
  String get expand => 'erweitern';

  @override
  String get createPlaylist => 'Playlist erstellen';

  @override
  String get likedSongsSidebar => 'Lieblingssongs';

  @override
  String playlistSongsCount(int count) {
    return 'Playlist • $count Songs';
  }

  @override
  String get failedToLoadLyrics => 'Fehler beim Laden der Lyrics';

  @override
  String get lyricsNotFoundSubtitle =>
      'Songtext für diesen Song konnte nicht gefunden werden';

  @override
  String get backToCurrent => 'Zurück zum aktuellen';

  @override
  String get exitFullscreen => 'Vollbild verlassen';

  @override
  String get fullscreen => 'Vollbild';

  @override
  String get noLyrics => 'Kein Songtext';

  @override
  String get internetRadioMiniPlayer => 'Internetradio';

  @override
  String get liveBadge => 'LIVE';

  @override
  String get localFilesModeBanner => 'Lokale Dateien Modus';

  @override
  String get offlineModeBanner =>
      'Offline-Modus - Nur heruntergeladene Songs abspielen';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get updateAvailableSubtitle =>
      'Eine neue Version von Musly ist verfügbar!';

  @override
  String updateCurrentVersion(String version) {
    return 'Aktuell: v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Neueste: $version';
  }

  @override
  String get whatsNew => 'Neuigkeiten';

  @override
  String get downloadUpdate => 'Download';

  @override
  String get remindLater => 'Später';

  @override
  String get seeAll => 'Alle ansehen';

  @override
  String get artistDataNotFound => 'Künstler nicht gefunden';

  @override
  String get addedArtistToQueue => 'Added artist to Queue';

  @override
  String get addedArtistToQueueError => 'Failed adding artist to Queue';

  @override
  String get casting => 'Übertragen';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Übertragen/DLNA (Beta)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Verbindung trennen';

  @override
  String get searchingDevices => 'Suche nach Geräten';

  @override
  String get castWifiHint =>
      'Stelle sicher, dass sich dein Cast / DLNA Gerät\nim selben Wi-Fi-Netzwerk befindet';

  @override
  String connectedToDevice(String name) {
    return 'Verbunden mit $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Verbindung zu $name fehlgeschlagen';
  }

  @override
  String get removedFromLikedSongs => 'Aus Lieblingssongs entfernen';

  @override
  String get addedToLikedSongs => 'Zu Lieblingssongs hinzufügen';

  @override
  String get enableShuffle => 'Shuffle aktivieren';

  @override
  String get enableRepeat => 'Wiederholung aktivieren';

  @override
  String get connecting => 'Verbinde';

  @override
  String get closeLyrics => 'Songtext schließen';

  @override
  String errorStartingDownload(Object error) {
    return 'Fehler beim Starten des Downloads: $error';
  }

  @override
  String get errorLoadingGenres => 'Fehler beim Laden des Genres';

  @override
  String get noGenresFound => 'Kein Genre gefunden';

  @override
  String get noAlbumsInGenre => 'Kein Album in diesem Genre';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount songs • $albumCount albums';
  }

  @override
  String get sectionJukebox => 'JUKEBOX MODE';

  @override
  String get jukeboxMode => 'Jukebox Modus';

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
  String get artworkPreview => 'Vorschau';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '${value}px';
  }

  @override
  String get noArtwork => 'No artwork';

  @override
  String get serverUnreachableTitle => 'Server nicht erreichbar';

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
