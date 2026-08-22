# Overview

[<- Backend Architecture](README.md)

## Purpose

`school-ba` is the Spring Boot API for Elven Driving School. Its first responsibility is to make the public trial-booking promise real: receive a booking from `school-ui`, validate it against the published business rules, and expose it to staff for callback handling.

The frontend currently serves content locally. The backend should grow behind the existing frontend data shapes rather than forcing the UI to discard its model.

## Current Product Shape

The public site is a marketing and lead-capture SPA. Its conversion goal is a free trial lesson booking with no account, no payment, and no obligation.

The critical gap is:

- `FR-201`: accept a trial-lesson booking.
- `FR-208`: deliver the booking to staff.

The first backend slice should close that gap before building larger portal features.

## Suggested Build Order

1. Public trial-booking submission.
2. Authentication foundation: immutable account types, credentials, MFA, sessions, and default-deny security wiring.
3. Versioned permission/protected-role seed manifest and one-time `school_super_admin` bootstrap.
4. Minimum staff invitation, branch assignment, and role-assignment workflows needed to authorize branch staff.
5. Branch-scoped callback queue and booking claim, dismiss, and conversion flow.
6. Enrolment, student lifecycle, and verified-contact workflows.
7. Scheduling, attendance, instructor assignment, payments, and instalments.
8. Student portal invitation, account binding, and learning-hub delivery.
9. Remaining school administration and reporting workflows.

This order follows both the data lifecycle and the authorization prerequisites. Public lead
capture can arrive first, but no staff queue may be exposed until the account, assignment,
permission, scope, and session controls required by the administration policy exist.

## Backend Project Rules

Follow the package conventions in `C:\elven-code\school\school-ba\AGENTS.md`:

```text
com.elvencode.schoolba
  booking/
  student/
  user/
  auth/
  common/
  config/
```

Use singular, lowercase domain package names. Keep controllers, services, repositories, entities, DTOs, mappers, and enums separated inside each domain package.
