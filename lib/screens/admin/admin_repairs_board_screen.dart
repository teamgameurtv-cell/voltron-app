import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/repair.dart';
import '../../providers/repairs_provider.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(repairsProvider);
    final orders = allOrders.where((o) => !o.archived).toList();
    final archivedOrders = allOrders.where((o) => o.archived).toList();

    return AdminShell(
      selected: AdminSection.repairsBoard,
      title: 'SUIVI RÉPARATIONS',
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
                return _BoardColumn(label: columnLabel, orders: columnOrders);
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
          ...orders.map(
            (order) => GestureDetector(
              onTap: () => context.push('/admin/repairs/${order.dbId}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VoltronColors.deepBlack,
                  borderRadius: BorderRadius.circular(VoltronRadii.sm),
                  border: order.isBlockedOnQuote
                      ? Border.all(
                          color: VoltronColors.warning.withValues(alpha: 0.6),
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      order.scooterName,
                      style: const TextStyle(
                        color: VoltronColors.greyText,
                        fontSize: 11,
                      ),
                    ),
                    if (order.isBlockedOnQuote)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'En attente devis',
                          style: TextStyle(
                            color: VoltronColors.warning,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
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
