# Mobile Phase 8 — Stay Services

Guest-facing service catalogue and service requests (`11 · Services &
requests`). The app **displays** backend values only — it never computes a
folio amount, marks an order confirmed / fulfilled, or mutates accounting.

## Scope

* The hotel service catalogue, grouped by category.
* One service in detail: quantity, optional notes, an **estimated** total, and
  the request action.
* The guest's service requests, one request in detail, and cancelling a
  still-`requested` order.
* Deterministic dummy behaviour while no guest-facing stay-services API is
  approved.

## Service-order state machine

`lib/features/stay_services/domain/entities/service_order_status.dart` mirrors
`App\Domain\StayServices\Models\ServiceOrder` and `ServiceOrderStateMachine`
**exactly** — no new statuses:

```
requested → confirmed | cancelled
confirmed → fulfilled | cancelled
fulfilled / cancelled → (terminal)
```

`isGuestCancellable` is `true` only for `requested` (`requested → cancelled` is
the approved edge; a `confirmed` order is already being actioned). The backend
remains the authority — a rejected cancel surfaces as a `conflict` `Failure`.

## UI flow

```
Reservation Detail
      │  "Stay services"
      ▼
Hotel services (StayServicesPage) — intro banner, grouped catalogue
      │  tap a service
      ▼
Service detail (ServiceDetailPage) — quantity stepper, notes, estimated total,
      │  "Request this service"
      ▼
Request details (ServiceOrderDetailPage) — doubles as the "request sent"
      │  confirmation (SR-xxxx + status); "Cancel request" while requested
      ▼   (cancel confirm dialog → pops back to the catalogue)
   ─ or ─
My requests (MyServiceRequestsPage) — list + empty state + "New request"
```

Routes (auth-guarded): `/reservation/:reservationId/services`,
`.../services/:serviceId`, `.../service-orders`,
`.../service-orders/:orderId`. `ServiceDetailPage` uses `pushReplacement` to the
order-detail screen after a successful request.

Reusable widgets: `ServiceCard`, `ServiceOrderCard`, `ServiceOrderStatusPill`.
Quantity uses the existing discovery `GuestStepper`; notes use `AppTextField`.
Icon-driven (Material glyphs chosen deterministically per service id) — no image
assets. Loading / empty / error states use `LoadingView` / `EmptyView` /
`MessageView`.

## State management

* `serviceCatalogueProvider(hotelId)` / `serviceOrdersProvider(reservationId)` /
  `serviceOrderProvider((reservationId, orderId))` — `FutureProvider.autoDispose`
  families.
* `serviceRequestControllerProvider` — a `Notifier<ServiceRequestState>`
  (`idle / submitting / done / failed`). Duplicate-submit is a no-op while
  submitting or after done for the same request; retry is allowed from failed;
  a stale result is dropped when a newer request superseded it. On success it
  invalidates `serviceOrdersProvider(reservationId)`.
* `cancelOrderControllerProvider` — a `NotifierProvider.family` **per order**
  (`(reservationId, orderId)`), so two orders' cancellations never share state
  and a late result can't cross over.

### Idempotency

`CreateServiceRequest.idempotencyKey` =
`svc|<reservationId>|<serviceId>|<quantity>|<notes>` — stable, no time / random.
Quantity and notes are part of the key, so changing the order is a different
operation. The dummy source is idempotent per request key.

## Data layer

```
StayServicesRepository
 └── StayServicesDataSource
       ├── DummyStayServicesDataSource   (DummyDataSource)
       └── ApiStayServicesDataSource     (RemoteDataSource — stubbed)
```

* `fetchCatalogue` returns a domain `ServiceCatalogue` (its text is bilingual;
  locale negotiation is a server concern). Orders come back as
  `ServiceOrderModel`s the repository joins with the catalogue to attach a
  bilingual display name.
* `ServiceOrderModel.fromJson` mirrors `ServiceOrderResource` — the app reads
  `unit_price_snapshot` / `total_amount` as **authoritative** figures and never
  recomputes `unit × quantity` from a real response.
* `HotelService.estimatedMinutes` is **not** in `ServiceResource` — a
  documented gap backing the "~20 min" chip. The dummy fixture supplies it; the
  API model tolerates it when a future contract adds it.

### Accounting rule

The app never: computes a folio amount, decides a payment amount, marks a
service confirmed / fulfilled, or calculates an outstanding balance. The
"estimated total" on the service detail screen is a **client-side estimate for
the guest's benefit** (`price × quantity`, clearly labelled "Estimated");
`ServiceOrder.totalAmount` from the DTO is the authoritative figure everywhere
it is displayed.

### API contract status — **not integrated (stubbed)**

`ApiStayServicesDataSource` raises `NotImplementedInPhaseException`. Reasons:

* `GET /hotels/{hotel}/service-categories`, `GET /hotels/{hotel}/services`,
  `GET|POST /reservations/{reservation}/service-orders`,
  `GET .../service-orders/{serviceOrder}`,
  `POST .../service-orders/{serviceOrder}/transition` are all
  **staff/dashboard-scoped** (`auth:sanctum` staff tokens; `HotelServicePolicy`
  / `ServiceCategoryPolicy` / `ServiceOrderPolicy` + hotel access;
  `ReservationService::findAccessibleBy`).
* There is **no guest cancel endpoint** — cancellation is a staff `transition`
  state-machine call.

**Backend integration still required:**

1. A guest-authenticated catalogue + service-orders surface (guest token; hotel
   scope + guest identity resolved server-side from the reservation).
2. A guest `POST .../service-orders` (`service_id`, `quantity`, `notes?` →
   `ServiceOrderResource`) and `GET` list / show.
3. A guest-permitted `requested → cancelled` transition (or a dedicated guest
   cancel endpoint).
4. Optionally an `estimated_minutes` field on `ServiceResource`, and
   locale-negotiated catalogue text.

Once available, un-stub the five methods in `ApiStayServicesDataSource`.

## Dummy datasource behaviour

* Catalogue: the fixed `ServiceCatalogueFixture` (two categories, six bilingual
  services — same for every hotel in dummy mode; documented). No `Random`, no
  time.
* `createOrder`: makes a `requested` order, id derived from the request key,
  `total_amount` = `unit × quantity` as a **sample in the backend DTO shape**.
* Hotel-side progression: an order's later status is a pure function of its id
  (`DummyStayServicesDataSource.progressFor` → `staysRequested` /
  `getsConfirmed` / `getsFulfilled`). A `requested` order can be cancelled; any
  other reports a `ConflictException`.
* `failWith` is a test seam.

## Security

* No card / payment data anywhere (a service order and a folio charge never
  carry any). `NotImplementedInPhaseException` messages carry no sensitive
  data. Guest-facing errors go through `Failure.localizedMessage`.

## Tests

`test/features/stay_services/` — domain (status mapping, `ServiceCatalogue.
grouped`, request idempotency, `ServiceOrder.reference`), models (DTO parsing,
authoritative snapshot values), dummy + API datasources (catalogue, create
idempotency, deterministic progression, cancel allowed / conflict, `failWith`),
repository (name join, `Failure` kinds), controllers (request idle/submitting/
done/failed/duplicate/supersession; per-order cancel family isolation),
routing, and a widget flow (catalogue → detail → request → order detail;
cancel; empty state; Arabic RTL).

## Known limitations

* The dummy catalogue is hotel-agnostic (documented) — once the guest API is
  wired, the reservation's hotel id must be threaded into the repository's
  order-name join.
* No push/notification for "request accepted" (Phase 8 shows status on refresh
  only).

## Missing assets

None. All screens use design-system components and Material glyphs.
