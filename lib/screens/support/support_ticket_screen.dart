import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/support_ticket.dart';
import '../../providers/support_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/support_chat_thread.dart';

class SupportTicketScreen extends ConsumerWidget {
  final String ticketId;

  const SupportTicketScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticket = ref.watch(myTicketsProvider).valueOrNull?.firstWhere(
          (t) => t.id == ticketId,
          orElse: () => SupportTicket(
            id: ticketId,
            clientId: '',
            subject: 'Ticket',
            status: TicketStatus.open,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
        title: Text(ticket?.subject ?? 'Ticket', style: const TextStyle(fontSize: 15)),
      ),
      body: SafeArea(
        child: SupportChatThread(ticketId: ticketId, myRole: SenderRole.client),
      ),
    );
  }
}
