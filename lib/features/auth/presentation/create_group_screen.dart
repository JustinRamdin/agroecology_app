import 'package:flutter/material.dart';

import '../../auth/application/permission_service.dart';
import '../../auth/domain/user_profile.dart';
import '../data/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _orgController = TextEditingController();
  final _service = GroupService();
  final _permissionService = PermissionService();

  bool _loading = false;
  String? _message;

  Future<void> _submit() async {
    if (!_permissionService.canCreateGroup(widget.profile)) {
      setState(() => _message = 'You do not have permission to create groups.');
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final groupId = await _service.createGroup(
        creator: widget.profile,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        organizationId: _orgController.text.trim().isEmpty ? null : _orgController.text.trim(),
      );
      setState(() => _message = 'Group created successfully: $groupId');
    } catch (e) {
      setState(() => _message = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Group name')),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(
              controller: _orgController,
              decoration: const InputDecoration(
                labelText: 'Organization ID (optional)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loading ? null : _submit, child: const Text('Create group')),
            if (_message != null) Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!),
            ),
          ],
        ),
      ),
    );
  }
}
