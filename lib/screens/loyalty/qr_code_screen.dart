import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/voltron_theme.dart';

class QrCodeScreen extends ConsumerWidget {
  const QrCodeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final userId = ref.watch(currentUserProvider)?.id ?? '';
    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('MON QR CODE'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(profile.name.isNotEmpty ? profile.name : 'Mon compte',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${profile.loyaltyPoints} points disponibles',
                  style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
              const SizedBox(height: 24),
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(VoltronRadii.md),
                ),
                child: QrImageView(
                  data: 'VOLTRON-CLIENT:$userId',
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Présente ce code en boutique pour cumuler\nou utiliser tes points fidélité.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
