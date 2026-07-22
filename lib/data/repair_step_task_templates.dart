import '../models/repair_step_task.dart';

/// Modèle de checklist à semer pour chaque étape à la création d'un dossier,
/// exactement comme les 8 [repairStepLabels] le sont déjà aujourd'hui. Seule
/// "Trottinette déposée" a une checklist détaillée pour l'instant ; les autres
/// étapes ont une simple tâche "Notes/Observations" par défaut.
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

List<RepairStepTaskTemplate> templateForStep(String stepLabel) =>
    repairStepTaskTemplates[stepLabel] ?? _defaultTemplate;
