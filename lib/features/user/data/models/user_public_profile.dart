class UserPublicProfile {

  const UserPublicProfile({
    required this.uid,
    required this.nickname,
    required this.name,
    required this.lastName,
    this.photoUrl,
  });

  final String uid;
  final String nickname;
  final String name;
  final String lastName;
  final String? photoUrl;

  factory UserPublicProfile.fromMap(Map<String, dynamic> map) => UserPublicProfile(
    uid: map['uid'] as String,
    nickname: map['nickname'] as String,
    name: map['name'] as String,
    lastName: map['lastName'] as String,
    photoUrl: map['photoUrl'] as String?,
  );


}