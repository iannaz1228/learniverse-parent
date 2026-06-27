import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_bootstrap.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    final client = ref.watch(supabaseClientProvider);
    if (client == null) return AuthStatus.unauthenticated;
    _listenAuthChanges(client);
    final session = client.auth.currentSession;
    return session != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  void _listenAuthChanges(SupabaseClient client) {
    client.auth.onAuthStateChange.listen((data) {
      state = data.session != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    });
  }

  Future<String?> signIn(String email, String password) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return 'No connection';
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(String email, String password, String name) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return 'No connection';
    try {
      await client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name, 'role': 'parent'},
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    final client = ref.read(supabaseClientProvider);
    await client?.auth.signOut();
  }

  String? get currentUserId {
    final client = ref.read(supabaseClientProvider);
    return client?.auth.currentUser?.id;
  }

  String? get currentUserEmail {
    final client = ref.read(supabaseClientProvider);
    return client?.auth.currentUser?.email;
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);
