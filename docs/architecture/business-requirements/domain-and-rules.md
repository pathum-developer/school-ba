# Domain and Rules

## Tenant Boundary

- School is the tenant boundary.
- Branch, learner, enrollment, lesson, payment, document, and transfer records are owned by one school.
- A branch must belong to exactly one school.
- Data owned by one school must not be mixed with data owned by another school.

## Learners

- A learner is a school-owned student record.
- A learner must belong to exactly one school.
- The system does not support one learner studying at multiple schools at the same time.
- A learner must have exactly one current registered branch.
- The current registered branch must belong to the same school as the learner.
- School-specific identifiers such as student number, admission number, enrollment status, balances, and learning progress belong directly to the learner.

## Branch Transfers

- Branch transfer is only between branches of the same school.
- Cross-school transfer is not supported.
- A transfer request must reference one learner, one source branch, and one target branch.
- The source branch must match the learner's current registered branch when the request is created.
- The target branch must belong to the same school as the source branch and learner.
- Only an approved transfer may change the learner's current registered branch.
- Transfer history must remain immutable after completion except for explicit audit corrections.
