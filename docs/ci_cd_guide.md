# Hotel Guest App --- CI/CD Guide

## Pipeline

Recommended checks:

``` text
Checkout
 ↓
Flutter dependencies
 ↓
Format check
 ↓
Analyze
 ↓
Unit tests
 ↓
Widget/integration tests
 ↓
Build Android
 ↓
Build iOS (macOS runner)
```

## Pull Requests

Every PR affecting mobile code should run:

-   formatting check
-   static analysis
-   automated tests

## Releases

Production releases must be created from reviewed/approved commits.

Environment-specific API configuration must be injected securely.

Never commit production secrets.

## Build Configuration

Separate:

``` text
development
staging
production
```

Each environment must use the correct Laravel API base URL.

## Backend Compatibility

Mobile releases should record the supported API version/contract.

Breaking backend changes require explicit compatibility planning.
