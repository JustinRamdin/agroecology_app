enum GlobalRole { developer, user }

enum OrganizationRole { superAdmin, admin, groupLeader, member }

extension GlobalRoleX on GlobalRole {
  String get value => switch (this) {
        GlobalRole.developer => 'developer',
        GlobalRole.user => 'user',
      };

  static GlobalRole fromDb(String value) {
    return value == 'developer' ? GlobalRole.developer : GlobalRole.user;
  }
}

extension OrganizationRoleX on OrganizationRole {
  String get value => switch (this) {
        OrganizationRole.superAdmin => 'super_admin',
        OrganizationRole.admin => 'admin',
        OrganizationRole.groupLeader => 'group_leader',
        OrganizationRole.member => 'member',
      };

  static OrganizationRole fromDb(String value) {
    return switch (value) {
      'super_admin' => OrganizationRole.superAdmin,
      'admin' => OrganizationRole.admin,
      'group_leader' => OrganizationRole.groupLeader,
      _ => OrganizationRole.member,
    };
  }
}
