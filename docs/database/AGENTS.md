# Database Guidance

These rules apply when the task involves database schema, migrations, seed data,
database-backed domain constraints, Liquibase changelogs, or standalone SQL data
files.

## Database Standards

Treat the database as an enterprise production schema. Every table and column must
be designed deliberately, with database-level validation wherever PostgreSQL can
enforce it.

- Prefix physical table names by table role:
  - `m_` for master/main domain tables, for example `m_school`, `m_branch`, `m_learner`, `m_staff`, `m_app_user`, and `m_role`.
  - `r_` for stable reference/catalogue tables, for example `r_license_class` and `r_permission`.
  - `x_` for cross-reference, join, and assignment link tables, for example `x_role_permission`, `x_staff_branch_membership`, and `x_branch_license_class`.
  - `t_` for transactional, workflow, session, token, or event tables, for example `t_user_role_assignment`, `t_refresh_token`, and `t_learner_branch_transfer`.
  - `h_` for immutable history or audit-history tables.
  - `log_` for technical/application log tables.
  - `tmp_` for temporary, staging, and import tables.
- Do not use unprefixed table names for new persistent tables.
- Keep entity names and domain class names clean and unprefixed. Prefixes are a physical database naming concern only.
- Use `uuid` primary keys for persistent tables unless a different identifier is explicitly agreed.
- Preserve stable public/API identifiers such as `rajagiriya` and `light` as separate unique `code` columns instead of exposing database UUIDs as public contract values.
- Use precise financial types for money, for example `numeric(12,2)` for LKR prices. Do not use floating point types for money. Use integer money fields only when storing minor units and name them accordingly, for example `amount_cents` or `amount_minor`.
- Add `NOT NULL` to required columns. Avoid nullable columns unless the absence of the value is meaningful and documented by the schema.
- Add check constraints for valid ranges, non-blank required text, enum-like values, code formats, URL/email/phone formats, JSON shape, positive quantities/prices, and timestamp consistency.
- Add unique constraints and indexes for natural keys and invariants, including partial unique indexes where the rule is conditional.
- Use foreign keys with deliberate `ON DELETE` behavior. Prefer `RESTRICT` for reference data and `CASCADE` only for owned child records.
- Keep Liquibase changelogs and standalone SQL reference files under `docs/database` aligned.
- Maintain `docs/database/school-schema.sql` and `docs/database/school-data.sql` as the canonical standalone SQL representation of the current database. A fresh PostgreSQL database must be creatable by running the schema file first and the data file second.
- Keep `school-schema.sql` as current-state DDL, not migration-style patch SQL. Each `CREATE TABLE` statement must include the complete current column list and table constraints; do not model current schema state with `ALTER TABLE ... ADD COLUMN` statements in this docs schema file.
- Keep `school-data.sql` limited to seed/reference data and make every seed statement idempotent.
- For already-applied Liquibase changesets, add a new changeset instead of editing old changesets, unless the database has not been shared or applied anywhere.
- Seed data should be idempotent using `ON CONFLICT` or an equivalent safe pattern.

## Verification

After changing Java code or database migrations, run:

```bash
mvn test
```
