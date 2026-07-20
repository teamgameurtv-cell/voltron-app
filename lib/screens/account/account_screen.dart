import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/client_avatar.dart';

class _AccountMenuItem {
  final String label;
  final IconData icon;
  final String? route;

  const _AccountMenuItem(this.label, this.icon, {this.route});
}

const List<_AccountMenuItem> _menuItems = [
  _AccountMenuItem('Mes informations', Icons.person_outline_rounded, route: '/account/info'),
  _AccountMenuItem('Mon Garage', Icons.garage_rounded, route: '/account/garage'),
  _AccountMenuItem('Adresses', Icons.location_on_outlined, route: '/account/addresses'),
  _AccountMenuItem('Moyens de paiement', Icons.credit_card_outlined, route: '/account/payment-methods'),
  _AccountMenuItem('Notifications', Icons.notifications_none_rounded, route: '/account/notification-settings'),
  _AccountMenuItem('Historique des réparations', Icons.history_rounded, route: '/account/repairs-history'),
  _AccountMenuItem('Mes factures', Icons.receipt_long_outlined, route: '/account/invoices'),
  _AccountMenuItem('Garantie et documents', Icons.shield_outlined, route: '/account/warranty'),
  _AccountMenuItem('Aide & contact', Icons.help_outline_rounded, route: '/account/help'),
  _AccountMenuItem('À propos de Voltron', Icons.info_outline_rounded, route: '/account/about'),
];

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlan = ref.watch(subscriptionProvider);
    final profile = ref.watch(profileProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                Image.asset('assets/images/voltron_logo.png', width: 32),
                const SizedBox(width: 10),
                const Text('COMPTE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    final file = result?.files.firstOrNull;
                    if (file?.bytes == null) return;
                    final ext = file!.extension ?? 'jpg';
                    await ref.read(profileProvider.notifier).updateAvatar(file.bytes!, ext);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo de profil mise à jour')),
                    );
                  },
                  child: Stack(
                    children: [
                      ClientAvatar(avatarUrl: profile.avatarUrl, radius: 28),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: VoltronColors.electricYellow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 12, color: VoltronColors.deepBlack),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name.isNotEmpty ? profile.name : 'Mon compte',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(currentUser?.email ?? profile.email,
                          style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => context.push('/loyalty/care'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: VoltronColors.cardBlack,
                  borderRadius: BorderRadius.circular(VoltronRadii.md),
                  border: Border.all(
                    color: activePlan != null ? VoltronColors.success.withValues(alpha: 0.5) : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      activePlan != null ? Icons.verified_rounded : Icons.shield_outlined,
                      color: activePlan != null ? VoltronColors.success : VoltronColors.greyText,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        activePlan != null ? 'Voltron Care ${activePlan.name} actif' : 'Aucun abonnement Voltron Care',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    Text(
                      activePlan != null ? 'Gérer' : 'Découvrir',
                      style: const TextStyle(color: VoltronColors.electricBlueGlow, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            if (activePlan?.id == 'plus') ...[
              const SizedBox(height: 10),
              _MenuTile(
                item: const _AccountMenuItem('Messagerie prioritaire', Icons.support_agent_rounded, route: '/support'),
                onTap: () => context.push('/support'),
              ),
            ],
            const SizedBox(height: 20),
            ..._menuItems.map((item) => _MenuTile(
                  item: item,
                  onTap: item.route != null ? () => context.push(item.route!) : () {},
                )),
            const SizedBox(height: 12),
            _MenuTile(
              item: const _AccountMenuItem('Déconnexion', Icons.logout_rounded),
              onTap: () async {
                await ref.read(authNotifierProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              destructive: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _AccountMenuItem item;
  final VoidCallback onTap;
  final bool destructive;

  const _MenuTile({required this.item, required this.onTap, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFFF5C5C) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VoltronRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: destructive ? color : VoltronColors.greyText),
            const SizedBox(width: 14),
            Expanded(
              child: Text(item.label, style: TextStyle(fontSize: 13, color: color)),
            ),
            if (!destructive)
              const Icon(Icons.chevron_right_rounded, color: VoltronColors.greyText, size: 20),
          ],
        ),
      ),
    );
  }
}
