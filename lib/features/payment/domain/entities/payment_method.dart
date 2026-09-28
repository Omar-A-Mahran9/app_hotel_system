import 'package:flutter/foundation.dart';

/// A guest-chosen way to pay, local to the device only.
///
/// This is a presentation-layer concept, not a backend one: the approved
/// deposit-hold contract (`PaymentHoldRequest`) carries no card data — the
/// MVP dummy gateway needs none, and a real integration would collect it
/// through the provider's own SDK/redirect, never through our API body
/// (mobile/docs/architecture.md §8). [PaymentMethodChoice] only drives which
/// screen the guest sees before that same hold request is submitted; nothing
/// here is sent to, or read from, the backend.
enum PaymentMethodKind { applePay, savedCard, newCard }

@immutable
class PaymentMethodChoice {
  const PaymentMethodChoice._(this.kind, {this.last4});

  static const PaymentMethodChoice applePay =
      PaymentMethodChoice._(PaymentMethodKind.applePay);

  /// A device-local placeholder "saved card" — no real card vault exists.
  factory PaymentMethodChoice.savedCard(String last4) =>
      PaymentMethodChoice._(PaymentMethodKind.savedCard, last4: last4);

  static const PaymentMethodChoice newCard =
      PaymentMethodChoice._(PaymentMethodKind.newCard);

  final PaymentMethodKind kind;

  /// Last 4 digits of a saved card, for display only. Never a full card
  /// number, never persisted, never sent anywhere.
  final String? last4;

  /// Whether choosing this method requires the card-details step before the
  /// hold can be requested.
  bool get needsCardDetails => kind == PaymentMethodKind.newCard;

  @override
  bool operator ==(Object other) =>
      other is PaymentMethodChoice && other.kind == kind && other.last4 == last4;

  @override
  int get hashCode => Object.hash(kind, last4);
}
