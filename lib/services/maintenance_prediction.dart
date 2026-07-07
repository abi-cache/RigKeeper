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
/// typical PC. A future improvement: vary this per PC based on fan
/// count, case airflow type, or usage environment (dust, pets, etc)
/// as mentioned in the original project brief's "Smart Maintenance
/// Prediction" section.
const int _idealCleaningIntervalDays = 60;

/// Returns how many days until the next cleaning is "due".
/// A negative number means it's already overdue.
int predictNextCleaning({required int daysSinceLastCleaned}) {
  return _idealCleaningIntervalDays - daysSinceLastCleaned;
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

  final overdueBy = daysSinceLastCleaned - _idealCleaningIntervalDays;
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