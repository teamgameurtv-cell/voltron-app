import '../models/repair.dart';

const List<RepairService> mockRepairServices = [
  RepairService(id: 'pneu', name: 'Changement de pneu', duration: '45 min', priceLabel: 'à partir de 35 €'),
  RepairService(id: 'freins', name: 'Réglage des freins', duration: '30 min', priceLabel: '25 €'),
  RepairService(id: 'revision', name: 'Révision complète', duration: '1h00', priceLabel: '75 €'),
  RepairService(id: 'diagnostic', name: 'Diagnostic électrique', duration: '1h00', priceLabel: '45 €'),
  RepairService(id: 'batterie', name: 'Réparation batterie', duration: '1h30', priceLabel: 'à partir de 90 €'),
  RepairService(id: 'perso', name: 'Personnalisation', duration: '', priceLabel: 'Sur devis'),
];
