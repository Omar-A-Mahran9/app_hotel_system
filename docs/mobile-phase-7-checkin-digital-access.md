# Mobile Phase 7 — Check-in + Digital Access

Guest-app check-in flow and the digital room key it issues. Follows the
approved backend state machine (`AccessGrant`); the app never transitions the
reservation and never renders provider internals.

## Scope

* Check-in eligibility pre-check (from the authoritative reservation status
  only), the check-in action, and its processing / result states.
* The digital access credential (`04 · Check in & Stay`): room number + entry
  code, expiry, and the "code not working — contact reception" help banner.
* Access status (active / issuing / failed / revoked / expired / not issued)
  and the right recovery action for each.
* Deterministic dummy behaviour while no guest-facing check-in / access API is
  approved.

Out of scope (staff / back-office): revoking access (`POST
/access/{reservation}/revoke` is a staff endpoint — the app renders a
`revoked` grant but does not initiate revocation).

## Access state machine

`lib/features/digital_access/domain/entities/access_status.dart` mirrors
`App\Domain\DigitalAccess\Models\AccessGrant` and `DigitalAccessStateMachine`
**exactly** (Phase 0 §11):

```
NOT_ISSUED → ISSUE_REQUESTED → ACTIVE → { EXPIRED | REVOKE_REQUESTED → REVOKED }
ISSUE_REQUESTED → FAILED → ISSUE_REQUESTED   (retry re-requests issuance)
```

`ISSUE_REQUESTED`, `FAILED` and `REVOKE_REQUESTED` are the architecture-derived
staged-provider-call nodes the backend documents, not new business states.
Derived predicates: `isActive`, `isTerminal`, `isIssuing`, `isFailed`,
`isNotIssued`.

`CheckInEligibility` (from `ReservationStatus`) is a **UX pre-check only** — the
backend `CheckInEligibilityException` remains the authority:
`VERIFIED → ready`, `PENDING`/`DEPOSIT_HELD → notReady`,
`CHECKED_IN`+ → alreadyCheckedIn, `CHECKED_OUT`/`CANCELLED` → unavailable.

`CheckInOutcome` mirrors `CheckInController::store`: `checkedIn` (201) /
`issueFailed` (422) / `pending`.

## UI flow

```
Reservation Detail
      │  "Check in"
      ▼
Check-in review (CheckInPage) — eligibility card, "Check in now"
      │  (grant already exists → hands off straight to Room access)
      ▼
Check-in processing (CheckInProcessingPage) — clear state, no cancel
      ▼
Room access (DigitalAccessPage)
      active   → AccessCredentialCard (room no. + spaced code + expiry) + help banner
      failed   → safe error + "Try again"
      issuing  → "almost there" + "Check again"
      revoked  → safe notice (no credential)
      expired  → safe notice (no credential)
      not issued → "Check in" CTA
      │  "Back to reservation"
      ▼
Reservation Detail
```

Routes (auth-guarded): `/reservation/:reservationId/check-in`,
`.../check-in/processing`, `.../access`. `CheckInPage` and the processing page
use `pushReplacement`, so the stack after the flow is `reservation → access`
and Android back / "Back to reservation" (`goNamed`) both land correctly.

Reusable widgets: `AccessCredentialCard`, `AccessStatusPill`. Icon-driven — no
image assets (consistent with Phases 0–6). Design `04 · Check in & Stay` and the
`07 · Error & Empty States` "Key offline" / "Arrived, still processing" states
map onto the design-system `InfoBanner` / `MessageView` components.

## State management

* `checkInControllerProvider` — an app-scoped `Notifier<CheckInActionState>`
  (`idle / submitting / done / failed`), shared across the three pages. Mirrors
  `PaymentController`: duplicate-submit is a no-op while submitting or after a
  *successful* done; retry is allowed from failed and from an `issueFailed`
  done; a stale async result is dropped when a newer `CheckInRequest`
  superseded it. The reservation status is never transitioned locally.
* `accessGrantProvider(reservationId)` — `FutureProvider.autoDispose.family`;
  the current `AccessGrant`, synthetic `AccessGrant.notIssued` when none.

### Idempotency

`CheckInRequest.idempotencyKey` = `checkin:<reservationId>` — stable, no time /
random. Used as the `Idempotency-Key` header (future API). The dummy caches a
non-failed grant by key; a `FAILED` grant is not cached, so a genuine retry
re-attempts.

## Data layer

```
DigitalAccessRepository
 └── DigitalAccessDataSource
       ├── DummyDigitalAccessDataSource   (DummyDataSource)
       └── ApiDigitalAccessDataSource     (RemoteDataSource — stubbed)
```

`AccessGrantModel.fromJson` mirrors the safe `AccessGrantResource` shape.
`AccessGrant.credential` is carried through only while the grant is `ACTIVE`,
held in memory on the immutable entity for the screen's lifetime, never
persisted, never logged (`toString()` never includes it).

### API contract status — **not integrated (stubbed)**

`ApiDigitalAccessDataSource` raises `NotImplementedInPhaseException`. Reasons:

* `POST /api/v1/check-in/{reservation}`, `GET /api/v1/access/{reservation}`,
  `POST /api/v1/access/{reservation}/revoke` are **staff/dashboard-scoped**:
  `CheckInController` / `DigitalAccessController` resolve the reservation via
  `ReservationService::findAccessibleBy($request->user(), …)` and authorise with
  `AccessGrantPolicy` against the acting user's hotel access. The `/v1` surface
  is behind `auth:sanctum` staff tokens.
* `AccessGrantResource` carries **no friendly room number** — `room_number` is a
  documented gap (the app shows the row only when present; the dummy supplies
  it, the API model tolerates it when a future contract adds it).

**Backend integration still required:**

1. A guest-authenticated check-in / access surface (guest token; hotel scope +
   guest identity resolved server-side from the reservation).
2. `POST .../check-in` (`Idempotency-Key` header → `AccessGrantResource`) and
   `GET .../access` for the current grant, accepting a guest caller.
3. A `room_number` (or equivalent display label) on `AccessGrantResource`.
4. Confirmation of the credential-visibility rule (PIN present only while
   `ACTIVE`) — already assumed by the app.

Once available, un-stub the two methods in `ApiDigitalAccessDataSource`.

## Dummy datasource behaviour

Deterministic scenario from the reservation id
(`DummyDigitalAccessDataSource.scenarioFor`):

| `% 3` | scenario           | first check-in    | retry         |
|-------|--------------------|-------------------|---------------|
| 0     | `issuesActive`     | `ACTIVE` + PIN    | —             |
| 1     | `failsThenActive`  | `FAILED`          | `ACTIVE`      |
| 2     | `staysPending`     | `ISSUE_REQUESTED` | `ISSUE_REQUESTED` |

No `Random`, no `DateTime.now()` branching (a `clock` is injected for display
timestamps only). `failWith` is a test seam; `seedGrant` places a reservation
into `revoked` / `expired` directly for tests.

## Security

* The PIN (`credential`) exists only on the in-memory entity while `ACTIVE`,
  is rendered only by `AccessCredentialCard` (which itself gates on
  `visibleCredential`), is never persisted and never logged.
* No provider reference, `idempotency_key`, attempt metadata or
  `failure_reason` *detail* is surfaced to the guest — failures go through
  `Failure.localizedMessage`; the "code not working" path points to reception.
* `NotImplementedInPhaseException` messages carry no sensitive data.

## Tests

`test/features/digital_access/` — domain (status/mode mapping, credential
safety, eligibility, outcome), dummy + API datasources (all three scenarios,
idempotency, retry, `seedGrant`, `failWith`), repository (mapping + `Failure`
kinds), controller (idle/loading/success/failure/retry/duplicate/stale/
supersession/reset), routing (registration + auth guard), and a widget flow
(check-in → processing → active key; eligibility gate; issue failure + retry;
revoked notice with no credential; Arabic RTL).

## Known limitations

* No real access provider — deterministic dummy only.
* No guest revoke action (staff-only endpoint); the app renders a revoked grant
  but cannot initiate revocation.
* The reservation stays at whatever status the backend reports; the app
  reflects the access grant independently and never drives
  `VERIFIED → CHECKED_IN`.

## Missing assets

None. The screens are card / banner / code-display based and use design-system
components and Material glyphs only.
