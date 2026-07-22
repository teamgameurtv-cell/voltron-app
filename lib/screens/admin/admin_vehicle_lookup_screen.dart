import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/scooter.dart';
import '../../providers/admin_crm_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/care_badge.dart';
import '../../widgets/client_avatar.dart';
import 'admin_shell.dart';

/// Recherche un véhicule par numéro de série, tous clients confondus — pour
/// retrouver rapidement le propriétaire d'une trottinette volée/retrouvée.
class AdminVehicleLookupScreen extends ConsumerStatefulWidget {
  const AdminVehicleLookupScreen({super.key});

  @override
  ConsumerState<AdminVehicleLookupScreen> createState() =>
      _AdminVehicleLookupScreenState();
}

class _AdminVehicleLookupScreenState
    extends ConsumerState<AdminVehicleLookupScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(vehicleSerialSearchProvider(_query));

    return AdminShell(
      selected: AdminSection.vehicleLookup,
      title: 'VÉHICULE VOLÉ',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Retrouvez le propriétaire d\'une trottinette à partir de son numéro de série — '
              'utile en cas de vol ou de véhicule retrouvé.',
              style: TextStyle(color: VoltronColors.greyText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Numéro de série...',
                hintStyle: const TextStyle(color: VoltronColors.greyText),
                prefixIcon: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: VoltronColors.greyText,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: VoltronColors.greyText,
                          size: 18,
                        ),
                        onPressed: () => setState(() {
                          _query = '';
                          _searchController.clear();
                        }),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _query.trim().isEmpty
                  ? const Center(
                      child: Text(
                        'Tapez un numéro de série pour rechercher.',
                        style: TextStyle(color: VoltronColors.greyText),
                      ),
                    )
                  : resultsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: VoltronColors.electricYellow,
                        ),
                      ),
                      error: (err, _) => Text(
                        'Erreur : $err',
                        style: const TextStyle(color: VoltronColors.greyText),
                      ),
                      data: (results) => results.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun véhicule trouvé pour ce numéro de série.',
                                style: TextStyle(color: VoltronColors.greyText),
                              ),
                            )
                          : ListView.separated(
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  _VehicleResultCard(vehicle: results[index]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleResultCard extends ConsumerWidget {
  final OwnedScooter vehicle;

  const _VehicleResultCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(clientByIdProvider(vehicle.ownerId)).valueOrNull;
    final plan = ref
        .watch(clientSubscriptionProvider(vehicle.ownerId))
        .valueOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
        border: Border.all(
          color: VoltronColors.electricYellow.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: VoltronColors.deepBlack,
                  borderRadius: BorderRadius.circular(VoltronRadii.sm),
                ),
                child:
                    (vehicle.imageUrl != null && vehicle.imageUrl!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(VoltronRadii.sm),
                        child: Image.network(
                          vehicle.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.electric_scooter_rounded,
                        color: VoltronColors.electricYellow,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'N° ${vehicle.serialNumber}',
                      style: const TextStyle(
                        color: VoltronColors.electricYellow,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 28),
          if (owner == null)
            const Text(
              'Propriétaire introuvable.',
              style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
            )
          else
            Row(
              children: [
                ClientAvatar(avatarUrl: owner.avatarUrl, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            owner.fullName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (plan != null) ...[
                            const SizedBox(width: 8),
                            CareBadge(plan: plan),
                          ],
                        ],
                      ),
                      Text(
                        owner.email,
                        style: const TextStyle(
                          color: VoltronColors.greyText,
                          fontSize: 12,
                        ),
                      ),
                      if (owner.phone.isNotEmpty)
                        Text(
                          owner.phone,
                          style: const TextStyle(
                            color: VoltronColors.greyText,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
