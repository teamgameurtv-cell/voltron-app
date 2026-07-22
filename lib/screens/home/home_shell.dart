import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';

/// Scaffold commun aux 5 onglets (Accueil, Boutique, Réparations, Fidélité, Compte).
/// Chaque onglet garde sa propre pile de navigation grâce à [StatefulNavigationShell].
class HomeShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id;
    final activeRepairsCount = ref
        .watch(repairsProvider)
        .where((o) => o.clientId == userId && !o.isComplete)
        .length;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_rounded),
            label: 'Boutique',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.build_rounded),
                if (activeRepairsCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: VoltronColors.electricYellow,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$activeRepairsCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: VoltronColors.deepBlack,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Réparations',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.star_rounded),
            label: 'Fidélité',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Compte',
          ),
        ],
      ),
    );
  }
}
