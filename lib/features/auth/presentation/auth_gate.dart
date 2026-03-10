import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dashboard/presentation/dashboard_screen.dart';
import '../data/auth_repository.dart';
import '../domain/user_profile.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = widget.repository.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      initialData: AuthState(AuthChangeEvent.initialSession, Supabase.instance.client.auth.currentSession),
      builder: (context, snapshot) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          return LoginScreen(repository: widget.repository);
        }

        return FutureBuilder<UserProfile?>(
          future: widget.repository.fetchCurrentProfile(),
          builder: (context, profileSnapshot) {
            if (!profileSnapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return DashboardScreen(
              repository: widget.repository,
              profile: profileSnapshot.data!,
            );
          },
        );
      },
    );
  }
}
