# Mobile — Deferred authentication (browse first, sign in to book)

The Guest App does **not** gate the app behind sign-in. A guest browses the
whole discovery + booking-review surface with no account; authentication is
requested only when they commit to a booking.

Source of truth: Figma board **`09 · Authentication`** —
*"التصفّح متاح دون حساب. يبدأ التسجيل عند «اختيار هذه الغرفة» – أول لحظة التزام
فعلي."* — and **`02 · Discover & Book`** — *"Browse the group, pick a room,
review before paying."*

## The gate

```
splash → language → welcome ──▶ discover ─▶ hotel ─▶ dates ─▶ rooms ─▶ room detail
                                      │
                                 (all public — no account)
                                      ▼
                            review  ──"confirm"──▶  [ sign in ]  ──▶  review  ──▶  reservation → payment → …
                                                   phone/OTP/profile      (selection intact)
```

* `/welcome` stays; its CTA (`entryStartAction`) now opens `/discover`, not
  sign-in.
* `RoomSelectionReviewPage` renders the full summary (room, dates, party, price,
  stay total) for a guest. Its primary CTA is **`reviewSignInToConfirm`**
  instead of `reservationConfirmCta`.
* Tapping it records the review location in `postAuthRedirectProvider` and routes
  to `/auth/phone`. After phone → OTP → (first-timers) profile, the router's
  `authenticated` branch **consumes** the remembered location and returns the
  guest to the review screen. The room selection survives because
  `roomSelectionControllerProvider` is a plain (non-autoDispose) provider.
* Everything under `/reservation/**` stays auth-only — it is only reachable once
  a reservation exists, which now always implies a session.

## Route sets — `lib/app/router/app_routes.dart`

| set | meaning |
|---|---|
| `authSurface` | language / welcome / signIn / otp / sessionExpired |
| `publicSurface` | discover, hotelSearch, hotelDetail, stayDates, availableRooms, roomDetail, **roomSelectionReview** — browsable while unauthenticated |
| everything else | auth-only |

`AppRoutes.isPublic(pattern)` is matched against `GoRouterState.fullPath` (the
route **pattern**, e.g. `/discover/hotel/:hotelId`), not the concrete location.

## Redirect — `lib/app/router/app_router.dart`

* `unauthenticated`: first-run language gate and `splash → welcome` unchanged;
  `onAuthSurface` or `isPublic(pattern)` → allowed; anything else → `/welcome`.
  (Deep-linking straight into an auth-only route while logged out is not a
  supported feature — `architecture.md §10` — so there is no return-path handling
  on that edge; the guest just lands on `/welcome`.)
* `authenticated`: when on splash / auth surface / profile, return
  `postAuthRedirectProvider.consume() ?? authenticatedHome`.
* `postAuthRedirectProvider` is **not** watched by `_AuthRouterRefresh`, so
  consuming it does not re-fire the redirect. It is set only from the widget at
  the gate, never from a provider `build`.

## `postAuthRedirectProvider`

`lib/features/authentication/presentation/state/post_auth_redirect_controller.dart`
— in-memory `Notifier<String?>` (`remember` / `consume`), same
deferred-persistence stance as `languageSelectedProvider`.

## Side effects

* **Sign-out** from `/discover` now leaves the guest on `/discover` in guest
  mode (was: bounce to `/welcome`).
* ~~The discover app bar shows a **sign-in** action for guests.~~ Removed with
  the v2 Home (Phase C, 2026-09-24, product decision): v2 `HOME_Default` has no
  sign-in entry, so a guest signs in when confirming a booking. Selecting the
  Account tab while signed out opens `/auth/phone`. The **Bookings** and
  **Services** tabs (`AppRoutes.guestTabs`) open for a guest and render
  `SignInRequiredView` ("sign in to continue" + CTA) instead of fetching data;
  the CTA remembers the tab in `postAuthRedirectProvider`, so after sign-in
  the guest lands back on it. Other protected routes still return guests to
  `/welcome`.
* The greeting already degrades to the generic `discoverGreeting` with no name.

## Tests

* `test/features/discovery/guest_browse_test.dart` — guest browses to review,
  sees `reviewSignInToConfirm`, signs in, is returned to the review screen and
  confirms.
* `test/support/pump_app.dart` → `pumpSignIn(tester)` jumps to `/auth/phone`
  (auth-screen tests can no longer reach it via the `/welcome` CTA).
