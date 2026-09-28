# Mobile Phase 10 — Loyalty + Reviews

The guest-facing loyalty surface (balance, history, earn, redeem —
`14 · Entry, loyalty & completion`) and post-stay reviews
(`05 · Depart & Invoice` — "كيف كانت إقامتك؟").

**The backend is authoritative for loyalty accounting and eligibility and for
review eligibility + moderation.** The app never computes a balance, never
invents a points rate / currency value / conversion, never assumes a review is
published. Everything in this phase is a deterministic dummy plus a documented
API stub — **no backend code, route, migration, resource or Postman entry was
touched.**

## Scope

* Loyalty: group-wide account (balance cache + program-active flag), the
  immutable transaction ledger (read-only copy), **earn** for an eligible
  completed stay, **redeem** against an eligible active booking. Contextual —
  always scoped to one reservation.
* Reviews: one review per eligible completed/stayed reservation, numeric rating
  1–5 + optional free text, and the moderation state (`pending` / `published` /
  `rejected`), plus optional ratings for the hotel's **dynamic review
  categories** (see *Dynamic review categories* below).
* Reservation-detail entry points, gated on the completed-stay statuses.
* Deterministic dummy behaviour while no guest-facing contract exists.

### Explicitly NOT built (no approved contract / MVP forbids)

Tiers, rewards catalogue, points expiration, conversion rate, currency value,
discount %, min/max points, category-specific loyalty rules, multi-rule
stacking, generic service/folio points redemption, arbitrary (non-stay)
reviews, editing/deleting a submitted review. (Hardcoded category columns such
as `cleanliness_rating` are deliberately **not** used — categories are
dynamic.)

## Loyalty domain

`lib/features/loyalty/domain/entities/`:

| type | mirrors | notes |
|---|---|---|
| `LoyaltyTransactionType` | `LoyaltyTransaction::TYPES` **exactly** | `earn` / `redeem` / `reverse` / `adjust` / `expire`; unknown → `adjust`; `expire` is modelled but never written (no expiration in the MVP) |
| `LoyaltyAccount` | `LoyaltyAccountResource` safe fields | `pointsBalance` is a **backend cache**; `isActive` is `false` until a Group Owner configures a valid rule (loyalty OFF until then) |
| `LoyaltyTransaction` | `LoyaltyTransactionResource` safe fields | signed `points` delta read verbatim; `earnBaseAmount` / `notionalValue` are display-only strings from `metadata` |
| `LoyaltyContext` | — | seeded from the authoritative reservation; the real API needs none of it |
| `LoyaltyEarnOutcome` | branches of the backend earn path | `earned` / `alreadyEarned` (idempotent replay) / `notEligible` / `programInactive` / `nothingToEarn` |
| `LoyaltyRedeemOutcome` | branches of the backend redeem path | `redeemed` / `alreadyRedeemed` / `alreadyRedeemedDifferent` / `insufficientPoints` / `notEligible` / `programInactive` / `invalidAmount` |

Business outcomes ride on the `EarnPointsResult` / `RedeemPointsResult` objects
as domain enums — **never** as a `Failure` (matching the Phase 5/9 precedent).
Only infrastructure errors become a `Failure`, via `ErrorMapper.toFailure` in
the repository `_guard`.

### Eligibility (UX pre-check — the backend stays the authority)

* **Earn** — reservation status ∈ {`CHECKED_OUT`, `INVOICED`}
  (`LoyaltyService::COMPLETED_RESERVATION_STATUSES`).
* **Redeem** — reservation status ∈ {`PENDING`, `DEPOSIT_HELD`, `VERIFIED`,
  `CHECKED_IN`, `IN_STAY`} (`LoyaltyService::REDEEMABLE_RESERVATION_STATUSES`).

### Idempotency

* `EarnPointsRequest.idempotencyKey` = `loyalty:earn:<reservationId>` — the
  approved backend earn carries no body; its idempotency is the
  `(account, type, source)` uniqueness.
* `RedeemPointsRequest.idempotencyKey` = `loyalty:redeem:<reservationId>:<points>`
  — a changed amount is a distinct operation.
* The earn/redeem controllers no-op a duplicate submit while submitting or after
  a successful done for the same request; a stale async result is dropped when a
  newer request superseded it.
* **The balance is never mutated locally.** On a successful earn/redeem the
  account + ledger providers are invalidated and re-read.

## Review domain

`lib/features/reviews/domain/entities/`:

| type | notes |
|---|---|
| `ReviewStatus` | `pending` / `published` / `rejected`; unknown/null → `pending`. Only `published` means "live" |
| `Review` | one per reservation; `rating` 1–5; optional `text` (never whitespace-only) |
| `ReviewDraft` | in-progress rating + text; validation lives here (`canSubmit` = rating 1–5) |
| `ReviewEligibility` | `eligible` (`CHECKED_OUT` / `INVOICED`) / `notCompleted` / `cancelled` — the same "completed stay" concept the backend uses |
| `ReviewContext` | seeded from the authoritative reservation |
| `SubmitReviewRequest` | `idempotencyKey` = `review:<id>:<rating>:<text-or-dash>` (+ `:<id=rating,…>` when category ratings are given) |
| `ReviewSubmitOutcome` | `submitted` / `alreadyReviewed` / `notEligible` / `invalidRating` |
| `ReviewCategory` | one of the hotel's dashboard-managed criteria (`id`, `label`, `description?`, `icon?`) |
| `ReviewCategoryRating` | a rating a review gave one category (`categoryId`, snapshot `label`, `rating`) |

## Dynamic review categories (2026-09-24)

Each hotel defines its own review categories in the dashboard (Hotel →
Reviews → *Review categories*: add / edit / activate-deactivate / reorder /
delete-while-unrated). **Nothing about them is hardcoded** — not in the
backend, not in Flutter: no fixed names, count or ids.

* **Form** — `reviewCategoriesProvider(reservationId)` fetches the
  reservation hotel's *active* categories
  (`GET /guest/hotels/{hotel}/review-categories`) and the form adds one star
  row per entry under the overall rating. Category ratings are optional; the
  overall rating stays required. With no categories (or while loading / on
  error) the form is just the overall rating + text.
* **Submit** — `POST /guest/reservations/{reservation}/review` with
  `{rating, text?, category_ratings?: [{category_id, rating}]}`. The backend
  rejects a category that isn't an active category of that hotel
  (`422 invalid_category:{id}`).
* **Read** — a review's `category_ratings[{category_id, label, rating}]`
  carry the **snapshot** label taken at rating time, so a later rename never
  changes what the guest rated; the existing-review view lists them.
* **Hotel detail** — `review_summary` on `GET /guest/hotels/{hotel}` drives
  the reviews section: published overall average + count and each active
  category's live average (published reviews only). Any number of categories
  renders; unrated ones are hidden; the section is hidden while nothing is
  rated.
* **Dummy mode** returns **no** categories and no summary — inventing a set
  would hardcode them.

Backend: `review_categories` + `review_category_ratings` (review ↔ category
junction with label snapshot), `ReviewCategoryService`, staff analytics at
`GET /hotels/{hotel}/reviews/analytics`.

## UI flow

```
Reservation Detail  (only when status ∈ {CHECKED_OUT, INVOICED})
   │  "Loyalty & points"                       │  "Leave a review" / "View your review"
   ▼                                           ▼
LoyaltyPage                                  ReviewFormPage
  · program-off banner (isActive == false)     · existing review → read-only card + status pill
  · LoyaltyBalanceCard (group-wide note,        · not eligible → MessageView
    no tier / rate / conversion)                · else → RatingSelector (1–5) + optional text
  · Earn section (completed stay):                    │  "Submit review"
      earned / alreadyEarned / notEligible /          ▼
      programInactive / nothingToEarn banner    ReviewProcessingPage — clear state, no cancel
  · Redeem section (hasPoints & redeemable):          ▼
      → LoyaltyRedeemPage (± stepper, "use max") ReviewResultPage
  · Points history (read-only copy, newest        submitted  → "Thanks" (+ pending-moderation note
    first, "this stay" chip, empty state)                       when status == pending)
                                                  alreadyReviewed / notEligible / invalidRating
                                                    → plain explanation
                                                  infra failure → "Try again"
```

Routes (all auth-guarded, inherit the router's unauthenticated redirect):
`/reservation/:reservationId/loyalty`, `.../loyalty/redeem`, `.../review`,
`.../review/processing`, `.../review/result`. The processing page uses
`pushReplacementNamed`; the result "Back to reservation" uses `goNamed`.

Reusable widgets: `LoyaltyBalanceCard`, `LoyaltyTransactionTile`,
`RatingSelector` / `RatingDisplay` (per-star `Semantics`), `ReviewStatusPill`.
`InfoBannerTone.success` was added to the core `InfoBanner` (additive; existing
tokens `semantic.success` / `successContainer`).

Icon / card / banner based — **no image assets added.**

## State management

`loyalty_providers.dart` / `review_providers.dart`:

* `_dummyLoyaltyProvider` / `_dummyReviewProvider` — one session-alive instance
  so an earn/redeem/submit done here is reflected by later reads.
* `loyaltyDataSourceProvider` / `reviewDataSourceProvider` — switch on
  `AppConfig.useDummyData`.
* `loyaltyContextProvider` / `reviewContextProvider` — `FutureProvider.autoDispose`
  families deriving the context from `reservationDetailProvider`.
* `loyaltyAccountProvider`, `loyaltyTransactionsProvider`,
  `reservationReviewProvider` — `autoDispose` family reads.
* `loyaltyEarnControllerProvider`, `loyaltyRedeemControllerProvider`,
  `reviewSubmissionControllerProvider` — `Notifier`s with a sealed
  `idle / submitting / done / failed` state; guarantees as above.

## Data layer

```
LoyaltyRepository                 ReviewRepository
 └── LoyaltyDataSource             └── ReviewDataSource
       ├── DummyLoyaltyDataSource        ├── DummyReviewDataSource
       └── ApiLoyaltyDataSource (stub)   └── ApiReviewDataSource (stub)
```

`loyalty_models.dart` mirrors `LoyaltyAccountResource` /
`LoyaltyTransactionResource`; the redeem body is `{ points }` (nothing else).
`review_models.dart` mirrors the *expected* future `ReviewResource`
(`id`, `reservation_id`, `rating`, `text`, `status`, `created_at`).

### API contract status — **not integrated (stubbed)**

Both `Api*DataSource` classes raise `NotImplementedInPhaseException`.

**Loyalty** — the endpoints exist but are **staff/dashboard-scoped**:

* `GET  /api/v1/reservations/{reservation}/loyalty` → `LoyaltyAccountResource`
* `GET  /api/v1/reservations/{reservation}/loyalty/transactions`
* `POST /api/v1/reservations/{reservation}/loyalty/earn` (no body) → `201`
* `POST /api/v1/reservations/{reservation}/loyalty/redeem` (`{points}`) → `201`

`LoyaltyController` resolves the reservation via
`ReservationService::findAccessibleBy($request->user(), …)` and authorises with
`LoyaltyPolicy` against the acting user's hotel access — the docblock is
explicit that *"guest authentication does not exist in this MVP"*. All business
preconditions come back as **HTTP 422** with a message embedding a machine
reason (`loyalty_program_inactive`, `reservation_not_completed:*`,
`insufficient_points_balance`, `already_redeemed_against_this_booking`, …).

**Backend integration still required (loyalty):**

1. A guest-authenticated loyalty surface (guest token; guest identity + hotel
   scope resolved server-side from the reservation).
2. A way to distinguish "just earned" (`201`, new) from "already earned" (the
   idempotent replay also returns `201`) — a `created` flag, a distinct
   `200`-vs-`201`, or a structured `outcome`.
3. A structured business-outcome instead of `422`-with-reason-code, so the
   adapter can map to `LoyaltyEarnOutcome` / `LoyaltyRedeemOutcome` without
   string-parsing.

**Reviews** — **there is no backend review domain at all.** Expected future
guest contract:

* `GET  /api/v1/reservations/{reservation}/review` → `200 ReviewResource` | `404`
* `POST /api/v1/reservations/{reservation}/review` (`{rating: 1..5, text?}`)
  → `201` (status `pending` while moderation is on) / `409`|`422` already exists
  (return the existing one) / `422` `reservation_not_completed:*`.

Eligibility, ownership, the one-review-per-stay rule and moderation are all
resolved server-side.

## Dummy datasource behaviour

**`DummyLoyaltyDataSource`** — one guest account + ledger per session.

* Seeded balance `1240`; ledger seeded with two `earn` + one `redeem` entry
  (unrelated reservation ids), so "this stay" highlighting and the empty state
  are both exercised. `seedLedger: false` gives an empty account.
* Scenario is a pure function of the reservation id:
  `earnScenarioFor` (`earnsFresh` / `alreadyEarned`),
  `redeemScenarioFor` (`redeemsOk` / `alreadyRedeemed`),
  `programActiveFor` (off for one deterministic 1-in-5 slice).
* **Dummy sample rates, documented as NOT a production rule** (there is no
  seeded backend rate): earn = 1 pt per 2 currency units; redeem notional value
  = 0.05 currency per pt. These drive display only; the backend computes the
  real figures.
* `earn` is idempotent (second call → `alreadyEarned`, no double accrual);
  `redeem` is idempotent for the same amount.
* No `Random`, no `DateTime.now()` branching (`clock` injected for entry
  timestamps only). `failWith` is a test seam.

**`DummyReviewDataSource`** — any review submitted this session is persisted so
a later fetch is consistent.

* Scenario from the reservation id: `noReviewThenPending` / `noReviewThenPublished`
  / `alreadyReviewedPending` / `alreadyReviewedRejected`.
* `submit` is idempotent — a reservation that already has a review returns the
  existing one (`alreadyReviewed`), never a duplicate.
* The app reads `Review.status` and never assumes publication.

## Reservation-detail integration

`_CompletedStayActions` (a small `ConsumerWidget`) renders **only** when the
reservation status ∈ {`CHECKED_OUT`, `INVOICED`} — otherwise
`SizedBox.shrink()`, so the Phase 5–9 CTAs above it are untouched. It adds a
"Loyalty & points" `SecondaryButton` and a review `SecondaryButton` whose label
is "View your review" when `reservationReviewProvider` reports an existing
review, else "Leave a review".

## Localization

~70 new keys added to **both** `app_en.arb` and `app_ar.arb` (loyalty ~45,
reviews ~28, three reservation CTA labels). Parameterised / plural keys:
`loyaltyPointsValue`, `loyaltyEarnedBody`, `loyaltyPointsAdded`,
`loyaltyPointsRemoved`, `loyaltyRedeemedBody`, `loyaltyRedeemedValueNote`,
`loyaltyRedeemMax`, `reviewStarsLabel`. Regenerated via `flutter gen-l10n`.
No English text hard-coded in a widget; enum → string mapping lives in
`loyalty_l10n.dart` / `reviews_l10n.dart` extensions. Both flows are verified
RTL in Arabic.

## Security / business rules

* No payment, identity or access credential is stored, logged or sent. Loyalty
  and review payloads carry no card / provider / secret data.
* The client sends **no** guest id, reservation-ownership claim, hotel id,
  balance, earned points, redemption eligibility, review eligibility or
  moderation state — every one of those is server-resolved.
* Business declines are domain outcomes, not errors; `NotImplementedInPhaseException`
  messages carry no sensitive data; guest-facing errors go through
  `Failure.localizedMessage`.

## Tests

`test/features/loyalty/` and `test/features/reviews/` (+ one
`test/features/reservation/reservation_completed_actions_test.dart`):

* **Domain** — transaction-type wire round-trip + `adjust` fallback, signed
  magnitude / credit / debit, `isForReservation`, account `hasPoints` /
  `unknown`, context eligibility for every reservation status, idempotency-key
  stability, outcome success/blocked partitions; review status round-trip,
  draft validation (rating range, optional/whitespace text, `copyWith`),
  eligibility, `SubmitReviewRequest` key + `toDraft` round-trip.
* **Models** — resource parsing incl. `metadata` figures, unknown enum
  fallbacks, `RedeemLoyaltyPayload` / `SubmitReviewPayload` serialisation.
* **Dummy datasources** — seeded balance + ledger order, earn (fresh /
  idempotent / already-earned / not-eligible / program-off / nothing-to-earn),
  redeem (ok / idempotent-replay / different-amount / insufficient / invalid /
  not-eligible), review (pending / published / already-reviewed / rejected /
  invalid-rating / not-eligible / optional-text / idempotent), `failWith` seam.
* **API stubs** — every method raises `NotImplementedInPhaseException`.
* **Controllers** — idle→submitting→done, duplicate-submit no-op,
  blocked-outcome-is-a-done, infra-failure→failed + retry recovers, balance
  re-read (not mutated), changed-amount / edited-draft is a fresh request,
  reset.
* **Routing** — the five new routes registered alongside the earlier ones;
  unauthenticated deep links redirect to welcome.
* **Widget flows** — loyalty: earn → updated summary, program-off banner,
  history list, Arabic RTL. Reviews: rate → submit → processing → "thanks"
  (pending-moderation note), missing-rating validation, existing-review
  read-only, non-completed not-eligible, Arabic RTL.
* **Reservation detail** — completed stay shows both CTAs and keeps the Phase
  5–9 CTAs; an in-progress stay shows neither; an already-reviewed stay shows
  "view your review".

`flutter test` — all pass. `flutter analyze` — clean. `flutter build web` —
succeeds.

## Known limitations

* No real loyalty engine or review backend — deterministic dummy only; the
  dummy rates are samples, not production values.
* The API data sources are stubs; wiring them needs an approved guest contract
  for **both** features (§ API contract status).
* The design (`14 · Entry, loyalty & completion`) shows tiers + a rewards
  catalogue — deliberately out of scope (the MVP backend has neither and the
  brief forbids inventing them).
* No standalone `/loyalty` or `/reviews` surface — both are always
  reservation-scoped (there is no guest bookings list and no guest-standalone
  endpoint).
* The reservation status is never transitioned locally; loyalty / review state
  is reflected independently of it.

## Missing assets

None. All screens use design-system components and Material glyphs.
