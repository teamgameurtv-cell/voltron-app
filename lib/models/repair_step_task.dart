/// Détermine le widget de rendu et quelle colonne fait foi pour une sous-tâche
/// de la checklist "ÉTAPE ACTUELLE" : [check] une case à cocher, [value] un
/// champ éditable (ex. kilométrage), [counter] un compteur dérivé des photos
/// liées à cette tâche, [select] une sélection multiple (ex. accessoires),
/// [note] un texte libre.
enum RepairStepTaskKind { check, value, counter, select, note }

class RepairStepTask {
  final String id;
  final String orderId;
  final String stepId;
  final RepairStepTaskKind kind;
  final String label;
  final int position;
  final bool done;
  final String? valueText;
  final int counterTarget;
  final List<String> selectedOptions;
  final DateTime updatedAt;

  const RepairStepTask({
    required this.id,
    required this.orderId,
    required this.stepId,
    required this.kind,
    required this.label,
    this.position = 0,
    this.done = false,
    this.valueText,
    this.counterTarget = 0,
    this.selectedOptions = const [],
    required this.updatedAt,
  });

  factory RepairStepTask.fromMap(Map<String, dynamic> map) {
    return RepairStepTask(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      stepId: map['step_id'] as String,
      kind: RepairStepTaskKind.values.byName(map['kind'] as String),
      label: map['label'] as String,
      position: map['position'] as int? ?? 0,
      done: map['done'] as bool? ?? false,
      valueText: map['value_text'] as String?,
      counterTarget: map['counter_target'] as int? ?? 0,
      selectedOptions:
          (map['selected_options'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
