/// Represents one hardware component belonging to a PC.
///
/// [manufacturingDate] and [serialNumber] are nullable because not
/// every user will fill these in — the app should work fine with
/// just a name and category, and gain more detail (age-based
/// predictions later) as more fields get filled in over time.
class Component {
  final String id;
  final String pcId;
  final String name;
  final String category;
  final String? serialNumber;
  final DateTime? manufacturingDate;
  final DateTime? purchaseDate;
  final DateTime? installationDate;
  final DateTime? warrantyExpiration;
  final String? notes;

  const Component({
    required this.id,
    required this.pcId,
    required this.name,
    required this.category,
    this.serialNumber,
    this.manufacturingDate,
    this.purchaseDate,
    this.installationDate,
    this.warrantyExpiration,
    this.notes,
  });

  factory Component.fromMap(Map<String, dynamic> map) {
    return Component(
      id: map['id'] as String,
      pcId: map['pc_id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      serialNumber: map['serial_number'] as String?,
      manufacturingDate: map['manufacturing_date'] != null
          ? DateTime.parse(map['manufacturing_date'] as String)
          : null,
      purchaseDate: map['purchase_date'] != null
          ? DateTime.parse(map['purchase_date'] as String)
          : null,
      installationDate: map['installation_date'] != null
          ? DateTime.parse(map['installation_date'] as String)
          : null,
      warrantyExpiration: map['warranty_expiration'] != null
          ? DateTime.parse(map['warranty_expiration'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  /// Days left until warranty expires. Negative = already expired.
  /// Null if no warranty date was ever entered.
  int? get warrantyDaysLeft {
    if (warrantyExpiration == null) return null;
    return warrantyExpiration!.difference(DateTime.now()).inDays;
  }

  /// How old this component is, in whole years — used later for
  /// health scoring / maintenance prediction. Returns null if no
  /// manufacturing date was ever entered.
  int? get ageInYears {
    if (manufacturingDate == null) return null;
    final now = DateTime.now();
    int years = now.year - manufacturingDate!.year;
    if (now.month < manufacturingDate!.month ||
        (now.month == manufacturingDate!.month &&
            now.day < manufacturingDate!.day)) {
      years--;
    }
    return years;
  }

  /// A rough "typical lifespan" per category, in years — these are
  /// general industry rules of thumb (e.g. fans and thermal paste
  /// wear out faster than a case), NOT manufacturer-guaranteed
  /// figures. Used only to suggest "this might be worth checking
  /// soon," never as a hard failure prediction.
  int get typicalLifespanYears {
    switch (category) {
      case 'CPU':
        return 7;
      case 'GPU':
        return 5;
      case 'RAM':
        return 10;
      case 'Storage':
        return 5;
      case 'PSU':
        return 7;
      case 'CPU Cooler':
        return 5;
      case 'Fan':
        return 4;
      case 'Motherboard':
        return 8;
      case 'Case':
        return 15;
      default:
        return 6;
    }
  }

  /// Years remaining before this component reaches its typical
  /// lifespan. Negative means it's past the typical window — worth
  /// a closer look, not necessarily broken.
  int? get estimatedYearsRemaining {
    if (ageInYears == null) return null;
    return typicalLifespanYears - ageInYears!;
  }

  /// Whether to show an "approaching end of typical lifespan"
  /// suggestion — true once within 1 year of, or past, the typical
  /// lifespan for that category.
  bool get isApproachingLifespan {
    final remaining = estimatedYearsRemaining;
    if (remaining == null) return false;
    return remaining <= 1;
  }
}

/// Fixed list of suggested categories for the dropdown. Users aren't
/// restricted to only these (the DB column is plain text), but this
/// keeps data reasonably consistent without over-engineering an enum
/// this early.
const List<String> componentCategories = [
  'CPU',
  'GPU',
  'Motherboard',
  'RAM',
  'Storage',
  'PSU',
  'CPU Cooler',
  'Case',
  'Fan',
  'Other',
];