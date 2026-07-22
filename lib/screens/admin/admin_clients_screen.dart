import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/account_models.dart';
import '../../models/booking.dart';
import '../../models/client.dart';
import '../../models/repair.dart';
import '../../models/scooter.dart';
import '../../models/support_ticket.dart';
import '../../providers/admin_crm_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/repair_services_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../providers/support_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/care_badge.dart';
import '../../widgets/client_avatar.dart';
import '../../widgets/client_repair_order_detail.dart';
import '../../widgets/support_chat_thread.dart';
import 'admin_shell.dart';

String _ticketStatusLabel(TicketStatus status) {
  switch (status) {
    case TicketStatus.open:
      return 'EN ATTENTE';
    case TicketStatus.answered:
      return 'RÉPONDU';
    case TicketStatus.closed:
      return 'CLÔTURÉ';
  }
}

Color _ticketStatusColor(TicketStatus status) {
  switch (status) {
    case TicketStatus.open:
      return VoltronColors.warning;
    case TicketStatus.answered:
      return VoltronColors.success;
    case TicketStatus.closed:
      return VoltronColors.greyText;
  }
}

String _formatFrenchDate(DateTime date) =>
    '${date.day} ${bookingMonthNames[date.month - 1]} ${date.year}';

class AdminClientsScreen extends ConsumerStatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  ConsumerState<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends ConsumerState<AdminClientsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedClientId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(clientSearchProvider(_query));

    return AdminShell(
      selected: AdminSection.clients,
      title: 'CLIENTS',
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
                    hintText:
                        'Rechercher (nom, email, tél., date de naissance)...',
                    hintStyle: TextStyle(color: VoltronColors.greyText),
                    prefixIcon: Icon(
                      Icons.search,
                      color: VoltronColors.greyText,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: resultsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: VoltronColors.electricYellow,
                      ),
                    ),
                    error: (err, _) => Text(
                      'Erreur : $err',
                      style: const TextStyle(
                        color: VoltronColors.greyText,
                        fontSize: 12,
                      ),
                    ),
                    data: (results) => ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final client = results[index];
                        final isSelected = client.id == _selectedClientId;
                        return Material(
                          color: isSelected
                              ? VoltronColors.cardBlack
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(VoltronRadii.md),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              VoltronRadii.md,
                            ),
                            onTap: () =>
                                setState(() => _selectedClientId = client.id),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClientAvatar(
                                    avatarUrl: client.avatarUrl,
                                    radius: 16,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          client.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          client.email,
                                          style: const TextStyle(
                                            color: VoltronColors.greyText,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _selectedClientId == null
                ? const Center(
                    child: Text(
                      'Sélectionne un client pour voir sa fiche.',
                      style: TextStyle(color: VoltronColors.greyText),
                    ),
                  )
                : _ClientDetail(
                    key: ValueKey(_selectedClientId),
                    clientId: _selectedClientId!,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClientDetail extends ConsumerWidget {
  final String clientId;

  const _ClientDetail({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientByIdProvider(clientId));
    final scootersAsync = ref.watch(clientScootersProvider(clientId));
    final invoicesAsync = ref.watch(clientInvoicesProvider(clientId));
    final services = ref.watch(repairServicesProvider);
    final clientBookings = ref
        .watch(bookingsProvider)
        .where((b) => b.clientId == clientId)
        .toList();
    final clientRepairs = ref
        .watch(repairsProvider)
        .where((o) => o.clientId == clientId)
        .toList();
    final clientTickets =
        (ref.watch(allTicketsProvider).valueOrNull ?? [])
            .where((t) => t.clientId == clientId)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return clientAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: VoltronColors.electricYellow),
      ),
      error: (err, _) => Text(
        'Erreur : $err',
        style: const TextStyle(color: VoltronColors.greyText),
      ),
      data: (client) {
        if (client == null) {
          return const Center(
            child: Text(
              'Client introuvable.',
              style: TextStyle(color: VoltronColors.greyText),
            ),
          );
        }
        final scooters = scootersAsync.valueOrNull ?? [];
        final invoices = invoicesAsync.valueOrNull ?? [];
        final carePlan = ref
            .watch(clientSubscriptionProvider(clientId))
            .valueOrNull;

        return ListView(
          children: [
            Row(
              children: [
                ClientAvatar(avatarUrl: client.avatarUrl, radius: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            client.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (carePlan != null) ...[
                            const SizedBox(width: 8),
                            CareBadge(plan: carePlan),
                          ],
                        ],
                      ),
                      Text(
                        client.email,
                        style: const TextStyle(
                          color: VoltronColors.greyText,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        client.phone,
                        style: const TextStyle(
                          color: VoltronColors.greyText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditClientDialog(context, ref, client),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: VoltronColors.cardBlack,
                    borderRadius: BorderRadius.circular(VoltronRadii.pill),
                  ),
                  child: Text(
                    '${client.loyaltyPoints} pts',
                    style: const TextStyle(
                      color: VoltronColors.electricYellow,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    if (scooters.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Impossible d\'ouvrir un dossier : ce client n\'a aucun véhicule enregistré dans son garage. Ajoute-en un d\'abord.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (services.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Impossible d\'ouvrir un dossier : aucun service configuré dans Services & tarifs.',
                          ),
                        ),
                      );
                      return;
                    }
                    _openRepairDialog(context, ref, client, scooters, services);
                  },
                  icon: const Icon(Icons.build_rounded, size: 16),
                  label: const Text('OUVRIR UN DOSSIER'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VÉHICULES',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: VoltronColors.greyText,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showScooterDialog(context, ref, clientId),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('AJOUTER'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (scooters.isEmpty)
              const Text(
                'Aucun véhicule enregistré.',
                style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
              ),
            ...scooters.map(
              (v) => Material(
                color: VoltronColors.cardBlack,
                borderRadius: BorderRadius.circular(VoltronRadii.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(VoltronRadii.md),
                  onTap: () =>
                      _showVehicleDetailDialog(context, ref, clientId, v),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: VoltronColors.deepBlack,
                            borderRadius: BorderRadius.circular(
                              VoltronRadii.sm,
                            ),
                          ),
                          child: (v.imageUrl != null && v.imageUrl!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    VoltronRadii.sm,
                                  ),
                                  child: Image.network(
                                    v.imageUrl!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.electric_scooter_rounded,
                                  color: VoltronColors.electricYellow,
                                  size: 18,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${v.brand} ${v.model}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'N° ${v.serialNumber}',
                                style: const TextStyle(
                                  color: VoltronColors.greyText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: VoltronColors.greyText,
                          size: 18,
                        ),
                        IconButton(
                          onPressed: () => _showScooterDialog(
                            context,
                            ref,
                            clientId,
                            existing: v,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                        ),
                        IconButton(
                          onPressed: () => ref
                              .read(adminCrmActionsProvider)
                              .removeScooter(v.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Color(0xFFFF5C5C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'RÉSERVATIONS',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: VoltronColors.greyText,
              ),
            ),
            const SizedBox(height: 10),
            if (clientBookings.isEmpty)
              const Text(
                'Aucune réservation.',
                style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
              ),
            ...clientBookings.map((b) => _BookingSummaryTile(booking: b)),
            const SizedBox(height: 24),
            const Text(
              'RÉPARATIONS',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: VoltronColors.greyText,
              ),
            ),
            const SizedBox(height: 10),
            if (clientRepairs.isEmpty)
              const Text(
                'Aucun dossier de réparation.',
                style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
              ),
            ...clientRepairs.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ClientRepairOrderDetail(order: order, collapsible: true),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SUPPORT',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: VoltronColors.greyText,
              ),
            ),
            const SizedBox(height: 10),
            if (clientTickets.isEmpty)
              const Text(
                'Aucune discussion support.',
                style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
              ),
            ...clientTickets.map(
              (ticket) => Material(
                color: VoltronColors.cardBlack,
                borderRadius: BorderRadius.circular(VoltronRadii.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(VoltronRadii.md),
                  onTap: () => _showTicketDialog(context, ref, ticket),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.subject,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _ticketStatusLabel(ticket.status),
                                style: TextStyle(
                                  color: _ticketStatusColor(ticket.status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: VoltronColors.greyText,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'HISTORIQUE D\'ACHATS',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: VoltronColors.greyText,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showInvoiceDialog(context, ref, clientId),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('AJOUTER UN ACHAT'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (invoices.isEmpty)
              const Text(
                'Aucun achat enregistré.',
                style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
              ),
            ...invoices.map(
              (p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VoltronColors.cardBlack,
                  borderRadius: BorderRadius.circular(VoltronRadii.md),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            p.date,
                            style: const TextStyle(
                              color: VoltronColors.greyText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${p.amount.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${p.pointsCredited} pts',
                      style: const TextStyle(
                        color: VoltronColors.electricYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (p.fileUrl != null && p.fileUrl!.isNotEmpty)
                      IconButton(
                        tooltip: 'Ouvrir le justificatif',
                        onPressed: () => launchUrl(
                          Uri.parse(p.fileUrl!),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      ),
                    IconButton(
                      onPressed: () => _showInvoiceDialog(
                        context,
                        ref,
                        clientId,
                        existing: p,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                    ),
                    IconButton(
                      onPressed: () =>
                          ref.read(adminCrmActionsProvider).deleteInvoice(p.id),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Color(0xFFFF5C5C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openRepairDialog(
    BuildContext context,
    WidgetRef ref,
    Client client,
    List<OwnedScooter> scooters,
    List<RepairService> services,
  ) {
    OwnedScooter selectedScooter = scooters.first;
    RepairService selectedService = services.first;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: VoltronColors.cardBlack,
          title: Text('Nouveau dossier — ${client.fullName}'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<OwnedScooter>(
                  value: selectedScooter,
                  dropdownColor: VoltronColors.cardBlack,
                  items: scooters
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text('${v.brand} ${v.model}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedScooter = v!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<RepairService>(
                  value: selectedService,
                  dropdownColor: VoltronColors.cardBlack,
                  items: services
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (s) => setDialogState(() => selectedService = s!),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Note visible par le client (optionnel)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final id = '${1300 + DateTime.now().millisecond}';
                await ref
                    .read(repairsProvider.notifier)
                    .addOrder(
                      displayId: id,
                      scooterName:
                          '${selectedScooter.brand} ${selectedScooter.model}',
                      clientId: client.id,
                      note: noteController.text,
                    );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Dossier #$id ouvert pour ${client.fullName} (${selectedService.name})',
                    ),
                  ),
                );
              },
              child: const Text('OUVRIR'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketDialog(
    BuildContext context,
    WidgetRef ref,
    SupportTicket ticket,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: VoltronColors.cardBlack,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.subject,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (ticket.status != TicketStatus.closed)
                      TextButton(
                        onPressed: () async {
                          final actions = ref.read(supportActionsProvider);
                          await actions.sendMessage(
                            ticketId: ticket.id,
                            senderRole: SenderRole.admin,
                            body:
                                'Cette discussion a été clôturée par notre équipe.',
                          );
                          await actions.updateStatus(
                            ticket.id,
                            TicketStatus.closed,
                          );
                        },
                        child: const Text(
                          'CLÔTURER',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Flexible(
                child: SupportChatThread(
                  ticketId: ticket.id,
                  myRole: SenderRole.admin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditClientDialog(
    BuildContext context,
    WidgetRef ref,
    Client client,
  ) {
    final firstNameController = TextEditingController(text: client.firstName);
    final nameController = TextEditingController(text: client.name);
    final emailController = TextEditingController(text: client.email);
    final phoneController = TextEditingController(text: client.phone);
    DateTime? dateOfBirth = client.dateOfBirth;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: VoltronColors.cardBlack,
          title: const Text('Modifier le client'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(hintText: 'Prénom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Nom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(hintText: 'E-mail'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(hintText: 'Téléphone'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: dateOfBirth ?? DateTime(2000, 1, 1),
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => dateOfBirth = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      hintText: 'Date de naissance',
                    ),
                    child: Text(
                      dateOfBirth != null
                          ? '${dateOfBirth!.day.toString().padLeft(2, '0')}/${dateOfBirth!.month.toString().padLeft(2, '0')}/${dateOfBirth!.year}'
                          : 'Non renseignée',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(adminCrmActionsProvider)
                    .updateClientProfile(
                      client.id,
                      name: nameController.text.trim(),
                      firstName: firstNameController.text.trim(),
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                      dateOfBirth: dateOfBirth,
                    );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleDetailDialog(
    BuildContext context,
    WidgetRef ref,
    String clientId,
    OwnedScooter vehicle,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: VoltronColors.cardBlack,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
          child: Consumer(
            builder: (context, ref, _) {
              final scooters =
                  ref.watch(clientScootersProvider(clientId)).valueOrNull ?? [];
              final v =
                  scooters.where((s) => s.id == vehicle.id).firstOrNull ??
                  vehicle;
              final scooterName = '${v.brand} ${v.model}';
              final orders = ref
                  .watch(repairsProvider)
                  .where(
                    (o) =>
                        o.clientId == clientId && o.scooterName == scooterName,
                  )
                  .toList();

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            scooterName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: VoltronColors.deepBlack,
                                      borderRadius: BorderRadius.circular(
                                        VoltronRadii.md,
                                      ),
                                    ),
                                    child:
                                        (v.imageUrl != null &&
                                            v.imageUrl!.isNotEmpty)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              VoltronRadii.md,
                                            ),
                                            child: Image.network(
                                              v.imageUrl!,
                                              width: 96,
                                              height: 96,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.electric_scooter_rounded,
                                            color: VoltronColors.electricYellow,
                                            size: 36,
                                          ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final result = await FilePicker.platform
                                            .pickFiles(
                                              type: FileType.image,
                                              withData: true,
                                            );
                                        final file = result?.files.firstOrNull;
                                        if (file?.bytes == null) return;
                                        await ref
                                            .read(adminCrmActionsProvider)
                                            .updateScooterImage(
                                              v.id,
                                              file!.bytes!,
                                              file.extension ?? 'jpg',
                                            );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: VoltronColors.electricYellow,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 13,
                                          color: VoltronColors.deepBlack,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'INFORMATIONS',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                                color: VoltronColors.greyText,
                              ),
                            ),
                            _VehicleInfoRow(
                              icon: Icons.local_offer_outlined,
                              label: 'Marque',
                              value: v.brand,
                              onEdit: () => _showEditFieldDialog(
                                context,
                                title: 'Marque',
                                initialValue: v.brand,
                                onSave: (value) => ref
                                    .read(adminCrmActionsProvider)
                                    .updateScooter(v.id, brand: value),
                              ),
                            ),
                            _VehicleInfoRow(
                              icon: Icons.electric_scooter_rounded,
                              label: 'Modèle',
                              value: v.model,
                              onEdit: () => _showEditFieldDialog(
                                context,
                                title: 'Modèle',
                                initialValue: v.model,
                                onSave: (value) => ref
                                    .read(adminCrmActionsProvider)
                                    .updateScooter(v.id, model: value),
                              ),
                            ),
                            _VehicleInfoRow(
                              icon: Icons.pin_outlined,
                              label: 'N° de série',
                              value: v.serialNumber,
                              onEdit: () => _showEditFieldDialog(
                                context,
                                title: 'Numéro de série',
                                initialValue: v.serialNumber,
                                onSave: (value) => ref
                                    .read(adminCrmActionsProvider)
                                    .updateScooter(v.id, serialNumber: value),
                              ),
                            ),
                            _VehicleInfoRow(
                              icon: Icons.event_outlined,
                              label: 'Achat le',
                              value: v.formattedPurchaseDate,
                              onEdit: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: v.purchaseDate,
                                  firstDate: DateTime(2015),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  await ref
                                      .read(adminCrmActionsProvider)
                                      .updateScooter(
                                        v.id,
                                        purchaseDate: picked,
                                      );
                                }
                              },
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'HISTORIQUE DES RÉPARATIONS',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                                color: VoltronColors.greyText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (orders.isEmpty)
                              const Text(
                                'Aucun dossier de réparation pour ce véhicule.',
                                style: TextStyle(
                                  color: VoltronColors.greyText,
                                  fontSize: 13,
                                ),
                              )
                            else
                              ...orders.map(
                                (o) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ClientRepairOrderDetail(
                                    order: o,
                                    collapsible: true,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEditFieldDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required ValueChanged<String> onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.of(dialogContext).pop();
            },
            child: const Text('ENREGISTRER'),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDialog(
    BuildContext context,
    WidgetRef ref,
    String clientId, {
    Invoice? existing,
  }) {
    final labelController = TextEditingController(
      text: existing?.label ?? 'Achat en boutique',
    );
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    DateTime selectedDate = existing != null
        ? (parseBookingDay(existing.date) ?? DateTime.now())
        : DateTime.now();
    String? fileUrl = existing?.fileUrl;
    String? pickedFileName;
    Uint8List? pickedFileBytes;
    bool uploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: VoltronColors.cardBlack,
          title: Text(
            existing == null ? 'Nouvel achat en magasin' : 'Modifier l\'achat',
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    hintText: 'Description (ex : Pneu + main d\'œuvre)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(hintText: 'Montant (€)'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      hintText: 'Date de l\'achat',
                    ),
                    child: Text(_formatFrenchDate(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: uploading
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles(
                            withData: true,
                          );
                          final file = result?.files.firstOrNull;
                          if (file?.bytes == null) return;
                          setDialogState(() {
                            pickedFileBytes = file!.bytes;
                            pickedFileName = file.name;
                          });
                        },
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: Text(
                    pickedFileName ??
                        (fileUrl != null
                            ? 'Remplacer le justificatif SumUp'
                            : 'Joindre le justificatif SumUp'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1 € dépensé = 1 point fidélité, crédité automatiquement au client.',
                  style: TextStyle(color: VoltronColors.greyText, fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: uploading
                  ? null
                  : () async {
                      final amount = double.tryParse(
                        amountController.text.trim().replaceAll(',', '.'),
                      );
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Montant invalide')),
                        );
                        return;
                      }
                      setDialogState(() => uploading = true);
                      if (pickedFileBytes != null && pickedFileName != null) {
                        fileUrl = await ref
                            .read(adminCrmActionsProvider)
                            .uploadInvoiceFile(
                              pickedFileBytes!,
                              pickedFileName!,
                            );
                      }
                      final actions = ref.read(adminCrmActionsProvider);
                      if (existing == null) {
                        await actions.addInvoice(
                          clientId,
                          label: labelController.text.trim(),
                          invoiceDate: _formatFrenchDate(selectedDate),
                          amount: amount,
                          fileUrl: fileUrl,
                        );
                      } else {
                        await actions.updateInvoice(
                          existing.id,
                          label: labelController.text.trim(),
                          invoiceDate: _formatFrenchDate(selectedDate),
                          amount: amount,
                          fileUrl: fileUrl,
                        );
                      }
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                    },
              child: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VoltronColors.deepBlack,
                      ),
                    )
                  : const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScooterDialog(
    BuildContext context,
    WidgetRef ref,
    String clientId, {
    OwnedScooter? existing,
  }) {
    final brandController = TextEditingController(text: existing?.brand ?? '');
    final modelController = TextEditingController(text: existing?.model ?? '');
    final serialController = TextEditingController(
      text: existing?.serialNumber ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: Text(
          existing == null ? 'Nouveau véhicule' : 'Modifier le véhicule',
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: brandController,
                decoration: const InputDecoration(hintText: 'Marque'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(hintText: 'Modèle'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: serialController,
                decoration: const InputDecoration(hintText: 'Numéro de série'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (existing == null) {
                ref
                    .read(adminCrmActionsProvider)
                    .addScooter(
                      clientId,
                      brand: brandController.text.trim(),
                      model: modelController.text.trim(),
                      serialNumber: serialController.text.trim(),
                    );
              } else {
                ref
                    .read(adminCrmActionsProvider)
                    .updateScooter(
                      existing.id,
                      brand: brandController.text.trim(),
                      model: modelController.text.trim(),
                      serialNumber: serialController.text.trim(),
                    );
              }
              Navigator.of(dialogContext).pop();
            },
            child: const Text('ENREGISTRER'),
          ),
        ],
      ),
    );
  }
}

class _BookingSummaryTile extends StatelessWidget {
  final Booking booking;

  const _BookingSummaryTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (booking.status) {
      BookingStatus.confirmed => VoltronColors.success,
      BookingStatus.pending => VoltronColors.warning,
      BookingStatus.cancelled => const Color(0xFFFF5C5C),
    };
    final statusLabel = switch (booking.status) {
      BookingStatus.confirmed => 'Confirmé',
      BookingStatus.pending => 'En attente',
      BookingStatus.cancelled => 'Annulé',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.day,
                  style: const TextStyle(
                    fontSize: 11,
                    color: VoltronColors.greyText,
                  ),
                ),
                Text(
                  booking.time,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (booking.scooterName.trim().isNotEmpty)
                  Text(
                    booking.scooterName,
                    style: const TextStyle(
                      color: VoltronColors.electricBlueGlow,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(VoltronRadii.pill),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _VehicleInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: VoltronColors.greyText),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: VoltronColors.greyText,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
