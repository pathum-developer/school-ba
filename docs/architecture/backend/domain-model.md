# Backend Domain Model

## Core Tenant Model

### School

- `id`: internal UUID primary key.
- `code`: stable public school code.
- `name`: school display name.

### Branch

- `id`: internal UUID primary key.
- `schoolId`: owning school.
- `code`: stable branch code unique within the school.
- `name`: branch display name.
- `city`: branch city.

## Learner Model

### Learner

Represents a school-owned learner record.

- `id`: internal UUID primary key.
- `schoolId`: owning school.
- `currentBranchId`: current registered branch.
- `learnerNo`: school-specific learner number.
- `status`: school-specific learner status.
- `phoneNumber`: required contact number.
- `email`: optional email address.
- Remaining identity fields required to manage the learner within the school.

Constraints:

- `currentBranchId` must reference a branch owned by the same `schoolId`.
- A learner belongs to exactly one school.
- One learner must not be shared across schools.
- `phoneNumber` is unique within the school and not across schools.
- `email` is optional, and unique within the school when present.

## Staff Model

### Staff

Represents a school-owned employment record. It exists whether or not the person
has a login, so someone can be recorded as staff and assigned to a branch without
being given system access.

- `id`: internal UUID primary key.
- `schoolId`: owning school.
- `employeeNo`: school-specific employee number.
- `fullName`: legal name, as distinct from a login display name.
- `designation`: human resources label such as instructor or registrar.
- `employmentStatus`: active, on leave, suspended, resigned, or terminated.
- `phoneNumber`: required contact number.
- `email`: optional email address.
- `joinedOn` and `leftOn`: employment dates.
- Remaining identity fields required to manage the employee within the school.

Constraints:

- A staff member belongs to exactly one school.
- `employeeNo` is unique within the school.
- `phoneNumber` is unique within the school and not across schools.
- `email` is optional, and unique within the school when present.
- `leftOn`, where present, is not before `joinedOn`.
- `designation` grants nothing. Authority comes only from roles granted to the login.

### StaffBranchMembership

Which branches a staff member works at: zero, one, or many.

- `staffId`: the employed person.
- `branchId`: a branch of that person's school.
- `isPrimary`: the home branch, at most one per staff member.

Constraints:

- `branchId` must reference a branch owned by the same school as the staff member.
- Membership is keyed by staff member, not by login, so it can be recorded for
  someone who has no system access.
- Membership grants nothing by itself. It is the precondition for holding a
  branch-owned role, and removing it removes those roles.

## Platform Model

### PlatformOperator

Represents a person who runs the platform itself. It has no owning school, which is
what separates an operator from school staff, and like the other person records it
exists whether or not the person currently has a login.

- `id`: internal UUID primary key.
- `employeeNo`: platform-wide employee number.
- `fullName`: legal name.
- `designation`: human resources label.
- `employmentStatus`: active, on leave, suspended, resigned, or terminated.
- `email`: required contact address.
- `joinedOn` and `leftOn`: employment dates.

Constraints:

- A platform operator belongs to no school.
- `employeeNo` and `email` are unique across the platform, since there is no school
  to scope them by.
- `designation` grants nothing. Authority comes only from roles granted to the login.

## Authentication Model

### AppUser

One login record. Platform operators, school staff, and learners all authenticate
through it. Every login points at exactly one person record; `app_user` itself holds
credentials and account state, never the person's details.

- `id`: internal UUID primary key.
- `schoolId`: owning school, or absent for a platform operator.
- `username`: login identifier.
- `passwordHash`: absent until the account is activated.
- `status`: pending activation, active, suspended, locked, or disabled.
- `platformOperatorId`: the operator this login belongs to, or absent otherwise.
- `staffId`: the staff member this login belongs to, or absent otherwise.
- `learnerId`: the learner this login belongs to, or absent otherwise.
- `authorizationVersion`: change counter used to invalidate cached permissions.

Constraints:

- Exactly one of `platformOperatorId`, `staffId`, and `learnerId` is present. The
  one that is present determines what kind of account it is.
- A login with no school must be a platform operator's, and a login with a school
  must be a staff member's or a learner's.
- Each person has at most one login.
- `staffId` and `learnerId` must reference records owned by the same `schoolId`.
- A learner login is never a branch member, which is what keeps it out of every
  branch-owned role.
- A branch-owned role may only be granted to a login whose staff member currently
  works at that branch.
- `displayName` and `email` on the login are the account's own label and its
  security contact address. The person record remains authoritative for the legal
  name and the contact address.

### Learner Username Generation

A learner does not choose a username. The system generates one from a fixed pattern:

```text
{schoolCode}-{learnerNo, lowercased with non-alphanumeric characters removed}
```

School `elven` and learner number `L-0001` produce `elven-l0001`.

Rules:

- The username is unique by construction, because the school code is unique across schools and the learner number is unique within the school. Generation needs no collision retry, and a uniqueness failure means a real defect rather than an expected race.
- The username is generated once when portal access is issued, then stored. It is never re-derived on read, so a later correction to a school code or a learner number cannot move a learner to a different username.
- The username is opaque once issued. Code must not parse it to recover the school or the learner; use `schoolId` and `learnerId` for that.
- Staff usernames are chosen by an administrator and do not follow this pattern.

## Branch Transfer Model

### LearnerBranchTransfer

- `id`: internal UUID primary key.
- `schoolId`: owning school.
- `learnerId`: learner being transferred.
- `fromBranchId`: source branch.
- `toBranchId`: target branch.
- `reason`: transfer reason.
- `status`: requested, approved, rejected, or cancelled.
- `requestedBy`: user who requested the transfer.
- `requestedAt`: request timestamp.
- `decidedBy`: user who approved or rejected the transfer.
- `decidedAt`: decision timestamp.

Constraints:

- `learnerId`, `fromBranchId`, and `toBranchId` must all belong to the same school.
- `fromBranchId` must match the learner's current branch when the request is created.
- Approval updates `Learner.currentBranchId` to `toBranchId`.
