# Roles and permissions

[<- Business requirements](README.md)

> **Status: target model, not implemented.**
> [Administration requirements](administration-requirements.md) is authoritative for
> account types, permissions, scopes, assignments, lifecycle workflows, delegation, and
> authorization enforcement. This document translates that policy into product personas
> and application behavior without redefining it.

## Account types and operational personas

There are exactly two immutable account types: `STAFF` and `STUDENT`. Instructor, branch
staff, and school staff describe work people perform; they are not account types and must
not become hard-coded authorization branches.

| Persona | Account type | Typical authorization | Primary need |
| --- | --- | --- | --- |
| Student | `STUDENT` | Protected `student_default` role at `SELF` scope | Their own lessons, progress, payments, and resources |
| Instructor *(still to confirm)* | `STAFF` | Ordinary staff role at `BRANCH` scope | Assigned lessons and student progress in an assigned branch |
| Branch staff | `STAFF` | One or more roles at `BRANCH` scope | Operate one or more specifically assigned branches |
| School staff | `STAFF` | One or more roles at `SCHOOL` scope | Authorized work across all branches |

A staff member can hold different roles in different branches and can also hold a
school-scoped role. Being assigned to a branch identifies where the staff member may work,
but grants no data access by itself. Being assigned to every branch does not create
`SCHOOL` scope.

`SELF` is reserved for the linked student account and the protected `student_default`
role. An instructor is staff, so "my assigned lessons" must be enforced as a branch-scoped
resource rule; it must not reuse student `SELF` scope.

## What each persona needs to do

Written as jobs rather than screens, because roles are configurable permission bundles and
screens follow from the work a person is authorized to perform.

**Student** - *"Am I on track, and what do I owe?"*
View the next lesson, lessons used, instalment status, licensing-journey progress,
learning-hub resources, and trial-test date. Request rescheduling if the business confirms
self-service under the 12-hour rule
([BR-12](domain-and-rules.md#service-delivery)).

**Instructor** - *"Who am I teaching today?"*
View assigned lessons with student, vehicle, and pickup details; mark attendance; record
syllabus progress; and flag a student as trial-ready. This persona remains an inferred
requirement until the business confirms that instructors sign in directly.

**Branch staff** - *"Keep today running."*
Handle the selected branch's callback queue, timetable, instructor and vehicle assignment,
enrolment, document collection, payment collection, rescheduling, and trial-test slots.
The callback queue closes the current gap between
[FR-208](functional-requirements.md#lead-capture) and the two-hour promise.

**School staff** - *"Is the business working?"*
Perform specifically permitted work across branches, such as catalogue administration,
reporting, staff lifecycle, and branch administration. School scope never bypasses an
inactive branch or a missing resource permission.

## Authorization model

Application code checks a permission against the target data scope. It does not check a
persona or display role name.

```text
can(account, permission, targetScope)  correct
account.role == "branch_staff"        incorrect
```

One request is authorized only when the server finds one complete matching grant:

1. The account, target branch, role, role assignment, and any required staff branch
   assignment are active.
2. One active role assignment contains the required permission at the target scope.
3. For `BRANCH`, the role, role assignment, staff branch assignment, and stored target
   record all refer to the same branch.
4. For `SCHOOL`, the permission comes from a school-scoped role; permissions from another
   role cannot be combined with that scope.
5. For `SELF`, the authenticated `STUDENT` account is linked to the target student record
   and the profile and owner branch allow that operation.

The three authorization scopes are:

| Scope | Meaning |
| --- | --- |
| `SCHOOL` | All branches for the exact actions granted by a school-scoped role |
| `BRANCH` | One immutable branch bound to the role and role assignment |
| `SELF` | Only the student record linked to the authenticated student account |

The server resolves scope from stored records. A branch ID, role ID, scope value, or
student ID supplied by the browser is input to validate, never proof of authority.

## Permission naming

Permissions are immutable, server-managed seed data with four categories:

| Prefix | Valid scope | Purpose |
| --- | --- | --- |
| `SC_` | `SCHOOL` | School-only actions |
| `BR_` | `BRANCH` | Branch-only actions |
| `CO_` | `SCHOOL` or `BRANCH` | The same action usable at either staff scope |
| `ST_` | `SELF` | Student self-service actions in `student_default` only |

For example, `CO_STUDENT_VIEW` in a school-scoped role can view authorized students across
branches. The same permission in a branch-scoped role applies only to the exact assigned
branch. A prefix classifies a permission but never grants it implicitly.

The complete usable and delegable permission sets must live in a reviewed,
version-controlled seed manifest. Do not revive the earlier dotted draft catalogue or
infer a permission from its prefix.

Control-plane permissions for lifecycle, role administration, protected-role assignment,
transfers, recovery, and equivalent security-sensitive workflows are non-delegable and
may be held only through the protected seed roles defined by the canonical policy.

## Roles and assignments

Ordinary roles are configurable permission bundles with one immutable `SCHOOL` or
`BRANCH` scope. A branch role is permanently bound to one branch. Roles have an `ACTIVE`
or `INACTIVE` lifecycle; deactivation is irreversible and ends their active assignments.

Role assignments are immutable bindings of account, role, scope, and branch where
applicable. They have `ACTIVE` or `ENDED` state. Changing the user, role, scope, or branch
means ending the old assignment and creating a new one through an authorized workflow.

Three protected system-role types are seeded and cannot be edited, cloned, renamed,
deleted, or delegated:

| Protected role | Scope | Purpose |
| --- | --- | --- |
| `school_super_admin` | `SCHOOL` | Protected school control plane defined by the seed manifest |
| `branch_super_admin` | `BRANCH` | One protected instance per branch, bound to that branch |
| `student_default` | `SELF` | The only role a `STUDENT` account may hold |

Permissions are assigned to roles, not directly to users. Role management, assignment,
revocation, lifecycle actions, and permission delegation are separate workflows. An
administrator cannot manage their own memberships, and one authorizing role must contain
both the required management permission and all required delegation rights.

## Account onboarding and sessions

Staff do not register publicly. A protected school-super-admin workflow sends a
single-use, time-limited invitation bound to an approved identity and verified contact.
The invitee establishes credentials and multi-factor authentication. The first
`school_super_admin` is created only by one-time deployment provisioning.

A student record can exist without an account. Once its branch, profile status, and
verified contact make it link-eligible, authorized branch staff can send a single-use,
time-limited portal invitation. Redemption creates or links one `STUDENT` account and
atomically assigns `student_default`. A student account can link to only one student
record, and a student record can have only one active account link.

On session establishment, the API should return identity and effective grants separated
by scope and branch. A single role name or flat permission list is insufficient for staff
who hold different grants in different branches. Grant boundaries must remain intact where
policy requires one authorizing role; the client must not union partial grants. The
frontend may use grants to shape navigation, but every backend request must authorize the
action and target again.

Access-relevant changes must take effect immediately through server-side authorization
version checks, role-policy revision checks, or session invalidation. Sensitive
control-plane actions require recent multi-factor reauthentication.

## Product questions still open

1. **Do instructors sign in?** If yes, define the branch-scoped operational permissions
   and the row rule that limits them to assigned work.
2. **Does the student portal ship in the first release?** The public site promises it, but
   the staff workflow is an earlier dependency.
3. **Which Rajagiriya staff receive school-scoped roles?** Head-office location alone must
   not grant `SCHOOL` scope.
4. **Which branch owns a student who trains and tests at different locations?** Every
   student has exactly one owner branch, so the business must define this rule.
5. **Can one student hold multiple enrolments?** This determines whether portal and
   payment views are singular or collections.
6. **Is rescheduling student self-service or staff-mediated?** Self-service requires an
   explicit `ST_` permission and server-side enforcement of the 12-hour rule.
