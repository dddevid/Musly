/// User actions.
enum UserAction {
//User indicates a like preference for the currently playing content.

  LIKE,

  ///User indicates a dislike preference for the currently playing content.

  DISLIKE,

  ///User wants to follow or star currently playing content.

  FOLLOW,

  ///User wants to stop following currently playing content.

  UNFOLLOW;

  factory UserAction.fromMap(String value) {
    return values.firstWhere((element) => element.toString() == value);
  }

  @override
  String toString() {
    return name;
  }
}
