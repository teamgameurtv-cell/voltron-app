import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/repair.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';

class QuoteScreen extends ConsumerWidget {
  final String orderId;

  const QuoteScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref
        .watch(repairsProvider)
        .firstWhere((o) => o.dbId == orderId);
    final quote = order.quote!;

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('DEVIS'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Devis ${quote.id}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                quote.date,
                style: const TextStyle(
                  color: VoltronColors.greyText,
                  fontSize: 12,
                ),
              ),
              if ((quote.note ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: VoltronColors.electricBlueGlow.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(VoltronRadii.md),
                    border: Border.all(
                      color: VoltronColors.electricBlueGlow.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'POURQUOI CE DEVIS ?',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          color: VoltronColors.electricBlueGlow,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        quote.note!.trim(),
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
              if ((quote.depositAmount ?? 0) > 0) ...[
                const SizedBox(height: 16),
                _DepositCard(orderDbId: order.dbId, quote: quote),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VoltronColors.cardBlack,
                  borderRadius: BorderRadius.circular(VoltronRadii.md),
                ),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DÉTAIL DE L\'INTERVENTION',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          color: VoltronColors.greyText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...quote.lines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              line.label,
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              '${line.price.toStringAsFixed(2).replaceAll('.', ',')} €',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${quote.total.toStringAsFixed(2).replaceAll('.', ',')} €',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: VoltronColors.electricYellow,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Délai estimé : ${quote.estimatedDelay}',
                style: const TextStyle(
                  color: VoltronColors.greyText,
                  fontSize: 12,
                ),
              ),
              if ((quote.fileUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(quote.fileUrl!),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: const Text('Voir le fichier joint'),
                ),
              ],
              if (quote.status != QuoteStatus.pendingApproval) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (quote.status == QuoteStatus.accepted
                                ? VoltronColors.success
                                : const Color(0xFFFF5C5C))
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(VoltronRadii.sm),
                  ),
                  child: Text(
                    quote.status == QuoteStatus.accepted
                        ? 'Devis accepté — réparation en cours'
                        : 'Devis refusé',
                    style: TextStyle(
                      color: quote.status == QuoteStatus.accepted
                          ? VoltronColors.success
                          : const Color(0xFFFF5C5C),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: quote.status == QuoteStatus.pendingApproval
                    ? () {
                        ref
                            .read(repairsProvider.notifier)
                            .acceptQuote(order.dbId);
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Devis accepté, ta réparation avance !',
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text('ACCEPTER LE DEVIS'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: quote.status == QuoteStatus.pendingApproval
                    ? () {
                        ref
                            .read(repairsProvider.notifier)
                            .refuseQuote(order.dbId);
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Devis refusé')),
                        );
                      }
                    : null,
                child: const Text('REFUSER LE DEVIS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepositCard extends ConsumerWidget {
  final String orderDbId;
  final Quote quote;

  const _DepositCard({required this.orderDbId, required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountLabel =
        '${quote.depositAmount!.toStringAsFixed(2).replaceAll('.', ',')} €';

    if (quote.depositStatus == DepositStatus.paid) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VoltronColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(VoltronRadii.md),
          border: Border.all(
            color: VoltronColors.success.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: VoltronColors.success,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Acompte de $amountLabel payé ${quote.depositMethod == DepositMethod.online ? 'en ligne' : 'en magasin'}',
                style: const TextStyle(
                  color: VoltronColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VoltronColors.electricYellow.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(VoltronRadii.md),
        border: Border.all(
          color: VoltronColors.electricYellow.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACOMPTE REQUIS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              color: VoltronColors.electricYellow,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Un acompte de $amountLabel est demandé avant le début de l\'intervention.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          if (quote.depositMethod == DepositMethod.inStore) ...[
            const SizedBox(height: 6),
            const Text(
              'Vous avez choisi de le régler en boutique.',
              style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/repairs/deposit/$orderDbId'),
                  child: const Text(
                    'PAYER EN LIGNE',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await ref
                        .read(repairsProvider.notifier)
                        .chooseDepositInStore(orderDbId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Réglez l\'acompte directement en boutique.',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'PAYER EN MAGASIN',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
