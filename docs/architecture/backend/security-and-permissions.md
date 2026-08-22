# Security and Permissions

[<- Backend Architecture](README.md)

The canonical policy is
[administration requirements](../business-requirements/administration-requirements.md).
This document records the backend shape required to implement it. If a summary here loses
an invariant or conflicts with the canonical policy, the administration requirements win.

## Security principles

- The server authenticates the principal and authorizes every protected operation.
- Authorization checks a permission, one complete matching grant, and stored target scope;
  application logic never branches on a display role or persona name.
- Every protected endpoint is default-deny until it has an explicit permission and target
  scope policy.
- The client may filter navigation and guard routes for usability, but those checks grant
  no authority.
- Access-relevant lifecycle changes must stop access immediately, including requests that
  were authorized before a revocation but have not committed yet.

```text
can(principal, "CO_STUDENT_VIEW", targetStudent)  correct
principal.role == "branch_staff"                 incorrect
```

## Principals and account onboarding

User accounts have one immutable type: `STAFF` or `STUDENT`.

Staff accounts are created only through a protected invitation workflow. Invitations are
single-use, time-limited, and bound to an approved identity and verified contact; the
invitee establishes credentials and MFA. The first `school_super_admin` account and role
assignment are provisioned once by deployment migration, not by an application endpoint.

A student profile can exist without an account. Portal invitation redemption validates a
single-use token, verified contact, profile status, owner branch, and link eligibility in
one transaction. It then creates or links one `STUDENT` account and assigns the protected
`student_default` role atomically.

Service identities are separate non-user principals. They use distinct rotated
credentials, an immutable explicit service policy, a fixed branch context, and their own
authorization and policy revisions. They cannot hold user roles or control-plane
permissions.

## Permission and scope contract

Permissions are immutable seed records. Their prefix fixes where they are valid:

| Prefix | Valid scope | Meaning |
| --- | --- | --- |
| `SC_` | `SCHOOL` | School-only permission |
| `BR_` | `BRANCH` | Branch-only permission |
| `CO_` | `SCHOOL` or `BRANCH` | Common action whose effect is limited by the role scope |
| `ST_` | `SELF` | Student self-service permission in `student_default` only |

The authorization scopes are:

| Scope | Stored meaning |
| --- | --- |
| `SCHOOL` | No branch ID; covers all branches for the exact granted action |
| `BRANCH` | One required immutable branch ID on the role and assignment |
| `SELF` | No branch ID; resolves only through the authenticated student's active link |

A prefix classifies a permission; it does not grant authority. The complete usable and
delegable sets for protected roles must come from a reviewed, version-controlled seed
manifest, never prefix inference.

## Roles, branch assignments, and grants

Permissions belong to roles, not directly to users. An ordinary role has one immutable
`SCHOOL` or `BRANCH` scope. A branch role is permanently bound to one branch. Ordinary
roles have an irreversible `ACTIVE` to `INACTIVE` lifecycle.

A role assignment is an immutable binding of user, role, scope, and branch where
applicable. It moves only from `ACTIVE` to `ENDED`. Changing any binding requires ending
the old assignment and creating a new one.

A staff branch assignment is a separate immutable lifecycle record. It says where a staff
member is eligible to work but grants no permission. Branch access requires both an active
staff branch assignment and an active matching branch role assignment. Ending the staff
branch assignment ends all attached branch role assignments in the same transaction.

Protected system-role types are:

- One `school_super_admin` at `SCHOOL` scope.
- One branch-bound `branch_super_admin` instance per branch.
- One `student_default` at `SELF` scope, which is the only role a `STUDENT` account may
  hold.

Protected roles cannot be modified, cloned, renamed, deleted, or delegated. Ordinary role
management must use one active authorizing role that contains both the required management
permission and a delegation set covering every requested permission and delegation right.
The server cannot assemble authorization from partial grants held in different roles.
Control-plane permissions are non-delegable and may be held only by protected seed roles.

## Request authorization

For each protected request, the server must:

1. Authenticate an active principal and validate its current authorization version.
2. Load the endpoint's explicit required permission and target-scope policy.
3. Resolve the target and owner branch from stored data rather than trusting request scope.
4. Find one active role assignment containing the permission at the required scope.
5. For `BRANCH`, also require the matching active staff branch assignment and active target
   branch.
6. For `SELF`, resolve the target from the account's active student link and validate the
   student profile status and owner branch lifecycle.
7. Before a sensitive commit, revalidate the principal authorization version, every
   relevant role-policy revision, target versions, and branch lifecycle version.

A school-scoped grant covers branches only for its exact resource action. It does not
bypass inactive-branch restrictions. A user cannot combine a permission from a branch role
with scope from a school role, or combine a management permission from one role with
delegation rights from another.

Reports, counts, search facets, exports, files, imports, bulk requests, jobs, webhooks, and
internal endpoints are protected operations too. Authorization filtering happens before
aggregation or data retrieval, so even an unauthorized count or empty/non-empty indicator
is not exposed.

## Branch-owned data and files

Students, vehicles, lessons, payments, documents, and later branch resources have one
required server-controlled owner branch. Generic updates cannot move that ownership.
Normal relationships stay within one owner branch; cross-branch transfers are dedicated,
school-scoped, permission-specific, audited workflows.

Files inherit authorization from an accessible parent record. Upload intents and download
links are single-use or short-lived and bound to one authorized parent, file, and
operation. Direct storage URLs that continue working after access revocation are not
allowed.

## Lifecycle, consistency, and audit

Account deactivation, role or branch-assignment revocation, role deactivation, branch
deactivation, student-link changes, profile restrictions, and service-identity changes
must invalidate current authorization immediately. Use a principal authorization version,
role-policy revision, service-policy revision, or stricter equivalent. A sensitive request
must fail if a relevant revision changes before commit.

Reactivating a staff account or branch restores no assignment or entitlement. Any change
that could remove the final eligible `school_super_admin` must serialize on the protected
invariant, evaluate the post-change state in the same transaction, and fail without changes
if no eligible administrator would remain.

Assignment creation and revocation are idempotent transactional workflows backed by
database uniqueness constraints. They lock stable records or use equivalent serialization,
reauthorize inside the transaction, and never reactivate historical records.

Control-plane actions require recent MFA reauthentication. Administrative state changes
are written to an append-only, tamper-evident audit log that no application role can alter
or delete.

## Code ownership

- `auth` owns login, credential and MFA workflows, sessions, invitations, authorization
  domain services, JWT helpers if JWT is selected, and auth DTOs.
- `config.security` owns Spring Security wiring, filters, exception handling, and method or
  request policy integration.
- `user` owns user identity/profile behavior that is not authentication workflow logic.
- Each resource domain owns its target-loading and row-scope policy inputs; it must not
  accept a client scope decision as authorization.
- `common` may hold genuinely shared security errors or value types but must not become a
  second auth domain.

Credential transport, session format, MFA technology, and concrete endpoint contracts are
still open; see [backend open questions](open-questions.md#blocking-before-authenticated-features).
