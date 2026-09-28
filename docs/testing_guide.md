# Hotel Guest App --- Testing Guide

## Testing Pyramid

``` text
        E2E
      Widget
    Integration
       Unit
```

Most business/data behavior should be covered at unit/integration level.
Critical guest journeys should have E2E coverage.

## Unit Tests

Test:

-   model mapping
-   repository behavior
-   validators
-   state transitions represented by mobile state
-   error mapping
-   formatting helpers

## Repository Tests

For every important repository:

-   successful response
-   empty response
-   malformed response
-   authentication failure
-   validation error
-   server error
-   retry behavior where applicable

Test both dummy and API data-source behavior where practical.

## Widget Tests

Test:

-   loading
-   success
-   empty
-   error
-   RTL/LTR
-   form validation
-   button disabled/enabled states
-   important navigation actions

## Critical E2E Journeys

At minimum plan flows for:

1.  Entry → Authentication
2.  Discovery → Search → Room selection
3.  Room → Reservation
4.  Reservation → Payment
5.  Payment → Identity Verification
6.  Verified reservation → Check-in
7.  Check-in → Digital Access
8.  In-stay → Service Request
9.  Checkout → Invoice
10. Completed stay → Loyalty/Review

## Backend State Testing

The app should be tested against realistic API states, including:

-   payment pending/failure
-   verification pending/failure/retry
-   reservation cancellation
-   unavailable rooms
-   checkout blocked
-   network failure
-   unauthorized access

## Test Data

Use fake/non-sensitive data only.

Never use real identity documents, payment credentials or production
tokens.
