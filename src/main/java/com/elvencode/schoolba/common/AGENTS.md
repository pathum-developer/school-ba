# Common Package Instructions

This package owns reusable cross-domain code.

## Package Scope

- Put shared DTOs, exceptions, mappers, and utilities here only when they are used by more than one domain.
- Do not place domain-specific business logic in `common`.
- Before adding a helper here, confirm it is not clearer as package-private or domain-local code.

## Design Rules

- Keep utilities stateless unless there is a clear Spring-managed dependency.
- Keep shared exceptions focused and reusable.
- Avoid coupling `common` back to `student`, `user`, or `auth`.
