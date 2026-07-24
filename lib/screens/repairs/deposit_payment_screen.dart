import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';

class DepositPaymentScreen extends ConsumerStatefulWidget {
  final String orderId;

  const DepositPaymentScreen({super.key, required this.orderId});

  @override
  ConsumerState<DepositPaymentScreen> createState() =>
      _DepositPaymentScreenState();
}

class _DepositPaymentScreenState extends ConsumerState<DepositPaymentScreen> {
  final _cardNumberController = TextEditingController(
    text: '4242 4242 4242 4242',
  );
  final _expiryController = TextEditingController(text: '12/28');
  final _cvvController = TextEditingController(text: '123');
  bool _paying = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = ref
        .watch(repairsProvider)
        .firstWhere((o) => o.dbId == widget.orderId);
    final quote = order.quote!;
    final amountLabel = quote.depositAmount!
        .toStringAsFixed(2)
        .replaceAll('.', ',');

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('PAIEMENT DE L\'ACOMPTE'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
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
                            'Dossier #${order.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'Acompte avant intervention',
                            style: TextStyle(
                              color: VoltronColors.greyText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$amountLabel €',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: VoltronColors.electricYellow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Informations de paiement',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cardNumberController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Numéro de carte',
                  hintStyle: TextStyle(color: VoltronColors.greyText),
                  prefixIcon: Icon(
                    Icons.credit_card,
                    color: VoltronColors.greyText,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'MM/AA',
                        hintStyle: TextStyle(color: VoltronColors.greyText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _cvvController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'CVV',
                        hintStyle: TextStyle(color: VoltronColors.greyText),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: VoltronColors.greyText,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Paiement simulé — aucune vraie transaction',
                    style: TextStyle(
                      color: VoltronColors.greyText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _paying
                    ? null
                    : () async {
                        setState(() => _paying = true);
                        await ref
                            .read(repairsProvider.notifier)
                            .payDepositOnline(widget.orderId);
                        if (!context.mounted) return;
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Acompte de $amountLabel € payé !'),
                          ),
                        );
                      },
                child: Text(_paying ? 'Paiement...' : 'PAYER $amountLabel €'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
