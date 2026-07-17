import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/voltron_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
        title: const Text('AIDE & CONTACT'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VoltronColors.cardBlack,
                borderRadius: BorderRadius.circular(VoltronRadii.md),
              ),
              child: const Column(
                children: [
                  _ContactRow(icon: Icons.phone_outlined, label: '01 23 45 67 89'),
                  SizedBox(height: 12),
                  _ContactRow(icon: Icons.mail_outline, label: 'contact@voltron-scoot.fr'),
                  SizedBox(height: 12),
                  _ContactRow(icon: Icons.schedule_outlined, label: 'Lun-Sam, 10h-19h'),
                  SizedBox(height: 12),
                  _ContactRow(icon: Icons.location_on_outlined, label: '11 bis, rue de la Trottinette, Paris'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('QUESTIONS FRÉQUENTES',
                style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: VoltronColors.greyText)),
            const SizedBox(height: 12),
            const _FaqTile(
              question: 'Combien de temps dure une réparation ?',
              answer: 'La plupart des interventions courantes sont réalisées en 1 à 2 jours ouvrés après acceptation du devis.',
            ),
            const _FaqTile(
              question: 'Comment fonctionne le programme fidélité ?',
              answer: '1 € dépensé = 1 point. Les points sont utilisables contre des récompenses dans l\'onglet Fidélité.',
            ),
            const _FaqTile(
              question: 'Puis-je résilier Voltron Care à tout moment ?',
              answer: 'Oui, directement depuis l\'écran Voltron Care, sans engagement.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: VoltronColors.electricBlueGlow),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        iconColor: VoltronColors.electricYellow,
        collapsedIconColor: VoltronColors.greyText,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          Text(answer, style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
        ],
      ),
    );
  }
}
