import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/garage_provider.dart';
import '../../theme/voltron_theme.dart';

class WarrantyScreen extends ConsumerWidget {
  const WarrantyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scooters = ref.watch(garageProvider);

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
        title: const Text('GARANTIE ET DOCUMENTS'),
      ),
      body: SafeArea(
        child: scooters.isEmpty
            ? const Center(child: Text('Aucun véhicule.', style: TextStyle(color: VoltronColors.greyText)))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: scooters
                    .map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: VoltronColors.cardBlack,
                            borderRadius: BorderRadius.circular(VoltronRadii.md),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${s.brand} ${s.model}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 10),
                              _DocRow(label: 'Certificat de garantie'),
                              const SizedBox(height: 8),
                              _DocRow(label: 'Manuel utilisateur'),
                              const SizedBox(height: 8),
                              _DocRow(label: 'Facture d\'achat'),
                            ],
                          ),
                        ))
                    .toList(),
              ),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final String label;

  const _DocRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.description_outlined, size: 16, color: VoltronColors.electricBlueGlow),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        TextButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Téléchargement simulé')),
          ),
          child: const Text('Télécharger', style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }
}
