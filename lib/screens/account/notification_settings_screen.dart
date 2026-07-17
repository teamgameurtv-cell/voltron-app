import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/account_provider.dart';
import '../../theme/voltron_theme.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
        title: const Text('NOTIFICATIONS'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile(
              value: prefs.repairs,
              onChanged: (v) => notifier.update(repairs: v),
              activeColor: VoltronColors.electricYellow,
              title: const Text('Suivi de réparation', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Avancement de tes dossiers', style: TextStyle(color: VoltronColors.greyText, fontSize: 11)),
            ),
            SwitchListTile(
              value: prefs.promos,
              onChanged: (v) => notifier.update(promos: v),
              activeColor: VoltronColors.electricYellow,
              title: const Text('Promotions', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Offres et nouveautés boutique', style: TextStyle(color: VoltronColors.greyText, fontSize: 11)),
            ),
            SwitchListTile(
              value: prefs.loyalty,
              onChanged: (v) => notifier.update(loyalty: v),
              activeColor: VoltronColors.electricYellow,
              title: const Text('Fidélité', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Points, récompenses et Voltron Care', style: TextStyle(color: VoltronColors.greyText, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
