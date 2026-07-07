/// Best-effort manufacturing date detection from serial numbers.
///
/// IMPORTANT LIMITATION: no manufacturer publishes an official,
/// guaranteed serial number format. Everything here is based on
/// commonly-cited community/hobbyist patterns, which can be wrong
/// for specific product lines, factories, or years. This is why
/// every result from this file should be labeled "Estimated" in the
/// UI, never "Confirmed" — and the user should always be able to
/// override it manually (see AddComponentScreen).
library;

class DecodedDate {
  final DateTime date;
  final String note;
  const DecodedDate(this.date, this.note);
}

/// Tries to find a 4-digit "YYWW" (year + week) code somewhere in
/// the serial number — a pattern used by several manufacturers
/// (memory, storage, PSUs) as a rough production date stamp.
///
/// This is intentionally generic rather than brand-specific, because
/// publicly confirmed, brand-specific formats are rare and change
/// over time. Returns null if no plausible YYWW pattern is found.
DecodedDate? _tryYearWeekPattern(String serial) {
  final digitsOnly = serial.replaceAll(RegExp(r'[^0-9]'), '');

  for (int i = 0; i <= digitsOnly.length - 4; i++) {
    final chunk = digitsOnly.substring(i, i + 4);
    final yy = int.tryParse(chunk.substring(0, 2));
    final ww = int.tryParse(chunk.substring(2, 4));

    if (yy == null || ww == null) continue;
    if (ww < 1 || ww > 52) continue;

    // Assume 2-digit year is 20xx if 00-30, otherwise skip — avoids
    // wildly implausible dates like the 1990s for modern parts.
    if (yy > 30) continue;

    final year = 2000 + yy;
    final approxDate = DateTime(year, 1, 1).add(Duration(days: (ww - 1) * 7));

    // Sanity check: don't return future dates.
    if (approxDate.isAfter(DateTime.now())) continue;

    return DecodedDate(
      approxDate,
      'Estimated from a YY$ww-style week/year code found in the serial. '
      'Verify against your invoice or manufacturer lookup tool if accuracy matters.',
    );
  }

  return null;
}

/// Attempts to decode a manufacturing date. Returns null if nothing
/// plausible was found — the UI should fall back to manual entry
/// in that case, not show an error.
DecodedDate? decodeManufacturingDate({
  required String brand,
  required String serialNumber,
}) {
  if (serialNumber.trim().isEmpty) return null;
  return _tryYearWeekPattern(serialNumber.trim());
}