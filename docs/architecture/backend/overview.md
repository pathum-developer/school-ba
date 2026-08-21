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
2. Branch-staff callback queue.
3. Booking claim, dismiss, and conversion flow.
4. Enrolment and student records.
5. Scheduling, attendance, and instructor assignment.
6. Payments and instalments.
7. Student portal and learning hub delivery.
8. School-staff administration and reporting.

This order follows the data lifecycle: a lead arrives before a student exists, and a student exists before lessons, payments, or portal state are meaningful.

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
