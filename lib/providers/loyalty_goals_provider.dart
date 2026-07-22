import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart' show parseBookingDay;
import 'account_provider.dart';
import 'auth_provider.dart';

/// Une ligne de l'historique des points : soit un objectif fidélité réclamé
/// ([isGoal] vrai, [label] est alors un id d'objectif à résoudre côté UI),
/// soit un achat/facture ayant crédité des points ([label] déjà le libellé
/// affichable, ex. un achat en magasin enregistré par l'admin).
typedef LoyaltyHistoryEntry = ({
  String label,
  int points,
  DateTime date,
  bool isGoal,
});

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

final _goalClaimsRowsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return Stream.value(const <Map<String, dynamic>>[]);
  return ref
      .watch(supabaseProvider)
      .from('loyalty_goal_claims')
      .stream(primaryKey: ['id'])
      .eq('client_id', userId)
      .order('claimed_at', ascending: false);
});

/// Historique complet des points gagnés : objectifs fidélité réclamés ET
/// achats/factures ayant crédité des points (ex. achat en magasin enregistré
/// par l'admin), fusionnés et triés par date, pour que le client retrouve
/// bien tous ses gains de points au même endroit.
final loyaltyHistoryProvider = Provider<List<LoyaltyHistoryEntry>>((ref) {
  final goalClaims = ref.watch(_goalClaimsRowsProvider).valueOrNull ?? const [];
  final invoices = ref.watch(invoicesProvider).valueOrNull ?? const [];

  final entries = <LoyaltyHistoryEntry>[
    for (final row in goalClaims)
      (
        label: row['goal_id'] as String,
        points: row['points'] as int,
        date: DateTime.parse(row['claimed_at'] as String),
        isGoal: true,
      ),
    for (final invoice in invoices)
      if (invoice.pointsCredited != 0)
        (
          label: invoice.label,
          points: invoice.pointsCredited,
          date: parseBookingDay(invoice.date) ?? DateTime.now(),
          isGoal: false,
        ),
  ];
  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
});

class LoyaltyGoalsNotifier {
  final SupabaseClient _client;

  LoyaltyGoalsNotifier(this._client);

  /// Retourne true si les points viennent d'être crédités, false si déjà réclamé.
  Future<bool> claim(String goalId, int points) async {
    final result = await _client.rpc(
      'claim_loyalty_goal',
      params: {'p_goal_id': goalId, 'p_points': points},
    );
    return result as bool;
  }
}

final loyaltyGoalsNotifierProvider = Provider<LoyaltyGoalsNotifier>(
  (ref) => LoyaltyGoalsNotifier(ref.watch(supabaseProvider)),
);
