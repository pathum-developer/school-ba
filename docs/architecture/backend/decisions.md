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

## ADR-002: Administration Requirements Own Authorization Policy

Date: 2026-08-22

Decision: Treat
`../business-requirements/administration-requirements.md` as the canonical policy for
accounts, permissions, scopes, roles, assignments, lifecycle workflows, delegation,
service identities, and authorization consistency.

Reason: Earlier architecture notes used a simplified persona model with `self`, `branch`,
and `all` scope and dotted draft permissions. That model cannot represent multiple branch
assignments, independent school grants, protected roles, revocation, or safe delegation.

Consequences:

- Use exactly `SCHOOL`, `BRANCH`, and `SELF` scope and the `SC_`, `BR_`, `CO_`, and `ST_`
  permission categories.
- Treat persona labels as user-experience concepts, not authorization identities.
- Store permissions on roles and authorize through one active matching role assignment;
  never assign permissions directly to users or combine partial grants from different roles.
- Model account, branch, role, assignment, student link, branch, and service-identity
  lifecycle changes as dedicated audited workflows.
- Use authorization/principal and role-policy revisions, or equivalent immediate session
  invalidation, so revocation takes effect before a later sensitive commit.
- Keep credential transport, session format, MFA technology, and endpoint contracts as
  explicit implementation decisions; the policy does not choose them.

## ADR-003: Hybrid Access JWT and Revocable Server Session

Date: 2026-08-22

Decision: Use a short-lived signed JWT only as an access-token transport. Each JWT is
bound to a server-side `auth_session`; a high-entropy opaque refresh token is stored only
in a secure HttpOnly cookie and persisted as a SHA-256 hash. The database retains refresh
token history so later rotation can detect replay.

Reason: The reference project's separation of controller, service, authentication
provider, security filter, and configuration is a good fit for this API. Its fully
stateless, long-lived JWT model is not sufficient for immediate account/session
revocation, current authorization checks, or staff MFA policy.

Consequences:

- Access JWTs contain only issuer/audience, account ID, session ID, authorization version,
  credential version, issued/expiry timestamps, token ID, and key ID. They contain no
  roles, permissions, scopes, or personal data.
- The request filter verifies the token signature and expected issuer/audience/key ID, then
  loads the active session and account and compares both current versions before creating a
  principal.
- `POST /api/auth/login` establishes a student password session. A staff password check
  creates a short-lived MFA challenge or returns `MFA_ENROLLMENT_REQUIRED`; it never issues
  an unrestricted staff token.
- JWT signing material must be supplied through `SCHOOL_SECURITY_JWT_SECRET`; no source
  fallback is permitted. The default access-token TTL is ten minutes, session idle TTL is
  seven days, and absolute TTL is thirty days, all configurable by environment.
- MFA verification, refresh-token rotation/reuse detection, logout, and protected
  permission enforcement remain separate follow-up workflows.
