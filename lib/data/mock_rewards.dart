import '../models/reward.dart';

const List<CarePlan> mockCarePlans = [
  CarePlan(
    id: 'essentiel',
    name: 'ESSENTIEL',
    monthlyPrice: 9.90,
    features: [
      'Contrôle de sécurité',
      'Réglage des freins',
      'Serrage général',
    ],
  ),
  CarePlan(
    id: 'plus',
    name: 'PLUS',
    monthlyPrice: 19.90,
    recommended: true,
    features: [
      'Tout le pack Essentiel',
      'Nettoyage régulier',
      'Révision semestrielle',
      'Priorité atelier',
      '-15% sur certaines pièces',
      'Diagnostic prioritaire',
      'Messagerie prioritaire avec notre équipe',
    ],
  ),
];
