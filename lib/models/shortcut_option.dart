import 'package:flutter/material.dart';

class ShortcutOption {
  final String id;
  final String label;
  final IconData icon;
  final String route;

  const ShortcutOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
  });
}

const List<ShortcutOption> allShortcuts = [
  ShortcutOption(
    id: 'book',
    label: 'Réserver',
    icon: Icons.calendar_month_rounded,
    route: '/repairs/book',
  ),
  ShortcutOption(
    id: 'shop',
    label: 'Boutique',
    icon: Icons.storefront_rounded,
    route: '/shop',
  ),
  ShortcutOption(
    id: 'garage',
    label: 'Mon Garage',
    icon: Icons.garage_rounded,
    route: '/account/garage',
  ),
  ShortcutOption(
    id: 'care',
    label: 'Voltron Care',
    icon: Icons.shield_rounded,
    route: '/loyalty/care',
  ),
  ShortcutOption(
    id: 'loyalty',
    label: 'Fidélité',
    icon: Icons.star_rounded,
    route: '/loyalty',
  ),
  ShortcutOption(
    id: 'repairs',
    label: 'Réparations',
    icon: Icons.build_rounded,
    route: '/repairs',
  ),
  ShortcutOption(
    id: 'account',
    label: 'Compte',
    icon: Icons.person_rounded,
    route: '/account',
  ),
  ShortcutOption(
    id: 'notifications',
    label: 'Notifications',
    icon: Icons.notifications_rounded,
    route: '/notifications',
  ),
  ShortcutOption(
    id: 'invoices',
    label: 'Factures',
    icon: Icons.receipt_long_outlined,
    route: '/account/invoices',
  ),
  ShortcutOption(
    id: 'payment',
    label: 'Paiement',
    icon: Icons.credit_card_outlined,
    route: '/account/payment-methods',
  ),
  ShortcutOption(
    id: 'history',
    label: 'Historique',
    icon: Icons.history_rounded,
    route: '/account/repairs-history',
  ),
];

const List<String> defaultShortcutIds = ['book', 'shop', 'garage', 'care'];
