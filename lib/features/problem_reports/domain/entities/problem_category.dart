/// The fixed in-stay problem-report category catalogue, mirroring
/// `App\Domain\Support\Models\ProblemReport::CATEGORIES` **exactly**
/// (mobile/docs/architecture.md §6 — no invented categories). Order matches
/// `mobile/Design/13 · Report a problem.png` screen 1.
enum ProblemCategory {
  acHeating('ac_heating'),
  plumbingWater('plumbing_water'),
  electricityLighting('electricity_lighting'),
  roomCleanliness('room_cleanliness'),
  internetWifi('internet_wifi'),
  noiseDisturbance('noise_disturbance');

  const ProblemCategory(this.wireValue);

  final String wireValue;

  /// Falls back to [acHeating] for anything unrecognised — mirrors
  /// `ReviewStatus.fromWire` / `ServiceOrderStatus.fromWire` so entity fields
  /// stay non-nullable.
  static ProblemCategory fromWire(String? value) {
    for (final ProblemCategory c in ProblemCategory.values) {
      if (c.wireValue == value) return c;
    }
    return ProblemCategory.acHeating;
  }
}
