# Administration Requirements

## User Types

There are two types of users:

- Staff
- Students

A staff member can have zero or more active branch assignments. An operational staff member normally has at least one branch assignment. A staff member who performs only school-scoped administration may have no operational branch assignment.

At any given time:

- A student is assigned to only one branch.
- A vehicle is assigned to only one branch.
- Each branch role assignment applies to exactly one branch.

A staff member can hold different roles in different assigned branches. A branch assignment is necessary but not sufficient for access: it identifies a branch the staff member may work in, while roles and permissions define the data and actions they may access.

This application has one school. School scope means all branches and is not a multi-school tenant boundary.

## Permissions

The permission naming contract has four fixed categories. Permissions, their scope classification, and their delegation policy are immutable, server-managed seed data:

- School-level permissions have the `SC_` prefix.
- Branch-level permissions have the `BR_` prefix.
- Permissions that can belong to either school or branch level have the `CO_` prefix.
- Student self-service permissions have the `ST_` prefix. They are valid only at `SELF` scope and are immutable permissions of the protected default student role.

`ST_` is deliberately separate from `SC_`, `BR_`, and `CO_` because `SELF` is neither school nor branch scope. An `ST_` permission cannot be included in a staff role.

A permission prefix is a classification, not authorization. The server authorizes using the stored permission, role scope, role assignment, and target data scope.

A `CO_` permission is a common permission. The permission defines the action, and the role scope defines where that action is allowed.

For example, `CO_STUDENT_VIEW` at school scope allows viewing students across all branches. The same `CO_STUDENT_VIEW` permission at branch scope allows viewing students only in the matching assigned branch.

## Scope

This application has three authorization scopes:

- `SCHOOL`: all branches. A school-scoped role and role assignment have no branch ID.
- `BRANCH`: one exact branch. A branch-scoped role and every assignment of it have the same branch ID and require an active staff assignment to that branch.
- `SELF`: only the authenticated student's linked record. A `SELF` role and role assignment have no branch ID and are limited to the protected default student role.

`SC_` permissions are valid only at `SCHOOL` scope. `BR_` permissions are valid only at `BRANCH` scope. `CO_` permissions are valid at either `SCHOOL` or `BRANCH` scope. `ST_` permissions are valid only at `SELF` scope.

A staff member does not gain `SCHOOL` scope by being assigned to many or all branches. Only a school-scoped role grants all-branch authority.

## Role Scope and Branch Binding

A role scope is set when the role is created and is immutable. `SC_ROLE_CREATE` creates only `SCHOOL` roles. `BR_ROLE_CREATE` creates only `BRANCH` roles for the exact branch where the actor has the required active assignment and permission.

The `SC_BRANCH_*` permissions listed in Role Management are the only cross-branch role-management permission family. `SC_BRANCH_ROLE_CREATE` is the member that lets the protected `school_super_admin` create an ordinary `BRANCH` role for a selected branch; it does not grant the actor branch data access or create a branch staff assignment.

The server, not the client, sets and validates a role's scope and branch ID. A `SCHOOL` or `SELF` role must have no branch ID. A `BRANCH` role must have one branch ID, and every assignment of that role must use that same branch ID. `SELF` roles are seed data only; no custom `SELF` role can be created.

A role assignment is an immutable binding of a user, role, scope, and branch where applicable. It has a server-managed lifecycle state of `ACTIVE` or `ENDED`; only an `ACTIVE` assignment can authorize access. Ending an assignment is irreversible. No request can change its user, role, scope, or branch ID, and only the dedicated authorized revocation or lifecycle workflow may change its state from `ACTIVE` to `ENDED`. To change the assigned user, role, or branch, the system must end the old role assignment and create a new authorized role assignment in the target scope.

Changing a role from `BRANCH` to `SCHOOL`, moving a branch role from one branch to another, or changing a role assignment's branch requires a new role and assignment. The actor must satisfy the normal create, delegation, and assignment rules for the target scope and branch.

The server and persistence model must reject any attempt to update a role's scope or branch ID, or a role assignment's user, role, scope, or branch ID. User interface controls and request fields are not security controls.

## Staff Permissions and Scope

A staff account does not receive data access simply because it is a staff account or has a branch assignment. It receives access through one or more role assignments.

A branch-scoped role can include `BR_` permissions and `CO_` permissions at branch scope. It authorizes an action only in the exact branch covered by the role assignment, and only while the staff member has an active assignment to that branch.

A school-scoped role can include `SC_` permissions and `CO_` permissions at school scope. It authorizes permitted actions across all branches. It does not require a branch assignment.

A school-scoped role must not include `BR_` permissions. A branch-scoped role must not include `SC_` permissions.

A staff member may hold branch-scoped roles for one or more branches and may also hold a school-scoped role. Each grant is evaluated independently. A user cannot combine a permission from a branch role with school scope from another role.

Authorization must find one matching permission-and-scope grant:

- For branch data, the user has the required permission in a role assigned for the target branch and has an active assignment to that branch.
- For school-scoped access, the user has the required permission in a school-scoped role. That scope covers all branches.
- The server resolves and validates the target data scope. A branch selected in the user interface or supplied in a request is not authorization.

Do not assign permissions directly to individual users during normal operation. Assign roles to users, and assign permissions to roles.

## Role Management and Delegation

Creating or updating a role, changing its permissions or delegation set, deactivating a role, assigning a role to a user, and revoking a role assignment are separate administrative actions.

The role-management seed permissions are:

- `SC_ROLE_CREATE`, `SC_ROLE_UPDATE`, `SC_ROLE_DEACTIVATE`, `SC_USER_ROLE_ASSIGN`, and `SC_USER_ROLE_REVOKE` for ordinary school-scoped roles.
- `BR_ROLE_CREATE`, `BR_ROLE_UPDATE`, `BR_ROLE_DEACTIVATE`, `BR_USER_ROLE_ASSIGN`, and `BR_USER_ROLE_REVOKE` for ordinary branch-scoped roles in the actor's assigned branch.
- `SC_BRANCH_ROLE_CREATE`, `SC_BRANCH_ROLE_UPDATE`, `SC_BRANCH_ROLE_DEACTIVATE`, `SC_BRANCH_USER_ROLE_ASSIGN`, `SC_BRANCH_USER_ROLE_REVOKE`, and `SC_BRANCH_PERMISSION_DELEGATE` for protected school-super-admin management of ordinary branch roles across all branches.

Each ordinary role has a server-managed lifecycle state of `ACTIVE` or `INACTIVE`. A newly created ordinary role becomes `ACTIVE` only through the authorized role-creation workflow. A client cannot set or change a role's lifecycle state in a generic role create or update request.

Only an `ACTIVE` ordinary role can be assigned to a user or authorize access. Deactivating an ordinary role is a named workflow, not a delete or generic update. It must be authorized in the role's exact scope, must not apply to protected system roles, must end every active role assignment for that role in the same transaction, must increment the role-policy revision, and must invalidate or revalidate affected users' active sessions immediately.

An ordinary role cannot be reactivated. If a retired role is needed again, a new role must be created through the normal authorized create, permission, delegation, and assignment rules. Historical inactive roles and their ended assignments may be retained for audit but cannot authorize access or be assigned again.

Usable permissions and delegable permissions are separate. The permission catalogue states whether a permission may ever be delegated at a scope. Each ordinary role has an explicit, server-controlled delegation set that is a subset of that role's usable permissions.

An authorization to create, update, or assign an ordinary role must come from one active authorizing role in the applicable scope. That one role must contain the required management permission and a delegation set that covers every permission and delegation right in the target role. The server must not combine a management permission from one role with delegation rights from another role.

For ordinary roles, every added permission and every added delegation right must be both usable and explicitly delegable by the authorizing role at the target scope. An ordinary role cannot delegate a permission it does not itself contain.

Control-plane permissions are non-delegable. They include every permission for role creation, role updates, role deactivation, role assignment or revocation, branch assignment, branch lifecycle, branch creation, branch-super-admin assignment, school-super-admin assignment, branch transfer, staff-account lifecycle, credential recovery, service-identity lifecycle, student-account unlinking or reassignment, verified-contact changes, and all `SC_BRANCH_*` administrative permissions. Only protected seed roles may hold them.

A staff member cannot add, remove, or change the permissions or delegation set of any active role assigned to them. Another eligible administrator must make those changes. Display-only role fields may be changed when permitted.

A staff member may assign an ordinary school-scoped role only when one active school-scoped role contains `SC_USER_ROLE_ASSIGN`, the target is an active staff member, and that same role's delegation set covers every permission in the target role.

A staff member may assign an ordinary branch-scoped role only when one active branch-scoped role for that exact branch contains `BR_USER_ROLE_ASSIGN`, the target is active staff assigned to that branch, and that same role's delegation set covers every permission in the target role.

A `school_super_admin` may manage ordinary branch roles only through the explicit `SC_BRANCH_*` permissions. Its immutable `SC_BRANCH_PERMISSION_DELEGATE` seed policy is the sole exception to the ordinary-role delegation rule. It permits only the listed branch operational permissions for a selected branch, never `BR_` control-plane permissions or protected roles, and never combines authority from another role. An assignment through `SC_BRANCH_USER_ROLE_ASSIGN` still requires the target to be active staff assigned to that exact branch.

Before deployment, a reviewed, version-controlled seed manifest must define the complete usable-permission set and delegation set for every protected role. The server must use that manifest and must not infer delegation from a permission prefix, a scope, or possession of a permission. A runtime role-management action cannot change a protected role's manifest.

A staff member cannot assign or revoke their own role memberships. A branch role cannot be assigned to a staff member without an active assignment to that branch. A `STUDENT` account can hold only the protected default student `SELF` role; it cannot receive a staff, school, branch, ordinary custom, or role-management role.

## Branch Assignment Management

A staff branch assignment is a separate administrative record with a server-managed lifecycle state of `ACTIVE` or `ENDED`. It is not a permission and does not grant data access by itself. Ending a staff branch assignment is irreversible.

Only a staff member with `SC_STAFF_BRANCH_ASSIGN` may create a branch assignment for another active staff account. The target branch must be active. Only a staff member with `SC_STAFF_BRANCH_REVOKE` may end a branch assignment.

`SC_STAFF_BRANCH_ASSIGN` and `SC_STAFF_BRANCH_REVOKE` are non-delegable school-scoped seed permissions. For the initial system, they are available only through the protected `school_super_admin` role and cannot be included in ordinary custom roles or any branch-scoped role.

A staff member cannot create, end, reactivate, or change their own branch assignments. A branch assignment cannot be moved from one branch to another; moving staff requires ending the old assignment and creating a new assignment for the destination branch.

Every branch role assignment belongs to one specific active staff branch assignment. Ending a staff branch assignment must, in the same transaction, end every branch role assignment attached to it, including `branch_super_admin`. Historical assignments may be retained for audit but are inactive.

Reassigning staff to a branch creates a new staff branch assignment. Previous branch roles must not reactivate automatically; each required role must be assigned again through the normal authorized role-assignment flow.

The server must reject branch-assignment changes through generic staff create or update requests. Every branch-assignment change must be audited and must invalidate or revalidate the affected user's active sessions immediately.

## Assignment Integrity and Concurrency

For each staff account and branch, there can be at most one `ACTIVE` staff branch assignment. For each user, role, scope, and branch where applicable, there can be at most one `ACTIVE` role assignment. The role-assignment rule applies to ordinary and protected roles, including `school_super_admin`, `branch_super_admin`, and `student_default`. It prevents duplicate copies of the same grant and does not prevent a user from holding different roles in the same scope or branch.

The persistence layer must enforce both active-assignment uniqueness rules with database constraints; an application-side existence check is not sufficient. For `SCHOOL` and `SELF` role assignments, the constraint must use a scope-specific constraint or an equivalent normalized no-branch key so that a nullable branch ID cannot permit duplicate active assignments.

Creating a branch assignment or role assignment must be an idempotent transactional operation. The server must lock stable target records or use an equivalent serializable mechanism, recheck the actor's authorization and the target's current eligibility, and rely on the database uniqueness constraint when inserting. If the exact logical assignment is already active, an authorized retry returns that existing assignment or succeeds as a no-op; it must not create another record or modify the existing grant. If a previous assignment is `ENDED`, a later authorized grant creates a new immutable assignment and never reactivates the historical record.

Ending a branch assignment or revoking a role assignment must also be idempotent and transactional. The server must authorize the action, derive the logical assignment key from stored data, lock the affected records, and end every active record matching that key. Ending a staff branch assignment must also end every attached branch role assignment as required above. Finding more than one active match indicates an integrity violation: the server must end all matches, record a security audit event, increment the affected principal's authorization version once, and invalidate or revalidate active sessions immediately. An already-ended or absent assignment may produce an authorized no-op but must never bypass the authorization check.

## Account Lifecycle and Bootstrap

An account has one immutable type: `STAFF` or `STUDENT`. Public registration, self-service profile updates, imports, and ordinary administrative updates must not create a staff account, change an account type or account status, or create or change a branch assignment, role membership, delegation right, protected-role membership, student-account link, or verified contact. Only the dedicated workflows in this document may change those access-relevant records.

`SC_STAFF_ACCOUNT_INVITE`, `SC_STAFF_ACCOUNT_ACTIVATE`, `SC_STAFF_ACCOUNT_DEACTIVATE`, `SC_STAFF_CREDENTIAL_RECOVER`, and `SC_STAFF_VERIFIED_CONTACT_CHANGE` are non-delegable school-scoped control-plane permissions available only through the protected `school_super_admin` role. A staff invitation is single-use, time-limited, bound to an approved staff identity and verified contact, and lets the invitee establish their own credentials and multi-factor authentication.

Deactivating a staff account must immediately block authentication and end every active branch assignment and role assignment in the same transaction. If the account holds `school_super_admin`, the transaction must first satisfy the final-school-super-admin invariant defined under System Roles. Ended records may be retained for audit, but cannot be reactivated. Activating the account must not restore any entitlement; every required branch assignment and role assignment must be created again through its normal authorized workflow.

Credential recovery and multi-factor recovery must verify the account holder through an out-of-band approved process, invalidate existing sessions, and never change the account type, account status, verified contact, branch assignments, role assignments, or delegation rights.

Changing a staff member's verified contact requires `SC_STAFF_VERIFIED_CONTACT_CHANGE`, verified identity, out-of-band confirmation, recent multi-factor reauthentication, audit logging, and immediate session invalidation. It cannot be performed as part of invitation acceptance, credential recovery, or multi-factor recovery.

The first `school_super_admin` account and membership are created only by a one-time deployment or provisioning migration after verified identity and multi-factor enrollment. This bootstrap flow is not an application API, cannot be triggered by registration, invitation, import, or branch creation, and cannot be reopened after completion. Later school-super-admin changes use `SC_SCHOOL_SUPER_ADMIN_ASSIGN`.

Recent reauthentication with multi-factor authentication is required for every control-plane action, including staff lifecycle, branch assignment and lifecycle, role management, system-role assignment, service-identity lifecycle, transfers, payment corrections, and student-account unlinking or reassignment.

## Branch Lifecycle

A branch has a server-managed lifecycle state of `ACTIVE` or `INACTIVE`. A newly created branch becomes `ACTIVE` only through the authorized branch-creation workflow; a client cannot set or change its lifecycle state in a generic create or update request.

`SC_BRANCH_DEACTIVATE`, `SC_BRANCH_REACTIVATE`, and `SC_BRANCH_ARCHIVE_VIEW` are non-delegable school-scoped seed permissions available only through the protected `school_super_admin` role. Deactivation and reactivation are named lifecycle workflows, not generic branch updates. `SC_BRANCH_ARCHIVE_VIEW` permits read-only access to inactive branch data only when the actor also has the matching school-scoped resource read permission.

Deactivating a branch must, in one transaction, mark the branch inactive, end every active staff branch assignment for that branch, end the attached branch role assignments through the normal branch-assignment cascade, and invalidate or revalidate affected sessions immediately. The protected branch role remains as seed data, but no old staff assignment or role assignment can reactivate when the branch is reactivated.

An inactive branch denies all normal branch-scoped operations and `SELF` access to records owned by that branch. School-scoped users may read inactive branch data only through `SC_BRANCH_ARCHIVE_VIEW` plus the matching school-scoped read permission. Normal writes, exports, imports, bulk operations, and operational actions are denied until the branch is reactivated. The only exceptions are the named lifecycle and archive-read workflows, plus a named school-scoped remediation workflow that explicitly permits an inactive source branch; school scope by itself is never such an exception.

Reactivating a branch changes only its lifecycle state. Staff access must be restored with new authorized branch assignments and role assignments; no previous entitlement is restored automatically.

## Service Identity Lifecycle

A service identity is a non-user authorization principal with a unique server-managed ID, an active or inactive state, an immutable service policy, a fixed allowed branch context, and a service-policy revision. It cannot hold a user role, a protected system role, or a control-plane permission.

`SC_SERVICE_IDENTITY_CREATE`, `SC_SERVICE_IDENTITY_DEACTIVATE`, and `SC_SERVICE_CREDENTIAL_ROTATE` are non-delegable school-scoped seed permissions available only through the protected `school_super_admin` role. A changed service policy or branch context requires deactivating the existing identity and creating a replacement; it is never an update to an existing identity.

Deactivating a service identity must revoke its credentials, increment its authorization version, stop new work, and cause in-flight work to fail at authorization revalidation or transaction commit. Credential rotation must invalidate the prior credential and increment the same authorization version. Service credentials are distinct, rotated secrets and are never user credentials.

## Branch-Owned Data and Transfers

Every branch-owned record has one required, server-controlled owner branch ID. This includes students, vehicles, lessons, payments, documents, and any later branch-owned resource. Normal create and update operations must not change that owner branch ID.

For a normal create, the server derives or validates the owner branch against either the actor's exact branch-scoped authorization or a matching school-scoped permission that permits the action across all branches. For a normal update, the server loads the existing record and authorizes it using its stored owner branch ID. A client-supplied branch ID is never trusted.

Every branch-owned relationship in a normal operation must reference records from the same owner branch. For example, a lesson, payment, or document cannot reference a student, vehicle, staff assignment, or other branch-owned record from another branch. When a branch-owned record references a staff member, that staff member must have an active assignment to the record's owner branch. Cross-branch relationships are rejected unless a named school-scoped workflow explicitly permits that exact relationship.

Branch changes are named school-scoped workflows, not generic updates. `SC_STUDENT_BRANCH_TRANSFER`, `SC_VEHICLE_BRANCH_TRANSFER`, `SC_LESSON_BRANCH_TRANSFER`, and `SC_DOCUMENT_BRANCH_TRANSFER` are separate non-delegable seed permissions. Branch staff cannot perform transfers.

A payment's owner branch is immutable. A payment correction across branches requires a separate, non-delegable `SC_PAYMENT_BRANCH_CORRECT` accounting workflow that reverses or corrects the original record and creates the required replacement record; it must never rewrite the original payment's branch.

Every transfer or payment correction must validate the stored source branch, the active destination branch, all related records allowed to move, and the actor's specific school-scoped permission. A transfer or correction may use an inactive source branch only as the named school-scoped remediation workflow; its destination must remain active. It must complete atomically, record before-and-after values and a reason in the audit log, and invalidate or revalidate affected sessions where needed.

## Student Profile Lifecycle

A student profile has one server-managed profile status. Profile status is separate from account type, portal invitation state, student-account link state, branch ownership, and contact verification state.

The normal student profile lifecycle is:

- `REQUESTED`: an admission request or inquiry exists, but the student is not yet accepted as an operational student.
- `REGISTERED`: the school has created or accepted the student profile in one branch, but required verification is not complete.
- `VERIFIED`: required student details, documents, and contact checks are complete, but the student is not yet active for normal operations.
- `ACTIVE`: the student is active in the assigned branch and may be used in normal operational workflows allowed by policy.
- `GRADUATED`: the student has completed the program. The profile becomes historical/read-only except for explicit school-scoped correction or archive workflows.

Exception statuses are:

- `INACTIVE`: the profile is temporarily not operational. Normal operations and student `SELF` access are denied unless an explicit policy permits a limited read.
- `SUSPENDED`: the profile is blocked by an administrative decision. Normal operations and student `SELF` access are denied unless an explicit policy permits a limited read.
- `TRANSFERRED_OUT`: the student has left this school. The profile is historical/read-only except for explicit school-scoped correction or archive workflows.

A transfer between branches inside this school is not represented by `TRANSFERRED_OUT`. It must use the `SC_STUDENT_BRANCH_TRANSFER` workflow and keep the student profile status appropriate to the student's real operational state.

Student profile status changes are named workflows with explicit permission-and-scope policies. The server must validate the stored current status, the requested target status, the actor's permission, the stored owner branch, and the branch lifecycle state. Generic student create, update, import, or bulk requests must not directly set or skip profile status transitions.

Changing a student profile to `INACTIVE`, `SUSPENDED`, `GRADUATED`, or `TRANSFERRED_OUT` must record a reason, write an audit event, and invalidate or revalidate the linked student's active sessions immediately.

Student contact verification has its own state: `UNVERIFIED` or `VERIFIED`. Generic student create, update, import, and bulk requests may store or replace contact values only as `UNVERIFIED`. A contact may become `VERIFIED` only through a dedicated verification workflow that proves control of the contact, or through the protected `SC_STUDENT_VERIFIED_CONTACT_CHANGE` remediation workflow. Setting a verified contact must be audited, and changing a contact must invalidate outstanding portal invitations and revalidate or invalidate linked account sessions where needed.

## Files and Attachments

Every file and attachment must be bound to one authorized parent record before it becomes accessible. It inherits that record's owner branch and, where applicable, the student's `SELF` scope. No accessible file may be unowned, public, or scoped only by an object-storage key.

The server must authorize file upload, download, preview, deletion, and transfer through the parent record on every request. Upload intents are single-use, short-lived, bound to the authorized parent and operation, and limited to the approved file type and size. Uncommitted uploads remain quarantined and inaccessible.

Download and preview requests must pass through an authorization-aware application or gateway endpoint that revalidates parent-record access and the current authorization revision when the URL is redeemed. Any downstream URL is short-lived, bound to one file and operation, and must not provide directory or object-key access. A direct object-storage URL that remains usable after access is revoked is not permitted. Moving or deleting a parent record updates or invalidates inherited file access atomically.

## System Roles

`school_super_admin`, `branch_super_admin`, and `student_default` are protected system-role types, not reusable client-supplied role codes. Every protected role instance has a server-managed system-role type, a unique opaque role ID and code, and, for a branch system role, one immutable branch ID. Authorization uses the immutable type and branch ID where applicable, never a display name or a code pattern.

The `school_super_admin` role is the one protected school-scoped system-role instance. It receives every `SC_` permission and every `CO_` permission at school scope declared in the reviewed seed manifest. Adding a new permission to that set requires a versioned seed migration and role-policy revision; the server must not grant it by an implicit prefix rule. Its permissions, scope, and immutable seed delegation policy are fixed at runtime; holding a permission does not by itself make that permission delegable.

Only a user with `SC_SCHOOL_SUPER_ADMIN_ASSIGN` may assign or revoke `school_super_admin`. This permission is non-delegable and is available only through the protected `school_super_admin` role. The target must be an active staff account with verified identity and multi-factor authentication enrolled. The action must be audited, must not be self-assignment, and must not remove or deactivate the final active school super admin.

The final-school-super-admin invariant counts distinct eligible staff accounts, never role-assignment rows. An eligible school super admin is an active staff account with verified identity, multi-factor authentication enrolled, and one active assignment to the protected `school_super_admin` role. Every role revocation, staff-account deactivation, identity-verification change, or multi-factor change that could remove this eligibility must serialize on a server-controlled invariant lock, evaluate the post-change set in the same transaction, and fail without changes if no eligible school super admin would remain. Any duplicate or otherwise inconsistent membership rows count as one user and must be treated as an audited integrity violation, not as additional administrators satisfying the invariant.

For each branch, the server creates exactly one protected `branch_super_admin` system-role instance with a unique role ID and code bound to that branch. Its permissions, scope, and immutable seed delegation policy are fixed. Its predefined permissions may include normal `BR_` role-management permissions, but those permissions remain non-delegable; its delegation policy can list only the branch operational permissions in the protected-role seed manifest.

`SC_BRANCH_SUPER_ADMIN_ASSIGN` is a non-delegable school-scoped seed permission available only through the protected `school_super_admin` role. It cannot be included in ordinary custom roles or branch-scoped roles.

A staff member who creates a branch needs `SC_BRANCH_CREATE`. Assigning the first or any later `branch_super_admin` requires `SC_BRANCH_SUPER_ADMIN_ASSIGN`, and the target must be active staff assigned to that exact branch. The branch creator does not receive `branch_super_admin` automatically. Branch-scoped users cannot assign or revoke `branch_super_admin`.

Protected system roles cannot be renamed, deleted, cloned, or have their permissions, delegation sets, scope, system-role type, or branch binding changed. Their internal IDs and role codes are reserved, unique, and immutable; ordinary custom roles cannot use those identifiers or a protected system-role type, or contain non-delegable control-plane permissions.

The protected `student_default` role is the one `SELF`-scoped system-role instance with predefined `ST_` permissions. It is the only role a `STUDENT` account may hold. It is assigned only by the server when a valid student-account link is created, and ended only by the server in an authorized unlink or reassignment workflow; no administrator can assign, modify, clone, or delegate it.

## Student Account Binding

A student account may link to only one student record, and a student record may link to only one active student account. A student record may exist without an account until an authorized account-linking action occurs. A normal account-linking action requires a link-eligible student record. Link-eligible means the student record belongs to an active branch, has no active account link, has a verified contact, and has profile status `REGISTERED`, `VERIFIED`, or `ACTIVE`.

`BR_STUDENT_ACCOUNT_INVITE` may initiate an initial portal invitation only for a link-eligible student in the actor's exact assigned branch. It sends a single-use, time-limited token to the student's verified contact. It does not select, create, or directly link an account.

There can be at most one active portal invitation for a student record. Issuing a replacement invitation invalidates the previous unredeemed invitation.

Portal invitation tokens must be stored only as cryptographic hashes. The raw token is shown or delivered once, is never logged, and cannot be recovered from the database. Redeeming a token must validate the hash, expiry, invitation state, verified contact, student profile status, branch lifecycle state, and account-link eligibility in one transaction. The server must atomically mark the invitation consumed before creating the account link and default student role. Changing the verified contact, ending or replacing the student-account link, issuing a replacement invitation, or making the student ineligible for portal access must invalidate outstanding invitations for that student.

An invitation can be redeemed only by creating a new `STUDENT` account or by an unlinked `STUDENT` account that proves control of the invited verified contact. The token is bound to one student record, expires after use, and the server atomically creates the link and default student role. A `STAFF` account and an already linked account cannot redeem it. When the invitation was issued by the named `SC_STUDENT_ACCOUNT_REASSIGN` remediation workflow for an inactive source branch, this narrowly scoped redemption is permitted to complete the link; it grants no `SELF` or other data access while the branch remains inactive.

Establishing, replacing, or administratively marking a student's verified contact requires the non-delegable `SC_STUDENT_VERIFIED_CONTACT_CHANGE` permission, out-of-band confirmation, and audit logging unless the contact is verified through the normal proof-of-control verification workflow. It cannot be performed in the same transaction as sending or redeeming a portal invitation. It is a named school-scoped remediation workflow and may operate on a student whose source branch is inactive.

Removing an existing student-account link requires the non-delegable `SC_STUDENT_ACCOUNT_UNLINK` permission. It is available only through the protected `school_super_admin` role and must be audited. It is a named school-scoped remediation workflow and may operate on a student whose source branch is inactive. In one transaction, the server ends the existing link, ends the old default student role, invalidates the old account's sessions, invalidates outstanding invitations for that student, and leaves the student record unlinked. It cannot select or link a replacement account.

Replacing or moving an existing student-account link requires the non-delegable `SC_STUDENT_ACCOUNT_REASSIGN` permission. It is available only through the protected `school_super_admin` role, must be audited, and is a named school-scoped remediation workflow that may operate on a student whose source branch is inactive. It must atomically perform the unlink safeguards before issuing one new invitation to the verified contact. It cannot directly select another account; the replacement link is created only when that invitation is redeemed.

The server must reject student-account link fields in generic student or user update requests. Students can never change the linked student record, account type, verified contact, branch ownership, or roles.

## Authorization Consistency

Every access-relevant state change must invalidate the server-side authorization decision for each affected authorization principal: a user account or a service identity. The implementation must use a principal authorization version, a role-policy revision where roles apply, or both. A change to role membership, role permissions, or delegation policy affects every account with an active assignment to that role; each subsequent authorization check and cached grant must validate the current principal and relevant role-policy revisions. A service-identity status, credential, or policy replacement change must invalidate its current service authorization decision.

For every sensitive write, transfer, role operation, account operation, service operation, and bulk operation, the server must evaluate authorization and perform the state change in one transaction. It must commit only when the current principal authorization version, every relevant role-policy revision or service-policy revision, and all target-record versions are unchanged. A request that was authorized before a revocation but reaches commit after that revocation must fail.

For an operation on branch-owned data, the stored owner branch's lifecycle state and version are authorization dependencies and must be checked at authorization and again before commit. An operation must fail if the branch becomes inactive before commit, unless it is the named archive-read or lifecycle workflow, or a named school-scoped remediation workflow that explicitly permits an inactive source branch.

A multi-record operation must authorize every target record under the same transaction. If any target is unauthorized or changes concurrently, the operation must fail without applying an unverified partial change.

## Data Access and Authorization Enforcement

Branch-scoped staff access requires both an active assignment to the target branch and a matching role permission for that branch. A staff member assigned to multiple branches can access only the actions permitted in each individual branch.

School-scoped staff access requires a matching school-scoped role permission. It allows access across branches only for the resources and actions covered by that permission.

School scope does not bypass branch lifecycle state. The inactive-branch restrictions in Branch Lifecycle apply to every staff and student request, and to service operations, unless the named archive-read or lifecycle workflow, or a named school-scoped remediation workflow, explicitly permits the action.

Students can access only their own details, and only when the linked student profile status and owner-branch lifecycle allow the requested `SELF` operation. The server resolves the student record from the authenticated account and does not trust a student identifier supplied by the client.

Every protected API, export, import, file operation, bulk operation, background job, webhook, and internal endpoint must have an explicit permission-and-scope policy. If no matching policy and target-scope rule exists, the server must deny the request.

Reports, dashboards, analytics, metrics, counts, summaries, and search facets are protected read operations. They must have explicit permission-and-scope policies, and authorization filters must be applied before aggregation. A branch-scoped user can aggregate only records in branches where they have the required branch-scoped permission and active branch assignment. A school-wide aggregate requires the matching school-scoped permission. The system must not expose totals, counts, empty/non-empty indicators, or grouped values for unauthorized branches or records.

Scope checks apply to read, create, update, delete, search, export, bulk, file, and background operations. Authorization is enforced on the server for every request and target record. User interface state, hidden fields, request role IDs, scope values, branch IDs, and client-side permission checks are not trusted.

Background jobs and webhooks must run as named, limited, active service identities with distinct, rotating credentials and an immutable explicit service policy. A service identity receives only the exact operations and branch context required by its job. Its active state, authorization version, and service-policy revision must be checked when work starts and again before a sensitive transaction commits.

No client request, webhook payload, or job parameter may select a service identity, user identity, role, or branch context without server-side validation. Webhooks require signature verification and replay protection before their limited service policy is evaluated.

Changing or revoking a user's branch assignment, role assignment, student-account link, account status, or branch lifecycle state must stop access immediately through server-side revalidation or session invalidation. Deactivating a service identity must stop its access immediately through the same revalidation and transaction-version checks.

Administrative changes to users, student-account links, branch assignments, branch lifecycle, roles, permissions, transfers, payment corrections, service identities, and branches must be written to an append-only, tamper-evident audit log. Application roles, including `school_super_admin`, cannot alter or delete audit events. Authorization tests must cover denial when no policy exists, cross-branch access attempts, inactive-branch access, scope changes, role delegation, protected-role identity, student-role boundaries, imports that attempt to change access state, account unlinking and reassignment, transfers, concurrent revocation, duplicate and concurrent assignment creation, idempotent assignment retries, duplicate-safe revocation, concurrent final-school-super-admin revocation or deactivation, file access, account lifecycle, and service-identity revocation.
