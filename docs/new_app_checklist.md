# Hotel Guest App --- New App / Foundation Checklist

## 1. Project

-   [ ] Flutter installed and verified
-   [ ] Correct Flutter/Dart versions documented
-   [ ] `mobile/` created under the hotel-management repository
-   [ ] Android/iOS package identifiers agreed
-   [ ] Environment strategy defined

## 2. Backend Contract

-   [ ] Laravel `/api/v1` base URL
-   [ ] Authentication contract
-   [ ] Standard response/error envelope
-   [ ] Reservation endpoints
-   [ ] Payment endpoints
-   [ ] Identity verification endpoints
-   [ ] Digital access endpoints
-   [ ] Stay services endpoints
-   [ ] Checkout/invoice endpoints
-   [ ] Loyalty endpoints
-   [ ] Reviews endpoints

Only mark an endpoint ready when its backend contract is approved.

## 3. Design

-   [ ] Figma screens available
-   [ ] Arabic RTL reviewed
-   [ ] English LTR reviewed
-   [ ] Typography
-   [ ] Colors
-   [ ] Spacing
-   [ ] Buttons/forms
-   [ ] Loading states
-   [ ] Empty states
-   [ ] Error states

## 4. Architecture

-   [ ] API client
-   [ ] Repository abstraction
-   [ ] Dummy data source
-   [ ] API data source
-   [ ] State management
-   [ ] Routing
-   [ ] Localization
-   [ ] Secure storage where required

## 5. Security

-   [ ] No secrets in source
-   [ ] No sensitive logging
-   [ ] Token handling reviewed
-   [ ] Identity files never stored publicly by the app/backend
-   [ ] Error messages are safe

## 6. Quality

-   [ ] Analyzer clean
-   [ ] Formatter clean
-   [ ] Unit tests
-   [ ] Widget tests
-   [ ] Critical E2E tests
-   [ ] Android build
-   [ ] iOS build

## 7. Backend-First Integration

For each feature:

-   [ ] API contract reviewed
-   [ ] Dummy implementation exists
-   [ ] API implementation exists
-   [ ] UI does not depend on data-source type
-   [ ] Backend remains authoritative
