import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/repairs_provider.dart';
import '../../widgets/repair_order_card.dart';
import 'admin_shell.dart';

class AdminRepairsScreen extends ConsumerWidget {
  const AdminRepairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repairs = ref.watch(repairsProvider);

    return AdminShell(
      selected: AdminSection.repairs,
      title: 'RÉPARATIONS',
      child: ListView.separated(
        itemCount: repairs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) => RepairOrderCard(order: repairs[index]),
      ),
    );
  }
}
