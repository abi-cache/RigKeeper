/// Rule-based maintenance prediction.
///
/// This is intentionally simple and fully explainable — every number
/// it produces can be traced back to a plain formula, not a black
/// box. That's a deliberate choice for now: there's no historical
/// usage data yet to train a machine learning model against, and a
/// transparent rule is something you can confidently explain in a
/// capstone defense. Once real usage data accumulates across many
/// users, this is the natural place to swap in a smarter model —
/// the rest of the app doesn't need to change, since everything
/// else just calls [predictNextCleaning] and [calculateHealthScore].
library;

/// How many days between cleanings we assume is "ideal" for a
/// typical PC under average conditions. This is the baseline before
/// any environment adjustments are applied below.
const int _baseCleaningIntervalDays = 60;

/// Adjusts the base interval based on real environment factors from
/// the original brief: dust exposure, pets, and usage hours. Still
/// fully rule-based and explainable — each adjustment is a plain,
/// named reason, not a hidden weight in a model.
int _adjustedIdealInterval({
  required String dustLevel,
  required bool hasPets,
  required int dailyUsageHours,
}) {
  int interval = _baseCleaningIntervalDays;

  switch (dustLevel) {
    case 'low':
      interval += 15;
      break;
    case 'high':
      interval -= 20;
      break;
    default: // 'medium'
      break;
  }

  if (hasPets) {
    interval -= 15; // pet hair/dander clogs filters faster
  }

  if (dailyUsageHours >= 10) {
    interval -= 10; // more runtime = more airflow = more dust pulled in
  } else if (dailyUsageHours <= 2) {
    interval += 10;
  }

  // Never let environment factors push the interval below 14 days —
  // avoids nonsensical "clean every 3 days" results from stacking
  // multiple adjustments.
  return interval < 14 ? 14 : interval;
}

/// Returns how many days until the next cleaning is "due", now
/// factoring in the PC's environment. A negative number means it's
/// already overdue.
int predictNextCleaning({
  required int daysSinceLastCleaned,
  String dustLevel = 'medium',
  bool hasPets = false,
  int dailyUsageHours = 4,
}) {
  final idealInterval = _adjustedIdealInterval(
    dustLevel: dustLevel,
    hasPets: hasPets,
    dailyUsageHours: dailyUsageHours,
  );
  return idealInterval - daysSinceLastCleaned;
}

/// A simple 0-100 score. Starts at 100 and drops as:
/// - cleaning becomes overdue (up to -40 points)
/// - components get older on average (up to -20 points)
///
/// Clamped so it never goes below 0 or above 100.
int calculateHealthScore({
  required int daysSinceLastCleaned,
  required double averageComponentAgeYears,
}) {
  double score = 100;

  final overdueBy = daysSinceLastCleaned - _baseCleaningIntervalDays;
  if (overdueBy > 0) {
    // Lose up to 40 points as cleaning gets more overdue, capped so
    // one very old PC doesn't return a nonsensical negative score.
    score -= (overdueBy / 2).clamp(0, 40);
  }

  // Lose up to 20 points as average component age increases,
  // roughly -4 points per year old, capped at 20.
  score -= (averageComponentAgeYears * 4).clamp(0, 20);

  return score.clamp(0, 100).round();
}