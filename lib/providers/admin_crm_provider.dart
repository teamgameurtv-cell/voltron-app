import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_models.dart';
import '../models/client.dart';
import '../models/scooter.dart';
import 'auth_provider.dart';

final clientSearchProvider = FutureProvider.family<List<Client>, String>((ref, query) async {
  final client = ref.watch(supabaseProvider);
  final q = query.trim();
  final rows = q.isEmpty
      ? await client.from('profiles').select().order('created_at', ascending: false).limit(30)
      : await client.from('profiles').select().or('name.ilike.%$q%,email.ilike.%$q%').limit(30);
  return rows.map(Client.fromMap).toList();
});

final clientScootersProvider = FutureProvider.family<List<OwnedScooter>, String>((ref, clientId) async {
  final rows = await ref.watch(supabaseProvider).from('scooters').select().eq('owner_id', clientId);
  return rows.map(OwnedScooter.fromMap).toList();
});

final clientInvoicesProvider = FutureProvider.family<List<Invoice>, String>((ref, clientId) async {
  final rows = await ref
      .watch(supabaseProvider)
      .from('invoices')
      .select()
      .eq('client_id', clientId)
      .order('invoice_date', ascending: false);
  return rows.map(Invoice.fromMap).toList();
});
