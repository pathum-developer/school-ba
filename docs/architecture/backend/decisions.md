# Decisions

[<- Backend Architecture](README.md)

Record backend architecture decisions here as they are agreed. Keep entries short and dated.

## ADR-001: Backend Docs Live Beside Frontend Architecture

Date: 2026-08-21

Decision: Create `docs/architecture/backend/` in `school-ui` for backend architecture notes, because the frontend architecture already holds the product requirements and API migration notes that shape `school-ba`.

Reason: The backend is being built to support the existing frontend and should not drift from the documented product contract.

Consequences:

- Backend endpoint design should reference these docs.
- If backend behavior changes the product/API contract, update the corresponding architecture document.
- `school-ba/AGENTS.md` points future Codex work to this folder.
