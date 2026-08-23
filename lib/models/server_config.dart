class ServerConfig {
  final String serverUrl;
  final String? lanUrl;
  final String username;
  final String password;
  final bool useLegacyAuth;
  final bool allowSelfSignedCertificates;
  final List<String> selectedMusicFolderIds;
  final String? serverType;
  final String? serverVersion;
  final String? customCertificatePath; 
  final String? clientCertificatePath; 
  final String? clientCertificatePassword;
  final String? name;
  final String serverFamily;
  final String? apiToken;
  final String? userId;

  ServerConfig({
    required this.serverUrl,
    this.lanUrl,
    required this.username,
    required this.password,
    this.useLegacyAuth = false,
    this.allowSelfSignedCertificates = false,
    this.selectedMusicFolderIds = const [],
    this.serverType,
    this.serverVersion,
    this.customCertificatePath,
    this.clientCertificatePath,
    this.clientCertificatePassword,
    this.name,
    this.serverFamily = 'subsonic',
    this.apiToken,
    this.userId,
  });

  bool get isJellyfin => serverFamily == 'jellyfin';
  bool get isYoutube => serverFamily == 'youtube';
  bool get isLocal => serverType == 'local' || serverFamily == 'local';

  String get displayServerName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (isYoutube) return 'Web Stream';
    if (isJellyfin) return 'Jellyfin';
    if (serverType != null && serverType!.isNotEmpty) return serverType!;
    return 'Navidrome / Subsonic';
  }

  String get displayUrl {
    if (isYoutube) return 'Web Stream';
    if (serverUrl.isEmpty) return 'Not configured';
    try {
      final uri = Uri.parse(serverUrl);
      if (uri.host.isNotEmpty) return uri.host;
    } catch (_) {}
    return serverUrl;
  }

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      serverUrl: json['serverUrl'] ?? '',
      lanUrl: json['lanUrl'] as String?,
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      useLegacyAuth: json['useLegacyAuth'] ?? false,
      allowSelfSignedCertificates: json['allowSelfSignedCertificates'] ?? false,
      selectedMusicFolderIds:
          (json['selectedMusicFolderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      serverType: json['serverType'],
      serverVersion: json['serverVersion'],
      customCertificatePath: json['customCertificatePath'],
      clientCertificatePath: json['clientCertificatePath'],
      clientCertificatePassword: json['clientCertificatePassword'],
      name: json['name'] as String?,
      serverFamily: json['serverFamily'] as String? ?? 'subsonic',
      apiToken: json['apiToken'] as String?,
      userId: json['userId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'lanUrl': lanUrl,
      'username': username,
      'password': password,
      'useLegacyAuth': useLegacyAuth,
      'allowSelfSignedCertificates': allowSelfSignedCertificates,
      'selectedMusicFolderIds': selectedMusicFolderIds,
      'serverType': serverType,
      'serverVersion': serverVersion,
      'customCertificatePath': customCertificatePath,
      'clientCertificatePath': clientCertificatePath,
      'clientCertificatePassword': clientCertificatePassword,
      'name': name,
      'serverFamily': serverFamily,
      'apiToken': apiToken,
      'userId': userId,
    };
  }

  ServerConfig copyWith({
    String? serverUrl,
    String? lanUrl,
    String? username,
    String? password,
    bool? useLegacyAuth,
    bool? allowSelfSignedCertificates,
    List<String>? selectedMusicFolderIds,
    String? serverType,
    String? serverVersion,
    String? customCertificatePath,
    String? clientCertificatePath,
    String? clientCertificatePassword,
    String? name,
    String? serverFamily,
    String? apiToken,
    String? userId,
  }) {
    return ServerConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      lanUrl: lanUrl ?? this.lanUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      useLegacyAuth: useLegacyAuth ?? this.useLegacyAuth,
      allowSelfSignedCertificates:
          allowSelfSignedCertificates ?? this.allowSelfSignedCertificates,
      selectedMusicFolderIds:
          selectedMusicFolderIds ?? this.selectedMusicFolderIds,
      serverType: serverType ?? this.serverType,
      serverVersion: serverVersion ?? this.serverVersion,
      customCertificatePath:
          customCertificatePath ?? this.customCertificatePath,
      clientCertificatePath:
          clientCertificatePath ?? this.clientCertificatePath,
      clientCertificatePassword:
          clientCertificatePassword ?? this.clientCertificatePassword,
      name: name ?? this.name,
      serverFamily: serverFamily ?? this.serverFamily,
      apiToken: apiToken ?? this.apiToken,
      userId: userId ?? this.userId,
    );
  }

  String get normalizedUrl {
    String url = serverUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  String? get normalizedLanUrl {
    if (lanUrl == null || lanUrl!.trim().isEmpty) return null;
    String url = lanUrl!.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  bool get isValid {
    if (isYoutube || isLocal) {
      return serverUrl.isNotEmpty;
    }
    return serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
  }
}
