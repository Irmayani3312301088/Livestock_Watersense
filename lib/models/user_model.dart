class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String role;
  final String password;
  final String? profileImage; // optional gambar profile dari assets

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    required this.password,
    this.profileImage,
  });
}
