import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/voltron_theme.dart';

/// Affiche la photo du produit si elle existe, sinon retombe sur son icône.
/// [size] fixe une image carrée ; utilise [width]/[height] pour qu'elle
/// remplisse un espace non carré (ex : `double.infinity` dans un AspectRatio).
class ProductVisual extends StatelessWidget {
  final Product product;
  final double? size;
  final double? width;
  final double? height;
  final double iconSize;

  const ProductVisual({
    super.key,
    required this.product,
    this.size,
    this.width,
    this.height,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    final url = product.imageUrl;
    if (url == null || url.isEmpty) {
      return SizedBox(
        width: w,
        height: h,
        child: Center(child: Icon(product.icon, size: iconSize, color: VoltronColors.electricYellow)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(VoltronRadii.sm),
      child: Image.network(
        url,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(product.icon, size: iconSize, color: VoltronColors.electricYellow),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : Icon(product.icon, size: iconSize, color: VoltronColors.electricYellow),
      ),
    );
  }
}
