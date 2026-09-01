# Student Package Instructions

This package owns student-related domain code.

## Package Scope

- Keep all student controllers, services, repositories, entities, DTOs, mappers, and enums under `student`.
- Model learners as school-owned student records. Do not introduce a global learner or shared student profile abstraction unless the architecture documents are updated first.
- Keep learner enrollment, current branch assignment, and same-school branch transfer workflows under `student`.
- Do not place student-specific business rules in `user`, `auth`, `common`, or `config`.
- Use `common` only for reusable behavior that is genuinely shared by more than one domain.

## Design Rules

- Keep controllers thin. Put request handling and HTTP concerns in controllers; put business logic in services.
- Keep persistence access in repositories.
- Use DTOs for API request and response models instead of exposing entities directly.
- Put student-specific enum types under `student.enums`.
- Before changing learner or transfer behavior, read `docs/architecture/business-requirements/functional-requirements.md`, `docs/architecture/business-requirements/domain-and-rules.md`, `docs/architecture/backend/domain-model.md`, `docs/architecture/backend/api-contracts.md`, and `docs/architecture/backend/security-and-permissions.md`.
