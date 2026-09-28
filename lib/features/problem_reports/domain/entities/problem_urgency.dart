/// The urgency the guest assigns to a problem report, mirroring
/// `App\Domain\Support\Models\ProblemReport::URGENCIES` exactly.
enum ProblemUrgency {
  normal('normal'),
  important('important'),
  urgent('urgent');

  const ProblemUrgency(this.wireValue);

  final String wireValue;

  /// Falls back to [normal] for anything unrecognised.
  static ProblemUrgency fromWire(String? value) {
    for (final ProblemUrgency u in ProblemUrgency.values) {
      if (u.wireValue == value) return u;
    }
    return ProblemUrgency.normal;
  }
}
