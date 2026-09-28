# Hotel Guest App --- OTP Auto-Fetch Guide

## Scope

OTP auto-fetch may be used for approved guest authentication flows.

It is a convenience feature, not a business-security bypass.

## Rules

-   Backend remains responsible for OTP generation and verification.
-   The app must still support manual OTP entry.
-   Auto-fetch must not log OTP values.
-   OTP values must not be persisted unnecessarily.
-   Expired/invalid OTP responses must be handled safely.

## Platform Considerations

Android and iOS have different SMS/OTP capabilities. Implement
platform-specific behavior only where supported and justified.

The SMS template/app configuration must follow the backend
authentication contract.

## Failure

If auto-fetch is unavailable, the guest must still be able to enter the
OTP manually.
