# Hotel Guest App --- Mobile Documentation

## Purpose

This documentation defines the Flutter Guest App for the Hotel
Management System.

The Guest App is a client of the Laravel REST API. Laravel is the
authoritative source of truth for business rules, availability,
reservations, pricing, payment, identity verification, digital access,
stay services, checkout, loyalty, reviews, permissions, and audit.

## Source of Truth

The documentation hierarchy is:

1.  `hotel_docs.pdf`
2.  Approved Phase 0 baseline
3.  Approved backend phase specifications and API contracts
4.  Figma Guest App screens
5.  This mobile documentation
6.  Implementation details

If a mobile document conflicts with an approved backend/business
requirement, the approved requirement wins.

## Product Scope

The Guest App covers:

-   Entry and language selection
-   Guest authentication
-   Hotel discovery
-   Search, filters and sorting
-   Stay dates and room availability
-   Reservation creation
-   Payment lifecycle
-   Identity verification
-   Check-in
-   Digital access
-   In-stay services and requests
-   Notifications
-   Checkout and invoice
-   Bookings/history
-   Loyalty
-   Ratings and reviews
-   Profile/account
-   Problem reporting
-   Error, loading and empty states

## Development Strategy

The application may use dummy data while backend APIs are being
completed.

Dummy data MUST live behind the same repository/data-source abstractions
used by the real API.

``` text
UI
 ↓
State Management
 ↓
Repository
 ↓
Data Source
 ├── DummyDataSource
 └── ApiDataSource
```

A screen must never contain hard-coded business data as its data source.

## Backend-First Rule

Before integrating a feature with production behavior:

1.  Confirm the Laravel endpoint and API contract.
2.  Confirm authentication and authorization rules.
3.  Confirm request/response fields.
4.  Confirm state transitions and error semantics.
5.  Implement/verify the API data source.
6.  Keep UI independent from the concrete data source.

## Mobile Roadmap

-   Mobile 0 --- Foundation & Design System
-   Mobile 1 --- Entry & Authentication
-   Mobile 2 --- Discovery & Search
-   Mobile 3 --- Dates, Availability & Rooms
-   Mobile 4 --- Reservations
-   Mobile 5 --- Payments
-   Mobile 6 --- Identity Verification
-   Mobile 7 --- Check-in & Digital Access
-   Mobile 8 --- Stay Services
-   Mobile 9 --- Checkout & Invoice
-   Mobile 10 --- Loyalty & Reviews
-   Mobile 11 --- Bookings, Account & Notifications
-   Mobile 12 --- Final Integration & QA

## Current Architecture Principle

The mobile app is a guest client, not a second business backend.

Never move authoritative business decisions into Flutter merely to make
the UI work.
