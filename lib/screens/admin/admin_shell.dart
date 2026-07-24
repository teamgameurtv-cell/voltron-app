import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_notifications_provider.dart';
import '../../theme/voltron_theme.dart';

enum AdminSection {
  dashboard,
  clients,
  products,
  stock,
  rewards,
  bookings,
  repairs,
  repairsBoard,
  technicians,
  services,
  announcements,
  support,
  vehicleLookup,
}

class _NavItem {
  final AdminSection section;
  final String label;
  final IconData icon;
  final String route;

  const _NavItem(this.section, this.label, this.icon, this.route);
}

const List<_NavItem> _navItems = [
  _NavItem(
    AdminSection.dashboard,
    'Tableau de bord',
    Icons.dashboard_rounded,
    '/admin',
  ),
  _NavItem(
    AdminSection.clients,
    'Clients',
    Icons.people_alt_rounded,
    '/admin/clients',
  ),
  _NavItem(
    AdminSection.bookings,
    'Réservations',
    Icons.calendar_month_rounded,
    '/admin/bookings',
  ),
  _NavItem(
    AdminSection.repairs,
    'Réparations',
    Icons.build_rounded,
    '/admin/repairs',
  ),
  _NavItem(
    AdminSection.repairsBoard,
    'Suivi réparations',
    Icons.view_kanban_rounded,
    '/admin/repairs-board',
  ),
  _NavItem(
    AdminSection.technicians,
    'Techniciens',
    Icons.engineering_rounded,
    '/admin/technicians',
  ),
  _NavItem(
    AdminSection.services,
    'Services & tarifs',
    Icons.handyman_rounded,
    '/admin/services',
  ),
  _NavItem(
    AdminSection.products,
    'Produits',
    Icons.storefront_rounded,
    '/admin/products',
  ),
  _NavItem(
    AdminSection.stock,
    'Stock',
    Icons.inventory_2_rounded,
    '/admin/stock',
  ),
  _NavItem(
    AdminSection.rewards,
    'Fidélité',
    Icons.star_rounded,
    '/admin/rewards',
  ),
  _NavItem(
    AdminSection.announcements,
    'Annonces',
    Icons.campaign_rounded,
    '/admin/announcements',
  ),
  _NavItem(
    AdminSection.support,
    'Support client',
    Icons.support_agent_rounded,
    '/admin/support',
  ),
  _NavItem(
    AdminSection.vehicleLookup,
    'Véhicule volé',
    Icons.manage_search_rounded,
    '/admin/vehicle-lookup',
  ),
];

class AdminShell extends StatelessWidget {
  final AdminSection selected;
  final String title;
  final Widget child;
  final Widget? actions;

  const AdminShell({
    super.key,
    required this.selected,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      drawer: isWide ? null : Drawer(child: _Sidebar(selected: selected)),
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) _Sidebar(selected: selected),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      children: [
                        if (!isWide)
                          Builder(
                            builder: (context) => IconButton(
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                              icon: const Icon(Icons.menu_rounded),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final unread = ref.watch(
                              unreadAdminNotificationsCountProvider,
                            );
                            return Stack(
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      context.push('/admin/notifications'),
                                  icon: const Icon(
                                    Icons.notifications_none_rounded,
                                  ),
                                ),
                                if (unread > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: VoltronColors.electricYellow,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        if (actions != null) actions!,
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: child,
                    ),
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

class _Sidebar extends StatelessWidget {
  final AdminSection selected;

  const _Sidebar({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: VoltronColors.surfaceBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Image(
                  image: AssetImage('assets/images/voltron_logo.png'),
                  width: 40,
                ),
                SizedBox(width: 10),
                Text(
                  'ADMIN',
                  style: TextStyle(
                    color: VoltronColors.greyText,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          ..._navItems.map((item) {
            final isSelected = item.section == selected;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: Material(
                color: isSelected
                    ? VoltronColors.cardBlack
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(VoltronRadii.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(VoltronRadii.sm),
                  onTap: () => context.go(item.route),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isSelected
                              ? VoltronColors.electricYellow
                              : VoltronColors.greyText,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : VoltronColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text(
                'Quitter l\'admin',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
