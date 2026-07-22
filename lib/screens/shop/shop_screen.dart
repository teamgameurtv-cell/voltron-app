import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock_products.dart' show ProductCategory, mockCategories;
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/product_visual.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String? _selectedCategory;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartItemCountProvider);
    final products = ref.watch(catalogProvider);

    if (products.isEmpty) {
      return const Scaffold(
        backgroundColor: VoltronColors.deepBlack,
        body: Center(
          child: CircularProgressIndicator(color: VoltronColors.electricYellow),
        ),
      );
    }

    final featured = products.first;
    final isFiltering = _selectedCategory != null || _query.trim().isNotEmpty;
    final filtered = products.where((p) {
      final matchesCategory =
          _selectedCategory == null || p.category == _selectedCategory;
      final matchesQuery =
          _query.trim().isEmpty ||
          p.name.toLowerCase().contains(_query.trim().toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
    final bestSellers = products.where((p) => p.isBestSeller).toList();

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const AppHeader(),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'BOUTIQUE',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () => context.push('/shop/cart'),
                      icon: const Icon(Icons.shopping_cart_outlined),
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: VoltronColors.electricYellow,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$cartCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: VoltronColors.deepBlack,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                hintStyle: const TextStyle(color: VoltronColors.greyText),
                prefixIcon: const Icon(
                  Icons.search,
                  color: VoltronColors.greyText,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: VoltronColors.greyText,
                          size: 18,
                        ),
                        onPressed: () => setState(() {
                          _query = '';
                          _searchController.clear();
                        }),
                      ),
              ),
            ),
            if (!isFiltering) ...[
              const SizedBox(height: 20),
              _FeaturedBanner(product: featured),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CATÉGORIES',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: VoltronColors.greyText,
                  ),
                ),
                if (_selectedCategory != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedCategory = null),
                    child: const Text(
                      'Réinitialiser',
                      style: TextStyle(
                        color: VoltronColors.electricBlueGlow,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _CategoryGrid(
              categories: mockCategories,
              selected: _selectedCategory,
              onSelect: (label) => setState(() {
                _selectedCategory = _selectedCategory == label ? null : label;
              }),
            ),
            const SizedBox(height: 24),
            if (!isFiltering) ...[
              const Text(
                'MEILLEURES VENTES',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: VoltronColors.greyText,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: bestSellers
                    .map((p) => Expanded(child: _ProductCard(product: p)))
                    .expand((widget) => [widget, const SizedBox(width: 12)])
                    .take(bestSellers.isEmpty ? 0 : bestSellers.length * 2 - 1)
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              isFiltering
                  ? 'RÉSULTATS (${filtered.length})'
                  : 'TOUS LES PRODUITS',
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: VoltronColors.greyText,
              ),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Aucun produit ne correspond.',
                  style: TextStyle(color: VoltronColors.greyText),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) =>
                    _ProductCard(product: filtered[index]),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  final Product product;

  const _FeaturedBanner({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shop/product/${product.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VoltronRadii.lg),
          color: VoltronColors.cardBlack,
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.4,
            colors: [
              VoltronColors.electricBlue.withValues(alpha: 0.35),
              VoltronColors.cardBlack,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.tagline ?? '',
              style: const TextStyle(
                color: VoltronColors.greyText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ProductVisual(product: product, size: 140, iconSize: 64),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/shop/product/${product.id}'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              child: const Text('DÉCOUVRIR'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<ProductCategory> categories;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: categories.map((cat) {
        final isSelected = cat.label == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(cat.label),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? VoltronColors.electricBlue
                        : VoltronColors.cardBlack,
                    borderRadius: BorderRadius.circular(VoltronRadii.md),
                    border: Border.all(
                      color: isSelected
                          ? VoltronColors.electricYellow
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    cat.icon,
                    color: isSelected
                        ? Colors.white
                        : VoltronColors.electricBlueGlow,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cat.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? VoltronColors.electricYellow
                        : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shop/product/${product.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VoltronColors.cardBlack,
          borderRadius: BorderRadius.circular(VoltronRadii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: VoltronColors.deepBlack,
                        borderRadius: BorderRadius.circular(VoltronRadii.sm),
                      ),
                      child: ProductVisual(
                        product: product,
                        width: double.infinity,
                        height: double.infinity,
                        iconSize: 48,
                      ),
                    ),
                  ),
                  if (product.stock > 0 && product.stock <= 5)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5C5C),
                          borderRadius: BorderRadius.circular(
                            VoltronRadii.pill,
                          ),
                        ),
                        child: Text(
                          'Plus que ${product.stock} !',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.formattedPrice,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: VoltronColors.electricYellow,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      product.rating.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: VoltronColors.greyText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
