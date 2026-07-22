import 'package:supabase_flutter/supabase_flutter.dart';

/// Ajoute une ligne au journal d'audit d'un dossier — fonction libre (pas un
/// provider) pour être appelable aussi bien depuis `repairs_provider.dart` que
/// `repair_order_detail_provider.dart` sans dépendance croisée entre les deux.
Future<void> logRepairOrderEvent(
  SupabaseClient client, {
  required String orderId,
  required String actorRole,
  required String eventType,
  required String description,
}) {
  return client.from('repair_order_events').insert({
    'order_id': orderId,
    'actor_role': actorRole,
    'event_type': eventType,
    'description': description,
  });
}
