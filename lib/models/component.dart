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
  final String? notes;

  const Component({
    required this.id,
    required this.pcId,
    required this.name,
    required this.category,
    this.serialNumber,
    this.manufacturingDate,
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
      notes: map['notes'] as String?,
    );
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