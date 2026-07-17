class RepairService {
  final String id;
  final String name;
  final String duration;
  final String priceLabel;

  const RepairService({
    required this.id,
    required this.name,
    required this.duration,
    required this.priceLabel,
  });
}

enum RepairStepStatus { done, current, pending }

class RepairStep {
  final String label;
  final RepairStepStatus status;
  final String? date;
  final int position;

  const RepairStep({required this.label, required this.status, this.date, this.position = 0});
}

class QuoteLine {
  final String label;
  final double price;

  const QuoteLine(this.label, this.price);
}

enum QuoteStatus { pendingApproval, accepted, refused }

class Quote {
  /// Identifiant Supabase (uuid) de la table quotes.
  final String dbId;
  final String id;
  final String date;
  final List<QuoteLine> lines;
  final String estimatedDelay;
  final QuoteStatus status;

  const Quote({
    required this.dbId,
    required this.id,
    required this.date,
    required this.lines,
    required this.estimatedDelay,
    this.status = QuoteStatus.pendingApproval,
  });

  double get total => lines.fold(0, (sum, l) => sum + l.price);
}

class RepairOrder {
  /// Identifiant Supabase (uuid) de la table repair_orders — utilisé pour les
  /// requêtes/routes. [id] est le numéro de dossier affiché ("1258").
  final String dbId;
  final String id;
  final String scooterName;
  final List<RepairStep> steps;
  final Quote? quote;
  final String clientId;

  const RepairOrder({
    required this.dbId,
    required this.id,
    required this.scooterName,
    required this.steps,
    this.quote,
    required this.clientId,
  });

  RepairStep get currentStep =>
      steps.firstWhere((s) => s.status == RepairStepStatus.current, orElse: () => steps.last);

  bool get isComplete => steps.isNotEmpty && steps.last.status == RepairStepStatus.done;

  /// L'étape "Devis envoyé" bloque tant que le devis n'est pas accepté.
  bool get isBlockedOnQuote =>
      currentStep.label == 'Devis envoyé' && quote != null && quote!.status != QuoteStatus.accepted;
}
