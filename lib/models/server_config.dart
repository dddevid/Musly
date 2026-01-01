class ServerConfig {
  final String serverUrl;
  final String username;
  final String password;
  final bool useLegacyAuth;

  ServerConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.useLegacyAuth = false,
  });

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      serverUrl: json['serverUrl'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      useLegacyAuth: json['useLegacyAuth'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'useLegacyAuth': useLegacyAuth,
    };
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