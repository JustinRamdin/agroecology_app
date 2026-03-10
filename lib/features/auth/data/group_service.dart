import '../../../core/superbase_client.dart';
import '../../auth/domain/user_profile.dart';

class GroupService {
  Future<String> createGroup({
    required UserProfile creator,
    required String name,
    required String description,
    String? organizationId,
  }) async {
    final row = await Supa.client
        .from('groups')
        .insert({
          'name': name,
          'description': description,
          'created_by_user_id': creator.id,
          'organization_id': organizationId,
        })
        .select('id')
        .single();

    final groupId = row['id'] as String;
    await Supa.client.from('group_memberships').upsert({
      'group_id': groupId,
      'user_id': creator.id,
      'role_in_group': 'leader',
    });

    return groupId;
  }
}
