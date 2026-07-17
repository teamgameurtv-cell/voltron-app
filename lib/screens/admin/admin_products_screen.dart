import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_products.dart';
import '../../models/product.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/voltron_theme.dart';
import 'admin_shell.dart';

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(catalogProvider);

    return AdminShell(
      selected: AdminSection.products,
      title: 'PRODUITS',
      actions: ElevatedButton.icon(
        onPressed: () => _showProductDialog(context, ref),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('AJOUTER'),
      ),
      child: ListView.separated(
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VoltronColors.cardBlack,
              borderRadius: BorderRadius.circular(VoltronRadii.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: VoltronColors.deepBlack,
                    borderRadius: BorderRadius.circular(VoltronRadii.sm),
                  ),
                  child: Icon(product.icon, color: VoltronColors.electricYellow),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(product.category, style: const TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(product.formattedPrice, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: Text(
                    'Stock : ${product.stock}',
                    style: TextStyle(
                      color: product.stock <= 5 ? const Color(0xFFFF5C5C) : VoltronColors.greyText,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showProductDialog(context, ref, existing: product),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                IconButton(
                  onPressed: () => ref.read(catalogProvider.notifier).removeProduct(product.id),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF5C5C)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showProductDialog(BuildContext context, WidgetRef ref, {Product? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final categoryController = TextEditingController(text: existing?.category ?? mockCategories.first.label);
    final priceController = TextEditingController(text: existing?.price.toString() ?? '');
    final stockController = TextEditingController(text: existing?.stock.toString() ?? '0');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: Text(existing == null ? 'Nouveau produit' : 'Modifier le produit'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Nom du produit')),
              const SizedBox(height: 12),
              TextField(controller: categoryController, decoration: const InputDecoration(hintText: 'Catégorie')),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Prix (€)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Stock'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0;
              final stock = int.tryParse(stockController.text) ?? 0;
              if (existing == null) {
                ref.read(catalogProvider.notifier).addProduct(
                      name: nameController.text.trim().isEmpty ? 'Nouveau produit' : nameController.text.trim(),
                      category: categoryController.text.trim(),
                      price: price,
                      stock: stock,
                    );
              } else {
                ref.read(catalogProvider.notifier).updateProduct(existing.copyWith(
                      name: nameController.text.trim(),
                      category: categoryController.text.trim(),
                      price: price,
                      stock: stock,
                    ));
              }
              Navigator.of(dialogContext).pop();
            },
            child: const Text('ENREGISTRER'),
          ),
        ],
      ),
    );
  }
}
