import 'package:flutter/material.dart';

const Map<String, IconData> productIconRegistry = {
  'electric_scooter': Icons.electric_scooter_rounded,
  'tire_repair': Icons.tire_repair,
  'power': Icons.power_rounded,
  'shopping_bag': Icons.shopping_bag_rounded,
  'settings': Icons.settings_rounded,
  'battery': Icons.battery_charging_full_rounded,
  'helmet': Icons.sports_motorsports_rounded,
};

IconData iconForName(String name) => productIconRegistry[name] ?? Icons.shopping_bag_rounded;

String nameForIcon(IconData icon) => productIconRegistry.entries
    .firstWhere((e) => e.value == icon, orElse: () => const MapEntry('shopping_bag', Icons.shopping_bag_rounded))
    .key;

class ProductSpec {
  final String label;
  final String value;

  const ProductSpec(this.label, this.value);
}

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final double rating;
  final int reviewCount;
  final IconData icon;
  final String? tagline;
  final List<ProductSpec> specs;
  final List<Color> colors;
  final bool isBestSeller;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.rating = 0,
    this.reviewCount = 0,
    required this.icon,
    this.tagline,
    this.specs = const [],
    this.colors = const [],
    this.isBestSeller = false,
    this.stock = 0,
  });

  String get formattedPrice =>
      '${price.toStringAsFixed(2).replaceAll('.', ',')} €';

  Product copyWith({
    String? name,
    String? category,
    double? price,
    int? stock,
    bool? isBestSeller,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      rating: rating,
      reviewCount: reviewCount,
      icon: icon,
      tagline: tagline,
      specs: specs,
      colors: colors,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      stock: stock ?? this.stock,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: map['review_count'] as int? ?? 0,
      icon: iconForName(map['icon_name'] as String? ?? 'shopping_bag'),
      tagline: map['tagline'] as String?,
      isBestSeller: map['is_best_seller'] as bool? ?? false,
      stock: map['stock'] as int? ?? 0,
    );
  }
}
