/// Marker types for the two data-source families every feature provides
/// (mobile/docs/README.md — "Development Strategy", mobile/docs/feature_guide.md
/// Step 4).
///
/// ```
/// Repository
///  └── <Feature>DataSource        (abstract contract)
///        ├── Dummy<Feature>DataSource   implements DummyDataSource
///        └── Api<Feature>DataSource     implements RemoteDataSource
/// ```
///
/// A repository depends on the abstract `<Feature>DataSource`; which concrete
/// class it receives is decided by DI (`AppConfig.useDummyData`), never by the
/// UI. Dummy sources must honour the same contract — including error behaviour —
/// as the API sources they stand in for (mobile/docs/coding_rules.md §7).
library;

/// Implemented by in-memory / fixture-backed data sources used while an approved
/// backend endpoint is not yet wired.
abstract interface class DummyDataSource {}

/// Implemented by data sources that talk to the Laravel API through
/// `ApiClient`.
abstract interface class RemoteDataSource {}
