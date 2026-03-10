import 'package:flutter/material.dart';

import '../../auth/application/permission_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_profile.dart';
import 'create_group_screen.dart';
import '../../home/home_screen.dart';
import 'create_organization.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.repository,
    required this.profile,
  });

  final AuthRepository repository;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final permission = PermissionService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard (${profile.globalRole.name})'),
        actions: [
          IconButton(
            onPressed: () => repository.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(profile.email),
              subtitle: Text('Global role: ${profile.globalRole.name}'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
            child: const Text('Open Home'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: permission.canCreateGroup(profile)
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CreateGroupScreen(profile: profile)),
                    );
                  }
                : null,
            child: const Text('Create Group'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: permission.canCreateOrganization(profile)
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CreateOrganizationScreen(profile: profile)),
                    );
                  }
                : null,
            child: const Text('Create Organization (Developer only)'),
          ),
        ],
      ),
    );
  }
}
