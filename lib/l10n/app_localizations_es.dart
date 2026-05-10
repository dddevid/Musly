// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Musly';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodAfternoon => 'Buenas tardes';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String get forYou => 'Para Ti';

  @override
  String get quickPicks => 'Selecciones Rápidas';

  @override
  String get discoverMix => 'Descubrir Mix';

  @override
  String get recentlyPlayed => 'Reproducido Recientemente';

  @override
  String get yourPlaylists => 'Tus Listas';

  @override
  String get favoritePlaylists => 'Favorite Playlists';

  @override
  String get madeForYou => 'Hecho Para Ti';

  @override
  String get topRated => 'Mejor Valorado';

  @override
  String get noContentAvailable => 'No hay contenido disponible';

  @override
  String get tryRefreshing =>
      'Intenta recargar o verifica la conexión del servidor';

  @override
  String get refresh => 'Actualizar';

  @override
  String get errorLoadingSongs => 'Error al cargar las pistas';

  @override
  String get noSongsInGenre => 'No hay canciones en este género';

  @override
  String get errorLoadingAlbums => 'Error al cargar álbumes';

  @override
  String get noTopRatedAlbums => 'Sin álbumes mejor valorados';

  @override
  String get login => 'Inicio de sesión';

  @override
  String get serverUrl => 'URL de servidor';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get password => 'Contraseña';

  @override
  String get selectCertificate => 'Seleccione certificado TLS/SSL';

  @override
  String failedToSelectCertificate(String error) {
    return 'No se pudo seleccionar el certificado: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'La URL del servidor debe comenzar con http:// o https://';

  @override
  String get failedToConnect => 'Error al conectar';

  @override
  String get library => 'Biblioteca';

  @override
  String get search => 'Búsqueda';

  @override
  String get settings => 'Preferencias';

  @override
  String get albums => 'Álbumes';

  @override
  String get artists => 'Artistas';

  @override
  String get songs => 'Canciones';

  @override
  String get playlists => 'Listas';

  @override
  String get genres => 'Géneros';

  @override
  String get years => 'Years';

  @override
  String get favorites => 'Favoritos';

  @override
  String get nowPlaying => 'Reproduciendo';

  @override
  String get queue => 'Cola';

  @override
  String get lyrics => 'Letras';

  @override
  String get play => 'Reproducir';

  @override
  String get pause => 'Pausa';

  @override
  String get next => 'Siguiente';

  @override
  String get previous => 'Anterior';

  @override
  String get shuffle => 'Aleatorio';

  @override
  String get repeat => 'Repetir';

  @override
  String get repeatOne => 'Repetir Una';

  @override
  String get repeatOff => 'Repetición Desactivada';

  @override
  String get addToPlaylist => 'Añadir a lista';

  @override
  String get removeFromPlaylist => 'Eliminar de la Lista';

  @override
  String get addToFavorites => 'Añadir a favoritos';

  @override
  String get removeFromFavorites => 'Eliminar de favoritos';

  @override
  String get download => 'Descargar';

  @override
  String get delete => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'Aceptar';

  @override
  String get save => 'Guardar';

  @override
  String get close => 'Cerrar';

  @override
  String get general => 'General';

  @override
  String get appearance => 'Apariencia';

  @override
  String get playback => 'Reproducción';

  @override
  String get storage => 'Almacenamiento';

  @override
  String get about => 'Acerca de';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get version => 'Versión';

  @override
  String get madeBy => 'Hecho por dddevid';

  @override
  String get githubRepository => 'Repositorio de GitHub';

  @override
  String get reportIssue => 'Reportar problema';

  @override
  String get joinDiscord => 'Únete a la comunidad de Discord';

  @override
  String get unknownArtist => 'Artista desconocido';

  @override
  String get unknownAlbum => 'Álbum Desconocido';

  @override
  String get playAll => 'Reproducir todo';

  @override
  String get shuffleAll => 'Mezclar todo';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortByName => 'Nombre';

  @override
  String get sortByArtist => 'Artista';

  @override
  String get sortByAlbum => 'Álbum';

  @override
  String get sortByDate => 'Fecha';

  @override
  String get sortByDuration => 'Duración';

  @override
  String get ascending => 'Ascendente';

  @override
  String get descending => 'Descendente';

  @override
  String get noLyricsAvailable => 'No hay letra disponible';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Reintentar';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get searchHint => 'Buscar canciones, álbumes, artistas...';

  @override
  String get allSongs => 'Todas las Canciones';

  @override
  String get allAlbums => 'Todos los Álbumes';

  @override
  String get allArtists => 'Todos los Artistas';

  @override
  String trackNumber(int number) {
    return 'Pista $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
      zero: 'No hay canciones',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count álbumes',
      one: '1 álbum',
      zero: 'No hay álbumes',
    );
    return '$_temp0';
  }

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get confirmLogout => '¿Está seguro de que quiere cerrar sesión?';

  @override
  String get yes => 'Si';

  @override
  String get no => 'No';

  @override
  String get offlineMode => 'Modo Sin Conexión';

  @override
  String get radio => 'Radio';

  @override
  String get changelog => 'Historial de actualizaciones';

  @override
  String get platform => 'Plataforma';

  @override
  String get server => 'Servidor';

  @override
  String get display => 'Pantalla';

  @override
  String get playerInterface => 'Interfaz del reproductor';

  @override
  String get smartRecommendations => 'Recomendaciones Inteligentes';

  @override
  String get showVolumeSlider => 'Mostrar barra de volumen';

  @override
  String get showVolumeSliderSubtitle =>
      'Mostrar control de volumen en la pantalla de reproducción';

  @override
  String get showStarRatings => 'Mostrar valoraciones de estrellas';

  @override
  String get showStarRatingsSubtitle => 'Valorar canciones y ver valoraciones';

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
  String get enableRecommendations => 'Habilitar Recomendaciones';

  @override
  String get enableRecommendationsSubtitle =>
      'Obtener sugerencias musicales personalizadas';

  @override
  String get listeningData => 'Datos de Reproducción';

  @override
  String totalPlays(int count) {
    return '$count reproducciones totales';
  }

  @override
  String get clearListeningHistory => 'Borrar Historial de Reproducción';

  @override
  String get confirmClearHistory =>
      'Esto restablecerá todos sus datos de reproducción y recomendaciones. ¿Está seguro?';

  @override
  String get historyCleared => 'Historial de Reproducción borrado';

  @override
  String get discordStatus => 'Estado de Discord';

  @override
  String get discordStatusSubtitle =>
      'Mostrar reproducción de la canción en el perfil de Discord';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get systemDefault => 'Valores por defecto del sistema';

  @override
  String get communityTranslations => 'Traducciones por la comunidad';

  @override
  String get communityTranslationsSubtitle =>
      'Ayude a traducir Musly en Crowdin';

  @override
  String get yourLibrary => 'Tu Biblioteca';

  @override
  String get filterAll => 'Todo';

  @override
  String get faves => 'Faves';

  @override
  String get filterPlaylists => 'Listas';

  @override
  String get filterAlbums => 'Álbumes';

  @override
  String get filterArtists => 'Artistas';

  @override
  String get likedSongs => 'Canciones que te gustan';

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
  String get radioStations => 'Emisoras de radio';

  @override
  String get playlist => 'Lista';

  @override
  String get internetRadio => 'Radio de Internet';

  @override
  String get newPlaylist => 'Nueva Lista';

  @override
  String get playlistName => 'Nombre de la Lista';

  @override
  String get create => 'Crear';

  @override
  String get deletePlaylist => 'Eliminar Lista';

  @override
  String deletePlaylistConfirmation(String name) {
    return '¿Está seguro de que desea eliminar la lista \"$name\"?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Lista \"$name\" eliminada';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Error al crear la lista: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Error al eliminar la lista: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Lista \"$name\" creada';
  }

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchPlaceholder => 'Artistas, Canciones, Álbumes';

  @override
  String get tryDifferentSearch => 'Intenta una búsqueda diferente';

  @override
  String get noSuggestions => 'Sin sugerencias';

  @override
  String get browseCategories => 'Explorar Categorías';

  @override
  String get liveSearchSection => 'Búsqueda';

  @override
  String get liveSearch => 'Búsqueda en tiempo real';

  @override
  String get liveSearchSubtitle =>
      'Actualizar los resultados mientras escribes en lugar de mostrar un desplegable';

  @override
  String get categoryMadeForYou => 'Hecho para ti';

  @override
  String get categoryNewReleases => 'Estrenos';

  @override
  String get categoryTopRated => 'Mejor valorado';

  @override
  String get categoryGenres => 'Géneros';

  @override
  String get categoryFavorites => 'Favoritos';

  @override
  String get categoryRadio => 'Radio';

  @override
  String get settingsTitle => 'Preferencias';

  @override
  String get tabPlayback => 'Reproducción';

  @override
  String get tabStorage => 'Almacenamiento';

  @override
  String get tabServer => 'Servidor';

  @override
  String get tabDisplay => 'Pantalla';

  @override
  String get tabSupport => 'Support';

  @override
  String get tabAbout => 'Acerca de';

  @override
  String get sectionAutoDj => 'AUTO DJ';

  @override
  String get autoDjMode => 'Modo Auto DJ';

  @override
  String songsToAdd(int count) {
    return 'Canciones a añadir: $count';
  }

  @override
  String get sectionReplayGain => 'NORMALIZACIÓN DE VOLUMEN (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Modo';

  @override
  String preamp(String value) {
    return 'Preamplificador: $value dB';
  }

  @override
  String get preventClipping => 'Evitar recorte';

  @override
  String fallbackGain(String value) {
    return 'Ganancia de reserva: $value dB';
  }

  @override
  String get sectionStreamingQuality => 'CALIDAD DE TRANSMISIÓN';

  @override
  String get enableTranscoding => 'Habilitar Transcodificación';

  @override
  String get qualityWifi => 'Calidad WiFi';

  @override
  String get qualityMobile => 'Calidad Móvil';

  @override
  String get format => 'Formato';

  @override
  String get transcodingSubtitle => 'Reducir el uso de datos con menor calidad';

  @override
  String get modeOff => 'Desactivado';

  @override
  String get modeTrack => 'Pista';

  @override
  String get modeAlbum => 'Álbum';

  @override
  String get sectionServerConnection => 'CONEXÓN DEL SERVIDOR';

  @override
  String get serverType => 'Tipo de Servidor';

  @override
  String get notConnected => 'No conectado';

  @override
  String get unknown => 'Desconocido';

  @override
  String get sectionMusicFolders => 'CARPETAS DE MÚSICA';

  @override
  String get musicFolders => 'Carpeta de Música';

  @override
  String get noMusicFolders => 'No se encontraron carpetas de música';

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
  String get sectionAccount => 'CUENTA';

  @override
  String get logoutConfirmation =>
      '¿Seguro que quieres cerrar sesión? También se eliminarán todos los datos en caché.';

  @override
  String get sectionCacheSettings => 'AJUSTES DE CACHÉ';

  @override
  String get imageCache => 'Caché de Imágenes';

  @override
  String get musicCache => 'Caché de Música';

  @override
  String get bpmCache => 'Caché de BPM';

  @override
  String get saveAlbumCovers => 'Guardar carátulas de álbumes localmente';

  @override
  String get saveSongMetadata => 'Guardar metadatos de la canción localmente';

  @override
  String get saveBpmAnalysis => 'Guardar el análisis de BPM localmente';

  @override
  String get sectionCacheCleanup => 'LIMPIEZA DE CACHÉ';

  @override
  String get clearAllCache => 'Borrar toda la caché';

  @override
  String get allCacheCleared => 'Toda la caché borrada';

  @override
  String get sectionOfflineDownloads => 'DESCARGAS SIN CONEXIÓN';

  @override
  String get downloadedSongs => 'Canciones Descargadas';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Descargando Biblioteca... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Descargar toda la Biblioteca';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Esto descargará $count canciones en tu dispositivo. Esto puede tardar un rato y usar un espacio de almacenamiento significativo.\n\n¿Continuar?';
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
  String get libraryDownloadStarted => 'Descarga de la Biblioteca iniciada';

  @override
  String get deleteDownloads => 'Eliminar Todas las Descargas';

  @override
  String get downloadsDeleted => 'Todas las descargas eliminadas';

  @override
  String get noSongsAvailable =>
      'No hay canciones disponibles. Por favor, cargue su biblioteca primero.';

  @override
  String get sectionBpmAnalysis => 'ANÁLISIS BPM';

  @override
  String get cachedBpms => 'BPM en caché';

  @override
  String get cacheAllBpms => 'Guardar todos los BPM en caché';

  @override
  String get clearBpmCache => 'Limpiar caché de BPM';

  @override
  String get bpmCacheCleared => 'Caché de BPM limpiada';

  @override
  String downloadedStats(int count, String size) {
    return '$count canciones · $size';
  }

  @override
  String get sectionInformation => 'INFORMACIÓN';

  @override
  String get sectionDeveloper => 'DESARROLLADOR';

  @override
  String get sectionLinks => 'ENLACES';

  @override
  String get githubRepo => 'Repositorio de GitHub';

  @override
  String get playingFrom => 'REPRODUCIENDO DESDE';

  @override
  String get live => 'EN DIRECTO';

  @override
  String get streamingLive => 'Transmisión en directo';

  @override
  String get stopRadio => 'Parar Radio';

  @override
  String get removeFromLiked => 'Eliminar de Canciones que te gustan';

  @override
  String get addToLiked => 'Añadir a Canciones que te gustan';

  @override
  String get playNext => 'Reproducir a continuación';

  @override
  String get addToQueue => 'Añadir a la Cola';

  @override
  String get goToAlbum => 'Ir al Álbum';

  @override
  String get goToArtist => 'Ir al artista';

  @override
  String get rateSong => 'Puntuar canción';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Puntuar Canción ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Valoración eliminada';

  @override
  String rated(int rating, String stars) {
    return 'Valorado con $rating $stars';
  }

  @override
  String get removeRating => 'Eliminar Puntuación';

  @override
  String get downloaded => 'Descargado';

  @override
  String downloading(int percent) {
    return 'Descargando... $percent%';
  }

  @override
  String get removeDownload => 'Eliminar la descarga';

  @override
  String get removeDownloadConfirm =>
      '¿Eliminar esta canción del almacenamiento sin conexión?';

  @override
  String get downloadRemoved => 'Descarga eliminada';

  @override
  String downloadedTitle(String title) {
    return 'Descargado \"$title\"';
  }

  @override
  String get downloadFailed => 'Descarga fallida';

  @override
  String downloadError(Object error) {
    return 'Error de descarga: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Añadido \"$title\" a $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Error al añadir a la lista: $error';
  }

  @override
  String get noPlaylists => 'No hay listas disponibles';

  @override
  String get createNewPlaylist => 'Crear Nueva Lista';

  @override
  String artistNotFound(String name) {
    return 'Artista \"$name\" no encontrado';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Error al buscar el artista: $error';
  }

  @override
  String get selectArtist => 'Seleccionar artista';

  @override
  String get removedFromFavorites => 'Eliminado de favoritos';

  @override
  String get addedToFavorites => 'Añadido a favoritos';

  @override
  String get star => 'estrella';

  @override
  String get stars => 'estrellas';

  @override
  String get albumNotFound => 'Álbum no encontrado.';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours H $minutes MIN';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get topSongs => 'Canciones Destacadas';

  @override
  String get connected => 'Conectado';

  @override
  String get noSongPlaying => 'No se está reproduciendo ninguna canción';

  @override
  String get internetRadioUppercase => 'RADIO DE INTERNET';

  @override
  String get playingNext => 'Reproducir siguiente';

  @override
  String get createPlaylistTitle => 'Crear Lista';

  @override
  String get playlistNameHint => 'Nombre de la Lista';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Lista creada \"$name\" con esta canción';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Error al cargar lista: $error';
  }

  @override
  String get playlistNotFound => 'Lista no encontrada';

  @override
  String get noSongsInPlaylist => 'No hay canciones en esta lista';

  @override
  String get noFavoriteSongsYet => 'Aún no hay canciones favoritas';

  @override
  String get noFavoriteAlbumsYet => 'Aún no hay álbumes favoritos';

  @override
  String get listeningHistory => 'Historial de Reproducción';

  @override
  String get noListeningHistory => 'Sin Historial de Reproducción';

  @override
  String get songsWillAppearHere =>
      'Las canciones que reproduzcas aparecerán aquí';

  @override
  String get sortByTitleAZ => 'Título (A-Z)';

  @override
  String get sortByTitleZA => 'Título (Z-A)';

  @override
  String get sortByArtistAZ => 'Artista (A-Z)';

  @override
  String get sortByArtistZA => 'Artista (Z-A)';

  @override
  String get sortByAlbumAZ => 'Álbum (A-Z)';

  @override
  String get sortByAlbumZA => 'Álbum (Z-A)';

  @override
  String get recentlyAdded => 'Añadido recientemente';

  @override
  String get noSongsFound => 'No se han encontrado canciones';

  @override
  String get noAlbumsFound => 'No se encontraron álbumes';

  @override
  String get noHomepageUrl => 'No hay URL de página de inicio disponible';

  @override
  String get playStation => 'Reproducir la Emisora';

  @override
  String get openHomepage => 'Abrir página de Inicio';

  @override
  String get copyStreamUrl => 'Copiar URL de la Transmisión';

  @override
  String get failedToLoadRadioStations =>
      'Error al cargar las emisoras de radio';

  @override
  String get noRadioStations => 'Sin Emisoras de Radio';

  @override
  String get noRadioStationsHint =>
      'Añade emisoras de radio en la configuración de tu servidor Navidrome para verlas aquí.';

  @override
  String get connectToServerSubtitle => 'Conectar a tu servidor de Subsonic';

  @override
  String get pleaseEnterServerUrl =>
      'Por favor, introduzca la URL del servidor';

  @override
  String get invalidUrlFormat =>
      'La dirección URL debe comenzar con http:// o https://';

  @override
  String get pleaseEnterUsername => 'Por favor, introduzca nombre de usuario';

  @override
  String get pleaseEnterPassword => 'Por favor, introduzca contraseña';

  @override
  String get legacyAuthentication => 'Autenticación heredada';

  @override
  String get legacyAuthSubtitle => 'Usar para servidores Subsonic antiguos';

  @override
  String get allowSelfSignedCerts => 'Permitir certificados autofirmados';

  @override
  String get allowSelfSignedSubtitle =>
      'Para servidores con certificados TLS/SSL personalizados';

  @override
  String get advancedOptions => 'Opciones Avanzadas';

  @override
  String get customTlsCertificate => 'Certificado TLS/SSL personalizado';

  @override
  String get customCertificateSubtitle =>
      'Subir un certificado personalizado para servidores con CA no estándar';

  @override
  String get selectCertificateFile => 'Seleccionar archivo de certificado';

  @override
  String get clientCertificate => 'Certificado de Cliente (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Autenticar este cliente usando un certificado (requiere un servidor con mTLS)';

  @override
  String get selectClientCertificate => 'Seleccionar Certificado de Cliente';

  @override
  String get clientCertPassword => 'Certificar contraseña (opcional)';

  @override
  String failedToSelectClientCert(String error) {
    return 'No se pudo seleccionar el certificado del cliente: $error';
  }

  @override
  String get connect => 'Conectar';

  @override
  String get or => 'O';

  @override
  String get useLocalFiles => 'Usar Archivos Locales';

  @override
  String get startingScan => 'Iniciando escaneo...';

  @override
  String get storagePermissionRequired =>
      'Permiso de almacenamiento necesario para escanear archivos locales';

  @override
  String get noMusicFilesFound =>
      'No se han encontrado archivos de música en tu dispositivo';

  @override
  String get remove => 'Eliminar';

  @override
  String failedToSetRating(Object error) {
    return 'Error al establecer la valoración: $error';
  }

  @override
  String get home => 'Inicio';

  @override
  String get playlistsSection => 'LISTAS';

  @override
  String get collapse => 'Contraer';

  @override
  String get expand => 'Expandir';

  @override
  String get createPlaylist => 'Crear Lista';

  @override
  String get likedSongsSidebar => 'Canciones que te gustan';

  @override
  String playlistSongsCount(int count) {
    return 'Lista • $count canciones';
  }

  @override
  String get failedToLoadLyrics => 'No se pudo cargar la letra';

  @override
  String get lyricsNotFoundSubtitle =>
      'No se pudo encontrar la letra de esta canción';

  @override
  String get backToCurrent => 'Volver a la actual';

  @override
  String get exitFullscreen => 'Salir de pantalla completa';

  @override
  String get fullscreen => 'Pantalla Completa';

  @override
  String get noLyrics => 'Sin letra';

  @override
  String get internetRadioMiniPlayer => 'Radio de Internet';

  @override
  String get liveBadge => 'EN DIRECTO';

  @override
  String get localFilesModeBanner => 'Modo archivos locales';

  @override
  String get offlineModeBanner =>
      'Modo sin conexión - Reproduciendo solo música descargada';

  @override
  String get updateAvailable => 'Actualización Disponible';

  @override
  String get updateAvailableSubtitle =>
      '¡Una nueva versión de Musly está disponible!';

  @override
  String updateCurrentVersion(String version) {
    return 'Versión actual: $version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Última versión: $version';
  }

  @override
  String get whatsNew => 'Novedades';

  @override
  String get downloadUpdate => 'Descargar';

  @override
  String get remindLater => 'Más tarde';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get artistDataNotFound => 'Artista no encontrado';

  @override
  String get addedArtistToQueue => 'Artista añadido a la cola';

  @override
  String get addedArtistToQueueError => 'Error al añadir artista a la cola';

  @override
  String get casting => 'Casting';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Casting / DL';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get searchingDevices => 'Buscando dispositivos';

  @override
  String get castWifiHint =>
      'Asegúrate de que tu dispositivo Cast / DLNA\nesté en la misma red Wi-Fi';

  @override
  String connectedToDevice(String name) {
    return 'Conectado a \$$name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'No se pudo conectar a $name';
  }

  @override
  String get removedFromLikedSongs => 'Eliminado de Canciones que te gustan';

  @override
  String get addedToLikedSongs => 'Añadido a Canciones que te gustan';

  @override
  String get enableShuffle => 'Activar aleatorio';

  @override
  String get enableRepeat => 'Activar repetición';

  @override
  String get connecting => 'Conectando';

  @override
  String get closeLyrics => 'Cerrar Letra';

  @override
  String errorStartingDownload(Object error) {
    return 'Error al iniciar la descarga: $error';
  }

  @override
  String get errorLoadingGenres => 'Error al cargar géneros';

  @override
  String get noGenresFound => 'No se encontraron géneros';

  @override
  String get noAlbumsInGenre => 'No hay álbumes en este género';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount canciones • $albumCount  ábumes';
  }

  @override
  String get sectionJukebox => 'MODO TOCADISCOS';

  @override
  String get jukeboxMode => 'Modo tocadiscos';

  @override
  String get jukeboxModeSubtitle =>
      'Reproducir audio a través del servidor en lugar de este dispositivo';

  @override
  String get openJukeboxController => 'Abrir Controlador de Tocadiscos';

  @override
  String get jukeboxClearQueue => 'Limpiar cola';

  @override
  String get jukeboxShuffleQueue => 'Mezclar cola';

  @override
  String get jukeboxQueueEmpty => 'No hay canciones en cola';

  @override
  String get jukeboxNowPlaying => 'Reproduciendo';

  @override
  String get jukeboxQueue => 'Cola';

  @override
  String get jukeboxVolume => 'Volumen';

  @override
  String get playOnJukebox => 'Reproducir en Jukebox';

  @override
  String get addToJukeboxQueue => 'Añadir a la cola de Tocadiscos';

  @override
  String get jukeboxNotSupported =>
      'El modo Jukebox no es compatible con este servidor. Actívalo en la configuración del servidor (p. ej. EnableJukebox = true en Navidrome).';

  @override
  String get musicFoldersDialogTitle => 'Seleccionar Carpetas de Música';

  @override
  String get musicFoldersHint =>
      'Deja todo activado para usar todas las carpetas (predeterminado).';

  @override
  String get musicFoldersSaved => 'Selección de carpeta de música guardada';

  @override
  String get artworkStyleSection => 'Estilo de Carátula';

  @override
  String get artworkCornerRadius => 'Radio de Esquinas';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Ajusta cómo aparecen las esquinas de las portadas del álbum';

  @override
  String get artworkCornerRadiusNone => 'Ninguna';

  @override
  String get artworkShape => 'Forma';

  @override
  String get artworkShapeRounded => 'Redondeado';

  @override
  String get artworkShapeCircle => 'Círculo';

  @override
  String get artworkShapeSquare => 'Cuadrado';

  @override
  String get artworkShadow => 'Sombra';

  @override
  String get artworkShadowNone => 'Ninguna';

  @override
  String get artworkShadowSoft => 'Suave';

  @override
  String get artworkShadowMedium => 'Medio';

  @override
  String get artworkShadowStrong => 'Fuerte';

  @override
  String get artworkShadowColor => 'Color de la sombra';

  @override
  String get artworkShadowColorBlack => 'Negra';

  @override
  String get artworkShadowColorAccent => 'Acento';

  @override
  String get artworkPreview => 'Vista previa';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '${value}px';
  }

  @override
  String get noArtwork => 'Sin carátula';

  @override
  String get serverUnreachableTitle => 'No se puede acceder al servidor';

  @override
  String get serverUnreachableSubtitle =>
      'Compruebe su conexión o configuración del servidor.';

  @override
  String get openOfflineMode => 'Abrir en modo sin conexión';

  @override
  String get appearanceSection => 'Apariencia';

  @override
  String get themeLabel => 'Tema';

  @override
  String get accentColorLabel => 'Color acentuado';

  @override
  String get circularDesignLabel => 'Diseño circular';

  @override
  String get circularDesignSubtitle =>
      'Interfaz flotante y redondeada con paneles translúcidos y efecto desenfoque de cristal en el reproductor y la barra de navegación.';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get liveLabel => 'EN DIRECTO';

  @override
  String get discordStatusText => 'Texto de estado de Discord';

  @override
  String get discordStatusTextSubtitle =>
      'Segunda línea mostrada en la actividad de Discord';

  @override
  String get discordRpcStyleArtist => 'Nombre del artista';

  @override
  String get discordRpcStyleSong => 'Título de canción';

  @override
  String get discordRpcStyleApp => 'Nombre de la aplicación (Musly)';

  @override
  String get sectionVolumeNormalization =>
      'NORMALIZACIÓN DE VOLUMEN (REPLAYGAIN)';

  @override
  String get replayGainModeOff => 'Desactivado';

  @override
  String get replayGainModeTrack => 'Pista';

  @override
  String get replayGainModeAlbum => 'Álbum';

  @override
  String replayGainPreamp(String value) {
    return 'Preamplificador: $value dB';
  }

  @override
  String get replayGainPreventClipping => 'Evitar recorte';

  @override
  String replayGainFallbackGain(String value) {
    return 'Ganancia de reserva: $value dB';
  }

  @override
  String autoDjSongsToAdd(int count) {
    return 'Canciones a añadir: $count';
  }

  @override
  String get transcodingEnable => 'Habilitar Transcodificación';

  @override
  String get transcodingEnableSubtitle =>
      'Reducir el uso de datos con menor calidad';

  @override
  String get smartTranscoding => 'Transcodificación Inteligente';

  @override
  String get smartTranscodingSubtitle =>
      'Ajusta automáticamente la calidad en función de tu conexión (WiFi vs datos móviles)';

  @override
  String get smartTranscodingDetectedNetwork => 'Red detectada: ';

  @override
  String smartTranscodingActiveBitrate(String bitrate) {
    return 'Tasa de bits activa: $bitrate';
  }

  @override
  String get transcodingWifiQuality => 'Calidad WiFi';

  @override
  String get transcodingWifiQualitySubtitleSmart =>
      'Utilizado automáticamente con WiFi';

  @override
  String get transcodingWifiQualitySubtitle => 'Tasa de bits al usar WiFi';

  @override
  String get transcodingMobileQuality => 'Calidad Móvil';

  @override
  String get transcodingMobileQualitySubtitleSmart =>
      'Utilizado automáticamente en datos móviles';

  @override
  String get transcodingMobileQualitySubtitle =>
      'Tasa de bits al usar datos móviles';

  @override
  String get transcodingFormat => 'Formato';

  @override
  String get transcodingFormatSubtitle =>
      'Códec de audio usado para la transmisión';

  @override
  String get transcodingBitrateOriginal => 'Original (Sin Transcodificación)';

  @override
  String get transcodingFormatOriginal => 'Original';

  @override
  String get imageCacheTitle => 'Caché de imagen';

  @override
  String get imageCacheSubtitle => 'Guardar carátulas de álbumes localmente';

  @override
  String get musicCacheTitle => 'Caché de Música';

  @override
  String get musicCacheSubtitle => 'Guardar metadatos de la canción localmente';

  @override
  String get bpmCacheTitle => 'Caché de BPM';

  @override
  String get bpmCacheSubtitle => 'Guardar el análisis de BPM localmente';

  @override
  String get sectionAboutInformation => 'INFORMACIÓN';

  @override
  String get sectionAboutDeveloper => 'DESARROLLADOR';

  @override
  String get sectionAboutLinks => 'ENLACES';

  @override
  String get aboutVersion => 'Versión';

  @override
  String get aboutPlatform => 'Plataforma';

  @override
  String get aboutMadeBy => 'Hecho por dddevid';

  @override
  String get aboutGitHub => 'github.com/dddevid';

  @override
  String get aboutLinkGitHub => 'Repositorio de GitHub';

  @override
  String get aboutLinkChangelog => 'Historial de actualizaciones';

  @override
  String get aboutLinkReportIssue => 'Reportar problema';

  @override
  String get aboutLinkDiscord => 'Únete a la comunidad de Discord';

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

  @override
  String get themeSaved => 'Theme saved';

  @override
  String get themeUnsavedChanges => 'Unsaved changes';

  @override
  String get themeUnsavedChangesTitle => 'Unsaved Changes';

  @override
  String get themeUnsavedChangesBody =>
      'You have unsaved changes. Do you want to save before leaving?';

  @override
  String get discard => 'Discard';

  @override
  String get done => 'Done';

  @override
  String pickColor(String label) {
    return 'Pick $label';
  }

  @override
  String get titleStyle => 'Title Style';

  @override
  String get artistStyle => 'Artist Style';

  @override
  String get themeActive => 'ACTIVE';

  @override
  String get themeSafeMode => 'SAFE';

  @override
  String get themeCodeMode => 'CODE';

  @override
  String get themeAnimBadge => 'ANIM';

  @override
  String themeAuthor(String author) {
    return 'by $author';
  }
}
