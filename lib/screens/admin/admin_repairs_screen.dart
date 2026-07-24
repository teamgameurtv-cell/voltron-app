import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/client.dart';
import '../../models/repair.dart';
import '../../models/scooter.dart';
import '../../providers/admin_crm_provider.dart';
import '../../providers/repair_services_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/client_avatar.dart';
import '../../widgets/repair_order_card.dart';
import 'admin_shell.dart';

class AdminRepairsScreen extends ConsumerStatefulWidget {
  const AdminRepairsScreen({super.key});

  @override
  ConsumerState<AdminRepairsScreen> createState() => _AdminRepairsScreenState();
}

class _AdminRepairsScreenState extends ConsumerState<AdminRepairsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(RepairOrder order, String query) {
    if (query.isEmpty) return true;
    if (order.id.toLowerCase().contains(query)) return true;
    if (order.scooterName.toLowerCase().contains(query)) return true;
    final client = ref.watch(clientByIdProvider(order.clientId)).valueOrNull;
    return client != null && client.fullName.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final allRepairs = ref.watch(repairsProvider);
    final query = _query.trim().toLowerCase();
    final activeRepairs = allRepairs
        .where((o) => !o.archived && _matches(o, query))
        .toList();
    final archivedRepairs = allRepairs
        .where((o) => o.archived && _matches(o, query))
        .toList();

    return AdminShell(
      selected: AdminSection.repairs,
      title: 'RÉPARATIONS',
      actions: ElevatedButton.icon(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _CreateRepairOrderDialog(),
        ),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('NOUVELLE RÉPARATION'),
      ),
      child: ListView(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Rechercher un dossier (n°, client, véhicule)...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),
          if (activeRepairs.isEmpty)
            Text(
              query.isEmpty
                  ? 'Aucun dossier en cours.'
                  : 'Aucun dossier ne correspond à cette recherche.',
              style: const TextStyle(color: VoltronColors.greyText),
            )
          else
            ...activeRepairs.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push(
                                  '/admin/repairs/${order.dbId}',
                                ),
                                child: RepairOrderCard(order: order),
                              ),
                            ),
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

/// Ouverture d'un dossier depuis n'importe où (pas besoin de passer par la
/// fiche client) : on recherche d'abord le client pour bien relier le
/// dossier à son compte, comme pour la création de réservation.
class _CreateRepairOrderDialog extends ConsumerStatefulWidget {
  const _CreateRepairOrderDialog();

  @override
  ConsumerState<_CreateRepairOrderDialog> createState() =>
      _CreateRepairOrderDialogState();
}

class _CreateRepairOrderDialogState
    extends ConsumerState<_CreateRepairOrderDialog> {
  final _searchController = TextEditingController();
  final _manualScooterNameController = TextEditingController();
  final _noteController = TextEditingController();
  String _query = '';
  Client? _selectedClient;
  OwnedScooter? _selectedScooter;
  RepairService? _selectedService;
  bool _submitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _manualScooterNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(Client client, List<OwnedScooter> scooters) async {
    // Le menu déroulant affiche déjà scooters.first par défaut tant que
    // l'admin n'a pas choisi explicitement — on applique la même valeur par
    // défaut ici pour ne pas silencieusement retomber sur le champ manuel.
    final effectiveScooter =
        _selectedScooter ?? (scooters.isNotEmpty ? scooters.first : null);
    final scooterName = effectiveScooter != null
        ? '${effectiveScooter.brand} ${effectiveScooter.model}'
        : _manualScooterNameController.text.trim();
    if (scooterName.isEmpty) return;

    setState(() => _submitting = true);
    final displayId = '${1300 + DateTime.now().millisecond}';
    final combinedNote = [
      if (_selectedService != null)
        'Service demandé : ${_selectedService!.name}',
      if (_noteController.text.trim().isNotEmpty) _noteController.text.trim(),
    ].join('\n');
    try {
      await ref
          .read(repairsProvider.notifier)
          .addOrder(
            displayId: displayId,
            scooterName: scooterName,
            clientId: client.id,
            scooterId: effectiveScooter?.id,
            note: combinedNote.isEmpty ? null : combinedNote,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = _selectedClient;
    return AlertDialog(
      backgroundColor: VoltronColors.cardBlack,
      title: const Text('Nouvelle réparation'),
      content: SizedBox(
        width: 420,
        child: client == null ? _buildClientSearch() : _buildForm(client),
      ),
      actions: client == null
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => setState(() {
                  _selectedClient = null;
                  _selectedScooter = null;
                  _selectedService = null;
                }),
                child: const Text('CHANGER DE CLIENT'),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final scooters =
                      ref
                          .watch(clientScootersProvider(client.id))
                          .valueOrNull ??
                      [];
                  return ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () => _submit(client, scooters),
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: VoltronColors.deepBlack,
                            ),
                          )
                        : const Text('OUVRIR LE DOSSIER'),
                  );
                },
              ),
            ],
    );
  }

  Widget _buildClientSearch() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recherche le client pour qui ouvrir le dossier.',
            style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Nom, téléphone ou email...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          if (_query.trim().isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Tape un nom, un numéro ou un email pour retrouver le client.',
                style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
              ),
            )
          else
            Consumer(
              builder: (context, ref, _) {
                final resultsAsync = ref.watch(clientSearchProvider(_query));
                return resultsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: VoltronColors.electricYellow,
                      ),
                    ),
                  ),
                  error: (err, _) => Text(
                    'Erreur : $err',
                    style: const TextStyle(color: VoltronColors.greyText),
                  ),
                  data: (clients) => clients.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Aucun client trouvé.',
                            style: TextStyle(
                              color: VoltronColors.greyText,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 300,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: clients.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final c = clients[index];
                              return Material(
                                color: VoltronColors.deepBlack,
                                borderRadius: BorderRadius.circular(
                                  VoltronRadii.md,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    VoltronRadii.md,
                                  ),
                                  onTap: () =>
                                      setState(() => _selectedClient = c),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        ClientAvatar(
                                          avatarUrl: c.avatarUrl,
                                          radius: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c.fullName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (c.phone.isNotEmpty ||
                                                  c.email.isNotEmpty)
                                                Text(
                                                  [c.phone, c.email]
                                                      .where(
                                                        (s) => s.isNotEmpty,
                                                      )
                                                      .join(' · '),
                                                  style: const TextStyle(
                                                    color:
                                                        VoltronColors.greyText,
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
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildForm(Client client) {
    final scooters =
        ref.watch(clientScootersProvider(client.id)).valueOrNull ?? [];
    final services = ref.watch(repairServicesProvider);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: VoltronColors.deepBlack,
              borderRadius: BorderRadius.circular(VoltronRadii.md),
            ),
            child: Row(
              children: [
                ClientAvatar(avatarUrl: client.avatarUrl, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (client.phone.isNotEmpty)
                        Text(
                          client.phone,
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
          const SizedBox(height: 16),
          const Text(
            'Véhicule',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (scooters.isNotEmpty)
            DropdownButtonFormField<OwnedScooter>(
              value: _selectedScooter ?? scooters.first,
              dropdownColor: VoltronColors.cardBlack,
              items: scooters
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text('${s.brand} ${s.model}'),
                    ),
                  )
                  .toList(),
              onChanged: (s) => setState(() => _selectedScooter = s),
            )
          else
            TextField(
              controller: _manualScooterNameController,
              decoration: const InputDecoration(
                hintText: 'Nom du véhicule (ex : Xiaomi M365)',
              ),
            ),
          const SizedBox(height: 14),
          const Text(
            'Service (optionnel)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<RepairService?>(
            value: _selectedService,
            dropdownColor: VoltronColors.cardBlack,
            hint: const Text('Aucun service spécifié'),
            items: [
              const DropdownMenuItem<RepairService?>(
                value: null,
                child: Text('Aucun service spécifié'),
              ),
              ...services.map(
                (s) => DropdownMenuItem<RepairService?>(
                  value: s,
                  child: Text(s.name),
                ),
              ),
            ],
            onChanged: (s) => setState(() => _selectedService = s),
          ),
          const SizedBox(height: 14),
          const Text(
            'Description du problème (optionnel)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ex : bruit anormal à l\'accélération...',
            ),
          ),
        ],
      ),
    );
  }
}
