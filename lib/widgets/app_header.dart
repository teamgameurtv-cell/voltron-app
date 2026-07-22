import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/account_provider.dart';
import '../providers/notifications_provider.dart';
import '../theme/voltron_theme.dart';
import 'client_avatar.dart';

/// En-tête (logo, salutation, cloche de notifications, avatar) affiché en
/// haut de chaque onglet de l'app pour un accès constant au compte/notifications.
class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final profile = ref.watch(profileProvider);
    final firstName = profile.firstName.trim().isEmpty
        ? null
        : profile.firstName.trim();

    return Row(
      children: [
        Image.asset('assets/images/voltron_logo.png', width: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName != null ? 'Salut $firstName !' : 'Salut !',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Prêt à rouler ?',
                style: TextStyle(color: VoltronColors.greyText, fontSize: 13),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () => context.push('/notifications'),
              icon: const Icon(Icons.notifications_none_rounded, size: 26),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: VoltronColors.electricYellow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        GestureDetector(
          onTap: () => context.push('/account'),
          child: ClientAvatar(avatarUrl: profile.avatarUrl, radius: 20),
        ),
      ],
    );
  }
}
