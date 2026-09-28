# Hotel Guest App --- Rate Limiting & Request Throttling

## Principle

Rate limiting is primarily enforced by Laravel.

Flutter should behave correctly when the API returns HTTP 429.

## Client Responsibilities

-   avoid accidental duplicate submissions
-   disable a submit action while the request is in progress
-   avoid uncontrolled retry loops
-   respect server-provided retry information when available
-   present a safe retry message

## Important Hotel Flows

Extra care is required for:

-   authentication/OTP
-   payment hold
-   identity verification submissions
-   reservation creation
-   service requests

Do not blindly retry payment or reservation commands.

## Idempotency

Where the backend requires an idempotency key, the mobile client must
preserve the same key for a retry of the same logical operation.

A retry must not create a second business operation.

## 429 Handling

Map HTTP 429 to a user-safe state such as:

``` text
Too many requests.
Please wait and try again.
```

Do not expose raw backend exception text.
