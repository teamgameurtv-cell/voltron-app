import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/voltron_theme.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isFavorite = false;
  Color? _selectedColor;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(catalogProvider);
    if (products.isEmpty) {
      return const Scaffold(
        backgroundColor: VoltronColors.deepBlack,
        body: Center(child: CircularProgressIndicator(color: VoltronColors.electricYellow)),
      );
    }
    final product = products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => products.first,
    );
    final specsAsync = ref.watch(productSpecsProvider(product.id));
    final colorsAsync = ref.watch(productColorsProvider(product.id));
    final colors = colorsAsync.valueOrNull ?? [];
    _selectedColor ??= colors.isNotEmpty ? colors.first : null;

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isFavorite = !_isFavorite),
                    icon: Icon(
                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isFavorite ? VoltronColors.electricYellow : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Container(
                    height: 220,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(VoltronRadii.lg),
                      gradient: RadialGradient(
                        colors: [
                          VoltronColors.electricBlue.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Icon(product.icon, size: 140, color: VoltronColors.electricYellow),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: VoltronColors.electricYellow,
                    ),
                  ),
                  if ((specsAsync.valueOrNull ?? []).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...(specsAsync.valueOrNull ?? []).map(
                      (spec) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: VoltronColors.success),
                            const SizedBox(width: 8),
                            Text('${spec.label} : ${spec.value}',
                                style: const TextStyle(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (colors.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Couleur',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Row(
                      children: colors.map((color) {
                        final selected = color == _selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? VoltronColors.electricYellow : Colors.white24,
                                width: selected ? 3 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VoltronColors.cardBlack,
                      borderRadius: BorderRadius.circular(VoltronRadii.md),
                    ),
                    child: const Column(
                      children: [
                        _InfoRow(icon: Icons.credit_card, text: 'Paiement 4x sans frais'),
                        SizedBox(height: 10),
                        _InfoRow(icon: Icons.local_shipping_outlined, text: 'Livraison ou retrait en boutique'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: () {
                  ref.read(cartProvider.notifier).add(product, color: _selectedColor);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} ajouté au panier')),
                  );
                },
                child: const Text('AJOUTER AU PANIER'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: VoltronColors.electricBlueGlow),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ),
      ],
    );
  }
}
