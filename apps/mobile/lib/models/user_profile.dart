class UserProfile {
  const UserProfile({this.displayName = '', this.major = ''});

  final String displayName;
  final String major;

  factory UserProfile.fromMap(Map<String, dynamic> data) => UserProfile(
    displayName: data['namaTampilan'] as String? ?? '',
    major: data['jurusan'] as String? ?? '',
  );

  Map<String, String> toMap() => {
    'namaTampilan': displayName,
    'jurusan': major,
  };
}
