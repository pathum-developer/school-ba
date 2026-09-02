# Functional Requirements

## Multi-Tenant School Management

- The system must support multiple schools as separate tenants.
- Each school may operate multiple branches in different cities.
- Each branch belongs to exactly one school.
- A learner belongs to exactly one school.
- A learner must not study at multiple schools at the same time in this system.
- Learner numbers, enrollments, lessons, payments, documents, progress, and branch assignment are scoped to the learner's school.
- A school must not be able to view or modify another school's learners.

## Branch Assignment

- Each learner must have one current registered branch at a time.
- The current registered branch must belong to the same school as the learner.
- Lessons, scheduling, attendance, and branch-level operations must use the learner's current registered branch unless a completed transfer changes it.

## Branch Transfer Workflow

- A learner may be transferred from one branch to another branch within the same school.
- A branch transfer must start as a request and must not change the current registered branch until approved.
- The transfer request must record the learner, source branch, target branch, reason, requester, status, and timestamps.
- Approved transfers must update the learner's current registered branch.
- Rejected or cancelled transfers must not change the learner's current registered branch.
- The system must keep branch transfer history for audit and reporting.
