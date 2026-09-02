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

## Authentication Model

### AppUser

One login record. Staff, platform operators, and learners all authenticate through it.

- `id`: internal UUID primary key.
- `schoolId`: owning school, or absent for a platform operator.
- `username`: login identifier.
- `passwordHash`: absent until the account is activated.
- `status`: pending activation, active, suspended, locked, or disabled.
- `staffId`: the staff member this login belongs to, or absent otherwise.
- `learnerId`: the learner this login belongs to, or absent otherwise.
- `authorizationVersion`: change counter used to invalidate cached permissions.

Constraints:

- `learnerId` present means the login is a learner's. `staffId` present means it is
  a staff member's. A login must never carry both.
- A platform operator carries neither, because they are employed by no school.
- A learner has at most one login, and a staff member has at most one login.
- `staffId` and `learnerId` must reference records owned by the same `schoolId`.
- A learner login is never a branch member, which is what keeps it out of every
  branch-owned role.
- A branch-owned role may only be granted to a login whose staff member currently
  works at that branch.

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
