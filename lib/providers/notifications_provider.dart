import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification.dart';
import 'auth_provider.dart';

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  NotificationsNotifier(this._client) : super([]) {
    _sub = _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((rows) {
      state = rows.map(AppNotification.fromMap).toList();
    });
  }

  /// Notification personnelle (le client se l'envoie à lui-même : achat, rappel...).
  Future<void> push({
    required NotificationType type,
    required String title,
    required String body,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('notifications').insert({
      'client_id': userId,
      'type': type.name,
      'title': title,
      'body': body,
    });
  }

  /// Diffusion à tous les clients (réservé aux admins par la RLS).
  Future<void> broadcast({
    required NotificationType type,
    required String title,
    required String body,
  }) async {
    await _client.from('notifications').insert({
      'client_id': null,
      'type': type.name,
      'title': title,
      'body': body,
    });
  }

  Future<void> markAllRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('notifications').update({'read': true}).eq('client_id', userId);
  }

  Future<void> markRead(String id) async {
    await _client.from('notifications').update({'read': true}).eq('id', id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(ref.watch(supabaseProvider)),
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.read).length;
});
