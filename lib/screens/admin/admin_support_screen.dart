import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/support_ticket.dart';
import '../../providers/admin_crm_provider.dart';
import '../../providers/support_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/care_badge.dart';
import '../../widgets/support_chat_thread.dart';
import 'admin_shell.dart';

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  String? _selectedTicketId;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(SupportTicket ticket) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    final client = ref.watch(clientByIdProvider(ticket.clientId)).valueOrNull;
    final scooters =
        ref.watch(clientScootersProvider(ticket.clientId)).valueOrNull ?? [];
    final haystack = [
      ticket.subject,
      client?.fullName ?? '',
      client?.phone ?? '',
      ...scooters.map((s) => '${s.brand} ${s.model}'),
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(allTicketsProvider);
    final subscribedIds =
        ref.watch(subscribedClientIdsProvider).valueOrNull ?? const <String>{};

    return AdminShell(
      selected: AdminSection.support,
      title: 'SUPPORT CLIENT',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher (nom, tél., trottinette)...',
                    hintStyle: TextStyle(color: VoltronColors.greyText),
                    prefixIcon: Icon(
                      Icons.search,
                      color: VoltronColors.greyText,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ticketsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: VoltronColors.electricYellow,
                      ),
                    ),
                    error: (err, _) => Text(
                      'Erreur : $err',
                      style: const TextStyle(color: VoltronColors.greyText),
                    ),
                    data: (allTickets) {
                      final tickets = allTickets.where(_matchesQuery).toList();
                      if (tickets.isEmpty) {
                        return Text(
                          _query.trim().isEmpty
                              ? 'Aucun ticket pour le moment.'
                              : 'Aucun résultat.',
                          style: const TextStyle(color: VoltronColors.greyText),
                        );
                      }

                      final activeTickets =
                          tickets
                              .where((t) => t.status != TicketStatus.closed)
                              .toList()
                            ..sort((a, b) {
                              final aSub = subscribedIds.contains(a.clientId);
                              final bSub = subscribedIds.contains(b.clientId);
                              if (aSub != bSub) return aSub ? -1 : 1;
                              return b.updatedAt.compareTo(a.updatedAt);
                            });
                      final closedTickets =
                          tickets
                              .where((t) => t.status == TicketStatus.closed)
                              .toList()
                            ..sort(
                              (a, b) => b.updatedAt.compareTo(a.updatedAt),
                            );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (closedTickets.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: OutlinedButton.icon(
                                onPressed: () => _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                ),
                                icon: const Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  'TICKETS CLÔTURÉS (${closedTickets.length})',
                                ),
                              ),
                            ),
                          Expanded(
                            child: ListView(
                              controller: _scrollController,
                              children: [
                                ...activeTickets.map(
                                  (ticket) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _TicketTile(
                                      ticket: ticket,
                                      isSelected:
                                          ticket.id == _selectedTicketId,
                                      onTap: () => setState(
                                        () => _selectedTicketId = ticket.id,
                                      ),
                                    ),
                                  ),
                                ),
                                if (closedTickets.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'TICKETS CLÔTURÉS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w700,
                                      color: VoltronColors.greyText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...closedTickets.map(
                                    (ticket) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _TicketTile(
                                        ticket: ticket,
                                        isSelected:
                                            ticket.id == _selectedTicketId,
                                        onTap: () => setState(
                                          () => _selectedTicketId = ticket.id,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _selectedTicketId == null
                ? const Center(
                    child: Text(
                      'Sélectionne un ticket pour répondre.',
                      style: TextStyle(color: VoltronColors.greyText),
                    ),
                  )
                : _TicketDetail(
                    key: ValueKey(_selectedTicketId),
                    ticketId: _selectedTicketId!,
                  ),
          ),
        ],
      ),
    );
  }
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

class _TicketTile extends ConsumerWidget {
  final SupportTicket ticket;
  final bool isSelected;
  final VoidCallback onTap;

  const _TicketTile({
    required this.ticket,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientByIdProvider(ticket.clientId)).valueOrNull;
    final plan = ref
        .watch(clientSubscriptionProvider(ticket.clientId))
        .valueOrNull;

    return Material(
      color: isSelected ? VoltronColors.cardBlack : Colors.transparent,
      borderRadius: BorderRadius.circular(VoltronRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(VoltronRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (plan != null) ...[
                    const SizedBox(width: 6),
                    CareBadge(plan: plan),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                client?.fullName ?? '...',
                style: const TextStyle(
                  color: VoltronColors.greyText,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _statusLabel(ticket.status),
                style: TextStyle(
                  color: _statusColor(ticket.status),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                  child: Text(
                    ticket?.subject ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (ticket != null && ticket.status != TicketStatus.closed)
                  TextButton(
                    onPressed: () async {
                      final actions = ref.read(supportActionsProvider);
                      await actions.sendMessage(
                        ticketId: ticketId,
                        senderRole: SenderRole.admin,
                        body:
                            'Cette discussion a été clôturée par notre équipe.',
                      );
                      await actions.updateStatus(ticketId, TicketStatus.closed);
                    },
                    child: const Text(
                      'CLÔTURER',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: SupportChatThread(
              ticketId: ticketId,
              myRole: SenderRole.admin,
            ),
          ),
        ],
      ),
    );
  }
}
