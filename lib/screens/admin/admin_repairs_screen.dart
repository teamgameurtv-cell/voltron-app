import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/repair_order_card.dart';
import 'admin_shell.dart';

class AdminRepairsScreen extends ConsumerWidget {
  const AdminRepairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRepairs = ref.watch(repairsProvider);
    final activeRepairs = allRepairs.where((o) => !o.archived).toList();
    final archivedRepairs = allRepairs.where((o) => o.archived).toList();

    return AdminShell(
      selected: AdminSection.repairs,
      title: 'RÉPARATIONS',
      child: ListView(
        children: [
          if (activeRepairs.isEmpty)
            const Text(
              'Aucun dossier en cours.',
              style: TextStyle(color: VoltronColors.greyText),
            )
          else
            ...activeRepairs.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTap: () => context.push('/admin/repairs/${order.dbId}'),
                  child: RepairOrderCard(order: order),
                ),
              ),
            ),
          if (archivedRepairs.isNotEmpty) ...[
            const SizedBox(height: 20),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: VoltronColors.electricYellow,
                collapsedIconColor: VoltronColors.greyText,
                title: Text(
                  'Réparations archivées (${archivedRepairs.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: VoltronColors.greyText,
                  ),
                ),
                children: archivedRepairs
                    .map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: RepairOrderCard(order: order)),
                            IconButton(
                              tooltip: 'Désarchiver',
                              onPressed: () => ref
                                  .read(repairsProvider.notifier)
                                  .setArchived(order.dbId, false),
                              icon: const Icon(
                                Icons.unarchive_outlined,
                                size: 20,
                                color: VoltronColors.greyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
