import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reward.dart';
import 'auth_provider.dart';

class RewardsNotifier extends StateNotifier<List<Reward>> {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  RewardsNotifier(this._client) : super([]) {
    _sub = _client.from('rewards').stream(primaryKey: ['id']).listen((rows) {
      state = rows.map(Reward.fromMap).toList();
    });
  }

  Future<void> addReward({required String label, required int points}) async {
    await _client.from('rewards').insert({'label': label, 'points': points, 'icon_name': 'card_giftcard'});
  }

  Future<void> updateReward(Reward reward) async {
    await _client.from('rewards').update({'label': reward.label, 'points': reward.points}).eq('id', reward.id);
  }

  Future<void> removeReward(String id) async {
    await _client.from('rewards').delete().eq('id', id);
  }

  /// Débite les points et enregistre l'échange côté serveur (vérifie le solde).
  /// Lève une [PostgrestException] si le solde est insuffisant.
  Future<RewardRedemption> redeem(String rewardId) async {
    final rows = await _client.rpc('redeem_reward', params: {'p_reward_id': rewardId});
    final row = (rows as List).first as Map<String, dynamic>;
    return RewardRedemption.fromMap(row);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final rewardsProvider = StateNotifierProvider<RewardsNotifier, List<Reward>>(
  (ref) => RewardsNotifier(ref.watch(supabaseProvider)),
);
