import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/superbase_client.dart';
import '../domain/roles.dart';
import '../domain/user_profile.dart';
import 'dev_bootstrap_config.dart';

class AuthRepository {
  final SupabaseClient _client = Supa.client;

  User? get currentAuthUser => _client.auth.currentUser;

  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Unable to create account.');
    }

    await ensureUserProfile(user: user, provider: 'email');
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        await ensureUserProfile(user: user, provider: 'email');
      }
    } on AuthException {
      final seeded = await _tryBootstrapDeveloper(email: email, password: password);
      if (!seeded) rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: null,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<UserProfile?> fetchCurrentProfile() async {
    final user = currentAuthUser;
    if (user == null) return null;

    final data = await _client.from('users').select().eq('id', user.id).maybeSingle();
    if (data == null) {
      await ensureUserProfile(user: user, provider: _providerFromMetadata(user));
      final created = await _client.from('users').select().eq('id', user.id).single();
      return UserProfile.fromMap(created);
    }

    return UserProfile.fromMap(data);
  }

  Future<void> ensureUserProfile({
    required User user,
    required String provider,
  }) async {
    final existing = await _client.from('users').select('id').eq('id', user.id).maybeSingle();
    if (existing != null) return;

    final email = user.email;
    if (email == null) {
      throw const AuthException('Authenticated account has no email.');
    }

    final isSeedDeveloper =
        email.toLowerCase() == DevBootstrapConfig.seedDeveloperEmail.toLowerCase();

    await _client.from('users').insert({
      'id': user.id,
      'email': email,
      'full_name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
      'auth_provider': provider,
      'global_role': isSeedDeveloper ? GlobalRole.developer.value : GlobalRole.user.value,
    });
  }

  Future<bool> _tryBootstrapDeveloper({
    required String email,
    required String password,
  }) async {
    if (!DevBootstrapConfig.enabled) return false;
    final isSeedEmail = email.toLowerCase() == DevBootstrapConfig.seedDeveloperEmail.toLowerCase();
    final isSeedPassword = password == DevBootstrapConfig.seedDeveloperPassword;
    if (!isSeedEmail || !isSeedPassword) return false;

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': 'Developer Bootstrap'},
    );

    final user = response.user;
    if (user == null) return false;
    await ensureUserProfile(user: user, provider: 'email');

    await _client.auth.signInWithPassword(email: email, password: password);
    return true;
  }

  String _providerFromMetadata(User user) {
    final provider = user.appMetadata['provider'] as String?;
    return provider == 'google' ? 'google' : 'email';
  }
}
