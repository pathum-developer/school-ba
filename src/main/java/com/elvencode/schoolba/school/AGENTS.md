# School Package Instructions

This package owns school-level public catalogue and school profile code.

## Package Scope

- Keep school profile, licence class, course, package, branch or yard, FAQ, testimonial, and learning-resource catalogue code under `school` unless a more specific domain is created after discussion.
- Do not put enrolled-student workflows here; use `student`.
- Do not put login, token, or permission logic here; use `auth` or `config.security`.
- Use `common` only for reusable behavior that is genuinely shared by more than one domain.

## Design Rules

- Keep controllers thin. Put request handling and HTTP concerns in controllers; put catalogue and profile rules in services.
- Keep persistence access in repositories.
- Use DTOs for API request and response models instead of exposing entities directly.
- Preserve frontend-facing stable ids such as `car-manual`, `rajagiriya`, and `light` in API contracts.
- Put school-specific enum types under `school.enums`.
