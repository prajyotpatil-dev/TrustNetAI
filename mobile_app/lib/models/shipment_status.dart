enum ShipmentStatus { pending, assigned, created, inTransit, delayed, delivered }

extension ShipmentStatusExtension on ShipmentStatus {
  String get firestoreValue {
    switch (this) {
      case ShipmentStatus.pending:
        return 'pending';
      case ShipmentStatus.assigned:
        return 'assigned';
      case ShipmentStatus.created:
        return 'created';
      case ShipmentStatus.inTransit:
        return 'in_transit';
      case ShipmentStatus.delayed:
        return 'delayed';
      case ShipmentStatus.delivered:
        return 'delivered';
    }
  }

  static ShipmentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ShipmentStatus.pending;
      case 'assigned':
        return ShipmentStatus.assigned;
      case 'in_transit':
        return ShipmentStatus.inTransit;
      case 'delayed':
        return ShipmentStatus.delayed;
      case 'delivered':
        return ShipmentStatus.delivered;
      case 'created':
      default:
        return ShipmentStatus.created;
    }
  }
}
