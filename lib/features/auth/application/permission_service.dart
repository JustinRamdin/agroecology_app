import '../../../core/superbase_client.dart';
import '../domain/roles.dart';
import '../domain/user_profile.dart';

class PermissionService {
  bool isDeveloper(UserProfile user) => user.globalRole == GlobalRole.developer;

  bool canCreateOrganization(UserProfile user) => isDeveloper(user);

  bool canCreateGroup(UserProfile user) =>
      user.globalRole == GlobalRole.user || user.globalRole == GlobalRole.developer;

  Future<bool> isOrganizationSuperAdmin({
    required UserProfile user,
    required String organizationId,
  }) async {
    final row = await Supa.client
        .from('organization_memberships')
        .select('org_role,status')
        .eq('organization_id', organizationId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) return false;
    return row['status'] == 'active' && row['org_role'] == OrganizationRole.superAdmin.value;
  }

  Future<bool> canAssignOrganizationRoles({
    required UserProfile user,
    required String organizationId,
  }) {
    return isOrganizationSuperAdmin(user: user, organizationId: organizationId);
  }
}
