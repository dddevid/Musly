class GoogleCastRequest {
  final bool inProgress;
  final bool isExternal;
  final int requestID;
  final String? error;
  GoogleCastRequest({
    required this.inProgress,
    required this.isExternal,
    required this.requestID,
    this.error,
  });
}
