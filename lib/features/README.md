# `lib/features/`

Feature modules live here, one folder per business capability. **No feature is
implemented in Mobile Phase 0** — this file documents the shape each one takes so
later phases stay consistent with `mobile/docs/architecture.md` and
`mobile/docs/feature_guide.md`.

## Planned modules (added per mobile phase)

`authentication`, `discovery`, `availability`, `reservations`, `payments`,
`identity_verification`, `digital_access`, `stay_services`, `checkout`,
`loyalty`, `reviews`, `bookings`, `notifications`, `profile`.

## Per-feature layout

```
features/<feature>/
├── data/
│   ├── datasources/
│   │   ├── dummy_<feature>_data_source.dart   # implements DummyDataSource
│   │   └── api_<feature>_data_source.dart     # implements RemoteDataSource
│   ├── models/                                # API request/response DTOs
│   └── repositories/                          # <Feature>RepositoryImpl
├── domain/
│   ├── entities/
│   ├── repositories/                          # abstract <Feature>Repository
│   └── usecases/
└── presentation/
    ├── pages/
    ├── widgets/
    └── state/                                 # Riverpod notifiers + UiState
```

## Rules

- UI depends on `domain/repositories`, never on a concrete data source.
- Dummy and API data sources satisfy the same contract, including errors.
- Repositories map data-layer errors to `Failure` (see `core/errors/`).
- Workflow features (reservations, payments, identity) mirror the backend state
  machine — they do not invent states.
- Shared building blocks (buttons, cards, state views, theme) come from
  `core/`, not copied into features.
