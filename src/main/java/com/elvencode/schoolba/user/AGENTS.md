# User Package Instructions

This package owns user-related domain code.

## Package Scope

- Keep all user controllers, services, repositories, entities, DTOs, mappers, and enums under `user`.
- Do not place authentication token handling or authorization filter logic here; use `auth` or `config.security`.
- Use `common` only for reusable behavior that is genuinely shared by more than one domain.

## Design Rules

- Keep controllers thin. Put request handling and HTTP concerns in controllers; put business logic in services.
- Keep persistence access in repositories.
- Use DTOs for API request and response models instead of exposing entities directly.
- Put user-specific enum types under `user.enums`.
