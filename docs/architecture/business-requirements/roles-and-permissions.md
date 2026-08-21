# Roles and permissions

[← Business requirements](README.md)

> **Status: proposal.** Nothing here is built — there is no authentication in the codebase
> today. This is a design for validation, and several points below are assumptions marked
> as such. The layout that renders it is in
> [frontend → app shell](../frontend/app-shell.md).

## The roles

Three were named: **student**, **school staff**, **branch staff**. Working through what
each actually does surfaces a fourth.

| Role | Frequency of use | Primary device | Scope |
| --- | --- | --- | --- |
| **Student** | Weekly or less | Phone | Only their own record |
| **Instructor** *(assumed)* | Daily | Phone | Their own assigned lessons |
| **Branch staff** | All day | Desk + phone | One branch |
| **School staff** | Daily | Desk | All branches |

**The instructor role is an inference, not something you named.** The published content
commits to instructor-level behaviour repeatedly — the same instructor for every lesson
([BR-14](domain-and-rules.md#service-delivery)), requesting a specific or female
instructor ([BR-15](domain-and-rules.md#service-delivery)), an instructor who drives the
student to the test ground and runs a rehearsal ([BR-13](domain-and-rules.md#service-delivery)).
Someone has to see that schedule. If instructors are meant to work from a paper sheet or a
branch coordinator's screen, say so — it is a legitimate answer, and it removes a role.

## What each role needs to do

Written as jobs rather than screens, because the screens follow from these.

**Student** — *"Am I on track, and what do I owe?"*
Next lesson and where. Lessons used against lessons bought. Reschedule, subject to the
12-hour rule ([BR-12](domain-and-rules.md#service-delivery)). Instalment status and what
falls due next ([BR-08](domain-and-rules.md#commercial), [BR-09](domain-and-rules.md#commercial)).
Position in the six-step journey. The learning hub — mock papers and videos, which the
copy promises free to every enrolled student
([FR-502](functional-requirements.md#referenced-but-not-built)). Their trial-test date.

**Instructor** — *"Who am I teaching today?"*
Today's and this week's lessons with student name, vehicle and pickup point. Mark
attendance. Record progress against the syllabus. Flag a student as trial-ready.

**Branch staff** — *"Keep today running."*
**The callback queue** — trial bookings submitted from the public site, waiting on the
two-hour promise ([BR-05](domain-and-rules.md#booking)). This is the single most important
screen in the whole application, because it is the one that closes
[FR-208](functional-requirements.md#lead-capture), the gap where a submitted booking
currently goes nowhere. Then: today's timetable, instructor and vehicle assignment,
enrolment and document collection ([BR-22](domain-and-rules.md#regulatory)), payment
collection, rescheduling, trial-test slot booking.

**School staff** — *"Is the business working?"*
All branches at once. Course and package pricing — currently hardcoded in
`src/data/school.ts`, and the thing that decides whether prices must be API-served
([open question 7](open-questions.md#significant--shape-what-gets-built)). Staff and
instructor accounts. Branch hours and which classes each teaches — note that
[BR-01](domain-and-rules.md#booking) depends on that data being editable. Site content in
all three languages. Pass rates and the figures published as marketing claims
([published claims](domain-and-rules.md#published-claims)).

## Model permissions, not roles

**Check what a user may do, never who they are.**

```
if (user.role === 'branch_staff')   ✗
if (can('lesson.reschedule'))       ✓
```

Roles are bundles of permissions, and bundles change. The moment the business introduces a
branch *manager* who can do everything branch staff can plus approve refunds, every
`role === 'branch_staff'` check in the codebase is wrong — and you find them one bug at a
time. Permission checks survive that; role checks do not. A fourth role appeared above
just from reading the requirements. Assume a fifth is coming.

Roles stay useful as the thing an administrator assigns. They just should not be what the
code branches on.

## Permission alone is not enough — scope matters

This is the trap worth designing around now rather than retrofitting.

Branch staff at Wellawatte and branch staff at Battaramulla hold **the same permission**
and must see **different data**. `student.view` does not mean "view any student", it means
"view students at my branch". Every permission therefore carries a scope:

| Scope | Meaning | Roles |
| --- | --- | --- |
| `self` | Only their own records | Student, instructor |
| `branch` | Records belonging to one branch | Branch staff, instructor |
| `all` | Every branch | School staff |

An authorization answer needs all three parts: **who, what, and over which rows.** A
system that checks only the first two lets a Wellawatte coordinator read Battaramulla's
student list — a data breach, not a bug.

Two wrinkles specific to this business, both needing answers:

- Rajagiriya is the head office and the only location teaching all four licence classes
  ([locations](domain-and-rules.md#locations)). Does its staff have `branch` scope or
  `all`?
- A student may train at one branch and sit the trial at another. Which branch "owns" them
  for scoping?

## Draft permission catalogue

A starting point to argue with, not a finished list. Grouped by the resource acted on.

| Group | Permissions |
| --- | --- |
| Booking | `booking.view`, `booking.claim`, `booking.convert`, `booking.dismiss` |
| Student | `student.view`, `student.enrol`, `student.edit`, `student.document.verify` |
| Lesson | `lesson.view`, `lesson.schedule`, `lesson.reschedule`, `lesson.attend`, `lesson.progress.record` |
| Payment | `payment.view`, `payment.collect`, `payment.refund` |
| Trial test | `trial.book`, `trial.result.record` |
| Instructor | `instructor.view`, `instructor.assign` |
| Catalogue | `course.view`, `course.edit`, `package.edit`, `price.edit` |
| Branch | `branch.view`, `branch.edit`, `branch.hours.edit` |
| Content | `content.faq.edit`, `content.resource.edit`, `content.translate` |
| Reporting | `report.branch.view`, `report.school.view` |
| Administration | `user.view`, `user.invite`, `user.role.assign` |

Note `content.translate` as its own permission. Site copy exists in three languages under
strict parity ([language parity](non-functional.md#language-parity)); whoever edits an FAQ
must not be able to publish it in English only.

## The server owns permissions

**Non-negotiable, and the one item here that is a security requirement rather than a
design preference.**

The client is *told* what the user may do; it never decides. On session establishment the
API returns the user's identity, their granted permissions and their scope. The client
uses that to render — and for nothing else.

Hiding a menu item is a courtesy, not a control. Every request must be authorized again on
the server, because a browser is a place where anyone can edit anything. The three
enforcement layers this implies on the client are described in
[app shell → enforcing access](../frontend/app-shell.md#enforcing-access).

## Open questions

1. **Is there an instructor role?** Everything above assumes yes.
2. **Do students get a portal in the first release**, or is this staff-first? The public
   site already promises students a portal and a learning hub, so shipping staff-only
   leaves those promises outstanding — but it is a smaller, faster first release.
3. **Head office scope** — does Rajagiriya staff see all branches?
4. **Branch ownership of a student** who trains and tests at different locations.
5. **Can a student hold more than one enrolment** — a scooter licence now, a car licence
   next year? This decides whether the student dashboard shows one course or a list.
6. **How does a student get an account?** The public booking form deliberately requires no
   account ([BR-04](domain-and-rules.md#booking)), so an account is created somewhere
   between callback and enrolment. Who creates it, and how does the student receive it?
7. **Self-service or staff-mediated rescheduling?** The copy promises students can
   reschedule themselves from a portal ([BR-12](domain-and-rules.md#service-delivery)),
   which is a materially larger build than staff doing it on request.
