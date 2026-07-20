import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

/// Identifiants des objectifs fidélité, réclamés une seule fois par client via
/// la fonction Postgres `claim_loyalty_goal` (idempotente et sécurisée côté serveur).
final claimedLoyaltyGoalsProvider = StreamProvider<Set<String>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return Stream.value(const <String>{});
  return ref
      .watch(supabaseProvider)
      .from('loyalty_goal_claims')
      .stream(primaryKey: ['id'])
      .eq('client_id', userId)
      .map((rows) => rows.map((r) => r['goal_id'] as String).toSet());
});

/// Historique complet des points gagnés (un objectif réclamé = une ligne).
final loyaltyHistoryProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return Stream.value(const <Map<String, dynamic>>[]);
  return ref
      .watch(supabaseProvider)
      .from('loyalty_goal_claims')
      .stream(primaryKey: ['id'])
      .eq('client_id', userId)
      .order('claimed_at', ascending: false);
});

class LoyaltyGoalsNotifier {
  final SupabaseClient _client;

  LoyaltyGoalsNotifier(this._client);

  /// Retourne true si les points viennent d'être crédités, false si déjà réclamé.
  Future<bool> claim(String goalId, int points) async {
    final result = await _client.rpc('claim_loyalty_goal', params: {
      'p_goal_id': goalId,
      'p_points': points,
    });
    return result as bool;
  }
}

final loyaltyGoalsNotifierProvider = Provider<LoyaltyGoalsNotifier>(
  (ref) => LoyaltyGoalsNotifier(ref.watch(supabaseProvider)),
);
