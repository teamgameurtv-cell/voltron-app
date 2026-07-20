import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_models.dart';
import '../models/client.dart';
import '../models/scooter.dart';
import 'auth_provider.dart';

/// Émet à chaque changement sur `profiles` — utilisé uniquement pour déclencher
/// le recalcul des providers de recherche ci-dessous (la recherche ilike/or
/// n'est pas exprimable directement avec .stream()).
final _profilesChangedProvider = StreamProvider<void>((ref) {
  return ref.watch(supabaseProvider).from('profiles').stream(primaryKey: ['id']).map((_) {});
});

final clientSearchProvider = FutureProvider.family<List<Client>, String>((ref, query) async {
  ref.watch(_profilesChangedProvider);
  final client = ref.watch(supabaseProvider);
  final q = query.trim();
  final rows = q.isEmpty
      ? await client.from('profiles').select().order('created_at', ascending: false).limit(30)
      : await client.from('profiles').select().or('name.ilike.%$q%,email.ilike.%$q%').limit(30);
  return rows.map(Client.fromMap).toList();
});

/// Fiche d'un client précis, mise à jour en direct (utilisée après une modification admin).
final clientByIdProvider = StreamProvider.family<Client?, String>((ref, clientId) {
  return ref
      .watch(supabaseProvider)
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', clientId)
      .map((rows) => rows.isEmpty ? null : Client.fromMap(rows.first));
});

final clientScootersProvider = StreamProvider.family<List<OwnedScooter>, String>((ref, clientId) {
  return ref
      .watch(supabaseProvider)
      .from('scooters')
      .stream(primaryKey: ['id'])
      .eq('owner_id', clientId)
      .map((rows) => rows.map(OwnedScooter.fromMap).toList());
});

final _invoicesChangedProvider = StreamProvider<void>((ref) {
  return ref.watch(supabaseProvider).from('invoices').stream(primaryKey: ['id']).map((_) {});
});

final clientInvoicesProvider = FutureProvider.family<List<Invoice>, String>((ref, clientId) async {
  ref.watch(_invoicesChangedProvider);
  final rows = await ref
      .watch(supabaseProvider)
      .from('invoices')
      .select()
      .eq('client_id', clientId)
      .order('invoice_date', ascending: false);
  return rows.map(Invoice.fromMap).toList();
});

/// Actions admin sur la fiche client : modifier ses infos, gérer ses véhicules.
class AdminCrmActions {
  final SupabaseClient _client;

  AdminCrmActions(this._client);

  Future<void> updateClientProfile(String clientId, {String? name, String? firstName, String? email, String? phone}) async {
    await _client.from('profiles').update({
      if (name != null) 'name': name,
      if (firstName != null) 'first_name': firstName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    }).eq('id', clientId);
  }

  Future<void> addScooter(
    String clientId, {
    required String brand,
    required String model,
    required String serialNumber,
  }) async {
    await _client.from('scooters').insert({
      'owner_id': clientId,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
    });
  }

  Future<void> updateScooter(
    String scooterId, {
    required String brand,
    required String model,
    required String serialNumber,
  }) async {
    await _client.from('scooters').update({
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
    }).eq('id', scooterId);
  }

  Future<void> removeScooter(String scooterId) async {
    await _client.from('scooters').delete().eq('id', scooterId);
  }
}

final adminCrmActionsProvider = Provider<AdminCrmActions>((ref) => AdminCrmActions(ref.watch(supabaseProvider)));
