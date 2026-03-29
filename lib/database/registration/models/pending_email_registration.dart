class PendingEmailRegistration {
  const PendingEmailRegistration({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.name,
    required this.lastName,
    required this.createdAt,
  });

  final String uid;
  final String email;
  final String nickname;
  final String name;
  final String lastName;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'nickname': nickname,
        'name': name,
        'lastName': lastName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingEmailRegistration.fromJson(Map<String, dynamic> json) {
    return PendingEmailRegistration(
      uid: json['uid'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      name: json['name'] as String,
      lastName: json['lastName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
