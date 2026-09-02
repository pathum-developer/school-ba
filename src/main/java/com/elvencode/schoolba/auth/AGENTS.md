# Auth Package Instructions

This package owns authentication and authorization domain code.

## Package Scope

- Keep login, registration, token issuing, token validation, and auth DTOs under `auth`.
- Keep Spring Security configuration classes under `config.security` unless the class is pure auth-domain logic.
- Do not put learner or user business workflows here unless they are required for authentication or authorization.

## Design Rules

- Keep controllers thin. Put authentication workflow logic in services.
- Keep JWT-specific helpers under `auth.jwt` when they are not Spring configuration classes.
- Use DTOs for auth request and response models.
- Avoid leaking security implementation details into unrelated domain packages.
