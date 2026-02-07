import 'dart:convert';

import 'package:flutter_chrome_cast/common/user_action.dart';

class UserActionState {
  ///User actions.
  final Map<String, dynamic>? customData;

  final UserAction? userAction;
  UserActionState({
    this.customData,
    this.userAction,
  });

  Map<String, dynamic> toMap() {
    return {
      'customData': customData,
      'userAction': userAction?.name,
    };
  }

  factory UserActionState.fromMap(Map<String, dynamic> map) {
    return UserActionState(
      customData: Map<String, dynamic>.from(map['customData']),
      userAction: map['userAction'] != null
          ? UserAction.fromMap(map['userAction'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserActionState.fromJson(String source) =>
      UserActionState.fromMap(json.decode(source));
}
