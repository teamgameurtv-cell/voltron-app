import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/voltron_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
        title: const Text('À PROPOS'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.electric_scooter_rounded, color: VoltronColors.electricYellow, size: 56),
                const SizedBox(height: 16),
                const Text('VOLTRON', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 4),
                const Text('Plus qu\'une trott, un mode de vie',
                    style: TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                const SizedBox(height: 20),
                const Text('Version 0.1.0 (Sprint 5+)',
                    style: TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                const SizedBox(height: 20),
                TextButton(onPressed: () {}, child: const Text('Conditions générales d\'utilisation')),
                TextButton(onPressed: () {}, child: const Text('Politique de confidentialité')),
                TextButton(onPressed: () {}, child: const Text('Mentions légales')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
