# Security and Permissions

[<- Backend Architecture](README.md)

## Principle

The server owns authorization. The frontend may hide unavailable UI, but every backend request must authorize the action and row scope again.

Use permission checks, not role-name checks, in application logic.

```text
can(user, "booking.view", branchId)  good
user.role == "branch_staff"          avoid
```

## Draft Roles

Roles are assignment bundles, not branching logic:

| Role | Scope |
| --- | --- |
| Student | `self` |
| Instructor | `self` or `branch` |
| Branch staff | `branch` |
| School staff | `all` |

The instructor role is still an inferred proposal. Do not build instructor-specific auth without confirmation.

## Draft Permission Areas

Start with the smallest set needed for the callback queue:

- `booking.view`
- `booking.claim`
- `booking.convert`
- `booking.dismiss`

Later areas from the frontend proposal include student, lesson, payment, trial, instructor, catalogue, branch, content, reporting, and administration permissions.

## Scope Rules

Branch-scoped users must only see records belonging to their branch. School-wide users may see all branches. Student users may see only their own records.

Open decisions before final implementation:

- Whether Rajagiriya head office staff have `branch` or `all` scope.
- Which branch owns a student who trains at one branch and tests at another.
