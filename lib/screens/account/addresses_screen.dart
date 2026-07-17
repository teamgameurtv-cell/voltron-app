import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/account_provider.dart';
import '../../theme/voltron_theme.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
        title: const Text('ADRESSES'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ...addresses.map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: VoltronColors.cardBlack,
                    borderRadius: BorderRadius.circular(VoltronRadii.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: VoltronColors.electricBlueGlow),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            Text(a.details, style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.read(addressesProvider.notifier).remove(a.id),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF5C5C)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showAddDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('AJOUTER UNE ADRESSE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final labelController = TextEditingController();
    final detailsController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: const Text('Nouvelle adresse'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: labelController, decoration: const InputDecoration(hintText: 'Libellé (ex: Domicile)')),
              const SizedBox(height: 12),
              TextField(controller: detailsController, decoration: const InputDecoration(hintText: 'Adresse complète')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              ref.read(addressesProvider.notifier).add(
                    labelController.text.trim().isEmpty ? 'Adresse' : labelController.text.trim(),
                    detailsController.text.trim(),
                  );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('AJOUTER'),
          ),
        ],
      ),
    );
  }
}
