import 'package:flutter/material.dart';

import '../../auth/application/permission_service.dart';
import '../../auth/domain/user_profile.dart';
import '../data/organization_service.dart';
import 'organization_management_screen.dart';

class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<CreateOrganizationScreen> createState() => _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _service = OrganizationService();
  final _permissionService = PermissionService();

  String? _selectedSuperAdminUserId;
  bool _loading = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    if (!_permissionService.canCreateOrganization(widget.profile)) {
      return const Scaffold(body: Center(child: Text('Access denied')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Organization')),
      body: FutureBuilder<List<UserProfile>>(
        future: _service.listUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Organization name')),
                const SizedBox(height: 12),
                TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedSuperAdminUserId,
                  items: users
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text('${u.email} (${u.globalRole.name})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedSuperAdminUserId = value),
                  decoration: const InputDecoration(labelText: 'Select super admin user'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading || _selectedSuperAdminUserId == null
                      ? null
                      : () async {
                          setState(() {
                            _loading = true;
                            _message = null;
                          });
                          try {
                            final orgId = await _service.createOrganization(
                              createdBy: widget.profile,
                              name: _nameController.text.trim(),
                              description: _descriptionController.text.trim(),
                              superAdminUserId: _selectedSuperAdminUserId!,
                            );
                            if (!mounted) return;
                            setState(() => _message = 'Organization created: $orgId');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrganizationManagementScreen(
                                  profile: widget.profile,
                                  organizationId: orgId,
                                ),
                              ),
                            );
                          } catch (e) {
                            setState(() => _message = 'Failed: $e');
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                  child: const Text('Create organization'),
                ),
                if (_message != null) Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_message!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
