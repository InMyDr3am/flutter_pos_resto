class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String role;
  final DateTime createdAt;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        role: json['role'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'role': role,
      };

  bool get isOwner => role == 'owner';
  bool get isKasir => role == 'kasir';
  bool get isKaryawan => role == 'karyawan';
}
