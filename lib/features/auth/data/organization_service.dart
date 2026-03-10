import '../../../core/superbase_client.dart';
import '../../auth/domain/roles.dart';
import '../../auth/domain/user_profile.dart';

class OrganizationService {
  Future<List<UserProfile>> listUsers() async {
    final rows = await Supa.client.from('users').select().order('email');
    return (rows as List).cast<Map<String, dynamic>>().map(UserProfile.fromMap).toList();
  }

  Future<String> createOrganization({
    required UserProfile createdBy,
    required String name,
    required String description,
    required String superAdminUserId,
    bool addDeveloperMembership = false,
  }) async {
    final org = await Supa.client
        .from('organizations')
        .insert({
          'name': name,
          'description': description,
          'created_by_user_id': createdBy.id,
          'super_admin_user_id': superAdminUserId,
        })
        .select('id')
        .single();

    final orgId = org['id'] as String;

    await Supa.client.from('organization_memberships').upsert({
      'organization_id': orgId,
      'user_id': superAdminUserId,
      'org_role': OrganizationRole.superAdmin.value,
      'status': 'active',
    });

    if (addDeveloperMembership && createdBy.id != superAdminUserId) {
      await Supa.client.from('organization_memberships').upsert({
        'organization_id': orgId,
        'user_id': createdBy.id,
        'org_role': OrganizationRole.admin.value,
        'status': 'active',
      });
    }

    return orgId;
  }

  Future<List<Map<String, dynamic>>> listOrganizationMembers(String organizationId) async {
    final rows = await Supa.client
        .from('organization_memberships')
        .select('id,user_id,org_role,status,users(email,full_name)')
        .eq('organization_id', organizationId)
        .order('created_at');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> assignOrganizationRole({
    required String organizationId,
    required String userId,
    required OrganizationRole role,
  }) async {
    await Supa.client.from('organization_memberships').upsert({
      'organization_id': organizationId,
      'user_id': userId,
      'org_role': role.value,
      'status': 'active',
    });
  }
}
