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
| `branch:read` | `BRANCH` | View branch details, including contact numbers and licence class offerings |
| `branch:update` | `BRANCH` | Update branch details such as name, address, type and contact numbers |
| `branch-license-class:manage` | `BRANCH` | Set which licence classes a branch offers, and the price of each |
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
role is allowed to hold, which today is all six.

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

### Still to define

No branch-scoped or platform-scoped roles exist yet. When they are added, record here
which permissions each carries and at which scope, and keep this section aligned with
the seed data.
