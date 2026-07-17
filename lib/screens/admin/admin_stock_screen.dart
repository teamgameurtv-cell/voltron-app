import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/voltron_theme.dart';
import 'admin_shell.dart';

class AdminStockScreen extends ConsumerWidget {
  const AdminStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(catalogProvider);
    final movements = ref.watch(stockMovementsProvider);

    return AdminShell(
      selected: AdminSection.stock,
      title: 'STOCK',
      child: ListView(
        children: [
          const Text('NIVEAUX DE STOCK',
              style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: VoltronColors.greyText)),
          const SizedBox(height: 12),
          ...products.map((product) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: VoltronColors.cardBlack,
                  borderRadius: BorderRadius.circular(VoltronRadii.md),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Text(
                      '${product.stock} unités',
                      style: TextStyle(
                        color: product.stock <= 5 ? const Color(0xFFFF5C5C) : VoltronColors.greyText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        ref.read(catalogProvider.notifier).updateProduct(product.copyWith(stock: product.stock + 1));
                        ref.read(stockMovementsProvider.notifier).log(product.id, product.name, 1);
                      },
                      icon: const Icon(Icons.add_circle_outline, color: VoltronColors.success),
                    ),
                    IconButton(
                      onPressed: product.stock > 0
                          ? () {
                              ref.read(catalogProvider.notifier).updateProduct(product.copyWith(stock: product.stock - 1));
                              ref.read(stockMovementsProvider.notifier).log(product.id, product.name, -1);
                            }
                          : null,
                      icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFF5C5C)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          const Text('HISTORIQUE DES MOUVEMENTS',
              style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: VoltronColors.greyText)),
          const SizedBox(height: 12),
          if (movements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Aucun mouvement enregistré.', style: TextStyle(color: VoltronColors.greyText, fontSize: 12)),
            ),
          ...movements.take(20).map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      m.delta > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 16,
                      color: m.delta > 0 ? VoltronColors.success : const Color(0xFFFF5C5C),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m.productName, style: const TextStyle(fontSize: 12))),
                    Text(
                      '${m.delta > 0 ? '+' : ''}${m.delta}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: m.delta > 0 ? VoltronColors.success : const Color(0xFFFF5C5C),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
