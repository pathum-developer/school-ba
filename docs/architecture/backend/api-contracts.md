# API Contracts

## Learners

`POST /schools/{schoolCode}/learners`

- Creates a school-owned learner.
- Requires an initial branch belonging to the school.

`GET /schools/{schoolCode}/learners/{learnerId}`

- Returns one school-scoped learner.
- Must not expose learners from other schools.

`GET /schools/{schoolCode}/learners`

- Returns learners owned by the requested school.
- Branch-level users receive only learners in authorized branches unless a school-level permission grants broader access.

## Branch Transfers

`POST /schools/{schoolCode}/learners/{learnerId}/branch-transfers`

- Creates a branch transfer request for the school-owned learner.
- Request body includes `toBranchCode` and `reason`.
- Source branch is derived from the learner's current registered branch.

`GET /schools/{schoolCode}/learners/{learnerId}/branch-transfers`

- Lists branch transfer history for the school-owned learner.

`POST /schools/{schoolCode}/branch-transfers/{transferId}/approve`

- Approves a pending branch transfer.
- Updates the learner's current registered branch to the target branch.

`POST /schools/{schoolCode}/branch-transfers/{transferId}/reject`

- Rejects a pending branch transfer.
- Does not change the learner's current registered branch.

`POST /schools/{schoolCode}/branch-transfers/{transferId}/cancel`

- Cancels a pending branch transfer.
- Does not change the learner's current registered branch.
