import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/support_ticket.dart';
import '../../providers/support_provider.dart';
import '../../theme/voltron_theme.dart';

class SupportTicketsScreen extends ConsumerWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(myTicketsProvider);

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
        title: const Text('MESSAGERIE PRIORITAIRE'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: VoltronColors.electricYellow,
        foregroundColor: VoltronColors.deepBlack,
        onPressed: () => _showNewTicketDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ticketsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: VoltronColors.electricYellow)),
          error: (err, _) => Center(child: Text('Erreur : $err', style: const TextStyle(color: VoltronColors.greyText))),
          data: (tickets) => tickets.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aucune question pour l\'instant.\nOuvre un ticket avec le bouton +, notre équipe te répond en priorité.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: VoltronColors.greyText),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return Material(
                      color: VoltronColors.cardBlack,
                      borderRadius: BorderRadius.circular(VoltronRadii.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(VoltronRadii.md),
                        onTap: () => context.push('/support/${ticket.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ticket.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(_statusLabel(ticket.status),
                                        style: TextStyle(color: _statusColor(ticket.status), fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: VoltronColors.greyText),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  String _statusLabel(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'En attente de réponse';
      case TicketStatus.answered:
        return 'Réponse reçue';
      case TicketStatus.closed:
        return 'Clôturé';
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

  void _showNewTicketDialog(BuildContext context, WidgetRef ref) {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: const Text('Nouveau ticket'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: subjectController, decoration: const InputDecoration(hintText: 'Sujet')),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Ta question'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (subjectController.text.trim().isEmpty || messageController.text.trim().isEmpty) return;
              final ticketId = await ref.read(supportActionsProvider).createTicket(
                    subject: subjectController.text.trim(),
                    firstMessage: messageController.text.trim(),
                  );
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              context.push('/support/$ticketId');
            },
            child: const Text('ENVOYER'),
          ),
        ],
      ),
    );
  }
}
