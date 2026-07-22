import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.session?.user ??
      Supabase.instance.client.auth.currentUser;
});

class AuthNotifier {
  final SupabaseClient _client;

  AuthNotifier(this._client);

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Connexion impossible. Réessaie.';
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String firstName,
    String address = '',
    DateTime? dateOfBirth,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'first_name': firstName,
          'address': address,
          'date_of_birth':
              dateOfBirth?.toIso8601String().split('T').first ?? '',
        },
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Inscription impossible. Réessaie.';
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}

final authNotifierProvider = Provider<AuthNotifier>(
  (ref) => AuthNotifier(ref.watch(supabaseProvider)),
);
