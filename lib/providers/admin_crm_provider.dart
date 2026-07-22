import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/mock_rewards.dart';
import '../models/account_models.dart';
import '../models/client.dart';
import '../models/reward.dart';
import '../models/scooter.dart';
import 'auth_provider.dart';

/// Émet à chaque changement sur `profiles` — utilisé uniquement pour déclencher
/// le recalcul des providers de recherche ci-dessous (la recherche ilike/or
/// n'est pas exprimable directement avec .stream()).
final _profilesChangedProvider = StreamProvider<void>((ref) {
  return ref
      .watch(supabaseProvider)
      .from('profiles')
      .stream(primaryKey: ['id'])
      .map((_) {});
});

final clientSearchProvider = FutureProvider.family<List<Client>, String>((
  ref,
  query,
) async {
  ref.watch(_profilesChangedProvider);
  final client = ref.watch(supabaseProvider);
  final rows = await client.rpc('search_clients', params: {'q': query.trim()});
  return (rows as List)
      .map((row) => Client.fromMap(row as Map<String, dynamic>))
      .toList();
});

/// Fiche d'un client précis, mise à jour en direct (utilisée après une modification admin).
final clientByIdProvider = StreamProvider.family<Client?, String>((
  ref,
  clientId,
) {
  return ref
      .watch(supabaseProvider)
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', clientId)
      .map((rows) => rows.isEmpty ? null : Client.fromMap(rows.first));
});

final clientScootersProvider =
    StreamProvider.family<List<OwnedScooter>, String>((ref, clientId) {
      return ref
          .watch(supabaseProvider)
          .from('scooters')
          .stream(primaryKey: ['id'])
          .eq('owner_id', clientId)
          .map((rows) => rows.map(OwnedScooter.fromMap).toList());
    });

final _invoicesChangedProvider = StreamProvider<void>((ref) {
  return ref
      .watch(supabaseProvider)
      .from('invoices')
      .stream(primaryKey: ['id'])
      .map((_) {});
});

final clientInvoicesProvider = FutureProvider.family<List<Invoice>, String>((
  ref,
  clientId,
) async {
  ref.watch(_invoicesChangedProvider);
  final rows = await ref
      .watch(supabaseProvider)
      .from('invoices')
      .select()
      .eq('client_id', clientId)
      .order('invoice_date', ascending: false);
  return rows.map(Invoice.fromMap).toList();
});

/// Ensemble des client_id ayant un abonnement Voltron Care actif, tous
/// confondus — utilisé pour prioriser/badger leurs tickets support.
final subscribedClientIdsProvider = StreamProvider<Set<String>>((ref) {
  return ref
      .watch(supabaseProvider)
      .from('subscriptions')
      .stream(primaryKey: ['id'])
      .map((rows) => rows.map((r) => r['client_id'] as String).toSet());
});

/// Formule Voltron Care active d'un client précis (Essentiel/Plus), ou null.
final clientSubscriptionProvider = StreamProvider.family<CarePlan?, String>((
  ref,
  clientId,
) {
  return ref
      .watch(supabaseProvider)
      .from('subscriptions')
      .stream(primaryKey: ['id'])
      .eq('client_id', clientId)
      .map((rows) {
        if (rows.isEmpty) return null;
        final planId = rows.first['plan_id'] as String;
        return mockCarePlans.firstWhere(
          (p) => p.id == planId,
          orElse: () => mockCarePlans.first,
        );
      });
});

/// Actions admin sur la fiche client : modifier ses infos, gérer ses véhicules.
class AdminCrmActions {
  final SupabaseClient _client;

  AdminCrmActions(this._client);

  /// La date de naissance n'est modifiable que par ici (fiche client admin) :
  /// le client ne peut ni la saisir ni la corriger depuis son propre compte.
  Future<void> updateClientProfile(
    String clientId, {
    String? name,
    String? firstName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
  }) async {
    await _client
        .from('profiles')
        .update({
          if (name != null) 'name': name,
          if (firstName != null) 'first_name': firstName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (dateOfBirth != null)
            'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
        })
        .eq('id', clientId);
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

  /// Chaque champ est optionnel pour permettre une édition ciblée (un seul
  /// champ à la fois) depuis la fiche détaillée du véhicule.
  Future<void> updateScooter(
    String scooterId, {
    String? brand,
    String? model,
    String? serialNumber,
    DateTime? purchaseDate,
  }) async {
    await _client
        .from('scooters')
        .update({
          if (brand != null) 'brand': brand,
          if (model != null) 'model': model,
          if (serialNumber != null) 'serial_number': serialNumber,
          if (purchaseDate != null)
            'purchase_date': purchaseDate.toIso8601String().split('T').first,
        })
        .eq('id', scooterId);
  }

  Future<void> removeScooter(String scooterId) async {
    await _client.from('scooters').delete().eq('id', scooterId);
  }

  /// Permet à l'admin de changer la photo d'un véhicule depuis sa fiche.
  Future<String> updateScooterImage(
    String scooterId,
    Uint8List bytes,
    String fileExtension,
  ) async {
    final path =
        '$scooterId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    await _client.storage
        .from('scooter-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = _client.storage.from('scooter-images').getPublicUrl(path);
    await _client
        .from('scooters')
        .update({'image_url': url})
        .eq('id', scooterId);
    return url;
  }

  /// Enregistre un achat fait en magasin (via SumUp) : crée la facture et
  /// crédite automatiquement les points fidélité (1€ = 1 pt).
  Future<void> addInvoice(
    String clientId, {
    required String label,
    required String invoiceDate,
    required double amount,
    String? fileUrl,
  }) async {
    await _client.rpc(
      'admin_add_invoice',
      params: {
        'p_client_id': clientId,
        'p_label': label,
        'p_invoice_date': invoiceDate,
        'p_amount': amount,
        'p_file_url': fileUrl,
      },
    );
  }

  /// Corrige une facture déjà saisie : les points fidélité sont réajustés
  /// (différence entre l'ancien et le nouveau montant), jamais recrédités en double.
  Future<void> updateInvoice(
    String invoiceId, {
    required String label,
    required String invoiceDate,
    required double amount,
    String? fileUrl,
  }) async {
    await _client.rpc(
      'admin_update_invoice',
      params: {
        'p_invoice_id': invoiceId,
        'p_label': label,
        'p_invoice_date': invoiceDate,
        'p_amount': amount,
        'p_file_url': fileUrl,
      },
    );
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await _client.rpc(
      'admin_delete_invoice',
      params: {'p_invoice_id': invoiceId},
    );
  }

  /// Envoie le justificatif (facture SumUp) dans le stockage Supabase.
  Future<String> uploadInvoiceFile(Uint8List bytes, String fileName) async {
    final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage
        .from('invoice-files')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('invoice-files').getPublicUrl(path);
  }
}

final adminCrmActionsProvider = Provider<AdminCrmActions>(
  (ref) => AdminCrmActions(ref.watch(supabaseProvider)),
);
