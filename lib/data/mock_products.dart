import 'package:flutter/material.dart';

class ProductCategory {
  final String label;
  final IconData icon;

  const ProductCategory(this.label, this.icon);
}

const List<ProductCategory> mockCategories = [
  ProductCategory('Trottinettes', Icons.electric_scooter_rounded),
  ProductCategory('Pièces', Icons.settings_rounded),
  ProductCategory('Accessoires', Icons.shopping_bag_rounded),
  ProductCategory('Batteries', Icons.battery_charging_full_rounded),
];
