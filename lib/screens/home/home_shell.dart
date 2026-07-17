import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold commun aux 5 onglets (Accueil, Boutique, Réparations, Fidélité, Compte).
/// Chaque onglet garde sa propre pile de navigation grâce à [StatefulNavigationShell].
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Boutique'),
          BottomNavigationBarItem(icon: Icon(Icons.build_rounded), label: 'Réparations'),
          BottomNavigationBarItem(icon: Icon(Icons.star_rounded), label: 'Fidélité'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Compte'),
        ],
      ),
    );
  }
}
