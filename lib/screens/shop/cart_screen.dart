import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_notification.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../theme/voltron_theme.dart';

enum _DeliveryMode { livraison, retrait }

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  _DeliveryMode _deliveryMode = _DeliveryMode.livraison;
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final cartIds = items.map((i) => i.product.id).toSet();
    final crossSell = ref.watch(catalogProvider).where((p) => !cartIds.contains(p.id)).take(2).toList();

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('PANIER'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Ton panier est vide.',
                style: TextStyle(color: VoltronColors.greyText),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: VoltronColors.cardBlack,
                            borderRadius: BorderRadius.circular(VoltronRadii.md),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: VoltronColors.deepBlack,
                                  borderRadius: BorderRadius.circular(VoltronRadii.sm),
                                ),
                                child: Icon(item.product.icon, color: VoltronColors.electricYellow),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(item.product.formattedPrice,
                                        style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(index, item.quantity - 1),
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  ),
                                  Text('${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                  IconButton(
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(index, item.quantity + 1),
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (crossSell.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('VOUS POURRIEZ AUSSI AIMER',
                              style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700, color: VoltronColors.greyText)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: crossSell.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final product = crossSell[index];
                                return Container(
                                  width: 220,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: VoltronColors.cardBlack,
                                    borderRadius: BorderRadius.circular(VoltronRadii.md),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(product.icon, color: VoltronColors.electricYellow, size: 28),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(product.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                            Text(product.formattedPrice,
                                                style: const TextStyle(fontSize: 11, color: VoltronColors.electricYellow)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => ref.read(cartProvider.notifier).add(product),
                                        icon: const Icon(Icons.add_circle, size: 20, color: VoltronColors.electricBlueGlow),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _promoController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Code promo',
                            hintStyle: TextStyle(color: VoltronColors.greyText),
                            prefixIcon: Icon(Icons.local_offer_outlined, color: VoltronColors.greyText),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _DeliveryChoiceChip(
                                label: 'Livraison',
                                icon: Icons.local_shipping_outlined,
                                selected: _deliveryMode == _DeliveryMode.livraison,
                                onTap: () => setState(() => _deliveryMode = _DeliveryMode.livraison),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DeliveryChoiceChip(
                                label: 'Retrait magasin',
                                icon: Icons.storefront_rounded,
                                selected: _deliveryMode == _DeliveryMode.retrait,
                                onTap: () => setState(() => _deliveryMode = _DeliveryMode.retrait),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(
                              '${total.toStringAsFixed(2).replaceAll('.', ',')} €',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: VoltronColors.electricYellow,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: () {
                            final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);
                            ref.read(notificationsProvider.notifier).push(
                                  type: NotificationType.order,
                                  title: 'Commande confirmée',
                                  body:
                                      '$itemCount article${itemCount > 1 ? 's' : ''} pour ${total.toStringAsFixed(2).replaceAll('.', ',')} €. Merci pour ta confiance !',
                                );
                            ref.read(cartProvider.notifier).clear();
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Commande validée !')),
                            );
                          },
                          child: const Text('VALIDER LA COMMANDE'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DeliveryChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DeliveryChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VoltronRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? VoltronColors.electricBlue.withValues(alpha: 0.2) : VoltronColors.cardBlack,
          borderRadius: BorderRadius.circular(VoltronRadii.md),
          border: Border.all(
            color: selected ? VoltronColors.electricBlue : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? VoltronColors.electricBlueGlow : Colors.white70),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
