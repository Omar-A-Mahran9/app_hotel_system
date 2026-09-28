/// Sort orders for the available-rooms list (`16 · Stay dates & available
/// rooms`, the "ترتيب الغرف" sheet). "الأنسب مساحةً" is shown locked in the
/// reference, so it is not a value here.
enum RoomSort {
  /// "الأقل سعراً" — cheapest nightly rate first (the reference's default).
  priceAsc,

  /// "الأكثر سعراً" — most expensive first.
  priceDesc,
}
