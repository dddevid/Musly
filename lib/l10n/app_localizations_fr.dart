// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Musly';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bonjour';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get forYou => 'Pour vous';

  @override
  String get quickPicks => 'Sélection rapide';

  @override
  String get discoverMix => 'Mix Découverte';

  @override
  String get recentlyPlayed => 'Lus récemment';

  @override
  String get yourPlaylists => 'Vos playlists';

  @override
  String get madeForYou => 'Fait pour vous';

  @override
  String get topRated => 'Les mieux notés';

  @override
  String get noContentAvailable => 'Aucun contenu disponible';

  @override
  String get tryRefreshing =>
      'Actualisez ou vérifiez votre connexion au serveur';

  @override
  String get refresh => 'Actualiser';

  @override
  String get errorLoadingSongs => 'Erreur lors du chargement des titres';

  @override
  String get noSongsInGenre => 'Pas de titre de ce genre';

  @override
  String get errorLoadingAlbums => 'Erreur lors du chargement des albums';

  @override
  String get noTopRatedAlbums => 'Aucun album le mieux noté';

  @override
  String get login => 'Connexion';

  @override
  String get serverUrl => 'Adresse du serveur';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get selectCertificate => 'Sélectionnez le certificat TLS/SSL';

  @override
  String failedToSelectCertificate(String error) {
    return 'Impossible de sélectionner le certificat : $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'L\'adresse du serveur doit commencer par http:// ou https://';

  @override
  String get failedToConnect => 'Échec de la connexion';

  @override
  String get library => 'Bibliothèque';

  @override
  String get search => 'Rechercher';

  @override
  String get settings => 'Paramètres';

  @override
  String get albums => 'Albums';

  @override
  String get artists => 'Artistes';

  @override
  String get songs => 'Titres';

  @override
  String get playlists => 'Playlists';

  @override
  String get genres => 'Genres';

  @override
  String get favorites => 'Favoris';

  @override
  String get nowPlaying => 'En cours de lecture';

  @override
  String get queue => 'File d\'attente';

  @override
  String get lyrics => 'Paroles';

  @override
  String get play => 'Lecture';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Suivant';

  @override
  String get previous => 'Précédent';

  @override
  String get shuffle => 'Aléatoire';

  @override
  String get repeat => 'Lecture en boucle';

  @override
  String get repeatOne => 'Boucler sur un titre';

  @override
  String get repeatOff => 'Lecture en boucle désactivée';

  @override
  String get addToPlaylist => 'Ajouter à la playlist';

  @override
  String get removeFromPlaylist => 'Retirer de la playlist';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String get download => 'Télécharger';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'Ok';

  @override
  String get save => 'Enregistrer';

  @override
  String get close => 'Fermer';

  @override
  String get general => 'Général';

  @override
  String get appearance => 'Apparence';

  @override
  String get playback => 'Lecture';

  @override
  String get storage => 'Stockage';

  @override
  String get about => 'À propos';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get language => 'Langue';

  @override
  String get version => 'Version';

  @override
  String get madeBy => 'Développé par dddevid';

  @override
  String get githubRepository => 'Dépôt GitHub';

  @override
  String get reportIssue => 'Signaler un problème';

  @override
  String get joinDiscord => 'Rejoindre la communauté Discord';

  @override
  String get unknownArtist => 'Artiste inconnu';

  @override
  String get unknownAlbum => 'Album inconnu';

  @override
  String get playAll => 'Tout lire';

  @override
  String get shuffleAll => 'Lecture aléatoire de tous les titres';

  @override
  String get sortBy => 'Trier par';

  @override
  String get sortByName => 'Nom';

  @override
  String get sortByArtist => 'Artiste';

  @override
  String get sortByAlbum => 'Album';

  @override
  String get sortByDate => 'Date';

  @override
  String get sortByDuration => 'Durée';

  @override
  String get ascending => 'Croissant';

  @override
  String get descending => 'Décroissant';

  @override
  String get noLyricsAvailable => 'Paroles non disponibles';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get searchHint => 'Rechercher des titres, des albums, des artistes...';

  @override
  String get allSongs => 'Tous les titres';

  @override
  String get allAlbums => 'Tous les albums';

  @override
  String get allArtists => 'Tous les artistes';

  @override
  String trackNumber(int number) {
    return 'Piste n°$number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
      zero: 'Aucun titre',
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
      zero: 'Aucun album',
    );
    return '$_temp0';
  }

  @override
  String get logout => 'Déconnexion';

  @override
  String get confirmLogout => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get offlineMode => 'Mode hors-connexion';

  @override
  String get radio => 'Radio';

  @override
  String get changelog => 'Journal des changements';

  @override
  String get platform => 'Plateforme';

  @override
  String get server => 'Serveur';

  @override
  String get display => 'Affichage';

  @override
  String get playerInterface => 'Interface du lecteur';

  @override
  String get smartRecommendations => 'Recommandations personnalisées';

  @override
  String get showVolumeSlider => 'Afficher le curseur du volume';

  @override
  String get showVolumeSliderSubtitle =>
      'Afficher le contrôle du volume dans l\'écran de lecture en cours';

  @override
  String get showStarRatings => 'Afficher les notes';

  @override
  String get showStarRatingsSubtitle => 'Noter les pistes et voir les notes';

  @override
  String get enableRecommendations => 'Activer les Recommandations';

  @override
  String get enableRecommendationsSubtitle =>
      'Recevez des suggestions musicales personnalisées';

  @override
  String get listeningData => 'Données d\'écoute';

  @override
  String totalPlays(int count) {
    return 'Lectures au total : $count';
  }

  @override
  String get clearListeningHistory => 'Effacer l\'historique des écoutes';

  @override
  String get confirmClearHistory =>
      'Cela réinitialisera toutes vos données d\'écoute et recommandations. Êtes-vous sûr(e) ?';

  @override
  String get historyCleared => 'Historique d\'écoutes effacé';

  @override
  String get discordStatus => 'Statut Discord';

  @override
  String get discordStatusSubtitle =>
      'Afficher la chanson en cours de lecture sur le profil Discord';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get systemDefault => 'Système par défaut';

  @override
  String get communityTranslations => 'Traductions par la communauté';

  @override
  String get communityTranslationsSubtitle =>
      'Aidez-nous à traduire Musly sur Crowdin';

  @override
  String get yourLibrary => 'Votre Bibliothèque';

  @override
  String get filterAll => 'Tout';

  @override
  String get filterPlaylists => 'Playlists';

  @override
  String get filterAlbums => 'Albums';

  @override
  String get filterArtists => 'Artistes';

  @override
  String get likedSongs => 'Titres \"J\'aime\"';

  @override
  String get radioStations => 'Stations radio';

  @override
  String get playlist => 'Playlist';

  @override
  String get internetRadio => 'Radio Internet';

  @override
  String get newPlaylist => 'Nouvelle Playlist';

  @override
  String get playlistName => 'Nom de la liste de lecture';

  @override
  String get create => 'Créer';

  @override
  String get deletePlaylist => 'Supprimer la Playlist';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Êtes-vous sûr de vouloir supprimer la playlist \"$name \" ?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Playlist \"$name\" supprimée';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Erreur lors de la création de la playlist : $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Erreur lors de la suppression de la playlist : $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Playlist \"$name\" créée';
  }

  @override
  String get searchTitle => 'Rechercher';

  @override
  String get searchPlaceholder => 'Artistes, chansons, albums';

  @override
  String get tryDifferentSearch => 'Essayez une recherche différente';

  @override
  String get noSuggestions => 'Aucune suggestion';

  @override
  String get browseCategories => 'Parcourir les catégories';

  @override
  String get liveSearchSection => 'Search';

  @override
  String get liveSearch => 'Live Search';

  @override
  String get liveSearchSubtitle =>
      'Update results as you type instead of showing a dropdown';

  @override
  String get categoryMadeForYou => 'Fait pour vous';

  @override
  String get categoryNewReleases => 'Nouvelles sorties';

  @override
  String get categoryTopRated => 'Les mieux notés';

  @override
  String get categoryGenres => 'Genres';

  @override
  String get categoryFavorites => 'Favoris';

  @override
  String get categoryRadio => 'Radio';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get tabPlayback => 'Lecture';

  @override
  String get tabStorage => 'Stockage';

  @override
  String get tabServer => 'Serveur';

  @override
  String get tabDisplay => 'Affichage';

  @override
  String get tabAbout => 'À propos';

  @override
  String get sectionAutoDj => 'DJ AUTO';

  @override
  String get autoDjMode => 'Mode DJ Auto';

  @override
  String songsToAdd(int count) {
    return 'Pistes à ajouter : $count';
  }

  @override
  String get sectionReplayGain => 'NORMALISATION DE VOLUME (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Mode';

  @override
  String preamp(String value) {
    return 'Pré-ampli : $value dB';
  }

  @override
  String get preventClipping => 'Empêcher le découpage audio';

  @override
  String fallbackGain(String value) {
    return 'Gain de repli : $value dB';
  }

  @override
  String get sectionStreamingQuality => 'QUALITÉ DE STREAMING';

  @override
  String get enableTranscoding => 'Activer le transcodage';

  @override
  String get qualityWifi => 'Qualité sur réseau Wi-Fi';

  @override
  String get qualityMobile => 'Qualité sur réseau mobile';

  @override
  String get format => 'Format';

  @override
  String get transcodingSubtitle =>
      'Réduire la consommation de données avec une qualité inférieure';

  @override
  String get modeOff => 'Désactivé';

  @override
  String get modeTrack => 'Piste';

  @override
  String get modeAlbum => 'Album';

  @override
  String get sectionServerConnection => 'CONNEXION DU SERVEUR';

  @override
  String get serverType => 'Type de serveur';

  @override
  String get notConnected => 'Non connecté';

  @override
  String get unknown => 'Inconnu';

  @override
  String get sectionMusicFolders => 'RÉPERTOIRES DE MUSIQUE';

  @override
  String get musicFolders => 'Dossiers musicaux';

  @override
  String get noMusicFolders => 'Aucun dossier de musique trouvé';

  @override
  String get sectionAccount => 'COMPTE';

  @override
  String get logoutConfirmation =>
      'Êtes-vous sûr de vouloir vous déconnecter ? Cela effacera également toutes les données mises en cache.';

  @override
  String get sectionCacheSettings => 'PARAMÈTRES DU CACHE';

  @override
  String get imageCache => 'Cache d\'images';

  @override
  String get musicCache => 'Cache de musiques';

  @override
  String get bpmCache => 'Cache BPM';

  @override
  String get saveAlbumCovers => 'Enregistrer les pochettes d\'album en local';

  @override
  String get saveSongMetadata =>
      'Enregistrer les métadonnées de la piste en local';

  @override
  String get saveBpmAnalysis => 'Enregistrer les analyses BPM en local';

  @override
  String get sectionCacheCleanup => 'SUPPRESSION DE CACHE';

  @override
  String get clearAllCache => 'Vider tout le cache';

  @override
  String get allCacheCleared => 'Tout le cache a été effacé';

  @override
  String get sectionOfflineDownloads => 'TÉLÉCHARGEMENT HORS LIGNE';

  @override
  String get downloadedSongs => 'Pistes téléchargées';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Téléchargement de la bibliothèque... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Télécharger toute la bibliothèque';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Cette action va télécharger $count pistes sur votre appareil. Cela peut prendre un certain temps et utiliser un espace de stockage significatif.\n\nVoulez-vous continuer ?';
  }

  @override
  String get libraryDownloadStarted =>
      'Le téléchargement de la bibliothèque a démarré';

  @override
  String get deleteDownloads => 'Supprimer tous les téléchargements';

  @override
  String get downloadsDeleted => 'Tous les téléchargements ont été supprimés';

  @override
  String get noSongsAvailable =>
      'Aucune musique disponible. Veuillez d\'abord charger votre bibliothèque.';

  @override
  String get sectionBpmAnalysis => 'ANALYSE BPM';

  @override
  String get cachedBpms => 'BPMs en cache';

  @override
  String get cacheAllBpms => 'Mettre en cache tous les BPMs';

  @override
  String get clearBpmCache => 'Vider le cache BPM';

  @override
  String get bpmCacheCleared => 'Cache BPM effacé';

  @override
  String downloadedStats(int count, String size) {
    return 'Chansons $count • $size';
  }

  @override
  String get sectionInformation => 'INFORMATIONS';

  @override
  String get sectionDeveloper => 'DÉVELOPPEURS';

  @override
  String get sectionLinks => 'LIENS';

  @override
  String get githubRepo => 'Dépôt GitHub';

  @override
  String get playingFrom => 'LECTURE DEPUIS';

  @override
  String get live => 'EN DIRECT';

  @override
  String get streamingLive => 'Diffusion en direct';

  @override
  String get stopRadio => 'Arrêter la radio';

  @override
  String get removeFromLiked => 'Supprimer des titres favoris';

  @override
  String get addToLiked => 'Ajouter aux pistes \"J\'aime\"';

  @override
  String get playNext => 'Lecture suivante';

  @override
  String get addToQueue => 'Ajouter à la liste';

  @override
  String get goToAlbum => 'Aller à l’album';

  @override
  String get goToArtist => 'Aller à l\'artiste';

  @override
  String get rateSong => 'Noter la chanson';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Noter la chanson ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Note effacée';

  @override
  String rated(int rating, String stars) {
    return 'Notée $rating $stars';
  }

  @override
  String get removeRating => 'Supprimer la note';

  @override
  String get downloaded => 'Téléchargé';

  @override
  String downloading(int percent) {
    return 'Téléchargement... $percent%';
  }

  @override
  String get removeDownload => 'Supprimer le téléchargement';

  @override
  String get removeDownloadConfirm =>
      'Supprimer cette chanson du stockage hors-ligne ?';

  @override
  String get downloadRemoved => 'Téléchargement supprimé';

  @override
  String downloadedTitle(String title) {
    return 'Téléchargé \"$title\"';
  }

  @override
  String get downloadFailed => 'Echec du téléchargement';

  @override
  String downloadError(Object error) {
    return 'Erreur de téléchargement : $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Ajout de «$title» à $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Erreur lors de l\'ajout à la playlist : $error';
  }

  @override
  String get noPlaylists => 'Aucune playlist disponible';

  @override
  String get createNewPlaylist => 'Créer une nouvelle playlist';

  @override
  String artistNotFound(String name) {
    return 'Artiste «$name» introuvable';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Erreur lors de la recherche de l\'artiste: $error';
  }

  @override
  String get selectArtist => 'Sélectionner un artiste';

  @override
  String get removedFromFavorites => 'Retiré des favoris';

  @override
  String get addedToFavorites => 'Ajouté aux favoris';

  @override
  String get star => 'étoile';

  @override
  String get stars => 'étoiles';

  @override
  String get albumNotFound => 'Album introuvable';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours HR $minutes MIN';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get topSongs => 'Top Chansons';

  @override
  String get connected => 'Connecté';

  @override
  String get noSongPlaying => 'Aucun morceau en cours de lecture';

  @override
  String get internetRadioUppercase => 'RADIO INTERNET';

  @override
  String get playingNext => 'Lecture suivante';

  @override
  String get createPlaylistTitle => 'Créer une liste de lecture';

  @override
  String get playlistNameHint => 'Nom de la liste de lecture';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Liste de lecture «$name» créée avec cette piste';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Erreur lors du chargement des listes de lecture : $error';
  }

  @override
  String get playlistNotFound => 'Liste de lecture introuvable';

  @override
  String get noSongsInPlaylist => 'Aucune piste dans cette liste de lecture';

  @override
  String get noFavoriteSongsYet => 'Aucune piste favorite pour le moment';

  @override
  String get noFavoriteAlbumsYet => 'Aucun album favori pour le moment';

  @override
  String get listeningHistory => 'Historique d\'écoute';

  @override
  String get noListeningHistory => 'Pas d\'historique d\'écoute';

  @override
  String get songsWillAppearHere =>
      'Les pistes que vous jouez apparaîtront ici';

  @override
  String get sortByTitleAZ => 'Titre (A-Z)';

  @override
  String get sortByTitleZA => 'Titre (Z-A)';

  @override
  String get sortByArtistAZ => 'Artiste (A-Z)';

  @override
  String get sortByArtistZA => 'Artiste (Z-A)';

  @override
  String get sortByAlbumAZ => 'Album (A-Z)';

  @override
  String get sortByAlbumZA => 'Album (Z-A)';

  @override
  String get recentlyAdded => 'Récemment Ajouté';

  @override
  String get noSongsFound => 'Aucune piste trouvée';

  @override
  String get noAlbumsFound => 'Aucun album trouvé';

  @override
  String get noHomepageUrl => 'Aucune URL de page d\'accueil disponible';

  @override
  String get playStation => 'Lancer la station';

  @override
  String get openHomepage => 'Ouvrir la page d\'accueil';

  @override
  String get copyStreamUrl => 'Copier l\'URL du flux';

  @override
  String get failedToLoadRadioStations =>
      'Impossible de charger les stations radio';

  @override
  String get noRadioStations => 'Aucune station radio';

  @override
  String get noRadioStationsHint =>
      'Ajoutez des stations radio dans les paramètres de votre serveur Navidrome pour les voir ici.';

  @override
  String get connectToServerSubtitle =>
      'Connectez-vous à votre serveur Subsonic';

  @override
  String get pleaseEnterServerUrl => 'Veuillez entrer l\'URL du serveur';

  @override
  String get invalidUrlFormat =>
      'L\'URL doit commencer par http:// ou https://';

  @override
  String get pleaseEnterUsername => 'Veuillez entrer le nom d\'utilisateur';

  @override
  String get pleaseEnterPassword => 'Veuillez saisir votre mot de passe';

  @override
  String get legacyAuthentication => 'Authentification héritée';

  @override
  String get legacyAuthSubtitle =>
      'Utiliser pour les anciens serveurs Subsonic';

  @override
  String get allowSelfSignedCerts => 'Autoriser les certificats autosignés';

  @override
  String get allowSelfSignedSubtitle =>
      'Pour les serveurs avec des certificats TLS/SSL personnalisés';

  @override
  String get advancedOptions => 'Options avancées';

  @override
  String get customTlsCertificate => 'Certificat TLS/SSL personnalisé';

  @override
  String get customCertificateSubtitle =>
      'Télécharger un certificat personnalisé pour les serveurs avec une AC non standard';

  @override
  String get selectCertificateFile => 'Sélectionner un fichier de certificat';

  @override
  String get clientCertificate => 'Certificat client (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Authentifier ce client en utilisant un certificat (nécessite le serveur mTLS)';

  @override
  String get selectClientCertificate => 'Sélectionnez le certificat client';

  @override
  String get clientCertPassword => 'Mot de passe du certificat (facultatif)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Impossible de sélectionner le certificat client : $error';
  }

  @override
  String get connect => 'Connexion';

  @override
  String get or => 'OU';

  @override
  String get useLocalFiles => 'Utiliser les fichiers locaux';

  @override
  String get startingScan => 'Démarrage de l\'analyse...';

  @override
  String get storagePermissionRequired =>
      'Autorisation d\'accès au stockage requise pour scanner les fichiers locaux';

  @override
  String get noMusicFilesFound =>
      'Aucun fichier de musique trouvé sur votre appareil';

  @override
  String get remove => 'Retirer';

  @override
  String failedToSetRating(Object error) {
    return 'Impossible de définir la note : $error';
  }

  @override
  String get home => 'Accueil';

  @override
  String get playlistsSection => 'LISTES DE LECTURE';

  @override
  String get collapse => 'Réduire';

  @override
  String get expand => 'Étendre';

  @override
  String get createPlaylist => 'Créer une liste de lecture';

  @override
  String get likedSongsSidebar => 'Pistes \"J\'aime\"';

  @override
  String playlistSongsCount(int count) {
    return 'Liste de lecture • $count pistes';
  }

  @override
  String get failedToLoadLyrics => 'Impossible de charger les paroles';

  @override
  String get lyricsNotFoundSubtitle =>
      'Les paroles de cette piste n\'ont pas pu être trouvées';

  @override
  String get backToCurrent => 'Revenir à l\'actuel';

  @override
  String get exitFullscreen => 'Quitter le mode plein écran';

  @override
  String get fullscreen => 'Plein écran';

  @override
  String get noLyrics => 'Aucune parole';

  @override
  String get internetRadioMiniPlayer => 'Radio Internet';

  @override
  String get liveBadge => 'EN DIRECT';

  @override
  String get localFilesModeBanner => 'Mode fichiers locaux';

  @override
  String get offlineModeBanner =>
      'Mode hors-ligne – Lecture de la musique téléchargée uniquement';

  @override
  String get updateAvailable => 'Mise à jour disponible';

  @override
  String get updateAvailableSubtitle =>
      'Une nouvelle version de Musly est disponible !';

  @override
  String updateCurrentVersion(String version) {
    return 'Version actuelle : v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Dernière version : v$version';
  }

  @override
  String get whatsNew => 'Quoi de neuf';

  @override
  String get downloadUpdate => 'Télécharger';

  @override
  String get remindLater => 'Me rappeler plus tard';

  @override
  String get seeAll => 'Tout Afficher';

  @override
  String get artistDataNotFound => 'Artiste introuvable';

  @override
  String get casting => 'Diffusion';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Diffusion / DLNA (Bêta)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Déconnexion';

  @override
  String get searchingDevices => 'Recherche de périphériques';

  @override
  String get castWifiHint =>
      'Assurez-vous que votre appareil Cast / DLNA\nest sur le même réseau Wi-Fi';

  @override
  String connectedToDevice(String name) {
    return 'Connecté à $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Impossible de se connecter à $name';
  }

  @override
  String get removedFromLikedSongs => 'Retiré des pistes \"J\'aime\"';

  @override
  String get addedToLikedSongs => 'Ajouté aux pistes \"J\'aime\"';

  @override
  String get enableShuffle => 'Activer la lecture aléatoire';

  @override
  String get enableRepeat => 'Activer la répétition';

  @override
  String get connecting => 'Connexion en cours';

  @override
  String get closeLyrics => 'Désactiver les paroles';

  @override
  String errorStartingDownload(Object error) {
    return 'Erreur lors du démarrage du téléchargement : $error';
  }

  @override
  String get errorLoadingGenres => 'Erreur lors du chargement des genres';

  @override
  String get noGenresFound => 'Aucun genre trouvé';

  @override
  String get noAlbumsInGenre => 'Aucun album dans ce genre';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount pistes • $albumCount albums';
  }

  @override
  String get sectionJukebox => 'MODE JUKEBOX';

  @override
  String get jukeboxMode => 'Mode Jukebox';

  @override
  String get jukeboxModeSubtitle =>
      'Jouer l\'audio via le serveur au lieu de cet appareil';

  @override
  String get openJukeboxController => 'Ouvrir le contrôleur du Jukebox';

  @override
  String get jukeboxClearQueue => 'Vider la file d\'attente';

  @override
  String get jukeboxShuffleQueue => 'Mélanger la file d\'attente';

  @override
  String get jukeboxQueueEmpty => 'Aucune piste dans la file d\'attente';

  @override
  String get jukeboxNowPlaying => 'En cours de lecture';

  @override
  String get jukeboxQueue => 'File d\'attente';

  @override
  String get jukeboxVolume => 'Volume';

  @override
  String get playOnJukebox => 'Jouer sur le Jukebox';

  @override
  String get addToJukeboxQueue => 'Ajouter à la file d\'attente du Jukebox';

  @override
  String get jukeboxNotSupported =>
      'Le mode Jukebox n\'est pas pris en charge par ce serveur. Activez-le dans la configuration de votre serveur (par exemple EnableJukebox = true dans Navidrome).';

  @override
  String get musicFoldersDialogTitle => 'Sélectionner les dossiers de musique';

  @override
  String get musicFoldersHint =>
      'Laisser tout activer pour utiliser tous les dossiers (par défaut).';

  @override
  String get musicFoldersSaved => 'Sélection de dossier de musique enregistrée';

  @override
  String get artworkStyleSection => 'Style d’illustration';

  @override
  String get artworkCornerRadius => 'Arrondi des coins';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Ajuster l\'apparence des angles des pochettes d\'album';

  @override
  String get artworkCornerRadiusNone => 'Aucun';

  @override
  String get artworkShape => 'Forme';

  @override
  String get artworkShapeRounded => 'Arrondi';

  @override
  String get artworkShapeCircle => 'Cercle';

  @override
  String get artworkShapeSquare => 'Carré';

  @override
  String get artworkShadow => 'Ombre';

  @override
  String get artworkShadowNone => 'Aucun';

  @override
  String get artworkShadowSoft => 'Faible';

  @override
  String get artworkShadowMedium => 'Moyen';

  @override
  String get artworkShadowStrong => 'Fort';

  @override
  String get artworkShadowColor => 'Couleur d\'ombre';

  @override
  String get artworkShadowColorBlack => 'Noir';

  @override
  String get artworkShadowColorAccent => 'Accentuation';

  @override
  String get artworkPreview => 'Aperçu';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '$value pixels';
  }

  @override
  String get noArtwork => 'Pas de pochette d\'album';

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
}
