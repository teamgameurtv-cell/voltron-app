import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification.dart';
import '../models/scooter.dart';
import 'auth_provider.dart';
import 'notifications_provider.dart';

class GarageNotifier extends StateNotifier<List<OwnedScooter>> {
  final Ref ref;
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  GarageNotifier(this.ref, this._client) : super([]) {
    _listen();
  }

  void _listen() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    _sub = _client
        .from('scooters')
        .stream(primaryKey: ['id'])
        .eq('owner_id', userId)
        .listen((rows) {
      state = rows.map(OwnedScooter.fromMap).toList();
    });
  }

  Future<void> addScooter({
    required String brand,
    required String model,
    required String serialNumber,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('scooters').insert({
      'owner_id': userId,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
    });
    ref.read(notificationsProvider.notifier).push(
          type: NotificationType.reminder,
          title: 'Contrôle pression des pneus',
          body: 'Pense à vérifier la pression des pneus de ta $brand $model cette semaine — c\'est gratuit en boutique.',
        );
    ref.read(notificationsProvider.notifier).push(
          type: NotificationType.reminder,
          title: 'Prochaine révision programmée',
          body: 'Révision recommandée pour ta $brand $model dans 6 mois.',
        );
  }

  Future<void> removeScooter(String id) async {
    await _client.from('scooters').delete().eq('id', id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final garageProvider = StateNotifierProvider<GarageNotifier, List<OwnedScooter>>(
  (ref) {
    ref.watch(currentUserProvider);
    return GarageNotifier(ref, ref.watch(supabaseProvider));
  },
);
