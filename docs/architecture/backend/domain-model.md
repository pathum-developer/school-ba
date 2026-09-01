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

Represents a school-owned student record.

- `id`: internal UUID primary key.
- `schoolId`: owning school.
- `currentBranchId`: current registered branch.
- `studentNo`: school-specific student number.
- `status`: school-specific student status.
- Identity and contact fields required to manage the learner within the school.

Constraints:

- `currentBranchId` must reference a branch owned by the same `schoolId`.
- A learner belongs to exactly one school.
- One learner must not be shared across schools.

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
