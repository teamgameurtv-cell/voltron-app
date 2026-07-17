import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/mock_rewards.dart';
import '../models/app_notification.dart';
import '../models/reward.dart';
import 'auth_provider.dart';
import 'notifications_provider.dart';

class SubscriptionNotifier extends StateNotifier<CarePlan?> {
  final Ref ref;
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  SubscriptionNotifier(this.ref, this._client) : super(null) {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      _sub = _client.from('subscriptions').stream(primaryKey: ['id']).eq('client_id', userId).listen((rows) {
        if (rows.isEmpty) {
          state = null;
        } else {
          final planId = rows.first['plan_id'] as String;
          state = mockCarePlans.firstWhere((p) => p.id == planId, orElse: () => mockCarePlans.first);
        }
      });
    }
  }

  Future<void> subscribe(CarePlan plan) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('subscriptions').upsert({'client_id': userId, 'plan_id': plan.id}, onConflict: 'client_id');
    ref.read(notificationsProvider.notifier).push(
          type: NotificationType.loyalty,
          title: 'Voltron Care activé',
          body: 'Ton abonnement ${plan.name} est actif. Prends soin de ta trottinette en toute sérénité !',
        );
  }

  Future<void> cancel() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('subscriptions').delete().eq('client_id', userId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, CarePlan?>(
  (ref) {
    ref.watch(currentUserProvider);
    return SubscriptionNotifier(ref, ref.watch(supabaseProvider));
  },
);
