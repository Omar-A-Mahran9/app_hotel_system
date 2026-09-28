import 'guest_phone.dart';

/// The guest's account details as the mobile app knows them.
///
/// Laravel is the system of record (architecture.md §6). The app only holds
/// what the approved `09 · Authentication` screens collect: the verified phone
/// number and — for a first-time guest — a full name and email.
class GuestProfile {
  const GuestProfile({
    required this.phone,
    this.fullName,
    this.email,
  });

  final GuestPhone phone;
  final String? fullName;
  final String? email;

  /// The `إكمال البيانات` step is only shown while this is `false`.
  bool get isComplete =>
      (fullName?.trim().isNotEmpty ?? false) &&
      (email?.trim().isNotEmpty ?? false);

  GuestProfile copyWith({String? fullName, String? email}) => GuestProfile(
        phone: phone,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
      );

  @override
  bool operator ==(Object other) =>
      other is GuestProfile &&
      other.phone == phone &&
      other.fullName == fullName &&
      other.email == email;

  @override
  int get hashCode => Object.hash(phone, fullName, email);
}

/// An authenticated guest session: the bearer token plus the profile it belongs
/// to. The token is persisted through [TokenStore]; this object is the in-memory
/// view the presentation layer routes on.
class AuthSession {
  const AuthSession({required this.accessToken, required this.profile});

  final String accessToken;
  final GuestProfile profile;

  bool get isProfileComplete => profile.isComplete;

  AuthSession copyWith({String? accessToken, GuestProfile? profile}) =>
      AuthSession(
        accessToken: accessToken ?? this.accessToken,
        profile: profile ?? this.profile,
      );

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.accessToken == accessToken &&
      other.profile == profile;

  @override
  int get hashCode => Object.hash(accessToken, profile);
}
