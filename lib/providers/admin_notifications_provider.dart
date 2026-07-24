import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_notification.dart';
import 'auth_provider.dart';

/// Notifie l'admin (ex : acompte payé par un client). Contrairement à
/// [notificationsProvider], qui ne peut viser qu'un client ou tout diffuser,
/// ceci alimente une table dédiée lue uniquement par l'admin (voir
/// admin_notifications dans schema.sql — aucune notion de destinataire admin
/// n'existe côté table "notifications").
Future<void> notifyAdmin(
  SupabaseClient client, {
  required String title,
  required String body,
  String? orderId,
}) async {
  await client.from('admin_notifications').insert({
    'title': title,
    'body': body,
    'order_id': orderId,
  });
}

class AdminNotificationsNotifier
    extends StateNotifier<List<AdminNotification>> {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  AdminNotificationsNotifier(this._client) : super([]) {
    _sub = _client
        .from('admin_notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((rows) {
          state = rows.map(AdminNotification.fromMap).toList();
        });
  }

  Future<void> markRead(String id) async {
    await _client
        .from('admin_notifications')
        .update({'read': true})
        .eq('id', id);
  }

  Future<void> markAllRead() async {
    await _client
        .from('admin_notifications')
        .update({'read': true})
        .eq('read', false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final adminNotificationsProvider =
    StateNotifierProvider<AdminNotificationsNotifier, List<AdminNotification>>(
      (ref) => AdminNotificationsNotifier(ref.watch(supabaseProvider)),
    );

final unreadAdminNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(adminNotificationsProvider).where((n) => !n.read).length;
});
