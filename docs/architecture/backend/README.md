# Backend Architecture

[<- Architecture](../README.md)

Architecture notes for `school-ba`, the Spring Boot API that backs the `school-ui` frontend.

> **Status.** Draft. The backend is being shaped from the frontend architecture and business requirements. Keep these documents aligned with implementation decisions as the API grows.

## Documents

| Document | Read it for |
| --- | --- |
| [Overview](overview.md) | Backend scope, first delivery slice, project constraints |
| [API contracts](api-contracts.md) | Endpoint shape, payloads, response contracts, frontend integration notes |
| [Domain model](domain-model.md) | Backend domains, entities, relationships, business rules |
| [Security and permissions](security-and-permissions.md) | Auth direction, permission and scope model, server-side enforcement |
| [Decisions](decisions.md) | Architecture decisions made during backend design |
| [Open questions](open-questions.md) | Business/product decisions that should not be guessed in code |

## Source Priority

For backend work, read in this order:

1. Business requirements in `../business-requirements/`.
2. Frontend API migration notes in `../frontend/state-and-data.md`.
3. Backend architecture docs in this folder.
4. Existing backend code in `C:\elven-code\school\school-ba`.

If these documents conflict with a discussed implementation decision, update the relevant document in the same change as the code.
