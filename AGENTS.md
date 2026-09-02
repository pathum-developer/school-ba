# AGENTS.md

# Project Instructions

Act as a Principal Software Architect and Technical Lead.

Always provide enterprise-grade solutions.

## Before Writing Code

- Understand the existing architecture.
- Think about scalability.
- Think about maintainability.
- Think about security.
- Think about performance.
- Think about concurrency.
- Think about testability.

## Follow

- SOLID.
- Clean Architecture.
- Clean Code.
- DDD when appropriate.
- Spring Boot best practices.
- Java best practices.
- REST best practices.
- OWASP security practices.
- Proper logging.
- Exception handling.
- Transaction management.
- Design patterns where appropriate.

Never choose the quickest solution if a cleaner enterprise solution exists.

## If Multiple Solutions Exist

1. Recommend the best one.
2. Explain why.
3. Mention alternatives and trade-offs.

## Project Overview

This is a Spring Boot backend project.

Base Java package:

`com.elvencode.schoolba`

## Rules

- Java package creation and folder structure rules live in `src/main/java/com/elvencode/schoolba/AGENTS.md`.
- Do not create random top-level packages for domain logic.
- Name list-valued fields, variables, record components, and DTO properties with a `List` suffix, for example `contactNoList`. Keep single-object names singular.
- When handling exceptions that can occur in multiple controller classes, rely on the global exception handler instead of duplicating controller-local exception handling.

## Review Mode

When the user asks to review a task or code, also follow [docs/review/AGENTS.md](docs/review/AGENTS.md).

## Instruction Layering

Use nested `AGENTS.md` files for package-specific rules. Keep this root file for repository-wide conventions only.

Codex loads instructions by directory path. When working inside a package such as `learner`, also follow the closest nested `AGENTS.md` in that package.

Do not add task-specific Markdown files that Codex must discover by class name. Prefer directory-scoped `AGENTS.md` files because they are loaded natively.

## Commit Guidance

When the task is commit-related, also follow [docs/commit/AGENTS.md](docs/commit/AGENTS.md).

## Architecture Reference

Use this repository's architecture documents as the source of truth before changing
backend behavior:

`C:\elven-code\school\school-ba\docs\architecture`

This backend also supports the frontend project at:

`C:\elven-code\school\school-ui`

When designing backend endpoints for frontend behavior, read the backend and
business architecture documents here first, then consult frontend architecture
documents only for current UI data shapes and migration notes:

`C:\elven-code\school\school-ui\docs\architecture`

Read business requirements first for product rules, then backend architecture for
API, domain model, and authorization contracts.

Key documents for backend work:

- `docs\architecture\backend\README.md`
- `docs\architecture\backend\overview.md`
- `docs\architecture\backend\api-contracts.md`
- `docs\architecture\backend\domain-model.md`
- `docs\architecture\backend\security-and-permissions.md`
- `docs\architecture\backend\open-questions.md`
- `docs\architecture\business-requirements\functional-requirements.md`
- `docs\architecture\business-requirements\domain-and-rules.md`
- `docs\architecture\business-requirements\roles-and-permissions.md`
- `docs\architecture\business-requirements\non-functional.md`
- `docs\architecture\business-requirements\open-questions.md`
- `docs\architecture\frontend\state-and-data.md`
- `docs\architecture\frontend\app-shell.md`

Current tenant model:

- School is the tenant boundary.
- Branch belongs to one school.
- Learner is a school-owned record of one enrolled person and belongs to exactly one school.
- A learner has one current registered branch at a time.
- Branch transfers happen only between branches of the same school.

Treat those documents as the preferred source of product intent. If implementation decisions change after discussion, update the relevant architecture document rather than letting backend behavior drift away from the documented contract.

## Database Guidance

When the task involves database schema, migrations, seed data, or database-backed
domain constraints, also follow [docs/database/AGENTS.md](docs/database/AGENTS.md).

## Verification

After changing Java code or database migrations, run:

```bash
mvn test
```
