/// One maintenance event for a PC — a dust cleaning, a thermal paste
/// swap, a fan replacement, etc.
class MaintenanceLog {
  final String id;
  final String pcId;
  final DateTime logDate;
  final String type;
  final String? notes;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;

  const MaintenanceLog({
    required this.id,
    required this.pcId,
    required this.logDate,
    required this.type,
    this.notes,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
  });

  factory MaintenanceLog.fromMap(Map<String, dynamic> map) {
    return MaintenanceLog(
      id: map['id'] as String,
      pcId: map['pc_id'] as String,
      logDate: DateTime.parse(map['log_date'] as String),
      type: map['type'] as String,
      notes: map['notes'] as String?,
      beforePhotoUrl: map['before_photo_url'] as String?,
      afterPhotoUrl: map['after_photo_url'] as String?,
    );
  }

  int get daysAgo => DateTime.now().difference(logDate).inDays;
}

const List<String> maintenanceTypes = [
  'Dust cleaning',
  'Thermal paste replacement',
  'Fan replacement',
  'BIOS update',
  'SSD upgrade',
  'Other',
];