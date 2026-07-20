import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/client_repair_order_detail.dart';

class RepairsScreen extends ConsumerWidget {
  const RepairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id;
    final orders = ref.watch(repairsProvider).where((o) => o.clientId == userId).toList();

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('RÉPARATIONS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ElevatedButton(
                  onPressed: () => context.push('/repairs/book'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: const Text('RÉSERVER', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (orders.isEmpty)
              const Text('Aucun dossier en cours.', style: TextStyle(color: VoltronColors.greyText))
            else
              ...orders.map((order) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: ClientRepairOrderDetail(order: order),
                  )),
          ],
        ),
      ),
    );
  }
}
