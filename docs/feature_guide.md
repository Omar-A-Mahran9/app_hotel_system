# Hotel Guest App --- Feature Implementation Guide

## Before Starting

For every feature, document:

-   Requirement/source
-   API endpoint(s)
-   Auth requirements
-   Request/response contract
-   Backend states
-   Figma screens
-   Loading/empty/error states
-   Dummy behavior
-   Tests

## Step 1 --- Create Feature Boundary

Create a folder under:

``` text
lib/features/<feature_name>/
```

Do not scatter feature files across unrelated folders.

## Step 2 --- Define Domain Contract

Define entities and repository interfaces around the business concept.

Example:

``` dart
abstract class AvailabilityRepository {
  Future<AvailabilityResult> checkAvailability(
    AvailabilityRequest request,
  );
}
```

## Step 3 --- Define API Models

Create request/response models that match Laravel's approved API
contract.

Do not invent fields simply because the UI wants them.

## Step 4 --- Data Sources

Create:

``` text
DummyDataSource
ApiDataSource
```

The dummy source is temporary and should mimic the API contract.

## Step 5 --- Repository

The repository chooses/coordinates the data source and maps data into
the domain contract.

## Step 6 --- State

Represent at least:

``` text
initial
loading
success
empty (when applicable)
failure
```

For workflows, represent backend states explicitly rather than treating
everything as success/failure.

## Step 7 --- UI

Implement the Figma-approved screens and states.

UI should consume state and trigger actions. It should not make backend
business decisions.

## Step 8 --- Integration

When Laravel API is ready:

1.  verify endpoint
2.  implement API data source
3.  test serialization
4.  test errors
5.  switch environment/configuration
6.  keep dummy implementation available for isolated UI tests if useful

## Step 9 --- Verification

Run:

-   formatter/analyzer
-   unit tests
-   widget tests
-   feature tests
-   E2E tests for critical journeys

## Hotel-Specific Rule

For reservation and stay workflows, the mobile state must reflect the
Laravel state machine.

Example:

``` text
PENDING
→ DEPOSIT_HELD
→ VERIFIED
→ CHECKED_IN
→ IN_STAY
→ CHECKOUT_IN_PROGRESS
→ CHECKED_OUT
→ INVOICED
```

Do not invent alternative states in the mobile app.
