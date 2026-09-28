# Hotel Guest App --- Maestro E2E Testing Guide

## Purpose

Maestro can be used for critical guest journeys on Android/iOS test
builds.

## Suggested Flows

``` text
01_entry.yaml
02_authentication.yaml
03_discover_and_search.yaml
04_reservation.yaml
05_payment.yaml
06_identity_verification.yaml
07_check_in.yaml
08_stay_services.yaml
09_checkout.yaml
10_loyalty_review.yaml
```

## Test Data

Use deterministic test accounts and backend test/dummy providers.

Never use real guest identity or payment information.

## Rules

E2E tests should verify user-visible behavior and critical journey
integration. Do not encode internal implementation details into every
test.

## Critical Principle

When an API operation has an important state machine, the E2E flow
should verify the resulting user state rather than assuming a button
click equals success.
