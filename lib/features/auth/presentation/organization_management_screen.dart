import 'package:flutter/material.dart';

import '../../auth/application/permission_service.dart';
import '../../auth/domain/roles.dart';
import '../../auth/domain/user_profile.dart';
import '../data/organization_service.dart';

class OrganizationManagementScreen extends StatefulWidget {
  const OrganizationManagementScreen({
    super.key,
    required this.profile,
    required this.organizationId,
  });

  final UserProfile profile;
  final String organizationId;

  @override
  State<OrganizationManagementScreen> createState() => _OrganizationManagementScreenState();
}

class _OrganizationManagementScreenState extends State<OrganizationManagementScreen> {
  final _service = OrganizationService();
  final _permissionService = PermissionService();
  String? _feedback;

  Future<void> _assignRole({
    required String userId,
    required OrganizationRole role,
  }) async {
    final allowed = await _permissionService.canAssignOrganizationRoles(
      user: widget.profile,
      organizationId: widget.organizationId,
    );
    if (!allowed) {
      setState(() => _feedback = 'Only organization super admin can assign roles.');
      return;
    }

    await _service.assignOrganizationRole(
      organizationId: widget.organizationId,
      userId: userId,
      role: role,
    );
    setState(() => _feedback = 'Role updated for user $userId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organization Management')),
      body: FutureBuilder<bool>(
        future: _permissionService.isOrganizationSuperAdmin(
          user: widget.profile,
          organizationId: widget.organizationId,
        ),
        builder: (context, permissionSnapshot) {
          if (!permissionSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (permissionSnapshot.data == false) {
            return const Center(child: Text('Only organization super admin can manage members.'));
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _service.listOrganizationMembers(widget.organizationId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final members = snapshot.data!;
              return Column(
            children: [
              if (_feedback != null) Padding(padding: const EdgeInsets.all(8), child: Text(_feedback!)),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final row = members[index];
                    final userData = row['users'] as Map<String, dynamic>?;
                    final userId = row['user_id'] as String;
                    return ListTile(
                      title: Text(userData?['email'] as String? ?? userId),
                      subtitle: Text('Role: ${row['org_role']} • Status: ${row['status']}'),
                      trailing: PopupMenuButton<OrganizationRole>(
                        onSelected: (role) => _assignRole(userId: userId, role: role),
                        itemBuilder: (_) => OrganizationRole.values
                            .map(
                              (role) => PopupMenuItem(
                                value: role,
                                child: Text(role.value),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
              );
            },
          );
        },
      ),
    );
  }
}
