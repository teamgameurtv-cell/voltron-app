import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/repair_order_message.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/repair_order_chat_thread.dart';

/// Un seul écran, utilisé par deux routes (admin et client) — seul [myRole]
/// change le sens des bulles de messages affichées.
class RepairOrderMessagesScreen extends ConsumerWidget {
  final String orderId;
  final RepairMessageSenderRole myRole;

  const RepairOrderMessagesScreen({
    super.key,
    required this.orderId,
    required this.myRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(repairsProvider);
    final order = orders.where((o) => o.dbId == orderId).firstOrNull;

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          order != null ? 'Dossier #${order.id}' : 'Messages',
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: SafeArea(
        child: RepairOrderChatThread(orderId: orderId, myRole: myRole),
      ),
    );
  }
}
