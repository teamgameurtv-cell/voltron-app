import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/account_provider.dart';
import '../../theme/voltron_theme.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('MES FACTURES'),
      ),
      body: SafeArea(
        child: invoicesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: VoltronColors.electricYellow,
            ),
          ),
          error: (err, _) => Center(
            child: Text(
              'Erreur : $err',
              style: const TextStyle(color: VoltronColors.greyText),
            ),
          ),
          data: (invoices) => invoices.isEmpty
              ? const Center(
                  child: Text(
                    'Aucune facture pour le moment.',
                    style: TextStyle(color: VoltronColors.greyText),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: VoltronColors.cardBlack,
                        borderRadius: BorderRadius.circular(VoltronRadii.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            color: VoltronColors.electricBlueGlow,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invoice.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  invoice.date,
                                  style: const TextStyle(
                                    color: VoltronColors.greyText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${invoice.amount.toStringAsFixed(2).replaceAll('.', ',')} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          if (invoice.fileUrl != null &&
                              invoice.fileUrl!.isNotEmpty)
                            IconButton(
                              onPressed: () => launchUrl(
                                Uri.parse(invoice.fileUrl!),
                                mode: LaunchMode.externalApplication,
                              ),
                              icon: const Icon(
                                Icons.download_outlined,
                                size: 18,
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
}
