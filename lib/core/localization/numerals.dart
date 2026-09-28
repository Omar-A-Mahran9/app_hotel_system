import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_ar.dart';

/// The app's numeral rule (Figma v2, approved 2026-09-26).
///
/// In **Arabic** the v2 boards write dates, times, stay / guest / room /
/// hotel counts, durations and loyalty points in Arabic-Indic digits
/// (`٦ — ٨ سبتمبر · ليلتان`, `١٢٤٠ نقطة`, `٩:٤٣`, `٨ غرف متاحة`), while money,
/// ratings / review counts, room numbers, phone numbers, booking references,
/// PINs / OTP codes and areas stay Western (`945`, `4.8 · 217`, `غرفة 412`,
/// `+966 …`). English is always Western.
///
/// Dates already follow this through intl's `ar` date symbols. Counts reach
/// the UI through the plural strings, so [ArabicDigitsLocalizations] converts
/// exactly those; times use [localizeDigits] at their call sites. Money is
/// never passed through here ([MoneyText] keeps Western digits).
String localizeDigits(String text, String languageCode) {
  if (!languageCode.startsWith('ar')) return text;
  final StringBuffer out = StringBuffer();
  for (final int unit in text.codeUnits) {
    out.writeCharCode(unit >= 0x30 && unit <= 0x39 ? 0x0660 + unit - 0x30 : unit);
  }
  return out.toString();
}

extension LocalizedDigitsX on BuildContext {
  /// [localizeDigits] for the current locale — for times and other
  /// count-like values built outside the plural strings.
  String localDigits(String text) =>
      localizeDigits(text, Localizations.localeOf(this).languageCode);
}

/// Arabic strings with the numeral rule applied to every count / points /
/// duration message. Everything else is inherited unchanged.
class ArabicDigitsLocalizations extends AppLocalizationsAr {
  ArabicDigitsLocalizations([super.locale]);

  @override
  String notificationsUnreadTitle(int count) =>
      localizeDigits(super.notificationsUnreadTitle(count), localeName);

  @override
  String searchResultsCount(int count) =>
      localizeDigits(super.searchResultsCount(count), localeName);

  @override
  String filterMatchCount(int count) =>
      localizeDigits(super.filterMatchCount(count), localeName);

  @override
  String filterSelectedCount(int count) =>
      localizeDigits(super.filterSelectedCount(count), localeName);

  @override
  String cityHotelCount(int count) =>
      localizeDigits(super.cityHotelCount(count), localeName);

  @override
  String hotelRoomTypeCount(int count) =>
      localizeDigits(super.hotelRoomTypeCount(count), localeName);

  @override
  String hotelPhotoCount(int count) =>
      localizeDigits(super.hotelPhotoCount(count), localeName);

  @override
  String hotelGuestCount(int count) =>
      localizeDigits(super.hotelGuestCount(count), localeName);

  @override
  String stayNights(int count) =>
      localizeDigits(super.stayNights(count), localeName);

  @override
  String guestsAdultsCount(int count) =>
      localizeDigits(super.guestsAdultsCount(count), localeName);

  @override
  String guestsChildrenCount(int count) =>
      localizeDigits(super.guestsChildrenCount(count), localeName);

  @override
  String roomsAvailableCount(int count) =>
      localizeDigits(super.roomsAvailableCount(count), localeName);

  @override
  String roomOccupancy(int count) =>
      localizeDigits(super.roomOccupancy(count), localeName);

  @override
  String roomPolicyRefundable(int hours) =>
      localizeDigits(super.roomPolicyRefundable(hours), localeName);

  @override
  String roomStayTotalLabel(int nights) =>
      localizeDigits(super.roomStayTotalLabel(nights), localeName);

  @override
  String stayGuestsCount(int count) =>
      localizeDigits(super.stayGuestsCount(count), localeName);

  @override
  String reviewTotalLabel(int nights) =>
      localizeDigits(super.reviewTotalLabel(nights), localeName);

  @override
  String serviceEstimatedMinutes(int count) =>
      localizeDigits(super.serviceEstimatedMinutes(count), localeName);

  @override
  String loyaltyPointsValue(int points) =>
      localizeDigits(super.loyaltyPointsValue(points), localeName);

  @override
  String loyaltyPointsAdded(int points) =>
      localizeDigits(super.loyaltyPointsAdded(points), localeName);

  @override
  String loyaltyPointsRemoved(int points) =>
      localizeDigits(super.loyaltyPointsRemoved(points), localeName);

  @override
  String loyaltyRedeemMax(int points) =>
      localizeDigits(super.loyaltyRedeemMax(points), localeName);

  @override
  String loyaltyRedeemedBody(int points) =>
      localizeDigits(super.loyaltyRedeemedBody(points), localeName);

  @override
  String hotelRoomCount(int count) =>
      localizeDigits(super.hotelRoomCount(count), localeName);

  @override
  String hotelNearbyPlace(String place, int minutes) =>
      localizeDigits(super.hotelNearbyPlace(place, minutes), localeName);

  @override
  String policyGeneral(int hours) =>
      localizeDigits(super.policyGeneral(hours), localeName);

  @override
  String profileIdentityHotelCopyNote(int days) =>
      localizeDigits(super.profileIdentityHotelCopyNote(days), localeName);

  @override
  String bookingLoyaltyMaxHint(String points) =>
      localizeDigits(super.bookingLoyaltyMaxHint(points), localeName);

  @override
  String identityAttemptCount(int count) =>
      localizeDigits(super.identityAttemptCount(count), localeName);

  @override
  String authOtpErrorBody(int count) =>
      localizeDigits(super.authOtpErrorBody(count), localeName);
}

/// [AppLocalizations.delegate] with the Arabic numeral rule.
class AppLocalizationsWithNumeralsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsWithNumeralsDelegate();

  static const List<LocalizationsDelegate<dynamic>> delegates =
      <LocalizationsDelegate<dynamic>>[
    AppLocalizationsWithNumeralsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(
        locale.languageCode == 'ar'
            ? ArabicDigitsLocalizations()
            : lookupAppLocalizations(locale),
      );

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.delegate.isSupported(locale);

  @override
  bool shouldReload(AppLocalizationsWithNumeralsDelegate old) => false;
}
