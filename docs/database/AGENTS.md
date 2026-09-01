# Database Guidance

These rules apply when the task involves database schema, migrations, seed data,
database-backed domain constraints, Liquibase changelogs, or standalone SQL data
files.

## Database Standards

Treat the database as an enterprise production schema. Every table and column must
be designed deliberately, with database-level validation wherever PostgreSQL can
enforce it.

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
