/// The sort orders offered by `15 · Search, filters & sort` (screen "ترتيب
/// النتائج"). "الأقرب إليك" is shown locked in the reference — it needs the
/// guest's location, which is a later phase — so it is not a value here.
enum HotelSort {
  /// "المُوصى به" — the curated default order.
  recommended,

  /// "الأعلى تقييماً" — highest rated first.
  ratingDesc,

  /// "الأوفر سعراً" — lowest nightly rate first.
  priceAsc,
}
