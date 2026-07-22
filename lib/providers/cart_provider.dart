import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import 'auth_provider.dart';

class CartItem {
  final Product product;
  final int quantity;
  final Color? color;

  const CartItem({required this.product, this.quantity = 1, this.color});

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity, Color? color}) => CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
        color: color ?? this.color,
      );
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void add(Product product, {Color? color}) {
    final index = state.indexWhere(
      (item) => item.product.id == product.id && item.color == color,
    );
    if (index >= 0) {
      final updated = [...state];
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + 1,
      );
      state = updated;
    } else {
      state = [...state, CartItem(product: product, color: color)];
    }
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeAt(index);
      return;
    }
    final updated = [...state];
    updated[index] = updated[index].copyWith(quantity: quantity);
    state = updated;
  }

  void removeAt(int index) {
    final updated = [...state]..removeAt(index);
    state = updated;
  }

  void clear() => state = [];
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold<int>(0, (sum, item) => sum + item.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold<double>(0, (sum, item) => sum + item.subtotal);
});

/// Ce que "valider la commande" doit réellement faire : tracer l'achat
/// (facture, historique) et décrémenter le stock vendu.
class CheckoutActions {
  final SupabaseClient _client;

  CheckoutActions(this._client);

  Future<void> checkout(List<CartItem> items, double total) async {
    if (items.isEmpty) return;

    final itemCount = items.fold<int>(0, (sum, i) => sum + i.quantity);
    final label = items.length == 1
        ? '${items.first.product.name}${items.first.quantity > 1 ? ' x${items.first.quantity}' : ''}'
        : '$itemCount articles (${items.map((i) => i.product.name).join(', ')})';
    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    await _client.rpc('checkout_cart', params: {
      'p_items': items.map((i) => {'product_id': i.product.id, 'quantity': i.quantity}).toList(),
      'p_total': total,
      'p_label': label,
      'p_invoice_date': formattedDate,
    });
  }
}

final checkoutActionsProvider = Provider<CheckoutActions>((ref) => CheckoutActions(ref.watch(supabaseProvider)));
