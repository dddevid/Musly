// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Musly';

  @override
  String get goodMorning => 'Buon giorno';

  @override
  String get goodAfternoon => 'Buona sera';

  @override
  String get goodEvening => 'Buon pomeriggio';

  @override
  String get forYou => 'Per Te';

  @override
  String get quickPicks => 'Scelte Rapide';

  @override
  String get discoverMix => 'Mix Scoperta';

  @override
  String get recentlyPlayed => 'Riprodotte Recentemente';

  @override
  String get yourPlaylists => 'Le Tue Playlist';

  @override
  String get favoritePlaylists => 'Favorite Playlists';

  @override
  String get madeForYou => 'Fatte Per Te';

  @override
  String get topRated => 'Più Votata';

  @override
  String get noContentAvailable => 'Nessun contenuto disponibile';

  @override
  String get tryRefreshing =>
      'Prova ad aggiornare o controlla la connessione al server';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get errorLoadingSongs => 'Errore durante il caricamento delle canzoni';

  @override
  String get noSongsInGenre => 'Nessun brano in questo genere';

  @override
  String get errorLoadingAlbums => 'Errore durante il caricamento album';

  @override
  String get noTopRatedAlbums => 'Nessun album classificato';

  @override
  String get login => 'Accedi';

  @override
  String get serverUrl => 'URL Del Server';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get selectCertificate => 'Seleziona Certificato TLS/SSL';

  @override
  String failedToSelectCertificate(String error) {
    return 'Impossibile selezionare il certificato: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'L\'URL del server deve iniziare con http:// o https://';

  @override
  String get failedToConnect => 'Connessione fallita';

  @override
  String get library => 'Libreria';

  @override
  String get search => 'Cerca';

  @override
  String get settings => 'Impostazioni';

  @override
  String get albums => 'Album';

  @override
  String get artists => 'Artisti';

  @override
  String get songs => 'Brani';

  @override
  String get playlists => 'Playlist';

  @override
  String get genres => 'Generi';

  @override
  String get years => 'Years';

  @override
  String get favorites => 'Preferiti';

  @override
  String get nowPlaying => 'In riproduzione';

  @override
  String get queue => 'Coda';

  @override
  String get lyrics => 'Testi';

  @override
  String get play => 'Riproduci';

  @override
  String get pause => 'Pausa';

  @override
  String get next => 'Successivo';

  @override
  String get previous => 'Precedente';

  @override
  String get shuffle => 'Riproduzione casuale';

  @override
  String get repeat => 'Ripeti';

  @override
  String get repeatOne => 'Ripeti una volta';

  @override
  String get repeatOff => 'Ripetizione disattivata';

  @override
  String get addToPlaylist => 'Aggiungi alla Playlist';

  @override
  String get removeFromPlaylist => 'Rimuovi dalla Playlist';

  @override
  String get addToFavorites => 'Aggiungi ai Preferiti';

  @override
  String get removeFromFavorites => 'Rimuovi dai Preferiti';

  @override
  String get download => 'Scarica';

  @override
  String get delete => 'Cancella';

  @override
  String get cancel => 'Annulla';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Salva';

  @override
  String get close => 'Chiudi';

  @override
  String get general => 'Generale';

  @override
  String get appearance => 'Aspetto';

  @override
  String get playback => 'Riproduzione';

  @override
  String get storage => 'Spazio di archiviazione';

  @override
  String get about => 'Informazioni';

  @override
  String get darkMode => 'Tema Scuro';

  @override
  String get language => 'Lingua';

  @override
  String get version => 'Versione';

  @override
  String get madeBy => 'Realizzato da dddevid';

  @override
  String get githubRepository => 'Repository GitHub';

  @override
  String get reportIssue => 'Segnala un problema';

  @override
  String get joinDiscord => 'Unisciti Alla Community Di Discord';

  @override
  String get unknownArtist => 'Artista sconosciuto';

  @override
  String get unknownAlbum => 'Album sconosciuto';

  @override
  String get playAll => 'Riproduci tutto';

  @override
  String get shuffleAll => 'Riproduzione casuale per tutti i brani';

  @override
  String get sortBy => 'Ordina Per';

  @override
  String get sortByName => 'Nome';

  @override
  String get sortByArtist => 'Artista';

  @override
  String get sortByAlbum => 'Album';

  @override
  String get sortByDate => 'Data';

  @override
  String get sortByDuration => 'Durata';

  @override
  String get ascending => 'Ascendente';

  @override
  String get descending => 'Discendente';

  @override
  String get noLyricsAvailable => 'Nessun testo disponibile per questo brano';

  @override
  String get loading => 'Caricamento in corso...';

  @override
  String get error => 'Errore';

  @override
  String get retry => 'Riprova';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get searchHint => 'Cerca brani, album, artisti...';

  @override
  String get allSongs => 'Tutti i Brani';

  @override
  String get allAlbums => 'Tutti Gli Album';

  @override
  String get allArtists => 'Tutti Gli Artisti';

  @override
  String trackNumber(int number) {
    return 'Traccia $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canzoni',
      one: '1 canzone',
      zero: 'Nessuna canzone',
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
      zero: 'Nessun album',
    );
    return '$_temp0';
  }

  @override
  String get logout => 'Logout';

  @override
  String get confirmLogout => 'Sei sicuro di volerti disconnettere?';

  @override
  String get yes => 'Si';

  @override
  String get no => 'No';

  @override
  String get offlineMode => 'Modalità offline';

  @override
  String get radio => 'Radio';

  @override
  String get changelog => 'Registro delle modifiche';

  @override
  String get platform => 'Piattaforma';

  @override
  String get server => 'Server';

  @override
  String get display => 'Schermo';

  @override
  String get playerInterface => 'Interfaccia Lettore';

  @override
  String get smartRecommendations => 'Raccomandazioni intelligenti';

  @override
  String get showVolumeSlider => 'Mostra Cursore Del Volume';

  @override
  String get showVolumeSliderSubtitle =>
      'Visualizza il controllo del volume nella schermata Ora in riproduzione';

  @override
  String get showStarRatings => 'Mostra Valutazioni Stella';

  @override
  String get showStarRatingsSubtitle => 'Vota brani e visualizza valutazioni';

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
  String get enableRecommendations => 'Attiva Raccomandazioni';

  @override
  String get enableRecommendationsSubtitle =>
      'Ottieni suggerimenti musicali personalizzati';

  @override
  String get listeningData => 'Dati Di Ascolto';

  @override
  String totalPlays(int count) {
    return '$count Riproduzioni Totali';
  }

  @override
  String get clearListeningHistory => 'Cancella Cronologia Ascolti';

  @override
  String get confirmClearHistory =>
      'Questo resetterà tutti i tuoi dati di ascolto e i tuoi consigli. Sei sicuro?';

  @override
  String get historyCleared => 'Cronologia di ascolto cancellata';

  @override
  String get discordStatus => 'Stato Discord';

  @override
  String get discordStatusSubtitle =>
      'Mostra il brano in riproduzione sul profilo Discord';

  @override
  String get selectLanguage => 'Seleziona lingua';

  @override
  String get systemDefault => 'Predefinita di Sistema';

  @override
  String get communityTranslations => 'Traduzioni da Community';

  @override
  String get communityTranslationsSubtitle =>
      'Aiuta a tradurre Musly su Crowdin';

  @override
  String get yourLibrary => 'La Tua Libreria';

  @override
  String get filterAll => 'Tutto';

  @override
  String get faves => 'Faves';

  @override
  String get filterPlaylists => 'Playlist';

  @override
  String get filterAlbums => 'Album';

  @override
  String get filterArtists => 'Artisti';

  @override
  String get likedSongs => 'Brani preferiti';

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
  String get radioStations => 'Stazioni radio';

  @override
  String get playlist => 'Playlist';

  @override
  String get internetRadio => 'Radio Internet';

  @override
  String get newPlaylist => 'Nuova Playlist';

  @override
  String get playlistName => 'Nome Playlist';

  @override
  String get create => 'Crea';

  @override
  String get deletePlaylist => 'Elimina Playlist';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Sei sicuro di voler eliminare la playlist \"$name\"?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Playlist \"$name\" eliminata';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Errore nella creazione della playlist: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Errore nell\'eliminare la playlist: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Playlist \"$name\" creata';
  }

  @override
  String get searchTitle => 'Cerca';

  @override
  String get searchPlaceholder => 'Artisti, Canzoni, Album';

  @override
  String get tryDifferentSearch => 'Prova un’altra ricerca';

  @override
  String get noSuggestions => 'Nessun suggerimento';

  @override
  String get browseCategories => 'Esplora le categorie';

  @override
  String get liveSearchSection => 'Ricerca';

  @override
  String get liveSearch => 'Ricerca Live';

  @override
  String get liveSearchSubtitle =>
      'Aggiorna i risultati mentre digiti invece di mostrare un menu a tendina';

  @override
  String get categoryMadeForYou => 'Fatte Per Te';

  @override
  String get categoryNewReleases => 'Nuovi Rilasci';

  @override
  String get categoryTopRated => 'I più votati';

  @override
  String get categoryGenres => 'Generi';

  @override
  String get categoryFavorites => 'Preferiti';

  @override
  String get categoryRadio => 'Radio';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get tabPlayback => 'Riproduzione';

  @override
  String get tabStorage => 'Spazio di archiviazione';

  @override
  String get tabServer => 'Server';

  @override
  String get tabDisplay => 'Schermo';

  @override
  String get tabSupport => 'Supporto';

  @override
  String get tabAbout => 'Informazioni';

  @override
  String get sectionAutoDj => 'AUTO DJ';

  @override
  String get autoDjMode => 'Modalità DJ Automatica';

  @override
  String songsToAdd(int count) {
    return 'Brani da aggiungere: $count';
  }

  @override
  String get sectionReplayGain => 'NORMALIZZAZIONE VOLUME (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Modalità';

  @override
  String preamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get preventClipping => 'Previeni Il Clipping';

  @override
  String fallbackGain(String value) {
    return 'Guadagno Fallback: $value dB';
  }

  @override
  String get sectionStreamingQuality => 'QUALITÀ DI STREAMING';

  @override
  String get enableTranscoding => 'Abilita La Transcodifica';

  @override
  String get qualityWifi => 'Qualità WiFi';

  @override
  String get qualityMobile => 'Qualità Mobile';

  @override
  String get format => 'Formato';

  @override
  String get transcodingSubtitle =>
      'Riduce l\'utilizzo dei dati con qualità inferiore';

  @override
  String get modeOff => 'Off';

  @override
  String get modeTrack => 'Traccia';

  @override
  String get modeAlbum => 'Album';

  @override
  String get sectionServerConnection => 'CONNESSIONE DEL SERVER';

  @override
  String get serverType => 'Tipo di server';

  @override
  String get notConnected => 'Non connesso';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get sectionMusicFolders => 'CARTELLE MUSICA';

  @override
  String get musicFolders => 'Cartelle Musica';

  @override
  String get noMusicFolders => 'Nessuna cartella musicale trovata';

  @override
  String get sectionSavedProfiles => 'PROFILI SALVATI';

  @override
  String get switchProfile => 'Cambia Profilo';

  @override
  String get switchServer => 'Cambia Server';

  @override
  String get addProfile => 'Aggiungi Profilo';

  @override
  String switchProfileConfirmation(String profile) {
    return 'Connetti a \"$profile\"?';
  }

  @override
  String get sectionAccount => 'ACCOUNT';

  @override
  String get logoutConfirmation =>
      'Sei sicuro di voler uscire? Questo cancellerà tutti i dati memorizzati nella cache.';

  @override
  String get sectionCacheSettings => 'IMPOSTAZIONI CACHE';

  @override
  String get imageCache => 'Cache delle immagini';

  @override
  String get musicCache => 'Cache Della Musica';

  @override
  String get bpmCache => 'Cache BPM';

  @override
  String get saveAlbumCovers => 'Salva localmente le copertine degli album';

  @override
  String get saveSongMetadata => 'Salva i metadati del brano localmente';

  @override
  String get saveBpmAnalysis => 'Salva analisi BPM localmente';

  @override
  String get sectionCacheCleanup => 'PULIZIA DELLA CACHE';

  @override
  String get clearAllCache => 'Svuota tutta la cache';

  @override
  String get allCacheCleared => 'Tutta la cache cancellata';

  @override
  String get sectionOfflineDownloads => 'DOWNLOAD OFFLINE';

  @override
  String get downloadedSongs => 'Brani Scaricati';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Scaricamento Della Libreria... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Scarica Tutta La Libreria';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Questo scaricherà  $count brani sul tuo dispositivo. Questo potrebbe richiedere un po\' di tempo e utilizzare uno spazio di archiviazione significativo.\n\nContinuare?';
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
  String get libraryDownloadStarted => 'Download della libreria avviato';

  @override
  String get deleteDownloads => 'Elimina tutti i download';

  @override
  String get downloadsDeleted => 'Tutti i download eliminati';

  @override
  String get noSongsAvailable =>
      'Nessun brano disponibile. Carica prima la tua libreria.';

  @override
  String get sectionBpmAnalysis => 'ANALISI BPM';

  @override
  String get cachedBpms => 'Cached BPMs';

  @override
  String get cacheAllBpms => 'Cache Tutti I Bpm';

  @override
  String get clearBpmCache => 'Cancella Cache BPM';

  @override
  String get bpmCacheCleared => 'Cache BPM cancellata';

  @override
  String downloadedStats(int count, String size) {
    return '$count canzoni • $size';
  }

  @override
  String get sectionInformation => 'INFORMAZIONI';

  @override
  String get sectionDeveloper => 'SVILUPPATORE';

  @override
  String get sectionLinks => 'LINKS';

  @override
  String get githubRepo => 'Repository GitHub';

  @override
  String get playingFrom => 'IN RIPRODUZIONE DA';

  @override
  String get live => 'IN DIRETTA';

  @override
  String get streamingLive => 'Streaming In Diretta';

  @override
  String get stopRadio => 'Ferma La Radio';

  @override
  String get removeFromLiked => 'Rimuovi dai brani aggiunti ai preferiti';

  @override
  String get addToLiked => 'Aggiungi alle canzoni preferite';

  @override
  String get playNext => 'Riproduci Successivo';

  @override
  String get addToQueue => 'Aggiungi alla coda';

  @override
  String get goToAlbum => 'Vai all\'album';

  @override
  String get goToArtist => 'Vai all\'artista';

  @override
  String get rateSong => 'Vota Brano';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Valuta Canzone ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Valutazione rimossa';

  @override
  String rated(int rating, String stars) {
    return 'Votato $rating $stars';
  }

  @override
  String get removeRating => 'Rimuovi Voto';

  @override
  String get downloaded => 'Scaricato';

  @override
  String downloading(int percent) {
    return 'Scaricamento... $percent%';
  }

  @override
  String get removeDownload => 'Rimuovi download';

  @override
  String get removeDownloadConfirm =>
      'Rimuovere questa canzone dalla memoria offline?';

  @override
  String get downloadRemoved => 'Download rimosso';

  @override
  String downloadedTitle(String title) {
    return 'Scaricato \"$title\"';
  }

  @override
  String get downloadFailed => 'Download fallito';

  @override
  String downloadError(Object error) {
    return 'Errore di download: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Aggiunto \"$title\" alla $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Errore nell\'aggiungere alla playlist: $error';
  }

  @override
  String get noPlaylists => 'Nessuna playlist disponibile';

  @override
  String get createNewPlaylist => 'Crea Nuova Playlist';

  @override
  String artistNotFound(String name) {
    return 'Artista \"$name\" non trovato';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Errore cercando l\'artista: $error';
  }

  @override
  String get selectArtist => 'Seleziona artista';

  @override
  String get removedFromFavorites => 'Rimosso dai preferiti';

  @override
  String get addedToFavorites => 'Aggiunto ai preferiti';

  @override
  String get star => 'stella';

  @override
  String get stars => 'stelle';

  @override
  String get albumNotFound => 'Album non trovato';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours HR $minutes MIN';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get topSongs => 'Canzoni più ascoltate';

  @override
  String get connected => 'Collegato';

  @override
  String get noSongPlaying => 'Nessuna brano in riproduzione';

  @override
  String get internetRadioUppercase => 'RADIO INTERNET';

  @override
  String get playingNext => 'Riproduzione Successiva';

  @override
  String get createPlaylistTitle => 'Crea playlist';

  @override
  String get playlistNameHint => 'Nome playlist';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Playlist creata \"$name\" con questa canzone';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Errore nel caricare le playlist: $error';
  }

  @override
  String get playlistNotFound => 'Playlist non trovata';

  @override
  String get noSongsInPlaylist => 'Nessun brano in questa playlist';

  @override
  String get noFavoriteSongsYet => 'Ancora nessuna canzone preferita';

  @override
  String get noFavoriteAlbumsYet => 'Ancora nessun album preferito';

  @override
  String get listeningHistory => 'Cronologia Ascolti';

  @override
  String get noListeningHistory => 'Nessuna Cronologia Di Ascolto';

  @override
  String get songsWillAppearHere => 'Le canzoni che riproduci appariranno qui';

  @override
  String get sortByTitleAZ => 'Titolo (A-Z)';

  @override
  String get sortByTitleZA => 'Titolo (Z-A)';

  @override
  String get sortByArtistAZ => 'Artista (A-Z)';

  @override
  String get sortByArtistZA => 'Artista (Z-A)';

  @override
  String get sortByAlbumAZ => 'Album (A-Z)';

  @override
  String get sortByAlbumZA => 'Album (Z-A)';

  @override
  String get recentlyAdded => 'Aggiunto di Recente';

  @override
  String get noSongsFound => 'Nessuna canzone trovata';

  @override
  String get noAlbumsFound => 'Nessun album trovato';

  @override
  String get noHomepageUrl => 'Nessun URL di homepage disponibile';

  @override
  String get playStation => 'Play Station';

  @override
  String get openHomepage => 'Apri Homepage';

  @override
  String get copyStreamUrl => 'Copia URL streaming';

  @override
  String get failedToLoadRadioStations =>
      'Impossibile caricare le stazioni radio';

  @override
  String get noRadioStations => 'Nessuna Stazione Radio';

  @override
  String get noRadioStationsHint =>
      'Aggiungi stazioni radio nelle impostazioni del tuo server Navidrome per vederle qui.';

  @override
  String get connectToServerSubtitle => 'Connettiti al tuo server Subsonic';

  @override
  String get pleaseEnterServerUrl => 'Inserisci l\'URL del server';

  @override
  String get invalidUrlFormat => 'L\'URL deve iniziare con http:// o https://';

  @override
  String get pleaseEnterUsername => 'Inserisci il nome utente';

  @override
  String get pleaseEnterPassword => 'Inserisci la password';

  @override
  String get legacyAuthentication => 'Autenticazione Legacy';

  @override
  String get legacyAuthSubtitle => 'Usa per vecchi server Subsonic';

  @override
  String get allowSelfSignedCerts => 'Consenti Certificati Auto-Firmati';

  @override
  String get allowSelfSignedSubtitle =>
      'Per server con certificati TLS/SSL personalizzati';

  @override
  String get advancedOptions => 'Opzioni Avanzate';

  @override
  String get customTlsCertificate => 'Certificato TLS/Ssl Personalizzato';

  @override
  String get customCertificateSubtitle =>
      'Carica un certificato personalizzato per server con CA non standard';

  @override
  String get selectCertificateFile => 'Seleziona il file del certificato';

  @override
  String get clientCertificate => 'Certificato Client (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Autenticare questo client utilizzando un certificato (richiede un server abilitato per mTLS)';

  @override
  String get selectClientCertificate => 'Seleziona Certificato Client';

  @override
  String get clientCertPassword => 'Password del certificato (opzionale)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Impossibile selezionare il certificato: $error';
  }

  @override
  String get connect => 'Connetti';

  @override
  String get or => 'O';

  @override
  String get useLocalFiles => 'Usa File Locali';

  @override
  String get startingScan => 'Avvio scansione...';

  @override
  String get storagePermissionRequired =>
      'È richiesta l\'autorizzazione di archiviazione per eseguire la scansione dei file locali';

  @override
  String get noMusicFilesFound =>
      'Nessun file musicale trovato sul tuo dispositivo';

  @override
  String get remove => 'Rimuovi';

  @override
  String failedToSetRating(Object error) {
    return 'Impossibile impostare la valutazione: $error';
  }

  @override
  String get home => 'Home';

  @override
  String get playlistsSection => 'PLAYLISTS';

  @override
  String get collapse => 'Comprimi';

  @override
  String get expand => 'Espandi';

  @override
  String get createPlaylist => 'Crea playlist';

  @override
  String get likedSongsSidebar => 'Brani piaciuti';

  @override
  String playlistSongsCount(int count) {
    return '';
  }

  @override
  String get failedToLoadLyrics => 'Impossibile caricare i testi';

  @override
  String get lyricsNotFoundSubtitle =>
      'Impossibile trovare il testo di questa canzone';

  @override
  String get backToCurrent => 'Torna al corrente';

  @override
  String get exitFullscreen => 'Esci da schermo intero';

  @override
  String get fullscreen => 'Schermo Intero';

  @override
  String get noLyrics => 'Nessun testo';

  @override
  String get internetRadioMiniPlayer => 'Radio Internet';

  @override
  String get liveBadge => 'IN DIRETTA';

  @override
  String get localFilesModeBanner => 'Modalità File Locali';

  @override
  String get offlineModeBanner =>
      'Modalità offline – Solo riproduzione di musica scaricata';

  @override
  String get updateAvailable => 'Aggiornamento disponibile';

  @override
  String get updateAvailableSubtitle =>
      'Una nuova versione di Musly è disponibile!';

  @override
  String updateCurrentVersion(String version) {
    return 'Attuale: v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Ultima: v$version';
  }

  @override
  String get whatsNew => 'Cosa c\'è di nuovo';

  @override
  String get downloadUpdate => 'Scarica';

  @override
  String get remindLater => 'Dopo';

  @override
  String get seeAll => 'Vedi tutti';

  @override
  String get artistDataNotFound => 'Artista non trovato';

  @override
  String get addedArtistToQueue => 'Added artist to Queue';

  @override
  String get addedArtistToQueueError => 'Failed adding artist to Queue';

  @override
  String get casting => 'In trasmissione';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Cast / DLNA (Beta)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get searchingDevices => 'Ricerca di dispositivi in corso';

  @override
  String get castWifiHint =>
      'Assicurati che il tuo dispositivo Cast / DLNA\nsia sulla stessa rete Wi-Fi';

  @override
  String connectedToDevice(String name) {
    return 'Connesso a $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Impossibile connettersi a $name';
  }

  @override
  String get removedFromLikedSongs => 'Rimosso da brani che ti piacciono';

  @override
  String get addedToLikedSongs => 'Aggiunto a brani che ti piacciono';

  @override
  String get enableShuffle => 'Attiva la riproduzione casuale';

  @override
  String get enableRepeat => 'Abilita ripetizione';

  @override
  String get connecting => 'In connessione';

  @override
  String get closeLyrics => 'Chiudi Testi';

  @override
  String errorStartingDownload(Object error) {
    return 'Errore nell\'avvio del download: $error';
  }

  @override
  String get errorLoadingGenres => 'Errore nel caricamento dei generi';

  @override
  String get noGenresFound => 'Nessun genere trovato';

  @override
  String get noAlbumsInGenre => 'Nessun album in questo genere';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount canzoni • $albumCount album';
  }

  @override
  String get sectionJukebox => 'MODALITÀ JUKEBOX';

  @override
  String get jukeboxMode => 'Modalità Jukebox';

  @override
  String get jukeboxModeSubtitle =>
      'Riproduci l\'audio tramite il server invece di questo dispositivo';

  @override
  String get openJukeboxController => 'Apri Controller Jukebox';

  @override
  String get jukeboxClearQueue => 'Cancella la coda';

  @override
  String get jukeboxShuffleQueue => 'Mescola la coda';

  @override
  String get jukeboxQueueEmpty => 'Nessuna canzone in coda';

  @override
  String get jukeboxNowPlaying => 'Riproduzione in corso';

  @override
  String get jukeboxQueue => 'Coda';

  @override
  String get jukeboxVolume => 'Volume';

  @override
  String get playOnJukebox => 'Riproduci su Jukebox';

  @override
  String get addToJukeboxQueue => 'Aggiungi alla coda di Jukebox';

  @override
  String get jukeboxNotSupported =>
      'La modalità Jukebox non è supportata da questo server. Abilitarla nella configurazione del server (ad es. EnableJukebox = true in Navidrome).';

  @override
  String get musicFoldersDialogTitle => 'Seleziona Cartelle Musicali';

  @override
  String get musicFoldersHint =>
      'Lascia tutto abilitato per usare tutte le cartelle (predefinito).';

  @override
  String get musicFoldersSaved => 'Selezione di cartelle musicali salvata';

  @override
  String get artworkStyleSection => 'Stile Grafica';

  @override
  String get artworkCornerRadius => 'Raggio Angoli';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Regola come appaiono gli angoli delle copertine degli album';

  @override
  String get artworkCornerRadiusNone => 'Nessuno';

  @override
  String get artworkShape => 'Forma';

  @override
  String get artworkShapeRounded => 'Arrotondato';

  @override
  String get artworkShapeCircle => 'Cerchio';

  @override
  String get artworkShapeSquare => 'Quadrato';

  @override
  String get artworkShadow => 'Ombra';

  @override
  String get artworkShadowNone => 'Nessuno';

  @override
  String get artworkShadowSoft => 'Soft';

  @override
  String get artworkShadowMedium => 'Medio';

  @override
  String get artworkShadowStrong => 'Strong';

  @override
  String get artworkShadowColor => 'Colore ombreggiatura';

  @override
  String get artworkShadowColorBlack => 'Nero';

  @override
  String get artworkShadowColorAccent => 'Accento';

  @override
  String get artworkPreview => 'Anteprima';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '${value}px';
  }

  @override
  String get noArtwork => 'Nessuna copertina';

  @override
  String get serverUnreachableTitle => 'Impossibile raggiungere il server';

  @override
  String get serverUnreachableSubtitle =>
      'Controllare la connessione o le impostazioni del server.';

  @override
  String get openOfflineMode => 'Apri in modalità offline';

  @override
  String get appearanceSection => 'Aspetto';

  @override
  String get themeLabel => 'Tema';

  @override
  String get accentColorLabel => 'Tema colore';

  @override
  String get circularDesignLabel => 'Design Circolare';

  @override
  String get circularDesignSubtitle =>
      'UI galleggiante e arrotondata con pannelli traslucidi ed effetto sfocatura di vetro sul lettore e sulla barra di navigazione.';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Chiaro';

  @override
  String get themeModeDark => 'Scuro';

  @override
  String get liveLabel => 'LIVE';

  @override
  String get discordStatusText => 'Stato di Discord';

  @override
  String get discordStatusTextSubtitle =>
      'Seconda riga mostrata nell\'attività di Discord';

  @override
  String get discordRpcStyleArtist => 'Nome artista';

  @override
  String get discordRpcStyleSong => 'Titolo del brano';

  @override
  String get discordRpcStyleApp => 'Nome app (Musly)';

  @override
  String get sectionVolumeNormalization =>
      'NORMALIZZAZIONE VOLUME (REPLAYGAIN)';

  @override
  String get replayGainModeOff => 'Off';

  @override
  String get replayGainModeTrack => 'Traccia';

  @override
  String get replayGainModeAlbum => 'Album';

  @override
  String replayGainPreamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get replayGainPreventClipping => 'Previeni Il Clipping';

  @override
  String replayGainFallbackGain(String value) {
    return 'Guadagno Fallback: $value dB';
  }

  @override
  String autoDjSongsToAdd(int count) {
    return 'Brani da aggiungere: $count';
  }

  @override
  String get transcodingEnable => 'Abilita La Transcodifica';

  @override
  String get transcodingEnableSubtitle =>
      'Riduce l\'utilizzo dei dati con qualità inferiore';

  @override
  String get smartTranscoding => 'Trascodifica Intelligente';

  @override
  String get smartTranscodingSubtitle =>
      'Regola automaticamente la qualità in base alla tua connessione (WiFi vs dati mobili)';

  @override
  String get smartTranscodingDetectedNetwork => 'Rete rilevata: ';

  @override
  String smartTranscodingActiveBitrate(String bitrate) {
    return 'Bitrate attivo $bitrate';
  }

  @override
  String get transcodingWifiQuality => 'Qualità WiFi';

  @override
  String get transcodingWifiQualitySubtitleSmart =>
      'Usato automaticamente su WiFi';

  @override
  String get transcodingWifiQualitySubtitle => 'Bitrate quando su WiFi';

  @override
  String get transcodingMobileQuality => 'Qualità Mobile';

  @override
  String get transcodingMobileQualitySubtitleSmart =>
      'Utilizzato automaticamente su dati cellulari';

  @override
  String get transcodingMobileQualitySubtitle =>
      'Bitrate quando su dati mobili';

  @override
  String get transcodingFormat => 'Formato';

  @override
  String get transcodingFormatSubtitle =>
      'Codec audio utilizzato per lo streaming';

  @override
  String get transcodingBitrateOriginal => 'Originale (Nessuna Transcodifica)';

  @override
  String get transcodingFormatOriginal => 'Originale';

  @override
  String get imageCacheTitle => 'Cache immagini';

  @override
  String get imageCacheSubtitle => 'Salva localmente le copertine degli album';

  @override
  String get musicCacheTitle => 'Cache Della Musica';

  @override
  String get musicCacheSubtitle => 'Salva i metadati del brano localmente';

  @override
  String get bpmCacheTitle => 'Cache BPM';

  @override
  String get bpmCacheSubtitle => 'Salva analisi BPM localmente';

  @override
  String get sectionAboutInformation => 'INFORMAZIONI';

  @override
  String get sectionAboutDeveloper => 'SVILUPPATORE';

  @override
  String get sectionAboutLinks => 'LINKS';

  @override
  String get aboutVersion => 'Versione';

  @override
  String get aboutPlatform => 'Piattaforma';

  @override
  String get aboutMadeBy => 'Realizzato da dddevid';

  @override
  String get aboutGitHub => 'github.com/ddddevid';

  @override
  String get aboutLinkGitHub => 'Repository GitHub';

  @override
  String get aboutLinkChangelog => 'Changelog';

  @override
  String get aboutLinkReportIssue => 'Segnala un problema';

  @override
  String get aboutLinkDiscord => 'Unisciti Alla Community Di Discord';

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
  String get supportGreeting => 'Ciao! 👋';

  @override
  String get supportParagraph1 =>
      'Sono Devid, lo sviluppatore di Musly. Ho creato questa app perché amo la musica e credo che tutti meritino un lettore musicale bellissimo e gratuito.';

  @override
  String get supportParagraph2 =>
      'Musly è completamente gratuito e open-source. Nessuna pubblicità, nessun abbonamento. Ci lavoro nel tempo libero perché mi piace davvero creare qualcosa di utile per persone come te.';

  @override
  String get supportParagraph3 =>
      'Ma server, strumenti di sviluppo e caffè non sono gratis 😅 Se Musly è diventato parte della tua giornata e vuoi dire \"grazie\", una piccola donazione significherebbe tantissimo per me. Aiuta a coprire i costi e mi motiva ad aggiungere nuove funzionalità.';

  @override
  String get supportParagraph4 =>
      'Ma nessuna pressione - il fatto che ti piaccia l\'app è già la migliore ricompensa! 💙';

  @override
  String get supportDonationTitle => 'Supporta con una Donazione';

  @override
  String get supportDonationSubtitle => 'via Revolut - qualsiasi cifra aiuta!';

  @override
  String get supportDiscordTitle => 'Unisciti al nostro Discord';

  @override
  String get supportDiscordSubtitle =>
      'Ottieni aiuto, suggerisci funzionalità o chiacchiera';

  @override
  String get supportWaysTitle => 'Altri modi per supportare';

  @override
  String get supportWayRate => 'Lascia una recensione sull\'app store';

  @override
  String get supportWayShare => 'Parla di Musly ai tuoi amici';

  @override
  String get supportWayBugs => 'Segnala bug o suggerisci funzionalità';

  @override
  String get supportWayEnjoy => 'Semplicemente goditi la musica! 🎵';

  @override
  String get supportMadeWithLove => 'Fatto con 💙 in Italia';

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
}
