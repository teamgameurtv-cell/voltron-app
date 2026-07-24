class RepairService {
  final String id;
  final String name;
  final String duration;
  final String priceLabel;
  final String? description;
  final String? imageUrl;

  const RepairService({
    required this.id,
    required this.name,
    required this.duration,
    required this.priceLabel,
    this.description,
    this.imageUrl,
  });

  RepairService copyWith({
    String? name,
    String? duration,
    String? priceLabel,
    String? description,
    String? imageUrl,
  }) {
    return RepairService(
      id: id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      priceLabel: priceLabel ?? this.priceLabel,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory RepairService.fromMap(Map<String, dynamic> map) {
    return RepairService(
      id: map['id'] as String,
      name: map['name'] as String,
      duration: map['duration'] as String? ?? '',
      priceLabel: map['price_label'] as String? ?? '',
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }
}

enum RepairStepStatus { done, current, pending }

class RepairStep {
  final String id;
  final String label;
  final RepairStepStatus status;
  final String? date;
  final int position;
  final String? note;

  const RepairStep({
    required this.id,
    required this.label,
    required this.status,
    this.date,
    this.position = 0,
    this.note,
  });
}

class QuoteLine {
  final String label;
  final double price;

  const QuoteLine(this.label, this.price);
}

enum QuoteStatus { pendingApproval, accepted, refused }

enum DepositStatus { none, pending, paid }

enum DepositMethod { online, inStore }

class Quote {
  /// Identifiant Supabase (uuid) de la table quotes.
  final String dbId;
  final String id;
  final String date;
  final List<QuoteLine> lines;
  final String estimatedDelay;
  final QuoteStatus status;
  final String? fileUrl;
  final String? note;
  final double? depositAmount;
  final DepositStatus depositStatus;
  final DepositMethod? depositMethod;
  final String? depositPaidAt;

  const Quote({
    required this.dbId,
    required this.id,
    required this.date,
    required this.lines,
    required this.estimatedDelay,
    this.status = QuoteStatus.pendingApproval,
    this.fileUrl,
    this.note,
    this.depositAmount,
    this.depositStatus = DepositStatus.none,
    this.depositMethod,
    this.depositPaidAt,
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
  final bool archived;

  /// Lien optionnel vers un véhicule enregistré (scooters.id) — permet
  /// d'afficher kilométrage/batterie/couleur/photo ; reste null pour les
  /// dossiers créés sans sélectionner de véhicule précis (scooterName suffit).
  final String? scooterId;
  final String? technicianId;
  final String? dropoffDate;
  final String? appointmentDay;
  final String? appointmentTime;
  final String arrivalCondition;
  final String? dropoffReportUrl;
  final String? dropoffClientNote;

  const RepairOrder({
    required this.dbId,
    required this.id,
    required this.scooterName,
    required this.steps,
    this.quote,
    required this.clientId,
    this.archived = false,
    this.scooterId,
    this.technicianId,
    this.dropoffDate,
    this.appointmentDay,
    this.appointmentTime,
    this.arrivalCondition = 'À compléter',
    this.dropoffReportUrl,
    this.dropoffClientNote,
  });

  RepairStep get currentStep => steps.firstWhere(
    (s) => s.status == RepairStepStatus.current,
    orElse: () => steps.last,
  );

  bool get isComplete =>
      steps.isNotEmpty && steps.last.status == RepairStepStatus.done;

  /// L'étape "Devis envoyé" bloque tant que le devis n'est pas accepté.
  bool get isBlockedOnQuote =>
      currentStep.label == 'Devis envoyé' &&
      quote != null &&
      quote!.status != QuoteStatus.accepted;
}
