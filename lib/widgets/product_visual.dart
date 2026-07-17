import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/voltron_theme.dart';

/// Affiche la photo du produit si elle existe, sinon retombe sur son icône.
class ProductVisual extends StatelessWidget {
  final Product product;
  final double size;
  final double iconSize;

  const ProductVisual({super.key, required this.product, required this.size, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl;
    if (url == null || url.isEmpty) {
      return Icon(product.icon, size: iconSize, color: VoltronColors.electricYellow);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(VoltronRadii.sm),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(product.icon, size: iconSize, color: VoltronColors.electricYellow),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : Icon(product.icon, size: iconSize, color: VoltronColors.electricYellow),
      ),
    );
  }
}
