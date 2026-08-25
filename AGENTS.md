# AGENTS.md

## Project Overview

This is a Spring Boot backend project.

Base Java package:

`com.elvencode.schoolba`

## Package Structure

Follow a feature/domain-based package structure.

Use lowercase singular domain names, for example:

- `student`
- `user`
- `auth`
- `school`

Each domain package should use this structure when applicable:

```text
domain/
  controller/
  service/
  repository/
  entity/
  dto/
  mapper/
  enums/
```

Shared project packages should use this structure:

```text
common/
  dto/
  exception/
  mapper/
  util/

config/
  security/
  web/
```

## Rules

- Do not create random top-level packages for domain logic.
- Put school-level catalogue and public school profile code under `school`.
- Put student-related code under `student`.
- Put user-related code under `user`.
- Put authentication and authorization code under `auth`.
- Put reusable helpers, shared DTOs, exceptions, mappers, and utilities under `common`.
- Put Spring configuration classes under `config`.
- Use singular package names, for example `student`, not `students`.
- Use lowercase package names.
- Keep controller, service, repository, entity, dto, mapper, and enums separated.
## Instruction Layering

Use nested `AGENTS.md` files for package-specific rules. Keep this root file for repository-wide conventions only.

Codex loads instructions by directory path. When working inside a package such as `student`, also follow the closest nested `AGENTS.md` in that package.

Do not add task-specific Markdown files that Codex must discover by class name. Prefer directory-scoped `AGENTS.md` files because they are loaded natively.

## Commit Guidance

When the task is commit-related, also follow [docs/commit/AGENTS.md](docs/commit/AGENTS.md).

## Frontend Architecture Reference

This backend supports the frontend project at:

`C:\elven-code\school\school-ui`

Before designing backend endpoints for frontend behavior, prefer the architecture documents at:

`C:\elven-code\school\school-ui\docs\architecture`

Read business requirements first for product rules, then frontend architecture for current UI data shapes and API migration notes.

Key documents for backend work:

- `backend\README.md`
- `backend\overview.md`
- `backend\api-contracts.md`
- `backend\domain-model.md`
- `backend\security-and-permissions.md`
- `backend\open-questions.md`
- `business-requirements\functional-requirements.md`
- `business-requirements\domain-and-rules.md`
- `business-requirements\roles-and-permissions.md`
- `business-requirements\non-functional.md`
- `business-requirements\open-questions.md`
- `frontend\state-and-data.md`
- `frontend\app-shell.md`

Treat those documents as the preferred source of product intent. If implementation decisions change after discussion, update the relevant architecture document rather than letting backend behavior drift away from the documented contract.

## Database Standards

Treat the database as an enterprise production schema. Every table and column must be
designed deliberately, with database-level validation wherever PostgreSQL can enforce it.

- Use `uuid` primary keys for persistent tables unless a different identifier is explicitly agreed.
- Preserve stable public/API identifiers such as `rajagiriya` and `light` as separate unique `code` columns instead of exposing database UUIDs as public contract values.
- Use precise financial types for money, for example `numeric(12,2)` for LKR prices. Do not use floating point types for money. Use integer money fields only when storing minor units and name them accordingly, for example `amount_cents` or `amount_minor`.
- Add `NOT NULL` to required columns. Avoid nullable columns unless the absence of the value is meaningful and documented by the schema.
- Add check constraints for valid ranges, non-blank required text, enum-like values, code formats, URL/email/phone formats, JSON shape, positive quantities/prices, and timestamp consistency.
- Add unique constraints and indexes for natural keys and invariants, including partial unique indexes where the rule is conditional.
- Use foreign keys with deliberate `ON DELETE` behavior. Prefer `RESTRICT` for reference data and `CASCADE` only for owned child records.
- Keep Liquibase changelogs and standalone SQL files under `src/main/resources/db-data` aligned whenever both paths exist.
- For already-applied Liquibase changesets, add a new changeset instead of editing old changesets, unless the database has not been shared or applied anywhere.
- Seed data should be idempotent using `ON CONFLICT` or an equivalent safe pattern.

## Verification

After changing Java code or database migrations, run:

```bash
mvn test
```
