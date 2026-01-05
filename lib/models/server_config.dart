class ServerConfig {
  final String serverUrl;
  final String username;
  final String password;
  final bool useLegacyAuth;
  final List<String> selectedMusicFolderIds;
  final String? serverType;
  final String? serverVersion;

  ServerConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.useLegacyAuth = false,
    this.selectedMusicFolderIds = const [],
    this.serverType,
    this.serverVersion,
  });

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      serverUrl: json['serverUrl'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      useLegacyAuth: json['useLegacyAuth'] ?? false,
      selectedMusicFolderIds:
          (json['selectedMusicFolderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      serverType: json['serverType'],
      serverVersion: json['serverVersion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'useLegacyAuth': useLegacyAuth,
      'selectedMusicFolderIds': selectedMusicFolderIds,
      'serverType': serverType,
      'serverVersion': serverVersion,
    };
  }

  ServerConfig copyWith({
    String? serverUrl,
    String? username,
    String? password,
    bool? useLegacyAuth,
    List<String>? selectedMusicFolderIds,
    String? serverType,
    String? serverVersion,
  }) {
    return ServerConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      useLegacyAuth: useLegacyAuth ?? this.useLegacyAuth,
      selectedMusicFolderIds:
          selectedMusicFolderIds ?? this.selectedMusicFolderIds,
      serverType: serverType ?? this.serverType,
      serverVersion: serverVersion ?? this.serverVersion,
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

  bool get isValid {
    return serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
  }
}
