import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/account_provider.dart';
import '../../theme/voltron_theme.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
        title: const Text('MOYENS DE PAIEMENT'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ...methods.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: VoltronColors.cardBlack,
                    borderRadius: BorderRadius.circular(VoltronRadii.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, color: VoltronColors.electricBlueGlow),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${m.brand} •••• ${m.last4}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            Text('Expire ${m.expiry}', style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.read(paymentMethodsProvider.notifier).remove(m.id),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF5C5C)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showAddDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('AJOUTER UNE CARTE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final numberController = TextEditingController();
    final expiryController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: const Text('Nouvelle carte'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: numberController, decoration: const InputDecoration(hintText: 'Numéro de carte')),
              const SizedBox(height: 12),
              TextField(controller: expiryController, decoration: const InputDecoration(hintText: 'MM/AA')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final digits = numberController.text.replaceAll(' ', '');
              final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
              ref.read(paymentMethodsProvider.notifier).add(
                    brand: 'Carte',
                    last4: last4.isEmpty ? '0000' : last4,
                    expiry: expiryController.text.trim().isEmpty ? '--/--' : expiryController.text.trim(),
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
