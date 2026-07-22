import 'dart:async';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import 'auth_provider.dart';

const List<String> csvColumns = ['nom', 'categorie', 'prix', 'stock', 'description'];

class CsvImportResult {
  final int created;
  final int updated;
  final int skipped;

  const CsvImportResult({required this.created, required this.updated, required this.skipped});
}

class StockMovement {
  final String productId;
  final String productName;
  final int delta;
  final DateTime date;

  const StockMovement({
    required this.productId,
    required this.productName,
    required this.delta,
    required this.date,
  });

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      productId: map['product_id'] as String? ?? '',
      productName: map['product_name'] as String,
      delta: map['delta'] as int,
      date: DateTime.parse(map['created_at'] as String),
    );
  }
}

class CatalogNotifier extends StateNotifier<List<Product>> {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  CatalogNotifier(this._client) : super([]) {
    _sub = _client.from('products').stream(primaryKey: ['id']).listen((rows) {
      state = rows.map(Product.fromMap).toList();
    });
  }

  Future<void> addProduct({
    required String name,
    required String category,
    required double price,
    required int stock,
    IconData icon = Icons.shopping_bag_rounded,
    String? imageUrl,
    String? description,
  }) async {
    await _client.from('products').insert({
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'icon_name': nameForIcon(icon),
      'image_url': imageUrl,
      'description': description,
    });
  }

  Future<void> updateProduct(Product product) async {
    await _client.from('products').update({
      'name': product.name,
      'category': product.category,
      'price': product.price,
      'stock': product.stock,
      'is_best_seller': product.isBestSeller,
      'image_url': product.imageUrl,
      'description': product.description,
    }).eq('id', product.id);
  }

  /// Envoie l'image choisie dans le stockage Supabase et retourne son URL publique.
  Future<String> uploadProductImage(Uint8List bytes, String fileName) async {
    final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('product-images').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('product-images').getPublicUrl(path);
  }

  Future<void> removeProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  /// Génère un CSV (nom, catégorie, prix, stock, description) du catalogue actuel.
  String exportCsv() {
    final rows = [
      csvColumns,
      for (final p in state) [p.name, p.category, p.price, p.stock, p.description ?? ''],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  /// Importe un CSV avec les mêmes colonnes que [exportCsv] : met à jour les
  /// produits existants (correspondance par nom) et crée les nouveaux.
  Future<CsvImportResult> importCsv(String content) async {
    final rows = const CsvToListConverter(eol: '\n').convert(content, shouldParseNumbers: false);
    if (rows.isEmpty) return const CsvImportResult(created: 0, updated: 0, skipped: 0);

    int created = 0, updated = 0, skipped = 0;
    for (final row in rows.skip(1)) {
      if (row.isEmpty || (row[0] as String).trim().isEmpty) {
        skipped++;
        continue;
      }
      final name = (row[0] as String).trim();
      final category = row.length > 1 ? (row[1] as String).trim() : '';
      final price = row.length > 2 ? double.tryParse((row[2] as String).replaceAll(',', '.')) : null;
      final stock = row.length > 3 ? int.tryParse(row[3] as String) : null;
      final description = row.length > 4 ? (row[4] as String).trim() : '';

      if (price == null || stock == null) {
        skipped++;
        continue;
      }

      final existing = state.where((p) => p.name.trim().toLowerCase() == name.toLowerCase()).firstOrNull;
      if (existing != null) {
        await updateProduct(existing.copyWith(
          category: category.isEmpty ? existing.category : category,
          price: price,
          stock: stock,
          description: description,
        ));
        updated++;
      } else {
        await addProduct(
          name: name,
          category: category.isEmpty ? 'Divers' : category,
          price: price,
          stock: stock,
          description: description,
        );
        created++;
      }
    }
    return CsvImportResult(created: created, updated: updated, skipped: skipped);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, List<Product>>(
  (ref) => CatalogNotifier(ref.watch(supabaseProvider)),
);

/// Specs et couleurs sont chargées à la demande (fiche produit), pas en flux réaltime.
final productSpecsProvider = FutureProvider.family<List<ProductSpec>, String>((ref, productId) async {
  final rows = await ref
      .watch(supabaseProvider)
      .from('product_specs')
      .select()
      .eq('product_id', productId)
      .order('position');
  return rows.map((r) => ProductSpec(r['label'] as String, r['value'] as String)).toList();
});

final productColorsProvider = FutureProvider.family<List<Color>, String>((ref, productId) async {
  final rows = await ref.watch(supabaseProvider).from('product_colors').select().eq('product_id', productId);
  return rows.map((r) {
    final hex = (r['color_hex'] as String).replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }).toList();
});

class StockMovementsNotifier extends StateNotifier<List<StockMovement>> {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  StockMovementsNotifier(this._client) : super([]) {
    _sub = _client
        .from('stock_movements')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((rows) {
      state = rows.map(StockMovement.fromMap).toList();
    });
  }

  Future<void> log(String productId, String productName, int delta) async {
    await _client.from('stock_movements').insert({
      'product_id': productId,
      'product_name': productName,
      'delta': delta,
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final stockMovementsProvider = StateNotifierProvider<StockMovementsNotifier, List<StockMovement>>(
  (ref) => StockMovementsNotifier(ref.watch(supabaseProvider)),
);
