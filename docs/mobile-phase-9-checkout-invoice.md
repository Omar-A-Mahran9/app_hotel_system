# Mobile Phase 9 — Checkout + Invoice

Guest checkout and the issued e-invoice (`05 · Depart & Invoice`). **The client
never computes or independently recalculates an authoritative financial
value** — every total is backend-supplied and displayed verbatim.

## Scope

* Checkout eligibility (from the authoritative reservation status), the folio /
  charge summary, and the "complete checkout" action.
* Settlement processing and its outcome: completed / awaiting settlement /
  settlement failed — never collapsed to a boolean.
* The issued invoice: number, dates, line items, subtotal, payments,
  outstanding, and a settled tag.
* Deterministic dummy behaviour while no guest-facing checkout / invoice API is
  approved.

## Checkout state machine

`lib/features/checkout/domain/entities/checkout_status.dart` mirrors
`App\Domain\Checkout\Models\Checkout` and `CheckoutStateMachine` **exactly**
(Phase 0 §12):

```
in_progress ─┐
awaiting_settlement ─┼─► completed  (terminal)
settlement_failed ───┘   (the non-completed three form a retry cluster)
```

`InvoiceStatus` mirrors `Invoice::STATUSES` (`draft` / `issued`).
`CheckoutOutcome` mirrors the branches of `CheckoutController::store`:
`completed` (200) / `settlementPending` (422) / `settlementFailed` (422).

Checkout eligibility (UX pre-check): reservation status ∈ {`CHECKED_IN`,
`IN_STAY`, `CHECKOUT_IN_PROGRESS`, `INVOICED`, `CHECKED_OUT`}. The backend
`CheckoutNotAllowedException` remains the authority.

## Accounting semantics (preserved from the backend)

| value | source |
|---|---|
| accommodation charge | `reservation.price_snapshot`, used exactly (`FolioCharge::SOURCE_ACCOMMODATION`) |
| charges / payments / outstanding totals | backend folio / invoice `totals` — **displayed, never summed by the app** |
| a deposit hold | an *authorization*, not captured money → `payments_total` is `0` until settlement |
| final settlement amount | computed **server-side** from the authoritative folio; the client sends no amount |
| settlement payment status | `CheckoutResource.payment.status` — a `PaymentStatus`, kept separate from the checkout status |
| invoice line items / totals | frozen `InvoiceResource` snapshot — no invented tax / fee / discount line |

`Payment.amount` is never used as a transactions total. `Folio.chargesTotal` /
`Invoice.subtotal` / `Checkout.outstandingTotal` are the only figures rendered.

## UI flow

```
Reservation Detail
      │  "Check out"
      ▼
Checkout (CheckoutPage) — ready / not-ready banner, FolioSummaryCard,
      │  "Complete checkout"
      ▼
Settlement processing (CheckoutProcessingPage) — clear state, no cancel
      ▼
Your stay summary (CheckoutCompletionPage)
      completed  → "Thank you for your stay" + invoice total + "View invoice"
      pending    → safe "settlement is processing" waiting state
      failed     → safe error + "Try again"
      │  "View invoice" / "Done"
      ▼
Invoice (InvoicePage) — issued banner, number + dates, line items, subtotal /
                        payments / outstanding, "Settled in full" tag
```

Routes (auth-guarded): `/reservation/:reservationId/checkout`,
`.../checkout/processing`, `.../checkout/complete`, `.../invoice`. `CheckoutPage`
and the processing page use `pushReplacement`; "Done" returns to the reservation
via `goNamed`.

Reusable widgets: `FolioSummaryCard`. Icon / card / banner based — no image
assets. The design's rating/review CTA on the completion screen belongs to a
later reviews phase and is not implemented here.

## State management

* `folioContextProvider(reservationId)` — derives a `FolioContext`
  (`accommodationAmount`, `currency`) from the authoritative reservation the
  guest already sees; the real `GET .../folio` needs none of this.
* `folioProvider(reservationId)` / `invoiceProvider(reservationId)` —
  `FutureProvider.autoDispose` families. `invoiceProvider` throws a `notFound`
  `Failure` before checkout completes (mirrors the backend 404).
* `checkoutControllerProvider` — an app-scoped `Notifier<CheckoutActionState>`
  (`idle / submitting / done / failed`). Mirrors `PaymentController`:
  duplicate-submit is a no-op while submitting or after a *completed* done;
  retry is allowed from failed and from a `settlementFailed` done; a stale
  result is dropped when a newer `CheckoutRequest` superseded it. On success it
  invalidates `invoiceProvider` + `folioProvider`. The reservation status is
  never transitioned locally and no money is computed here.

### Idempotency

`CheckoutRequest.idempotencyKey` = `checkout:<reservationId>` — stable, no time
/ random (shared with the final-settlement transaction, per
`PerformCheckoutRequest`). The dummy caches a non-failed result by key; a
`settlement_failed` result is not cached, so a genuine retry re-attempts.

## Data layer

```
CheckoutRepository            InvoiceRepository
 └── CheckoutDataSource        └── InvoiceDataSource
       ├── DummyCheckoutDataSource   (implements BOTH — one instance shares state)
       └── ApiCheckoutDataSource     (implements BOTH — stubbed)
```

`checkout_models.dart` mirrors `FolioResource` / `FolioChargeResource`,
`CheckoutResource`, `InvoiceResource` / `InvoiceItemResource` exactly. No
arithmetic on any total in the model layer.

### API contract status — **not integrated (stubbed)**

`ApiCheckoutDataSource` raises `NotImplementedInPhaseException`. Reasons:

* `GET /reservations/{reservation}/folio`,
  `POST /reservations/{reservation}/checkout` (`PerformCheckoutRequest`: no
  body, `Idempotency-Key` header → `CheckoutResource`),
  `GET /reservations/{reservation}/invoice` are all
  **staff/dashboard-scoped** (`auth:sanctum` staff tokens; `CheckoutPolicy` /
  `InvoicePolicy` / `FolioPolicy` + hotel access;
  `ReservationService::findAccessibleBy`).

**Backend integration still required:**

1. A guest-authenticated checkout / folio / invoice surface (guest token; hotel
   scope + guest identity resolved server-side from the reservation).
2. A guest `GET .../folio`, `POST .../checkout` (`Idempotency-Key` header,
   no body), `GET .../invoice`.
3. Confirmation that `CheckoutResource` / `FolioResource` shapes are stable
   (the models mirror them 1:1).

Once available, un-stub the three methods in `ApiCheckoutDataSource` — the
`FolioContext` seed is dropped for the real API (the server derives every
figure).

## Dummy datasource behaviour

* Folio: accommodation charge = `FolioContext.accommodationAmount` (i.e. the
  reservation price snapshot); deterministic service charges from the
  reservation id hash (`[]` / `[45]` / `[45, 120]`); `chargesTotal` computed
  **once** in the backend DTO shape; `paymentsTotal` = 0 (a deposit hold is not
  captured money); `outstandingTotal` = `chargesTotal`.
* Settlement scenario from the reservation id
  (`DummyCheckoutDataSource.scenarioFor`): `settles` (completes + issues
  invoice) / `failsThenSettles` (`settlement_failed`, then a retry completes) /
  `staysPending` (`awaiting_settlement`, no invoice).
* Invoice: available only after checkout completes (`NotFoundException` before);
  number `INV-<n>-<nn>`, items snapshotted from the posted folio charges,
  `outstanding_total` 0.
* No `Random`, no `DateTime.now()` branching (`clock` injected for display
  timestamps only). `failWith` is a test seam.

## Security

* No card number / CVV / PIN / payment secret / provider reference anywhere.
* The client sends no settlement amount and no reservation-ownership /
  guest-identity claim.
* `NotImplementedInPhaseException` messages carry no sensitive data;
  guest-facing errors go through `Failure.localizedMessage`.

## Tests

`test/features/checkout/` — domain (status / outcome mapping, `Folio` /
`Invoice` display-only invariants — a cancelled charge does **not** change the
backend total, `Invoice.isSettled` derives purely from `outstanding_total`),
models (DTO parsing of every resource), dummy + API datasources (accommodation
= reservation snapshot, `payments_total` = 0, settlement scenarios, idempotency,
retry, invoice-after-completion / 404-before, `failWith`), repository (totals
passthrough, `Failure` kinds), controller (idle/loading/completed/pending/
failed/duplicate/retry/stale/idempotency-key/supersession/reset), routing, and
a widget flow (checkout → processing → completion → invoice; eligibility gate;
settlement failure + retry; pending waiting state; invoice "not ready" before
checkout; Arabic RTL).

## Known limitations

* No real payment provider — deterministic dummy only.
* The dummy folio's `paymentsTotal` is always 0 (a deposit hold isn't captured
  money); a real folio would reflect any actually-captured payment.
* The completion screen's rating/review CTA is out of scope (reviews phase).
* The reservation stays at whatever status the backend reports; the app
  reflects checkout / invoice state independently and never drives
  `IN_STAY → CHECKOUT_IN_PROGRESS → INVOICED`.

## Missing assets

None. All screens use design-system components and Material glyphs.
