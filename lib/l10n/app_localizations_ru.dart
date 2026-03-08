// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Musly';

  @override
  String get goodMorning => 'Доброе утро';

  @override
  String get goodAfternoon => 'Добрый день';

  @override
  String get goodEvening => 'Добрый вечер';

  @override
  String get forYou => 'Для вас';

  @override
  String get quickPicks => 'Быстрые подборки';

  @override
  String get discoverMix => 'Микс «Открытия»';

  @override
  String get recentlyPlayed => 'Недавно играли';

  @override
  String get yourPlaylists => 'Ваши плейлисты';

  @override
  String get madeForYou => 'Сделано для вас';

  @override
  String get topRated => 'Высоко оценённые';

  @override
  String get noContentAvailable => 'Нет доступного контента';

  @override
  String get tryRefreshing =>
      'Попробуйте обновить или проверить подключение к серверу';

  @override
  String get refresh => 'Обновить';

  @override
  String get errorLoadingSongs => 'Ошибка при загрузке треков';

  @override
  String get noSongsInGenre => 'Нет песен в этом жанре';

  @override
  String get errorLoadingAlbums => 'Ошибка при загрузке альбомов';

  @override
  String get noTopRatedAlbums => 'Нет высоко оценённых альбомов';

  @override
  String get login => 'Войти';

  @override
  String get serverUrl => 'URL-адрес сервера';

  @override
  String get username => 'Имя пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get selectCertificate => 'Выберите сертификат TLS/SSL';

  @override
  String failedToSelectCertificate(String error) {
    return 'Не удалось выбрать сертификат: $error';
  }

  @override
  String get serverUrlMustStartWith =>
      'URL-адрес сервера должен начинаться с http:// или https://';

  @override
  String get failedToConnect => 'Не удалось подключиться';

  @override
  String get library => 'Библиотека';

  @override
  String get search => 'Поиск';

  @override
  String get settings => 'Настройки';

  @override
  String get albums => 'Альбомы';

  @override
  String get artists => 'Исполнители';

  @override
  String get songs => 'Песни';

  @override
  String get playlists => 'Плейлисты';

  @override
  String get genres => 'Жанры';

  @override
  String get favorites => 'Избранное';

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get queue => 'Очередь';

  @override
  String get lyrics => 'Текст';

  @override
  String get play => 'Играть';

  @override
  String get pause => 'Пауза';

  @override
  String get next => 'Далее';

  @override
  String get previous => 'Предыдущ.';

  @override
  String get shuffle => 'Перемешивание';

  @override
  String get repeat => 'Повтор';

  @override
  String get repeatOne => 'Повтор одного';

  @override
  String get repeatOff => 'Повтор выкл.';

  @override
  String get addToPlaylist => 'Добавить в плейлист';

  @override
  String get removeFromPlaylist => 'Удалить из плейлиста';

  @override
  String get addToFavorites => 'Добавить в избранное';

  @override
  String get removeFromFavorites => 'Удалить из избранного';

  @override
  String get download => 'Скачать';

  @override
  String get delete => 'Удалить';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'ОК';

  @override
  String get save => 'Сохранить';

  @override
  String get close => 'Закрыть';

  @override
  String get general => 'Общее';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get playback => 'Проигрывание';

  @override
  String get storage => 'Хранилище';

  @override
  String get about => 'Информация';

  @override
  String get darkMode => 'Тёмный режим';

  @override
  String get language => 'Язык';

  @override
  String get version => 'Версия';

  @override
  String get madeBy => 'Сделано dddevid';

  @override
  String get githubRepository => 'Репозиторий на GitHub';

  @override
  String get reportIssue => 'Сообщить о проблеме';

  @override
  String get joinDiscord => 'Присоединяйтесь к Discord сообществу';

  @override
  String get unknownArtist => 'Неизвестный исполнитель';

  @override
  String get unknownAlbum => 'Неизвестный альбом';

  @override
  String get playAll => 'Проиграть все';

  @override
  String get shuffleAll => 'Перемешать все';

  @override
  String get sortBy => 'Сортировать по';

  @override
  String get sortByName => 'Название';

  @override
  String get sortByArtist => 'Исполнитель';

  @override
  String get sortByAlbum => 'Альбом';

  @override
  String get sortByDate => 'Дата';

  @override
  String get sortByDuration => 'Длительность';

  @override
  String get ascending => 'По возрастанию';

  @override
  String get descending => 'По убыванию';

  @override
  String get noLyricsAvailable => 'Нет доступных текстов';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get retry => 'Повторить';

  @override
  String get noResults => 'Ничего не найдено';

  @override
  String get searchHint => 'Поиск песен, альбомов, исполнителей...';

  @override
  String get allSongs => 'Все песни';

  @override
  String get allAlbums => 'Все альбомы';

  @override
  String get allArtists => 'Все исполнители';

  @override
  String trackNumber(int number) {
    return 'Трек $number';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песен',
      one: '1 песня',
      zero: 'Нет песен',
      many: '$count песен',
      few: '$count песни',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count альбомов',
      one: '1 альбом',
      zero: 'Нет альбомов',
      many: '$count альбомов',
      few: '$count альбома',
    );
    return '$_temp0';
  }

  @override
  String get logout => 'Выйти';

  @override
  String get confirmLogout => 'Вы уверены, что хотите выйти?';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get offlineMode => 'Автономный режим';

  @override
  String get radio => 'Радио';

  @override
  String get changelog => 'Список изменений';

  @override
  String get platform => 'Платформа';

  @override
  String get server => 'Сервер';

  @override
  String get display => 'Дисплей';

  @override
  String get playerInterface => 'Интерфейс плеера';

  @override
  String get smartRecommendations => 'Умные рекомендации';

  @override
  String get showVolumeSlider => 'Показать ползунок громкости';

  @override
  String get showVolumeSliderSubtitle =>
      'Отображать управление громкостью на экране воспроизведения';

  @override
  String get showStarRatings => 'Отображать оценку звёздами';

  @override
  String get showStarRatingsSubtitle =>
      'Оценивайте песни и просматривайте рейтинги';

  @override
  String get enableRecommendations => 'Включить рекомендации';

  @override
  String get enableRecommendationsSubtitle =>
      'Получайте персональные рекомендации';

  @override
  String get listeningData => 'Данные о прослушивании';

  @override
  String totalPlays(int count) {
    return 'Всего прослушиваний: $count ';
  }

  @override
  String get clearListeningHistory => 'Очистить историю прослушивания';

  @override
  String get confirmClearHistory =>
      'Это сбросит все ваши данные и рекомендации. Вы уверены?';

  @override
  String get historyCleared => 'История прослушивания очищена';

  @override
  String get discordStatus => 'Discord Статус';

  @override
  String get discordStatusSubtitle =>
      'Показывать проигрываемую песню в профиле Discord';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get systemDefault => 'Системный по умолчанию';

  @override
  String get communityTranslations => 'Переведено сообществом';

  @override
  String get communityTranslationsSubtitle =>
      'Помогите перевести Musly на Crowdin';

  @override
  String get yourLibrary => 'Ваша библиотека';

  @override
  String get filterAll => 'Все';

  @override
  String get filterPlaylists => 'Плейлисты';

  @override
  String get filterAlbums => 'Альбомы';

  @override
  String get filterArtists => 'Исполнители';

  @override
  String get likedSongs => 'Понравившиеся песни';

  @override
  String get radioStations => 'Радиостанции';

  @override
  String get playlist => 'Плейлист';

  @override
  String get internetRadio => 'Интернет-радио';

  @override
  String get newPlaylist => 'Новый плейлист';

  @override
  String get playlistName => 'Название плейлиста';

  @override
  String get create => 'Создать';

  @override
  String get deletePlaylist => 'Удалить плейлист';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Вы уверены, что хотите удалить плейлист «$name»?';
  }

  @override
  String playlistDeleted(String name) {
    return 'Плейлист с названием «$name» удалён';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return 'Ошибка при создании плейлиста: $error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return 'Ошибка при удалении плейлиста: $error';
  }

  @override
  String playlistCreated(String name) {
    return 'Плейлист с названием «$name» создан';
  }

  @override
  String get searchTitle => 'Поиск';

  @override
  String get searchPlaceholder => 'Исполнители, Песни, Альбомы';

  @override
  String get tryDifferentSearch => 'Попробуйте другой поисковый запрос';

  @override
  String get noSuggestions => 'Нет предложений';

  @override
  String get browseCategories => 'Просмотреть категории';

  @override
  String get liveSearchSection => 'Search';

  @override
  String get liveSearch => 'Live Search';

  @override
  String get liveSearchSubtitle =>
      'Update results as you type instead of showing a dropdown';

  @override
  String get categoryMadeForYou => 'Сделано для вас';

  @override
  String get categoryNewReleases => 'Новые выпуски';

  @override
  String get categoryTopRated => 'Высоко оценённые';

  @override
  String get categoryGenres => 'Жанры';

  @override
  String get categoryFavorites => 'Избранное';

  @override
  String get categoryRadio => 'Радио';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get tabPlayback => 'Проигрывание';

  @override
  String get tabStorage => 'Хранилище';

  @override
  String get tabServer => 'Сервер';

  @override
  String get tabDisplay => 'Дисплей';

  @override
  String get tabAbout => 'Информация';

  @override
  String get sectionAutoDj => 'Авто-диджей';

  @override
  String get autoDjMode => 'Режим авто-диджея';

  @override
  String songsToAdd(int count) {
    return 'Песни для добавления: $count';
  }

  @override
  String get sectionReplayGain => 'НОРМАЛИЗАЦИЯ ГРОМКОСТИ (REPLAYGAIN)';

  @override
  String get replayGainMode => 'Режим';

  @override
  String preamp(String value) {
    return 'Предусиление: $value дБ';
  }

  @override
  String get preventClipping => 'Предотвращение клиппинга';

  @override
  String fallbackGain(String value) {
    return 'Усиление по умолчанию: $value дБ';
  }

  @override
  String get sectionStreamingQuality => 'КАЧЕСТВО СТРИМИНГА';

  @override
  String get enableTranscoding => 'Включить транскодирование';

  @override
  String get qualityWifi => 'Качество WiFi';

  @override
  String get qualityMobile => 'Мобильное качество';

  @override
  String get format => 'Формат';

  @override
  String get transcodingSubtitle => 'Экономить трафик при низком качестве';

  @override
  String get modeOff => 'Выкл.';

  @override
  String get modeTrack => 'Трек';

  @override
  String get modeAlbum => 'Альбом';

  @override
  String get sectionServerConnection => 'ПОДКЛЮЧЕНИЕ СЕРВЕРА';

  @override
  String get serverType => 'Тип сервера';

  @override
  String get notConnected => 'Не подключено';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get sectionMusicFolders => 'ПАПКИ С МУЗЫКОЙ';

  @override
  String get musicFolders => 'Папки с музыкой';

  @override
  String get noMusicFolders => 'Папки с музыкой не найдены';

  @override
  String get sectionAccount => 'АККАУНТ';

  @override
  String get logoutConfirmation =>
      'Вы уверены, что хотите выйти? Это также удалит все кэшированные данные.';

  @override
  String get sectionCacheSettings => 'НАСТРОЙКИ КЭША';

  @override
  String get imageCache => 'Кэш изображений';

  @override
  String get musicCache => 'Кэш музыки';

  @override
  String get bpmCache => 'Кэш BPM';

  @override
  String get saveAlbumCovers => 'Сохранить обложки альбома локально';

  @override
  String get saveSongMetadata => 'Сохранить метаданные песни локально';

  @override
  String get saveBpmAnalysis => 'Сохранить определение BPM локально';

  @override
  String get sectionCacheCleanup => 'ОЧИСТКА КЭША';

  @override
  String get clearAllCache => 'Очистить весь кэш';

  @override
  String get allCacheCleared => 'Весь кэш очищен';

  @override
  String get sectionOfflineDownloads => 'АВТОНОМНЫЕ ЗАГРУЗКИ';

  @override
  String get downloadedSongs => 'Загруженные песни';

  @override
  String downloadingLibrary(int progress, int total) {
    return 'Загрузка библиотеки... $progress/$total';
  }

  @override
  String get downloadAllLibrary => 'Загрузить всю библиотеку';

  @override
  String downloadLibraryConfirm(int count) {
    return 'Будет скачано $count песен. Это может занять некоторое время и потребовать значительного объёма памяти.\n\nПродолжить?';
  }

  @override
  String get libraryDownloadStarted => 'Загрузка библиотеки началась';

  @override
  String get deleteDownloads => 'Удалить все загрузки';

  @override
  String get downloadsDeleted => 'Все загрузки удалены';

  @override
  String get noSongsAvailable =>
      'Нет доступных песен. Пожалуйста, загрузите сначала вашу библиотеку.';

  @override
  String get sectionBpmAnalysis => 'ОПРЕДЕЛЕНИЕ BPM';

  @override
  String get cachedBpms => 'Кэшированные BPM';

  @override
  String get cacheAllBpms => 'Кэшировать все BPM';

  @override
  String get clearBpmCache => 'Очистить кэш BPM';

  @override
  String get bpmCacheCleared => 'Кэш BPM очищен';

  @override
  String downloadedStats(int count, String size) {
    return '$count пес. • $size';
  }

  @override
  String get sectionInformation => 'ИНФОРМАЦИЯ';

  @override
  String get sectionDeveloper => 'РАЗРАБОТЧИК';

  @override
  String get sectionLinks => 'ССЫЛКИ';

  @override
  String get githubRepo => 'Репозиторий на GitHub';

  @override
  String get playingFrom => 'ИГРАЕТ ИЗ';

  @override
  String get live => 'В ЭФИРЕ';

  @override
  String get streamingLive => 'Прямая трансляция';

  @override
  String get stopRadio => 'Остановить радио';

  @override
  String get removeFromLiked => 'Удалить из понравившихся песен';

  @override
  String get addToLiked => 'Добавить в понравившиеся песни';

  @override
  String get playNext => 'Воспроизвести следующим';

  @override
  String get addToQueue => 'Добавить в очередь';

  @override
  String get goToAlbum => 'Перейти к альбому';

  @override
  String get goToArtist => 'Перейти к исполнителю';

  @override
  String get rateSong => 'Оценить песню';

  @override
  String rateSongValue(int rating, String stars) {
    return 'Оценка песни ($rating $stars)';
  }

  @override
  String get ratingRemoved => 'Оценка удалена';

  @override
  String rated(int rating, String stars) {
    return 'Оценка $rating $stars';
  }

  @override
  String get removeRating => 'Удалить оценку';

  @override
  String get downloaded => 'Скачано';

  @override
  String downloading(int percent) {
    return 'Скачивание... $percent%';
  }

  @override
  String get removeDownload => 'Удалить загрузку';

  @override
  String get removeDownloadConfirm =>
      'Удалить эту песню из автономного хранилища?';

  @override
  String get downloadRemoved => 'Загрузка удалена';

  @override
  String downloadedTitle(String title) {
    return 'Загружено «$title»';
  }

  @override
  String get downloadFailed => 'Не удалось загрузить';

  @override
  String downloadError(Object error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return 'Добавлено «$title» в плейлист «$playlist»';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return 'Ошибка при добавлении в плейлист: $error';
  }

  @override
  String get noPlaylists => 'Нет доступных плейлистов';

  @override
  String get createNewPlaylist => 'Создать новый плейлист';

  @override
  String artistNotFound(String name) {
    return 'Исполнитель «$name» не найден';
  }

  @override
  String errorSearchingArtist(Object error) {
    return 'Ошибка при поиске исполнителя: $error';
  }

  @override
  String get selectArtist => 'Выберите исполнителя';

  @override
  String get removedFromFavorites => 'Удалено из избранного';

  @override
  String get addedToFavorites => 'Добавлено в избранное';

  @override
  String get star => 'зв.';

  @override
  String get stars => 'зв.';

  @override
  String get albumNotFound => 'Альбом не найден';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours ЧАС. $minutes МИН.';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes МИН.';
  }

  @override
  String get topSongs => 'Лучшие песни';

  @override
  String get connected => 'Подключено';

  @override
  String get noSongPlaying => 'Ничего не играет';

  @override
  String get internetRadioUppercase => 'ИНТЕРНЕТ-РАДИО';

  @override
  String get playingNext => 'Проигрывание следующей';

  @override
  String get createPlaylistTitle => 'Создать плейлист';

  @override
  String get playlistNameHint => 'Название плейлиста';

  @override
  String playlistCreatedWithSong(String name) {
    return 'Создан плейлист «$name» с этой песней';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return 'Ошибка при загрузке плейлистов: $error';
  }

  @override
  String get playlistNotFound => 'Плейлист не найден';

  @override
  String get noSongsInPlaylist => 'Нет песен в этом плейлисте';

  @override
  String get noFavoriteSongsYet => 'Нет избранных песен';

  @override
  String get noFavoriteAlbumsYet => 'Нет избранных альбомов';

  @override
  String get listeningHistory => 'История прослушивания';

  @override
  String get noListeningHistory => 'Нет истории прослушивания';

  @override
  String get songsWillAppearHere => 'Здесь будут появляться прослушанные песни';

  @override
  String get sortByTitleAZ => 'Название (А-Я)';

  @override
  String get sortByTitleZA => 'Название (Я-А)';

  @override
  String get sortByArtistAZ => 'Исполнитель (А-Я)';

  @override
  String get sortByArtistZA => 'Исполнитель (Я-А)';

  @override
  String get sortByAlbumAZ => 'Альбом (А-Я)';

  @override
  String get sortByAlbumZA => 'Альбом (Я-А)';

  @override
  String get recentlyAdded => 'Недавно добавлено';

  @override
  String get noSongsFound => 'Не найдено песен';

  @override
  String get noAlbumsFound => 'Альбомы не найдены';

  @override
  String get noHomepageUrl => 'URL-адрес главной страницы не найден';

  @override
  String get playStation => 'Включить станцию';

  @override
  String get openHomepage => 'Открыть главную страницу';

  @override
  String get copyStreamUrl => 'Копировать URL-адрес трансляции';

  @override
  String get failedToLoadRadioStations => 'Не удалось загрузить радиостанции';

  @override
  String get noRadioStations => 'Нет радиостанций';

  @override
  String get noRadioStationsHint =>
      'Добавьте радиостанции в настройках сервера Navidrome, чтобы они появились здесь.';

  @override
  String get connectToServerSubtitle =>
      'Подключиться к вашему серверу Subsonic';

  @override
  String get pleaseEnterServerUrl => 'Пожалуйста, введите URL-адрес сервера';

  @override
  String get invalidUrlFormat =>
      'URL-адрес должен начинаться с http:// или https://';

  @override
  String get pleaseEnterUsername => 'Пожалуйста, введите имя пользователя';

  @override
  String get pleaseEnterPassword => 'Пожалуйста, введите пароль';

  @override
  String get legacyAuthentication => 'Устаревшая аутентификация';

  @override
  String get legacyAuthSubtitle => 'Использовать для старых серверов Subsonic';

  @override
  String get allowSelfSignedCerts => 'Разрешить самоподписанные сертификаты';

  @override
  String get allowSelfSignedSubtitle =>
      'Для серверов с собственными TLS/SSL-сертификатами';

  @override
  String get advancedOptions => 'Дополнительные настройки';

  @override
  String get customTlsCertificate => 'Собственный TLS/SSL-сертификат';

  @override
  String get customCertificateSubtitle =>
      'Загрузите собственный сертификат для серверов с нестандартным центром сертификации (CA)';

  @override
  String get selectCertificateFile => 'Выбрать файл сертификата';

  @override
  String get clientCertificate => 'Сертификат клиента (mTLS)';

  @override
  String get clientCertificateSubtitle =>
      'Авторизовать клиент по сертификату (требуется сервер с поддержкой mTLS)';

  @override
  String get selectClientCertificate => 'Выбрать сертификат клиента';

  @override
  String get clientCertPassword => 'Пароль сертификата (необязательно)';

  @override
  String failedToSelectClientCert(String error) {
    return 'Не удалось выбрать сертификат клиента: $error';
  }

  @override
  String get connect => 'Подключиться';

  @override
  String get or => 'ИЛИ';

  @override
  String get useLocalFiles => 'Использовать локальные файлы';

  @override
  String get startingScan => 'Запуск сканирования...';

  @override
  String get storagePermissionRequired =>
      'Для сканирования локальных файлов требуется разрешение на доступ к памяти';

  @override
  String get noMusicFilesFound =>
      'На вашем устройстве не найдено музыкальных файлов';

  @override
  String get remove => 'Удалить';

  @override
  String failedToSetRating(Object error) {
    return 'Не удалось задать оценку: $error';
  }

  @override
  String get home => 'Главная';

  @override
  String get playlistsSection => 'ПЛЕЙЛИСТЫ';

  @override
  String get collapse => 'Свернуть';

  @override
  String get expand => 'Развернуть';

  @override
  String get createPlaylist => 'Создать плейлист';

  @override
  String get likedSongsSidebar => 'Понравившиеся песни';

  @override
  String playlistSongsCount(int count) {
    return 'Плейлист • $count пес.';
  }

  @override
  String get failedToLoadLyrics => 'Не удалось загрузить текст';

  @override
  String get lyricsNotFoundSubtitle => 'Тексты для этой песни не найдены';

  @override
  String get backToCurrent => 'Назад к текущей';

  @override
  String get exitFullscreen => 'Выйти из полноэкранного режима';

  @override
  String get fullscreen => 'Полный экран';

  @override
  String get noLyrics => 'Нет текста';

  @override
  String get internetRadioMiniPlayer => 'Интернет-радио';

  @override
  String get liveBadge => 'В ЭФИРЕ';

  @override
  String get localFilesModeBanner => 'Режим локальных файлов';

  @override
  String get offlineModeBanner => 'Автономный режим — только скачанная музыка';

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String get updateAvailableSubtitle => 'Доступна новая версия Musly!';

  @override
  String updateCurrentVersion(String version) {
    return 'Текущая: в$version';
  }

  @override
  String updateLatestVersion(String version) {
    return 'Последняя: в$version';
  }

  @override
  String get whatsNew => 'Что нового';

  @override
  String get downloadUpdate => 'Скачать';

  @override
  String get remindLater => 'Позже';

  @override
  String get seeAll => 'Смотреть все';

  @override
  String get artistDataNotFound => 'Исполнитель не найден';

  @override
  String get casting => 'Трансляция';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => 'Трансляция / DLNA (Бета-версия)';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => 'Отключиться';

  @override
  String get searchingDevices => 'Поиск устройств';

  @override
  String get castWifiHint =>
      'Убедитесь, что устройство Cast / DLNA \nподключено к той же сети Wi-Fi';

  @override
  String connectedToDevice(String name) {
    return 'Подключено к $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return 'Не удалось подключиться к $name';
  }

  @override
  String get removedFromLikedSongs => 'Удалено из понравившихся песен';

  @override
  String get addedToLikedSongs => 'Добавлено в понравившиеся песни';

  @override
  String get enableShuffle => 'Включить перемешивание';

  @override
  String get enableRepeat => 'Включить повтор';

  @override
  String get connecting => 'Подключение';

  @override
  String get closeLyrics => 'Закрыть текст';

  @override
  String errorStartingDownload(Object error) {
    return 'Ошибка при запуске загрузки: $error';
  }

  @override
  String get errorLoadingGenres => 'Ошибка при загрузке жанров';

  @override
  String get noGenresFound => 'Жанры не найдены';

  @override
  String get noAlbumsInGenre => 'Нет альбомов в этом жанре';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount пес. • $albumCount альб.';
  }

  @override
  String get sectionJukebox => 'РЕЖИМ «МУЗ. АВТОМАТ»';

  @override
  String get jukeboxMode => 'Режим муз. автомат';

  @override
  String get jukeboxModeSubtitle =>
      'Воспроизводите через сервер вместо этого устройства';

  @override
  String get openJukeboxController => 'Открыть контроллер муз. автомата';

  @override
  String get jukeboxClearQueue => 'Очистить очередь';

  @override
  String get jukeboxShuffleQueue => 'Перемешать очередь';

  @override
  String get jukeboxQueueEmpty => 'В очереди нет песен';

  @override
  String get jukeboxNowPlaying => 'Сейчас играет';

  @override
  String get jukeboxQueue => 'Очередь';

  @override
  String get jukeboxVolume => 'Громкость';

  @override
  String get playOnJukebox => 'Играть через муз. автомат';

  @override
  String get addToJukeboxQueue => 'Добавить в очередь муз. автомата';

  @override
  String get jukeboxNotSupported =>
      'Режим муз. автомата не поддерживается этим сервером. Включите его в конфигурации сервера (например, EnableJukebox = true в Navidrome).';

  @override
  String get musicFoldersDialogTitle => 'Выберите папки с музыкой';

  @override
  String get musicFoldersHint =>
      'Оставьте всё включенным, чтобы использовать все папки (по умолчанию).';

  @override
  String get musicFoldersSaved => 'Выбор папки для музыки сохранён';

  @override
  String get artworkStyleSection => 'Стиль обложек';

  @override
  String get artworkCornerRadius => 'Радиус углов';

  @override
  String get artworkCornerRadiusSubtitle =>
      'Настройте степень скругления углов у обложек альбомов';

  @override
  String get artworkCornerRadiusNone => 'Нет';

  @override
  String get artworkShape => 'Форма';

  @override
  String get artworkShapeRounded => 'Скругление';

  @override
  String get artworkShapeCircle => 'Круг';

  @override
  String get artworkShapeSquare => 'Квадрат';

  @override
  String get artworkShadow => 'Тень';

  @override
  String get artworkShadowNone => 'Нет';

  @override
  String get artworkShadowSoft => 'Мягко';

  @override
  String get artworkShadowMedium => 'Сред.';

  @override
  String get artworkShadowStrong => 'Сильно';

  @override
  String get artworkShadowColor => 'Цвет тени';

  @override
  String get artworkShadowColorBlack => 'Чёрный';

  @override
  String get artworkShadowColorAccent => 'Акцент';

  @override
  String get artworkPreview => 'Предпросмотр';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '${value}px';
  }

  @override
  String get noArtwork => 'Нет обложки';

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
