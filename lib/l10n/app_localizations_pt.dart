// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Musly';

  @override
  String get goodMorning => 'Bom dia';

  @override
  String get goodAfternoon => 'Boa tarde';

  @override
  String get goodEvening => 'Boa noite';

  @override
  String get forYou => 'Para você';

  @override
  String get quickPicks => 'Escolhas Rápidas';

  @override
  String get discoverMix => 'Mix de Descobertas';

  @override
  String get recentlyPlayed => 'Reproduzidos Recentemente';

  @override
  String get yourPlaylists => 'Suas Playlists';

  @override
  String get madeForYou => 'Feito para você';

  @override
  String get topRated => 'Melhor Avaliados';

  @override
  String get noContentAvailable => 'Sem conteúdo disponível';

  @override
  String get tryRefreshing =>
      'Tente atualizar ou verifique a conexão do servidor';

  @override
  String get refresh => 'Atualizar';

  @override
  String get errorLoadingSongs => 'Erro ao carregar músicas';

  @override
  String get noSongsInGenre => 'Nenhuma música neste gênero';

  @override
  String get errorLoadingAlbums => 'Erro ao carregar álbuns';

  @override
  String get noTopRatedAlbums => 'Nenhum álbum avaliado';

  @override
  String get login => 'Iniciar Sessão';

  @override
  String get serverUrl => 'URL do Servidor';

  @override
  String get username => 'Nome de usuário';

  @override
  String get password => 'Senha';

  @override
  String get selectCertificate => 'Selecione o certificado TLS/SSL';

  @override
  String failedToSelectCertificate(String error) {
    return 'Falha ao selecionar certificado: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'O URL do servidor deve começar com http:// ou https://';

  @override
  String get failedToConnect => 'Falha ao conectar';

  @override
  String get library => 'Biblioteca';

  @override
  String get search => 'Buscar';

  @override
  String get settings => 'Configurações';

  @override
  String get albums => 'Álbuns';

  @override
  String get artists => 'Artistas';

  @override
  String get songs => 'Músicas';

  @override
  String get playlists => 'Playlists';

  @override
  String get genres => 'Gêneros';

  @override
  String get favorites => 'Favoritos';

  @override
  String get nowPlaying => 'Tocando Agora';

  @override
  String get queue => 'Fila';

  @override
  String get lyrics => 'Letras';

  @override
  String get play => 'Reproduzir';

  @override
  String get pause => 'Pausar';

  @override
  String get next => 'Próximo';

  @override
  String get previous => 'Anterior';

  @override
  String get shuffle => 'Aleatório';

  @override
  String get repeat => 'Repetir';

  @override
  String get repeatOne => 'Repetir Faixa';

  @override
  String get repeatOff => 'Não Repetir';

  @override
  String get addToPlaylist => 'Adicionar à Playlist';

  @override
  String get removeFromPlaylist => 'Remover da Playlist';

  @override
  String get addToFavorites => 'Adicionar aos Favoritos';

  @override
  String get removeFromFavorites => 'Remover dos Favoritos';

  @override
  String get download => 'Baixar';

  @override
  String get delete => 'Excluir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Salvar';

  @override
  String get close => 'Fechar';

  @override
  String get general => 'Geral';

  @override
  String get appearance => 'Aparência';

  @override
  String get playback => 'Reprodução';

  @override
  String get storage => 'Armazenamento';

  @override
  String get about => 'Sobre';

  @override
  String get darkMode => 'Modo Escuro';

  @override
  String get language => 'Idioma';

  @override
  String get version => 'Versão';

  @override
  String get madeBy => 'Feito por dddevid';

  @override
  String get githubRepository => 'Repositório no GitHub';

  @override
  String get reportIssue => 'Reportar Problema';

  @override
  String get joinDiscord => 'Entrar na Comunidade do Discord';

  @override
  String get unknownArtist => 'Artista Desconhecido';

  @override
  String get unknownAlbum => 'Álbum Desconhecido';

  @override
  String get playAll => 'Reproduzir Tudo';

  @override
  String get shuffleAll => 'Reproduzir em Aleatório';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortByName => 'Nome';

  @override
  String get sortByArtist => 'Artista';

  @override
  String get sortByAlbum => 'Álbum';

  @override
  String get sortByDate => 'Data';

  @override
  String get sortByDuration => 'Duração';

  @override
  String get ascending => 'Crescente';

  @override
  String get descending => 'Decrescente';

  @override
  String get noLyricsAvailable => 'Sem letras disponíveis';

  @override
  String get loading => 'Carregando...';

  @override
  String get error => 'Erro';

  @override
  String get retry => 'Tentar Novamente';

  @override
  String get noResults => 'Sem resultados';

  @override
  String get searchHint => 'Buscar músicas, álbuns, artistas...';

  @override
  String get allSongs => 'Todas as músicas';

  @override
  String get allAlbums => 'Todos os Álbuns';

  @override
  String get allArtists => 'Todos os Artistas';

  @override
  String trackNumber(int number) {
    return 'Faixa $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count músicas',
      one: '1 música',
      zero: 'Sem músicas',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count álbuns',
      one: '1 álbum',
      zero: 'Sem álbuns',
    );
    return '$_temp0';
  }

  @override
  String get logout => 'Encerrar Sessão';

  @override
  String get confirmLogout => 'Tem certeza que deseja encerrar a sessão?';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get offlineMode => 'Modo Offline';

  @override
  String get radio => 'Rádio';

  @override
  String get changelog => 'Changelog';

  @override
  String get platform => 'Plataforma';

  @override
  String get server => 'Servidor';

  @override
  String get display => 'Personalização';

  @override
  String get playerInterface => 'Interface do Player';

  @override
  String get smartRecommendations => 'Recomendações Inteligentes';

  @override
  String get showVolumeSlider => 'Mostrar Controle de Volume';

  @override
  String get showVolumeSliderSubtitle =>
      'Exibir controle de volume na tela Tocando Agora';

  @override
  String get showStarRatings => 'Mostrar Avaliações';

  @override
  String get showStarRatingsSubtitle => 'Avaliar músicas e ver avaliações';

  @override
  String get enableRecommendations => 'Habilitar Recomendações';

  @override
  String get enableRecommendationsSubtitle =>
      'Obter sugestões de músicas personalizadas';

  @override
  String get listeningData => 'Dados de Reprodução';

  @override
  String totalPlays(int count) {
    return 'Total de $count reproduções';
  }

  @override
  String get clearListeningHistory => 'Limpar Histórico de Reprodução';

  @override
  String get confirmClearHistory =>
      'Isso redefinirá todos os seus dados de reprodução e recomendações. Deseja continuar?';

  @override
  String get historyCleared => 'Histórico de reprodução limpo';

  @override
  String get discordStatus => 'Status do Discord';

  @override
  String get discordStatusSubtitle =>
      'Mostrar música em reprodução no perfil do Discord';

  @override
  String get selectLanguage => 'Selecionar Idioma';

  @override
  String get systemDefault => 'Padrão do Sistema';

  @override
  String get communityTranslations => 'Traduções pela Comunidade';

  @override
  String get communityTranslationsSubtitle =>
      'Ajude a traduzir o Musly no Crowdin';

  @override
  String get yourLibrary => 'Sua Biblioteca';

  @override
  String get filterAll => 'Tudo';

  @override
  String get filterPlaylists => 'Playlists';

  @override
  String get filterAlbums => 'Álbuns';

  @override
  String get filterArtists => 'Artistas';

  @override
  String get likedSongs => 'Músicas favoritas';

  @override
  String get radioStations => 'Estações de rádio';

  @override
  String get playlist => 'Playlist';

  @override
  String get internetRadio => 'Rádio Online';

  @override
  String get newPlaylist => 'Nova Playlist';

  @override
  String get playlistName => 'Nome da Playlist';

  @override
  String get create => 'Criar';

  @override
  String get deletePlaylist => 'Excluir Playlist';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Tem certeza de que deseja excluir a playlist \"$name\"?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Playlist \"$name\" excluída';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Erro ao criar playlist: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Erro ao excluir playlist: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Playlist \"$name\" criada';
  }

  @override
  String get searchTitle => 'Pesquisar';

  @override
  String get searchPlaceholder => 'Artistas, músicas e álbuns';

  @override
  String get tryDifferentSearch => 'Tente uma busca diferente';

  @override
  String get noSuggestions => 'Sem sugestões';

  @override
  String get browseCategories => 'Navegar categorias';

  @override
  String get categoryMadeForYou => 'Feito para você';

  @override
  String get categoryNewReleases => 'Novos lançamentos';

  @override
  String get categoryTopRated => 'Melhor Avaliados';

  @override
  String get categoryGenres => 'Gêneros';

  @override
  String get categoryFavorites => 'Favoritos';

  @override
  String get categoryRadio => 'Rádio';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get tabPlayback => 'Reprodução';

  @override
  String get tabStorage => 'Armazenamento';

  @override
  String get tabServer => 'Servidor';

  @override
  String get tabDisplay => 'Personalização';

  @override
  String get tabAbout => 'Sobre';

  @override
  String get sectionAutoDj => 'AUTO DJ';

  @override
  String get autoDjMode => 'Modo Auto DJ';

  @override
  String songsToAdd(int count) {
    return 'Músicas a adicionar: $count';
  }

  @override
  String get sectionReplayGain => 'NORMALIZAÇÃO DE VOLUME (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Modo';

  @override
  String preamp(String value) {
    return 'Preamp: $value dB';
  }

  @override
  String get preventClipping => 'Prevenir Clipping';

  @override
  String fallbackGain(String value) {
    return 'Fallback Gain: $value dB';
  }

  @override
  String get sectionStreamingQuality => 'QUALIDADE DE STREAMING';

  @override
  String get enableTranscoding => 'Ativar a transcodificação';

  @override
  String get qualityWifi => 'Qualidade em WiFi';

  @override
  String get qualityMobile => 'Qualidade em Dados Móveis';

  @override
  String get format => 'Formato';

  @override
  String get transcodingSubtitle => 'Reduzir uso de dados com menor qualidade';

  @override
  String get modeOff => 'Desligado';

  @override
  String get modeTrack => 'Faixa';

  @override
  String get modeAlbum => 'Álbum';

  @override
  String get sectionServerConnection => 'CONEXÃO DO SERVIDOR';

  @override
  String get serverType => 'Tipo de Servidor';

  @override
  String get notConnected => 'Não conectado';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get sectionMusicFolders => 'PASTAS DE MÚSICA';

  @override
  String get musicFolders => 'Pastas de música';

  @override
  String get noMusicFolders => 'Nenhuma pasta de música encontrada';

  @override
  String get sectionAccount => 'CONTA';

  @override
  String get logoutConfirmation =>
      'Tem certeza que deseja encerrar a sessão? Isso também limpará todos os dados em cache.';

  @override
  String get sectionCacheSettings => 'CONFIGURAÇÕES DE CACHE';

  @override
  String get imageCache => 'Cache de Imagem';

  @override
  String get musicCache => 'Cache de Música';

  @override
  String get bpmCache => 'Cache BPM';

  @override
  String get saveAlbumCovers => 'Salvar capas de álbuns localmente';

  @override
  String get saveSongMetadata => 'Salvar metadados da música localmente';

  @override
  String get saveBpmAnalysis => 'Salvar análise de BPM localmente';

  @override
  String get sectionCacheCleanup => 'LIMPEZA DE CACHE';

  @override
  String get clearAllCache => 'Limpar todo o cache';

  @override
  String get allCacheCleared => 'Todo o cache limpo';

  @override
  String get sectionOfflineDownloads => 'DOWNLOADS OFFLINE';

  @override
  String get downloadedSongs => 'Músicas Baixadas';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Baixando Biblioteca... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Baixar Toda a Biblioteca';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Isso baixará $count músicas para o seu dispositivo. Isso pode levar um tempo e usar espaço significativo de armazenamento.\n\nContinuar?';
  }

  @override
  String get libraryDownloadStarted => 'Download da biblioteca iniciado';

  @override
  String get deleteDownloads => 'Excluir Todos os Downloads';

  @override
  String get downloadsDeleted => 'Todos os downloads excluídos';

  @override
  String get noSongsAvailable =>
      'Nenhuma música disponível. Carregue sua biblioteca primeiro.';

  @override
  String get sectionBpmAnalysis => 'ANÁLISE BPM';

  @override
  String get cachedBpms => 'BPMs em Cache';

  @override
  String get cacheAllBpms => 'Cachear Todos os BPMs';

  @override
  String get clearBpmCache => 'Limpar Cache BPM';

  @override
  String get bpmCacheCleared => 'Cache BPM limpo';

  @override
  String downloadedStats(int count, String size) {
    return '$count músicas • $size';
  }

  @override
  String get sectionInformation => 'INFORMAÇÕES';

  @override
  String get sectionDeveloper => 'DESENVOLVEDOR';

  @override
  String get sectionLinks => 'LINKS';

  @override
  String get githubRepo => 'Repositório no GitHub';

  @override
  String get playingFrom => 'REPRODUZINDO DE';

  @override
  String get live => 'AO VIVO';

  @override
  String get streamingLive => 'Transmissão Ao Vivo';

  @override
  String get stopRadio => 'Parar Rádio';

  @override
  String get removeFromLiked => 'Remover das Músicas Favoritas';

  @override
  String get addToLiked => 'Adicionar às Músicas Favoritas';

  @override
  String get playNext => 'Tocar em Seguida';

  @override
  String get addToQueue => 'Adicionar à Fila';

  @override
  String get goToAlbum => 'Ir para o Álbum';

  @override
  String get goToArtist => 'Ir para o Artista';

  @override
  String get rateSong => 'Avaliar Música';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Avaliar Música ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Avaliação removida';

  @override
  String rated(int rating, String stars) {
    return 'Avaliado com $rating $stars';
  }

  @override
  String get removeRating => 'Remover avaliação';

  @override
  String get downloaded => 'Baixado';

  @override
  String downloading(int percent) {
    return 'Baixando... $percent%';
  }

  @override
  String get removeDownload => 'Remover Download';

  @override
  String get removeDownloadConfirm =>
      'Remover esta música do armazenamento offline?';

  @override
  String get downloadRemoved => 'Download removido';

  @override
  String downloadedTitle(String title) {
    return '\"$title\" baixado';
  }

  @override
  String get downloadFailed => 'Falha no download';

  @override
  String downloadError(Object error) {
    return 'Erro no download: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Adicionado \"$title\" a $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Erro ao adicionar à playlist: $error';
  }

  @override
  String get noPlaylists => 'Sem playlists disponíveis';

  @override
  String get createNewPlaylist => 'Criar Nova Playlist';

  @override
  String artistNotFound(String name) {
    return 'O artista \"$name\" não foi encontrado';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Erro ao buscar artista: $error';
  }

  @override
  String get selectArtist => 'Selecionar Artista';

  @override
  String get removedFromFavorites => 'Removido dos favoritos';

  @override
  String get addedToFavorites => 'Adicionado aos favoritos';

  @override
  String get star => 'estrela';

  @override
  String get stars => 'estrelas';

  @override
  String get albumNotFound => 'Álbum não encontrado';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours H $minutes MIN';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes MIN';
  }

  @override
  String get topSongs => 'Mais Ouvidas';

  @override
  String get connected => 'Conectado';

  @override
  String get noSongPlaying => 'Nenhuma música em reprodução';

  @override
  String get internetRadioUppercase => 'RÁDIO ONLINE';

  @override
  String get playingNext => 'A seguir';

  @override
  String get createPlaylistTitle => 'Criar Playlist';

  @override
  String get playlistNameHint => 'Nome da Playlist';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Playlist criada \"$name\" com esta música';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Erro ao carregar playlists: $error';
  }

  @override
  String get playlistNotFound => 'Playlist não foi encontrada';

  @override
  String get noSongsInPlaylist => 'Não há músicas nesta playlist';

  @override
  String get noFavoriteSongsYet => 'Nenhuma música favorita ainda';

  @override
  String get noFavoriteAlbumsYet => 'Nenhum álbum favorito ainda';

  @override
  String get listeningHistory => 'Histórico de Reprodução';

  @override
  String get noListeningHistory => 'Nenhum histórico de reprodução';

  @override
  String get songsWillAppearHere =>
      'As músicas que você reproduzir aparecerão aqui';

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
  String get recentlyAdded => 'Adicionado Recentemente';

  @override
  String get noSongsFound => 'Nenhuma música foi encontrada';

  @override
  String get noAlbumsFound => 'Nenhum álbum foi encontrado';

  @override
  String get noHomepageUrl => 'Nenhuma URL de página inicial disponível';

  @override
  String get playStation => 'Reproduzir estação';

  @override
  String get openHomepage => 'Abrir Página Inicial';

  @override
  String get copyStreamUrl => 'Copiar URL da Transmissão';

  @override
  String get failedToLoadRadioStations => 'Falha ao carregar estações de rádio';

  @override
  String get noRadioStations => 'Nenhuma estação de rádio';

  @override
  String get noRadioStationsHint =>
      'Adicione estações de rádio nas configurações do seu servidor Navidrome para vê-las aqui.';

  @override
  String get connectToServerSubtitle => 'Conecte-se ao seu servidor Subsonic';

  @override
  String get pleaseEnterServerUrl => 'Por favor, insira o URL do servidor';

  @override
  String get invalidUrlFormat => 'O URL deve começar com http:// ou https://';

  @override
  String get pleaseEnterUsername => 'Por favor, insira o nome de usuário';

  @override
  String get pleaseEnterPassword => 'Por favor, insira a senha';

  @override
  String get legacyAuthentication => 'Autenticação Legada';

  @override
  String get legacyAuthSubtitle => 'Usado para antigos servidores Subsonic';

  @override
  String get allowSelfSignedCerts => 'Permitir Certificados Auto-Assinados';

  @override
  String get allowSelfSignedSubtitle =>
      'Para servidores com certificados TLS/SSL personalizados';

  @override
  String get advancedOptions => 'Opções Avançadas';

  @override
  String get customTlsCertificate => 'Certificado TLS/SSL personalizado';

  @override
  String get customCertificateSubtitle =>
      'Enviar certificado personalizado para servidores com CA não padrão';

  @override
  String get selectCertificateFile => 'Selecione o arquivo de certificado';

  @override
  String get clientCertificate => 'Certificado de Cliente (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Autenticar este cliente usando um certificado (requer servidor com mTLS ativado)';

  @override
  String get selectClientCertificate => 'Selecione o certificado do cliente';

  @override
  String get clientCertPassword => 'Senha do certificado (opcional)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Falha ao selecionar certificado do cliente: $error';
  }

  @override
  String get connect => 'Conectar';

  @override
  String get or => 'OU';

  @override
  String get useLocalFiles => 'Usar Arquivos Locais';

  @override
  String get startingScan => 'Iniciando scan...';

  @override
  String get storagePermissionRequired =>
      'Permissão de armazenamento necessária para o scan dos arquivos locais';

  @override
  String get noMusicFilesFound =>
      'Nenhum arquivo de música foi encontrado no seu dispositivo';

  @override
  String get remove => 'Excluir';

  @override
  String failedToSetRating(Object error) {
    return 'Falha ao definir avaliação: $error';
  }

  @override
  String get home => 'Início';

  @override
  String get playlistsSection => 'PLAYLISTS';

  @override
  String get collapse => 'Recolher';

  @override
  String get expand => 'Expand';

  @override
  String get createPlaylist => 'Create playlist';

  @override
  String get likedSongsSidebar => 'Músicas favoritas';

  @override
  String playlistSongsCount(int count) {
    return 'Playlist • $count músicas';
  }

  @override
  String get failedToLoadLyrics => 'Falha ao carregar as letras';

  @override
  String get lyricsNotFoundSubtitle =>
      'Não foi possível encontrar as letras desta música';

  @override
  String get backToCurrent => 'Voltar para a atual';

  @override
  String get exitFullscreen => 'Sair da Tela Cheia';

  @override
  String get fullscreen => 'Tela cheia';

  @override
  String get noLyrics => 'Sem letras';

  @override
  String get internetRadioMiniPlayer => 'Rádio Online';

  @override
  String get liveBadge => 'AO VIVO';

  @override
  String get localFilesModeBanner => 'Modo Arquivos Locais';

  @override
  String get offlineModeBanner =>
      'Modo Offline – Reproduzindo apenas músicas baixadas';

  @override
  String get updateAvailable => 'Atualização disponível';

  @override
  String get updateAvailableSubtitle =>
      'Uma nova versão do Musly está disponível!';

  @override
  String updateCurrentVersion(String version) {
    return 'Atual: v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Mais recente: v$version';
  }

  @override
  String get whatsNew => 'Novidades';

  @override
  String get downloadUpdate => 'Baixar';

  @override
  String get remindLater => 'Mais tarde';

  @override
  String get seeAll => 'Ver Todos';

  @override
  String get artistDataNotFound => 'Artista não foi encontrado';

  @override
  String get casting => 'Transmitindo';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Transmitir / DLNA (Beta)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Encerrar sessão';

  @override
  String get searchingDevices => 'Buscando dispositivos';

  @override
  String get castWifiHint =>
      'Certifique-se de que seu dispositivo Cast / DLNA esteja na mesma rede Wi-Fi';

  @override
  String connectedToDevice(String name) {
    return 'Conectado a $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Falha ao conectar a $name';
  }

  @override
  String get removedFromLikedSongs => 'Removido das Músicas Favoritas';

  @override
  String get addedToLikedSongs => 'Adicionado às Músicas Favoritas';

  @override
  String get enableShuffle => 'Ativar aleatório';

  @override
  String get enableRepeat => 'Ativar repetição';

  @override
  String get connecting => 'Conectando';

  @override
  String get closeLyrics => 'Fechar Letras';

  @override
  String errorStartingDownload(Object error) {
    return 'Erro ao iniciar download: $error';
  }

  @override
  String get errorLoadingGenres => 'Erro ao carregar gêneros';

  @override
  String get noGenresFound => 'Nenhum gênero foi encontrado';

  @override
  String get noAlbumsInGenre => 'Nenhum álbum neste gênero';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount músicas • $albumCount álbuns';
  }

  @override
  String get sectionJukebox => 'MODO JUKEBOX';

  @override
  String get jukeboxMode => 'Modo Jukebox';

  @override
  String get jukeboxModeSubtitle =>
      'Reproduzir áudio pelo servidor ao invés deste dispositivo';

  @override
  String get openJukeboxController => 'Abrir Controle do Jukebox';

  @override
  String get jukeboxClearQueue => 'Limpar Fila';

  @override
  String get jukeboxShuffleQueue => 'Aleatorizar Fila';

  @override
  String get jukeboxQueueEmpty => 'Nenhuma música na fila';

  @override
  String get jukeboxNowPlaying => 'Tocando Agora';

  @override
  String get jukeboxQueue => 'Fila';

  @override
  String get jukeboxVolume => 'Volume';

  @override
  String get playOnJukebox => 'Tocar na Jukebox';

  @override
  String get addToJukeboxQueue => 'Adicionar à Fila do Jukebox';

  @override
  String get jukeboxNotSupported =>
      'O modo Jukebox não é suportado por este servidor. Ative-o na configuração do servidor (ex: EnableJukebox = true no Navidrome).';

  @override
  String get musicFoldersDialogTitle => 'Selecionar pastas de música';

  @override
  String get musicFoldersHint =>
      'Deixe todas ativadas para usar todas as pastas (padrão).';

  @override
  String get musicFoldersSaved => 'Seleção de pastas de música salva';

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
}
