# Java Package Instructions

These rules apply to Java package and folder creation under the base package:

`com.elvencode.schoolba`

## Package Structure

Follow a feature/domain-based package structure.

Use lowercase singular domain names, for example:

- `learner`
- `user`
- `auth`
- `school`

Each domain package should use this structure when applicable:

```text
domain/
  controller/
  service/
    impl/
  repository/
  entity/
  dto/
    request/
  mapper/
  enums/
```

Shared project packages should use this structure:

```text
common/
  dto/
    request/
  exception/
  mapper/
  util/

config/
  security/
  web/
```

## Rules

- Put school-level catalogue, public school profile, branch, and yard code under `school`.
- Put learner-related code under `learner`.
- Put user-related code under `user`.
- Put authentication and authorization code under `auth`.
- Put reusable helpers, shared DTOs, exceptions, mappers, and utilities under `common`.
- Put Spring configuration classes under `config`.
- Map JPA entities to the prefixed physical table names defined in `docs/database/AGENTS.md`; do not leak those prefixes into Java domain type names.
- Use singular package names, for example `learner`, not `learners`.
- Use lowercase package names.
- Keep controller, service, repository, entity, dto, mapper, and enums separated.
- Keep service interfaces in `service` and service implementations in `service.impl`.
- When creating or updating branch package code, follow the existing `school/branch` package folder structure.
- Put request DTOs under the `dto.request` subpackage, for example `school.branch.dto.request`.
- Keep non-request DTOs directly under the domain `dto` package.
