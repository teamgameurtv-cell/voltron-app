import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/support_ticket.dart';
import '../../providers/admin_crm_provider.dart';
import '../../providers/support_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/support_chat_thread.dart';
import 'admin_shell.dart';

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  String? _selectedTicketId;

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(allTicketsProvider);

    return AdminShell(
      selected: AdminSection.support,
      title: 'SUPPORT CLIENT',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 320,
            child: ticketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: VoltronColors.electricYellow)),
              error: (err, _) => Text('Erreur : $err', style: const TextStyle(color: VoltronColors.greyText)),
              data: (tickets) => tickets.isEmpty
                  ? const Text('Aucun ticket pour le moment.', style: TextStyle(color: VoltronColors.greyText))
                  : ListView.separated(
                      itemCount: tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        final isSelected = ticket.id == _selectedTicketId;
                        return Material(
                          color: isSelected ? VoltronColors.cardBlack : Colors.transparent,
                          borderRadius: BorderRadius.circular(VoltronRadii.md),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(VoltronRadii.md),
                            onTap: () => setState(() => _selectedTicketId = ticket.id),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ticket.subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final client = ref.watch(clientByIdProvider(ticket.clientId)).valueOrNull;
                                      return Text(client?.fullName ?? '...',
                                          style: const TextStyle(color: VoltronColors.greyText, fontSize: 11));
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_statusLabel(ticket.status),
                                      style: TextStyle(color: _statusColor(ticket.status), fontSize: 10, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _selectedTicketId == null
                ? const Center(
                    child: Text('Sélectionne un ticket pour répondre.', style: TextStyle(color: VoltronColors.greyText)),
                  )
                : _TicketDetail(key: ValueKey(_selectedTicketId), ticketId: _selectedTicketId!),
          ),
        ],
      ),
    );
  }

  String _statusLabel(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'EN ATTENTE';
      case TicketStatus.answered:
        return 'RÉPONDU';
      case TicketStatus.closed:
        return 'CLÔTURÉ';
    }
  }

  Color _statusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return VoltronColors.warning;
      case TicketStatus.answered:
        return VoltronColors.success;
      case TicketStatus.closed:
        return VoltronColors.greyText;
    }
  }
}

class _TicketDetail extends ConsumerWidget {
  final String ticketId;

  const _TicketDetail({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(allTicketsProvider).valueOrNull ?? [];
    final ticket = tickets.where((t) => t.id == ticketId).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: VoltronColors.surfaceBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Text(ticket?.subject ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                if (ticket != null && ticket.status != TicketStatus.closed)
                  TextButton(
                    onPressed: () async {
                      final actions = ref.read(supportActionsProvider);
                      await actions.sendMessage(
                        ticketId: ticketId,
                        senderRole: SenderRole.admin,
                        body: 'Cette discussion a été clôturée par notre équipe.',
                      );
                      await actions.updateStatus(ticketId, TicketStatus.closed);
                    },
                    child: const Text('CLÔTURER', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: SupportChatThread(ticketId: ticketId, myRole: SenderRole.admin),
          ),
        ],
      ),
    );
  }
}
