import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import 'auth_provider.dart';

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
  }) async {
    await _client.from('products').insert({
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'icon_name': nameForIcon(icon),
    });
  }

  Future<void> updateProduct(Product product) async {
    await _client.from('products').update({
      'name': product.name,
      'category': product.category,
      'price': product.price,
      'stock': product.stock,
      'is_best_seller': product.isBestSeller,
    }).eq('id', product.id);
  }

  Future<void> removeProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
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
