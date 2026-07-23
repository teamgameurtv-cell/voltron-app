import '../models/repair_step_task.dart';

/// Modèle de checklist à semer pour chaque étape à la création d'un dossier,
/// exactement comme les 8 [repairStepLabels] le sont déjà aujourd'hui.
/// "Trottinette déposée" et "Diagnostic en cours" ont une checklist détaillée ;
/// les autres étapes ont une simple tâche "Notes/Observations" par défaut.
/// Les tâches "note" et "counter" (photos) sont visibles du client une fois
/// renseignées (voir `client_repair_order_detail.dart`).
class RepairStepTaskTemplate {
  final RepairStepTaskKind kind;
  final String label;
  final int counterTarget;

  const RepairStepTaskTemplate({
    required this.kind,
    required this.label,
    this.counterTarget = 0,
  });
}

const _defaultTemplate = [
  RepairStepTaskTemplate(
    kind: RepairStepTaskKind.note,
    label: 'Notes/Observations',
  ),
];

const Map<String, List<RepairStepTaskTemplate>> repairStepTaskTemplates = {
  'Trottinette déposée': [
    RepairStepTaskTemplate(
      kind: RepairStepTaskKind.check,
      label: 'Vérifier l\'identité du client',
    ),
    RepairStepTaskTemplate(
      kind: RepairStepTaskKind.check,
      label: 'Contrôler l\'état général à l\'arrivée',
    ),
    RepairStepTaskTemplate(
      kind: RepairStepTaskKind.value,
      label: 'Relever le kilométrage',
    ),
    RepairStepTaskTemplate(
      kind: RepairStepTaskKind.counter,
      label: 'Prendre des photos',
      counterTarget: 4,
    ),
    RepairStepTaskTemplate(
      kind: RepairStepTaskKind.select,
      label: 'Enregistrer les accessoires fournis',
    ),
    RepairStepTaskTemplate(
      kind: RepairStepTaskKind.note,
      label: 'Notes/Observations',
    ),
  ],
  'Diagnostic en cours': [
    RepairStepTaskTemplate(
      kind: RepairStepTaskKind.note,
      label: 'Résultat du diagnostic',
    ),
    RepairStepTaskTemplate(
      kind: RepairStepTaskKind.counter,
      label: 'Photos du diagnostic',
      counterTarget: 4,
    ),
  ],
};

/// Accessoires courants proposés dans le sélecteur — liste fermée volontairement
/// simple plutôt qu'un champ libre, pour rester rapide à cocher en boutique.
const List<String> commonAccessories = [
  'Chargeur',
  'Antivol / cadenas',
  'Casque',
  'Sacoche',
  'Housse',
  'Clé',
];

/// Checklist rapide de vérification au dépôt (freins, accélération...), dans
/// l'ordre — semée une fois pour tout le dossier, visible du client une fois
/// cochée. (clé, libellé)
const List<(String, String)> dropoffCheckTemplate = [
  ('freins', 'Freins'),
  ('acceleration', 'Accélération'),
  ('etat_general', 'État général de la trottinette'),
  ('serrage', 'Serrage'),
  ('led', 'Éclairage / LED'),
  ('pression_pneus', 'Pression des pneus'),
];

List<RepairStepTaskTemplate> templateForStep(String stepLabel) =>
    repairStepTaskTemplates[stepLabel] ?? _defaultTemplate;
