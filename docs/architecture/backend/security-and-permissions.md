# Security and Permissions

## Tenant Isolation

- School is the tenant boundary for authorization.
- Users may access only schools they are authorized for.
- Users may access only branches they are authorized for unless granted school-level permissions.
- Learner data must always be filtered by school authorization.
- A learner belongs to exactly one school and must not be shared across schools.

## Learner Permissions

- Creating a learner requires permission for the target school and initial branch.
- Reading or updating a learner requires permission for the owning school.
- Branch-level users may read or update only learners currently assigned to their authorized branches unless a school-level role grants broader access.

## Branch Transfer Permissions

- Creating a branch transfer request requires permission for the learner's current branch.
- Approving or rejecting a transfer requires permission for the school and, where branch-level approval is enforced, permission over both source and target branches.
- Transfer APIs must verify that the transfer, learner, source branch, and target branch all belong to the requested school.
