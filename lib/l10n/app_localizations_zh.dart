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
  String get goodMorning => '早上好';

  @override
  String get goodAfternoon => '下午好';

  @override
  String get goodEvening => '晚上好';

  @override
  String get forYou => '为你推荐';

  @override
  String get quickPicks => '快速选择';

  @override
  String get discoverMix => '发现混音';

  @override
  String get recentlyPlayed => '最近播放';

  @override
  String get yourPlaylists => '你的歌单';

  @override
  String get favoritePlaylists => 'Favorite Playlists';

  @override
  String get madeForYou => '为你制作';

  @override
  String get topRated => '评分最高';

  @override
  String get noContentAvailable => '暂无内容';

  @override
  String get tryRefreshing => '请刷新或检查服务器连接';

  @override
  String get refresh => '刷新';

  @override
  String get errorLoadingSongs => '加载歌曲出错';

  @override
  String get noSongsInGenre => '该分类没有歌曲';

  @override
  String get errorLoadingAlbums => '加载专辑出错';

  @override
  String get noTopRatedAlbums => '暂无评分最高的专辑';

  @override
  String get login => '登录';

  @override
  String get serverUrl => '服务器地址';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get selectCertificate => '选择 TLS/SSL 证书';

  @override
  String failedToSelectCertificate(String error) {
    return '选择证书失败：$error';
  }

  @override
  String get serverUrlMustStartWith => '服务器地址必须以 http:// 或 https:// 开头';

  @override
  String get failedToConnect => '连接失败';

  @override
  String get library => '音乐库';

  @override
  String get search => '搜索';

  @override
  String get settings => '设置';

  @override
  String get albums => '专辑';

  @override
  String get artists => '艺术家';

  @override
  String get songs => '歌曲';

  @override
  String get playlists => '歌单';

  @override
  String get genres => '分类';

  @override
  String get years => 'Years';

  @override
  String get favorites => '收藏';

  @override
  String get nowPlaying => '正在播放';

  @override
  String get queue => '播放队列';

  @override
  String get lyrics => '歌词';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get next => '下一首';

  @override
  String get previous => '上一首';

  @override
  String get shuffle => '随机播放';

  @override
  String get repeat => '循环';

  @override
  String get repeatOne => '单曲循环';

  @override
  String get repeatOff => '关闭循环';

  @override
  String get addToPlaylist => '添加到歌单';

  @override
  String get removeFromPlaylist => '从歌单移除';

  @override
  String get addToFavorites => '添加到收藏';

  @override
  String get removeFromFavorites => '从收藏移除';

  @override
  String get download => '下载';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get save => '保存';

  @override
  String get close => '关闭';

  @override
  String get general => '通用';

  @override
  String get appearance => '外观';

  @override
  String get playback => '播放';

  @override
  String get storage => '存储';

  @override
  String get about => '关于';

  @override
  String get darkMode => '深色模式';

  @override
  String get language => '语言';

  @override
  String get version => '版本';

  @override
  String get madeBy => '由 dddevid 开发';

  @override
  String get githubRepository => 'GitHub 仓库';

  @override
  String get reportIssue => '报告问题';

  @override
  String get joinDiscord => '加入 Discord 社区';

  @override
  String get unknownArtist => '未知艺术家';

  @override
  String get unknownAlbum => '未知专辑';

  @override
  String get playAll => '播放全部';

  @override
  String get shuffleAll => '随机播放全部';

  @override
  String get sortBy => '排序方式';

  @override
  String get sortByName => '名称';

  @override
  String get sortByArtist => '艺术家';

  @override
  String get sortByAlbum => '专辑';

  @override
  String get sortByDate => '日期';

  @override
  String get sortByDuration => '时长';

  @override
  String get ascending => '升序';

  @override
  String get descending => '降序';

  @override
  String get noLyricsAvailable => '暂无歌词';

  @override
  String get loading => '加载中...';

  @override
  String get error => '错误';

  @override
  String get retry => '重试';

  @override
  String get noResults => '无结果';

  @override
  String get searchHint => '搜索歌曲、专辑、艺术家...';

  @override
  String get allSongs => '全部歌曲';

  @override
  String get allAlbums => '全部专辑';

  @override
  String get allArtists => '全部艺术家';

  @override
  String trackNumber(int number) {
    return '第 $number 首';
  }

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 首歌曲',
      one: '1 首歌曲',
      zero: '无歌曲',
    );
    return '$_temp0';
  }

  @override
  String albumsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张专辑',
      one: '1 张专辑',
      zero: '无专辑',
    );
    return '$_temp0';
  }

  @override
  String get logout => '退出登录';

  @override
  String get confirmLogout => '确定要退出登录吗？';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get offlineMode => '离线模式';

  @override
  String get radio => '电台';

  @override
  String get changelog => '更新日志';

  @override
  String get platform => '平台';

  @override
  String get server => '服务器';

  @override
  String get display => '显示';

  @override
  String get playerInterface => '播放器界面';

  @override
  String get smartRecommendations => '智能推荐';

  @override
  String get showVolumeSlider => '显示音量滑块';

  @override
  String get showVolumeSliderSubtitle => '在正在播放界面显示音量控制';

  @override
  String get showStarRatings => '显示星级评分';

  @override
  String get showStarRatingsSubtitle => '为歌曲评分并查看评分';

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
  String get enableRecommendations => '启用推荐';

  @override
  String get enableRecommendationsSubtitle => '获取个性化音乐推荐';

  @override
  String get listeningData => '收听数据';

  @override
  String totalPlays(int count) {
    return '共播放 $count 次';
  }

  @override
  String get clearListeningHistory => '清除收听历史';

  @override
  String get confirmClearHistory => '这将重置您的所有收听数据和推荐。确定吗？';

  @override
  String get historyCleared => '收听历史已清除';

  @override
  String get discordStatus => 'Discord 状态';

  @override
  String get discordStatusSubtitle => '在 Discord 个人资料上显示正在播放的歌曲';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get communityTranslations => '社区翻译';

  @override
  String get communityTranslationsSubtitle => '在 Crowdin 上帮助翻译 Musly';

  @override
  String get yourLibrary => '你的音乐库';

  @override
  String get filterAll => '全部';

  @override
  String get faves => 'Faves';

  @override
  String get filterPlaylists => '歌单';

  @override
  String get filterAlbums => '专辑';

  @override
  String get filterArtists => '艺术家';

  @override
  String get likedSongs => '喜欢的歌曲';

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
  String get radioStations => '电台';

  @override
  String get playlist => '歌单';

  @override
  String get internetRadio => '网络电台';

  @override
  String get newPlaylist => '新建歌单';

  @override
  String get playlistName => '歌单名称';

  @override
  String get create => '创建';

  @override
  String get deletePlaylist => '删除歌单';

  @override
  String deletePlaylistConfirmation(String name) {
    return '确定要删除歌单「$name」吗？';
  }

  @override
  String playlistDeleted(String name) {
    return '歌单「$name」已删除';
  }

  @override
  String errorCreatingPlaylist(Object error) {
    return '创建歌单出错：$error';
  }

  @override
  String errorDeletingPlaylist(Object error) {
    return '删除歌单出错：$error';
  }

  @override
  String playlistCreated(String name) {
    return '歌单「$name」已创建';
  }

  @override
  String get searchTitle => '搜索';

  @override
  String get searchPlaceholder => '艺术家、歌曲、专辑';

  @override
  String get tryDifferentSearch => '尝试不同的搜索';

  @override
  String get noSuggestions => '无建议';

  @override
  String get browseCategories => '浏览分类';

  @override
  String get liveSearchSection => 'Search';

  @override
  String get liveSearch => 'Live Search';

  @override
  String get liveSearchSubtitle =>
      'Update results as you type instead of showing a dropdown';

  @override
  String get categoryMadeForYou => '为你制作';

  @override
  String get categoryNewReleases => '新歌首发';

  @override
  String get categoryTopRated => '评分最高';

  @override
  String get categoryGenres => '分类';

  @override
  String get categoryFavorites => '收藏';

  @override
  String get categoryRadio => '电台';

  @override
  String get settingsTitle => '设置';

  @override
  String get tabPlayback => '播放';

  @override
  String get tabStorage => '存储';

  @override
  String get tabServer => '服务器';

  @override
  String get tabDisplay => '显示';

  @override
  String get tabSupport => 'Support';

  @override
  String get tabAbout => '关于';

  @override
  String get sectionAutoDj => '自动播放';

  @override
  String get autoDjMode => '自动播放模式';

  @override
  String songsToAdd(int count) {
    return '添加歌曲数：$count';
  }

  @override
  String get sectionReplayGain => '音量标准化 (REPLAYGAIN)';

  @override
  String get replayGainMode => '模式';

  @override
  String preamp(String value) {
    return '前置增益：$value dB';
  }

  @override
  String get preventClipping => '防止削波';

  @override
  String fallbackGain(String value) {
    return '备用增益：$value dB';
  }

  @override
  String get sectionStreamingQuality => '流媒体质量';

  @override
  String get enableTranscoding => '启用转码';

  @override
  String get qualityWifi => 'WiFi 质量';

  @override
  String get qualityMobile => '移动网络质量';

  @override
  String get format => '格式';

  @override
  String get transcodingSubtitle => '降低质量以减少数据使用';

  @override
  String get modeOff => '关闭';

  @override
  String get modeTrack => '单曲';

  @override
  String get modeAlbum => '专辑';

  @override
  String get sectionServerConnection => '服务器连接';

  @override
  String get serverType => '服务器类型';

  @override
  String get notConnected => '未连接';

  @override
  String get unknown => '未知';

  @override
  String get sectionMusicFolders => '音乐文件夹';

  @override
  String get musicFolders => '音乐文件夹';

  @override
  String get noMusicFolders => '未找到音乐文件夹';

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
  String get sectionAccount => '账户';

  @override
  String get logoutConfirmation => '确定要退出登录吗？这也将清除所有缓存数据。';

  @override
  String get sectionCacheSettings => '缓存设置';

  @override
  String get imageCache => '图片缓存';

  @override
  String get musicCache => '音乐缓存';

  @override
  String get bpmCache => 'BPM 缓存';

  @override
  String get saveAlbumCovers => '本地保存专辑封面';

  @override
  String get saveSongMetadata => '本地保存歌曲元数据';

  @override
  String get saveBpmAnalysis => '本地保存 BPM 分析';

  @override
  String get sectionCacheCleanup => '缓存清理';

  @override
  String get clearAllCache => '清除所有缓存';

  @override
  String get allCacheCleared => '所有缓存已清除';

  @override
  String get sectionOfflineDownloads => '离线下载';

  @override
  String get downloadedSongs => '已下载歌曲';

  @override
  String downloadingLibrary(int progress, int total) {
    return '正在下载音乐库... $progress/$total';
  }

  @override
  String get downloadAllLibrary => '下载全部音乐库';

  @override
  String downloadLibraryConfirm(int count) {
    return '这将下载 $count 首歌曲到您的设备。这可能需要一段时间并占用大量存储空间。\n\n是否继续？';
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
  String get libraryDownloadStarted => '音乐库下载已开始';

  @override
  String get deleteDownloads => '删除所有下载';

  @override
  String get downloadsDeleted => '所有下载已删除';

  @override
  String get noSongsAvailable => '没有可用歌曲。请先加载您的音乐库。';

  @override
  String get sectionBpmAnalysis => 'BPM 分析';

  @override
  String get cachedBpms => '已缓存的 BPM';

  @override
  String get cacheAllBpms => '缓存所有 BPM';

  @override
  String get clearBpmCache => '清除 BPM 缓存';

  @override
  String get bpmCacheCleared => 'BPM 缓存已清除';

  @override
  String downloadedStats(int count, String size) {
    return '$count 首歌曲 • $size';
  }

  @override
  String get sectionInformation => '信息';

  @override
  String get sectionDeveloper => '开发者';

  @override
  String get sectionLinks => '链接';

  @override
  String get githubRepo => 'GitHub 仓库';

  @override
  String get playingFrom => '正在播放来自';

  @override
  String get live => '直播';

  @override
  String get streamingLive => '正在直播';

  @override
  String get stopRadio => '停止电台';

  @override
  String get removeFromLiked => '从喜欢的歌曲中移除';

  @override
  String get addToLiked => '添加到喜欢的歌曲';

  @override
  String get playNext => '下一首播放';

  @override
  String get addToQueue => '添加到队列';

  @override
  String get goToAlbum => '前往专辑';

  @override
  String get goToArtist => '前往艺术家';

  @override
  String get rateSong => '为歌曲评分';

  @override
  String rateSongValue(int rating, String stars) {
    return '为歌曲评分（$rating $stars）';
  }

  @override
  String get ratingRemoved => '评分已移除';

  @override
  String rated(int rating, String stars) {
    return '已评分 $rating $stars';
  }

  @override
  String get removeRating => '移除评分';

  @override
  String get downloaded => '已下载';

  @override
  String downloading(int percent) {
    return '正在下载... $percent%';
  }

  @override
  String get removeDownload => '移除下载';

  @override
  String get removeDownloadConfirm => '从离线存储中移除这首歌曲？';

  @override
  String get downloadRemoved => '下载已移除';

  @override
  String downloadedTitle(String title) {
    return '已下载「$title」';
  }

  @override
  String get downloadFailed => '下载失败';

  @override
  String downloadError(Object error) {
    return '下载错误：$error';
  }

  @override
  String addedToPlaylist(String title, String playlist) {
    return '已将「$title」添加到 $playlist';
  }

  @override
  String errorAddingToPlaylist(Object error) {
    return '添加到歌单出错：$error';
  }

  @override
  String get noPlaylists => '没有可用的歌单';

  @override
  String get createNewPlaylist => '创建新歌单';

  @override
  String artistNotFound(String name) {
    return '未找到艺术家「$name」';
  }

  @override
  String errorSearchingArtist(Object error) {
    return '搜索艺术家出错：$error';
  }

  @override
  String get selectArtist => '选择艺术家';

  @override
  String get removedFromFavorites => '已从收藏中移除';

  @override
  String get addedToFavorites => '已添加到收藏';

  @override
  String get star => '星';

  @override
  String get stars => '星';

  @override
  String get albumNotFound => '未找到专辑';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get topSongs => '热门歌曲';

  @override
  String get connected => '已连接';

  @override
  String get noSongPlaying => '当前无歌曲播放';

  @override
  String get internetRadioUppercase => '网络电台';

  @override
  String get playingNext => '即将播放';

  @override
  String get createPlaylistTitle => '创建歌单';

  @override
  String get playlistNameHint => '歌单名称';

  @override
  String playlistCreatedWithSong(String name) {
    return '已创建歌单「$name」并添加了这首歌曲';
  }

  @override
  String errorLoadingPlaylists(Object error) {
    return '加载歌单出错：$error';
  }

  @override
  String get playlistNotFound => '未找到歌单';

  @override
  String get noSongsInPlaylist => '该歌单中没有歌曲';

  @override
  String get noFavoriteSongsYet => '还没有喜欢的歌曲';

  @override
  String get noFavoriteAlbumsYet => '还没有喜欢的专辑';

  @override
  String get listeningHistory => '收听历史';

  @override
  String get noListeningHistory => '没有收听历史';

  @override
  String get songsWillAppearHere => '您播放的歌曲将显示在这里';

  @override
  String get sortByTitleAZ => '标题 (A-Z)';

  @override
  String get sortByTitleZA => '标题 (Z-A)';

  @override
  String get sortByArtistAZ => '艺术家 (A-Z)';

  @override
  String get sortByArtistZA => '艺术家 (Z-A)';

  @override
  String get sortByAlbumAZ => '专辑 (A-Z)';

  @override
  String get sortByAlbumZA => '专辑 (Z-A)';

  @override
  String get recentlyAdded => '最近添加';

  @override
  String get noSongsFound => '未找到歌曲';

  @override
  String get noAlbumsFound => '未找到专辑';

  @override
  String get noHomepageUrl => '没有可用的首页链接';

  @override
  String get playStation => '播放电台';

  @override
  String get openHomepage => '打开首页';

  @override
  String get copyStreamUrl => '复制流地址';

  @override
  String get failedToLoadRadioStations => '加载电台失败';

  @override
  String get noRadioStations => '没有电台';

  @override
  String get noRadioStationsHint => '在您的 Navidrome 服务器设置中添加电台以在此处查看。';

  @override
  String get connectToServerSubtitle => '连接到您的 Subsonic 服务器';

  @override
  String get pleaseEnterServerUrl => '请输入服务器地址';

  @override
  String get invalidUrlFormat => 'URL 必须以 http:// 或 https:// 开头';

  @override
  String get pleaseEnterUsername => '请输入用户名';

  @override
  String get pleaseEnterPassword => '请输入密码';

  @override
  String get legacyAuthentication => '旧版认证';

  @override
  String get legacyAuthSubtitle => '用于较旧的 Subsonic 服务器';

  @override
  String get allowSelfSignedCerts => '允许自签名证书';

  @override
  String get allowSelfSignedSubtitle => '用于具有自定义 TLS/SSL 证书的服务器';

  @override
  String get advancedOptions => '高级选项';

  @override
  String get customTlsCertificate => '自定义 TLS/SSL 证书';

  @override
  String get customCertificateSubtitle => '为使用非标准 CA 的服务器上传自定义证书';

  @override
  String get selectCertificateFile => '选择证书文件';

  @override
  String get clientCertificate => '客户端证书 (mTLS)';

  @override
  String get clientCertificateSubtitle => '使用证书对此客户端进行身份验证（需要支持 mTLS 的服务器）';

  @override
  String get selectClientCertificate => '选择客户端证书';

  @override
  String get clientCertPassword => '证书密码（可选）';

  @override
  String failedToSelectClientCert(String error) {
    return '选择客户端证书失败：$error';
  }

  @override
  String get connect => '连接';

  @override
  String get or => '或者';

  @override
  String get useLocalFiles => '使用本地文件';

  @override
  String get startingScan => '正在开始扫描...';

  @override
  String get storagePermissionRequired => '需要存储权限才能扫描本地文件';

  @override
  String get noMusicFilesFound => '在您的设备上未找到音乐文件';

  @override
  String get remove => '移除';

  @override
  String failedToSetRating(Object error) {
    return '设置评分失败：$error';
  }

  @override
  String get home => '首页';

  @override
  String get playlistsSection => '歌单';

  @override
  String get collapse => '收起';

  @override
  String get expand => '展开';

  @override
  String get createPlaylist => '创建歌单';

  @override
  String get likedSongsSidebar => '喜欢的歌曲';

  @override
  String playlistSongsCount(int count) {
    return '歌单 • $count 首歌曲';
  }

  @override
  String get failedToLoadLyrics => '加载歌词失败';

  @override
  String get lyricsNotFoundSubtitle => '无法找到这首歌曲的歌词';

  @override
  String get backToCurrent => '返回当前';

  @override
  String get exitFullscreen => '退出全屏';

  @override
  String get fullscreen => '全屏';

  @override
  String get noLyrics => '无歌词';

  @override
  String get internetRadioMiniPlayer => '网络电台';

  @override
  String get liveBadge => '直播';

  @override
  String get localFilesModeBanner => '本地文件模式';

  @override
  String get offlineModeBanner => '离线模式 - 仅播放已下载的音乐';

  @override
  String get updateAvailable => '有可用更新';

  @override
  String get updateAvailableSubtitle => '新版本的 Musly 已可用！';

  @override
  String updateCurrentVersion(String version) {
    return '当前版本：v$version';
  }

  @override
  String updateLatestVersion(String version) {
    return '最新版本：v$version';
  }

  @override
  String get whatsNew => '更新内容';

  @override
  String get downloadUpdate => '下载';

  @override
  String get remindLater => '稍后提醒';

  @override
  String get seeAll => '查看全部';

  @override
  String get artistDataNotFound => '未找到艺术家';

  @override
  String get addedArtistToQueue => 'Added artist to Queue';

  @override
  String get addedArtistToQueueError => 'Failed adding artist to Queue';

  @override
  String get casting => '投射中';

  @override
  String get dlna => 'DLNA';

  @override
  String get castDlnaBeta => '投射 / DLNA（测试版）';

  @override
  String get chromecast => 'Chromecast';

  @override
  String get dlnaUpnp => 'DLNA / UPnP';

  @override
  String get disconnect => '断开连接';

  @override
  String get searchingDevices => '正在搜索设备';

  @override
  String get castWifiHint => '请确保您的投射/DLNA设备\n处于同一 Wi-Fi 网络上';

  @override
  String connectedToDevice(String name) {
    return '已连接到 $name';
  }

  @override
  String failedToConnectDevice(String name) {
    return '连接到 $name 失败';
  }

  @override
  String get removedFromLikedSongs => '已从喜欢的歌曲中移除';

  @override
  String get addedToLikedSongs => '已添加到喜欢的歌曲';

  @override
  String get enableShuffle => '启用随机播放';

  @override
  String get enableRepeat => '启用循环';

  @override
  String get connecting => '正在连接';

  @override
  String get closeLyrics => '关闭歌词';

  @override
  String errorStartingDownload(Object error) {
    return '开始下载出错：$error';
  }

  @override
  String get errorLoadingGenres => '加载分类出错';

  @override
  String get noGenresFound => '未找到分类';

  @override
  String get noAlbumsInGenre => '该分类中没有专辑';

  @override
  String genreTooltip(int songCount, int albumCount) {
    return '$songCount 首歌曲 • $albumCount 张专辑';
  }

  @override
  String get sectionJukebox => '点唱机模式';

  @override
  String get jukeboxMode => '点唱机模式';

  @override
  String get jukeboxModeSubtitle => '通过服务器而非本设备播放音频';

  @override
  String get openJukeboxController => '打开点唱机控制器';

  @override
  String get jukeboxClearQueue => '清空队列';

  @override
  String get jukeboxShuffleQueue => '随机排序队列';

  @override
  String get jukeboxQueueEmpty => '队列中没有歌曲';

  @override
  String get jukeboxNowPlaying => '正在播放';

  @override
  String get jukeboxQueue => '播放队列';

  @override
  String get jukeboxVolume => '音量';

  @override
  String get playOnJukebox => '在点唱机上播放';

  @override
  String get addToJukeboxQueue => '添加到点唱机队列';

  @override
  String get jukeboxNotSupported =>
      '此服务器不支持点唱机模式。请在服务器配置中启用（例如在 Navidrome 中设置 EnableJukebox = true）。';

  @override
  String get musicFoldersDialogTitle => '选择音乐文件夹';

  @override
  String get musicFoldersHint => '保持全部启用以使用所有文件夹（默认）。';

  @override
  String get musicFoldersSaved => '音乐文件夹选择已保存';

  @override
  String get artworkStyleSection => '封面样式';

  @override
  String get artworkCornerRadius => '圆角';

  @override
  String get artworkCornerRadiusSubtitle => '调整专辑封面的圆角程度';

  @override
  String get artworkCornerRadiusNone => '无';

  @override
  String get artworkShape => '形状';

  @override
  String get artworkShapeRounded => '圆角矩形';

  @override
  String get artworkShapeCircle => '圆形';

  @override
  String get artworkShapeSquare => '方形';

  @override
  String get artworkShadow => '阴影';

  @override
  String get artworkShadowNone => '无';

  @override
  String get artworkShadowSoft => '柔和';

  @override
  String get artworkShadowMedium => '中等';

  @override
  String get artworkShadowStrong => '强烈';

  @override
  String get artworkShadowColor => '阴影颜色';

  @override
  String get artworkShadowColorBlack => '黑色';

  @override
  String get artworkShadowColorAccent => '强调色';

  @override
  String get artworkPreview => '预览';

  @override
  String artworkCornerRadiusLabel(int value) {
    return '$value像素';
  }

  @override
  String get noArtwork => '无封面';

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
  String get transcodingMobileQualitySubtitleSmart => '在移动数据上自动使用';

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
  String get musicCacheTitle => '音乐缓存';

  @override
  String get musicCacheSubtitle => '本地保存歌曲元数据';

  @override
  String get bpmCacheTitle => 'BPM 缓存';

  @override
  String get bpmCacheSubtitle => '本地保存 BPM 分析';

  @override
  String get sectionAboutInformation => 'INFORMATION';

  @override
  String get sectionAboutDeveloper => '开发者';

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
