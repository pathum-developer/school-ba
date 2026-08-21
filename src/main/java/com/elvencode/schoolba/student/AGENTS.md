# Student Package Instructions

This package owns student-related domain code.

## Package Scope

- Keep all student controllers, services, repositories, entities, DTOs, mappers, and enums under `student`.
- Do not place student-specific business rules in `user`, `auth`, `common`, or `config`.
- Use `common` only for reusable behavior that is genuinely shared by more than one domain.

## Design Rules

- Keep controllers thin. Put request handling and HTTP concerns in controllers; put business logic in services.
- Keep persistence access in repositories.
- Use DTOs for API request and response models instead of exposing entities directly.
- Put student-specific enum types under `student.enums`.
