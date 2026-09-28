# Hotel Guest App --- Coding Rules & Standards

## 1. Think Before Coding

Before implementing a feature:

1.  Read the approved requirement.
2.  Identify the backend API contract.
3.  Identify the Figma screens/states.
4.  Identify loading, empty and error states.
5.  Decide the smallest architecture that satisfies the requirement.
6.  Implement only the requested scope.

## 2. Surgical Changes

-   Do not rewrite unrelated files.
-   Do not introduce dependencies without justification.
-   Do not create duplicate models for the same API concept.
-   Do not put business rules in widgets.
-   Do not bypass repositories.

## 3. Dart Naming

Use standard Dart conventions:

-   `PascalCase` for classes/enums.
-   `camelCase` for variables/functions.
-   `snake_case.dart` for files.
-   Names should describe responsibility, not implementation details.

## 4. Nullability

Nullability must reflect the API contract.

Do not use `!` merely to silence the compiler when the value can
legitimately be absent.

## 5. Models

Separate API models from domain entities when the feature complexity
warrants it.

Do not make UI widgets responsible for JSON parsing.

## 6. Networking

All API requests go through the shared network layer.

Never:

``` dart
http.get(...) // inside a page
```

Prefer:

``` text
Page → State → Repository → ApiDataSource → ApiClient
```

## 7. Dummy Data

Dummy implementations must satisfy the same repository contract as API
implementations.

Never put dummy arrays directly inside pages.

## 8. UI

Reusable UI components should not know about HTTP, repositories or
backend DTOs.

Pages compose widgets and state.

## 9. Errors

Do not expose raw exceptions, stack traces, server payloads or secrets
to users.

Map backend errors to user-safe presentation states.

## 10. Security

Never commit:

-   API secrets
-   provider secrets
-   signing keys
-   real identity documents
-   production credentials

Do not log access tokens or sensitive identity/payment information.

## 11. Tests

New business/data behavior should have appropriate automated tests.
Important stateful workflows must be tested for success and failure
paths.

## 12. Dependency Discipline

Before adding a package, verify:

-   why it is needed
-   platform support
-   maintenance status
-   security implications
-   whether Flutter/Dart already provides the capability

Avoid adding a package for trivial functionality.
