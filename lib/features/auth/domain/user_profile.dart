import 'roles.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.authProvider,
    required this.globalRole,
  });

  final String id;
  final String email;
  final String? fullName;
  final String authProvider;
  final GlobalRole globalRole;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      authProvider: map['auth_provider'] as String,
      globalRole: GlobalRoleX.fromDb(map['global_role'] as String? ?? 'user'),
    );
  }
}
