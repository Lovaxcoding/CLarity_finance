// profile_model.dart

class Profile {
  final String? firstName;
  final String? avatarUrl;

  Profile({
    required this.firstName,
    required this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      firstName: json['first_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}