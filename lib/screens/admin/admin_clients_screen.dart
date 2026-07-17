import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/client.dart';
import '../../models/repair.dart';
import '../../models/scooter.dart';
import '../../providers/admin_crm_provider.dart';
import '../../providers/repair_services_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/client_avatar.dart';
import 'admin_shell.dart';

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
                    hintText: 'Rechercher un client (nom, email)...',
                    hintStyle: TextStyle(color: VoltronColors.greyText),
                    prefixIcon: Icon(Icons.search, color: VoltronColors.greyText),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: resultsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: VoltronColors.electricYellow)),
                    error: (err, _) =>
                        Text('Erreur : $err', style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                    data: (results) => ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final client = results[index];
                        final isSelected = client.id == _selectedClientId;
                        return Material(
                          color: isSelected ? VoltronColors.cardBlack : Colors.transparent,
                          borderRadius: BorderRadius.circular(VoltronRadii.md),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(VoltronRadii.md),
                            onTap: () => setState(() => _selectedClientId = client.id),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClientAvatar(avatarUrl: client.avatarUrl, radius: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(client.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        Text(client.email, style: const TextStyle(color: VoltronColors.greyText, fontSize: 11)),
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
                    child: Text('Sélectionne un client pour voir sa fiche.', style: TextStyle(color: VoltronColors.greyText)),
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
    final clientsAsync = ref.watch(clientSearchProvider(''));
    final scootersAsync = ref.watch(clientScootersProvider(clientId));
    final invoicesAsync = ref.watch(clientInvoicesProvider(clientId));
    final services = ref.watch(repairServicesProvider);

    return clientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: VoltronColors.electricYellow)),
      error: (err, _) => Text('Erreur : $err', style: const TextStyle(color: VoltronColors.greyText)),
      data: (clients) {
        final client = clients.firstWhere((c) => c.id == clientId, orElse: () => clients.first);
        final scooters = scootersAsync.valueOrNull ?? [];
        final invoices = invoicesAsync.valueOrNull ?? [];

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
                      Text(client.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(client.email, style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                      Text(client.phone, style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: VoltronColors.cardBlack,
                    borderRadius: BorderRadius.circular(VoltronRadii.pill),
                  ),
                  child: Text('${client.loyaltyPoints} pts',
                      style: const TextStyle(color: VoltronColors.electricYellow, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: scooters.isEmpty || services.isEmpty
                      ? null
                      : () => _openRepairDialog(context, ref, client, scooters, services),
                  icon: const Icon(Icons.build_rounded, size: 16),
                  label: const Text('OUVRIR UN DOSSIER'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('VÉHICULES',
                style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: VoltronColors.greyText)),
            const SizedBox(height: 10),
            if (scooters.isEmpty)
              const Text('Aucun véhicule enregistré.', style: TextStyle(color: VoltronColors.greyText, fontSize: 12)),
            ...scooters.map((v) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: VoltronColors.cardBlack, borderRadius: BorderRadius.circular(VoltronRadii.md)),
                  child: Row(
                    children: [
                      const Icon(Icons.electric_scooter_rounded, color: VoltronColors.electricYellow, size: 18),
                      const SizedBox(width: 10),
                      Text('${v.brand} ${v.model}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Text('N° ${v.serialNumber}', style: const TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            const Text('HISTORIQUE D\'ACHATS',
                style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: VoltronColors.greyText)),
            const SizedBox(height: 10),
            if (invoices.isEmpty)
              const Text('Aucun achat enregistré.', style: TextStyle(color: VoltronColors.greyText, fontSize: 12)),
            ...invoices.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: VoltronColors.cardBlack, borderRadius: BorderRadius.circular(VoltronRadii.md)),
                  child: Row(
                    children: [
                      Expanded(child: Text(p.label, style: const TextStyle(fontSize: 13))),
                      Text(p.date, style: const TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                      const SizedBox(width: 12),
                      Text('${p.amount.toStringAsFixed(2).replaceAll('.', ',')} €',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                )),
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

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: VoltronColors.cardBlack,
          title: Text('Nouveau dossier — ${client.name}'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<OwnedScooter>(
                  value: selectedScooter,
                  dropdownColor: VoltronColors.cardBlack,
                  items: scooters
                      .map((v) => DropdownMenuItem(value: v, child: Text('${v.brand} ${v.model}')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedScooter = v!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<RepairService>(
                  value: selectedService,
                  dropdownColor: VoltronColors.cardBlack,
                  items: services
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                      .toList(),
                  onChanged: (s) => setDialogState(() => selectedService = s!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final id = '${1300 + DateTime.now().millisecond}';
                await ref.read(repairsProvider.notifier).addOrder(
                      displayId: id,
                      scooterName: '${selectedScooter.brand} ${selectedScooter.model}',
                      clientId: client.id,
                    );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dossier #$id ouvert pour ${client.name} (${selectedService.name})')),
                );
              },
              child: const Text('OUVRIR'),
            ),
          ],
        ),
      ),
    );
  }
}
