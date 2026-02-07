abstract class GoogleCastDiscoveryCriteria {
  static GoogleCastDiscoveryCriteriaInitialize initialize(
          GoogleCastDiscoveryCriteriaInitialize initializeWith) =>
      initializeWith;

  /// this command is useful to native execute a custom command

  static const String kDefaultApplicationId = 'CC1AD845';

  Set<String>? get applicationIds;

  bool? get hasApplicationIds;

  Set<String>? get namespaces;

  bool? get hasNamespaces;

  Set<String>? get allSubtypes;
}

class GoogleCastDiscoveryCriteriaInitialize {
  final Map<String, dynamic> data;
  GoogleCastDiscoveryCriteriaInitialize._({
    required this.data,
  });

  factory GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(
      String applicationID) {
    return GoogleCastDiscoveryCriteriaInitialize._(
      data: <String, dynamic>{
        'method': 'initWithApplicationID',
        'applicationID': applicationID,
      },
    );
  }

  factory GoogleCastDiscoveryCriteriaInitialize.initWithNamespaces(
      Set<String> namespaces) {
    return GoogleCastDiscoveryCriteriaInitialize._(
      data: <String, dynamic>{
        'method': 'initWithNamespaces',
        'namespaces': namespaces,
      },
    );
  }

  Map<String, dynamic> toMap() => data;
}
