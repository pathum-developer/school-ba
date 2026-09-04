# Roles and Permissions

## How a Permission Is Named

A permission code is `<resource>:<action>`, for example `branch:read`. The code is
the only thing application code checks. Role names are never checked, so a role can
be renamed or restructured without touching a single authorization check.

The scope a permission applies to is **not** part of its name. `staff:read` granted
at branch scope reads the staff of that branch; the same code granted at school scope
reads every branch's staff. Putting the scope in the name would need a separate code
for each level and force every check to know which one to ask for.

So there is no `branch:view-staff` and no `branch:view-details`. There is `staff:read`
and `branch:read`, and the word "branch" comes from the grant.

## Permission Ceilings

Each permission carries a `maxScopeType`: the **deepest** scope a role may hold it at.
It is a ceiling on placement, not a measure of privilege.

| `maxScopeType` | May be held by |
| --- | --- |
| `PLATFORM` | platform roles only |
| `SCHOOL` | platform and school roles |
| `BRANCH` | platform, school and branch roles |

A permission capped at `BRANCH` is therefore the least restricted, because it may be
placed anywhere. The ceiling exists to bound delegation: a branch that can define its
own roles must not be able to put a school-wide action into one of them.

## Current Permissions

Branch administration, the first set defined.

| Code | Ceiling | What it allows |
| --- | --- | --- |
| `branch:create` | `SCHOOL` | Create a branch or yard within the school |
| `branch:manage-status` | `SCHOOL` | Activate or deactivate a branch, and set the head office |
| `branch:read` | `BRANCH` | View branch details, including address and contact numbers |
| `branch:update` | `BRANCH` | Update branch details such as name, address, type and contact numbers |
| `branch-license-class:manage` | `BRANCH` | Set which licence classes a branch offers, and the price of each |
| `branch-license-class:read` | `BRANCH` | View the licence classes a branch offers and the price of each |
| `staff:read` | `BRANCH` | View staff records and their branch assignments |

Why the two ceilings differ:

- `branch:create` cannot be branch-scoped, because the branch does not exist yet.
  There is nothing for such a grant to be scoped to.
- `branch:manage-status` is capped at school scope because closing a branch is the
  school's decision, not the branch's own. A branch-owned role can never carry it.
- `branch:update` reaches branch scope, so a branch can maintain its own details.
  That is only safe because the dangerous state change is not part of it. Had
  activation and the head office flag been folded into `branch:update`, the whole
  permission would have had to sit at school scope, and every routine address
  correction would have needed a school administrator.
- The branch code is not covered by `branch:update`. It is a stable public identifier
  that appears in URLs, set once at creation and never edited.
- `branch-license-class:manage` reaches branch scope so a branch may manage its own
  offering. Note this includes pricing; if prices are meant to be set centrally,
  raise the ceiling to `SCHOOL`.
- `branch-license-class:read` is separate from `branch:read` because the offering
  carries what the branch charges, which is commercially sensitive in a way that an
  address and a telephone number are not. Splitting the read is what lets a role look
  up a branch without seeing its pricing. It shares the `BRANCH` ceiling of the manage
  code, since a branch that may set its own offering must be able to read it.
- Neither licence class code covers `r_license_class`. That is the Department of Motor
  Traffic's list of classes: platform-wide reference data, identical for every school,
  and not gated by a permission.
- `staff:read` and `branch:read` reach branch scope so a branch role sees its own
  branch, while a school role sees all of them, using the same code.

## Rules for Adding a Permission

- Name the resource acted on, not the screen it appears behind.
- Never encode a scope in the name. The grant supplies it.
- Set the ceiling to the deepest scope at which the action is still safe to delegate.
  When unsure, choose the shallower one: raising a ceiling later is a data change,
  while lowering it revokes access that roles already depend on.
- Permissions are reference data. They are created by migration only, never at
  runtime.
- A role may only contain permissions whose ceiling reaches the role's own scope.
  The database refuses the rest, so a mistake here fails loudly rather than granting
  quietly.

## Roles

### School Super Admin

`school-super-admin`, scope `SCHOOL`, audience `STAFF`, system role.

Full administrative access within one school. Holds every permission a school-scoped
role is allowed to hold, which today is all seven.

There is **one role row per school**, not one shared role. Roles are school-owned, so
a school-scoped row must name its school, and an unowned role would break the foreign
key chain that ties a grant to the role it names. A school created later therefore
needs its own copy, provisioned when the school is created.

It is marked as a system role, so a school administrator cannot weaken or delete the
role that grants their own access.

What it deliberately cannot do:

- Nothing at platform scope. The ceiling rule keeps a school-scoped role away from
  any permission capped at `PLATFORM`, so "super admin" means super within one
  school, never across the platform.
- Nothing at another school. The scope names one school, and every grant made from
  this role is bounded by it.

The permission set is selected by ceiling rather than listed by code, so a permission
added later is granted to every school super admin on the next run. That is bounded
by the ceiling, but it means the grant is implicit. Replace the select with a literal
list if each addition should be a deliberate decision.

### Branch Super Admin

`branch-super-admin`, scope `BRANCH`, audience `STAFF`, system role.

Full administrative access within one branch. Holds every permission a branch-scoped
role is allowed to hold, which today is five: `branch:read`, `branch:update`,
`branch-license-class:read`, `branch-license-class:manage` and `staff:read`.

There is **one role row per branch**, seeded from `m_branch`. A branch-scoped row must
name both its school and its branch, so there is no shared template row, and a branch
created later needs its own copy provisioned with it. The code repeats across branches
without collision because roles are unique on `(code, schoolId, branchId)`: every
branch may have its own `branch-super-admin`, just as every branch may have its own
`instructor`.

The audience is not a choice. A branch-scoped role may not be assignable to learners
at all, which is the rule that keeps a learner login out of every branch-owned role.

What it deliberately cannot do:

- `branch:create`. A branch cannot create branches, and there would be nothing for
  such a grant to be scoped to.
- `branch:manage-status`. Deactivating a branch, or moving the head office, is the
  school's decision. A branch super admin who could close their own branch, or promote
  it to head office, would be acting outside the branch they administer.
- Anything at another branch. The scope names one branch, and both the grant and every
  check made through it are bounded by it.

So "super admin" here means super within one branch's day-to-day operation, never
power over the branch's existence. The exclusions are not a policy decision layered on
top: both codes are capped at `SCHOOL`, so the database refuses them in a branch-owned
role regardless of what the seed asks for.

The permission set is selected by ceiling rather than listed by code, with the same
consequence as the school role: a permission added later at `BRANCH` ceiling joins
this role on the next run. That is arguably the definition of the role, since a
`BRANCH` ceiling means precisely "safe to delegate to a branch", but replace the
select with a literal list if each addition should be deliberate.

The role is created holding permissions and granted to nobody. Assignment is a
separate step, and additionally requires the staff member to currently work at that
branch.

### Still to define

No platform-scoped roles exist yet, and no learner-facing role. When they are added,
record here which permissions each carries and at which scope, and keep this section
aligned with the seed data.
