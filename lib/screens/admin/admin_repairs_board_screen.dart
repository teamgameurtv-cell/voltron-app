import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/repair.dart';
import '../../models/technician.dart';
import '../../providers/admin_crm_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../providers/technicians_provider.dart';
import '../../theme/voltron_theme.dart';
import 'admin_shell.dart';

const List<String> _columns = [
  'Rendez-vous pris',
  'Trottinette déposée',
  'Diagnostic en cours',
  'Devis envoyé',
  'Pièces commandées',
  'Réparation en cours',
  'Prête à récupérer',
  'Récupérée',
];

class AdminRepairsBoardScreen extends ConsumerStatefulWidget {
  const AdminRepairsBoardScreen({super.key});

  @override
  ConsumerState<AdminRepairsBoardScreen> createState() =>
      _AdminRepairsBoardScreenState();
}

class _AdminRepairsBoardScreenState
    extends ConsumerState<AdminRepairsBoardScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(RepairOrder order, String query) {
    if (query.isEmpty) return true;
    if (order.id.toLowerCase().contains(query)) return true;
    if (order.scooterName.toLowerCase().contains(query)) return true;
    final client = ref.watch(clientByIdProvider(order.clientId)).valueOrNull;
    return client != null && client.fullName.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(repairsProvider);
    final query = _query.trim().toLowerCase();
    final orders = allOrders
        .where((o) => !o.archived && _matches(o, query))
        .toList();
    final archivedOrders = allOrders
        .where((o) => o.archived && _matches(o, query))
        .toList();

    return AdminShell(
      selected: AdminSection.repairsBoard,
      title: 'SUIVI RÉPARATIONS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher un dossier (n°, client, véhicule)...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._columns.map((columnLabel) {
                      final columnOrders = orders
                          .where((o) => o.currentStep.label == columnLabel)
                          .toList();
                      return _BoardColumn(
                        label: columnLabel,
                        orders: columnOrders,
                      );
                    }),
                    _BoardColumn(
                      label: 'Archivé',
                      orders: archivedOrders,
                      highlight: VoltronColors.greyText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardColumn extends StatelessWidget {
  final String label;
  final List<RepairOrder> orders;
  final Color? highlight;

  const _BoardColumn({
    required this.label,
    required this.orders,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: highlight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: VoltronColors.deepBlack,
                  borderRadius: BorderRadius.circular(VoltronRadii.pill),
                ),
                child: Text(
                  '${orders.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: VoltronColors.electricYellow,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...orders.map((order) => _BoardCard(order: order)),
          if (orders.isEmpty)
            const Text(
              '—',
              style: TextStyle(color: VoltronColors.greyText, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class _BoardCard extends ConsumerWidget {
  final RepairOrder order;

  const _BoardCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Technician? technician;
    if (order.technicianId != null) {
      final technicians = ref.watch(techniciansProvider).valueOrNull ?? [];
      for (final t in technicians) {
        if (t.id == order.technicianId) {
          technician = t;
          break;
        }
      }
    }

    return GestureDetector(
      onTap: () => context.push('/admin/repairs/${order.dbId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: VoltronColors.deepBlack,
          borderRadius: BorderRadius.circular(VoltronRadii.sm),
          border: order.isBlockedOnQuote
              ? Border.all(color: VoltronColors.warning.withValues(alpha: 0.6))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${order.id}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Text(
              order.scooterName,
              style: const TextStyle(
                color: VoltronColors.greyText,
                fontSize: 11,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.engineering_rounded,
                  size: 11,
                  color: technician != null
                      ? VoltronColors.electricYellow
                      : VoltronColors.greyText,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    technician?.name ?? 'Aucun technicien',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: technician != null
                          ? VoltronColors.electricYellow
                          : VoltronColors.greyText,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            if (order.isBlockedOnQuote)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'En attente devis',
                  style: TextStyle(color: VoltronColors.warning, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
