# Product scope

[← Business requirements](README.md)

## Goal

Convert a Colombo resident who is thinking about learning to drive into a **booked free
trial lesson**, in the language they read most comfortably, without requiring them to
create an account or pay anything.

Everything on the page serves that goal in one of three ways:

1. **Credibility** — 75 years of operation, 42,000+ drivers licensed, a stated 94%
   first-attempt pass rate, DMT approval, and five student reviews.
2. **Self-selection** — helping a visitor identify which licence class, course, package
   and branch fits them, so the conversation that follows starts from a decision rather
   than from scratch.
3. **Objection removal** — the six-step journey, the ten-question FAQ, transparent
   pricing including what is *not* included, and branch opening hours.

## Audiences

| Audience | What they need | Where the site serves them |
| --- | --- | --- |
| **First-time learner** (the primary audience) | Reassurance that the process is manageable, and what it costs end to end | Journey section, FAQ, Complete package, Kaduwela yard positioned for first-ever lessons |
| **Licence upgrader / professional driver** | A specific class (heavy, three-wheeler), fast, around work | Course tabs by licence class, Fast Track package, Battaramulla's heavy-vehicle instructors |
| **Returning or experienced driver** | Minimum viable path to the licence | Essential package — "you have driven before and just need the licence" |
| **A family member acting on someone's behalf** | Prices, locations, phone numbers, at a glance | Branch cards with hours and per-branch phone numbers, hotline and WhatsApp everywhere |

The trilingual requirement is not a nice-to-have for these audiences: the site states that
instruction, written-exam coaching and mock papers are all available in Sinhala, Tamil and
English, so a visitor who cannot read the site is being told, in a language they do not
read, that they would be taught in one they do.

## In scope

- Public, unauthenticated marketing content for courses, packages, the licensing journey,
  branches, learning resources, reviews and FAQs.
- A trial-lesson lead-capture form.
- Direct contact routes: hotline, per-branch phone, WhatsApp, email, map directions.
- Full delivery in English, Sinhala and Tamil.
- Light and dark presentation.

## Out of scope (today)

These are referenced in the site's own copy but are **not part of this application**. Each
is a commitment the copy makes that some system will eventually have to keep:

| Referenced capability | Where the copy promises it |
| --- | --- |
| Student portal with online lesson slot selection | `journeyStep.lessons.weHandle`, `faqItem.f7.answer` |
| Rescheduling up to 12 hours before a lesson | `hero.highlights`, `faqItem.f7.answer` |
| Learning hub with videos, marked mock papers and flashcards | Learning hub section, `journeyStep.written.weHandle` |
| Payment and instalment collection | `packages.*`, `faqItem.f9.answer` |
| Licence dispatch tracking and notification | `journeyStep.licence.weHandle` |
| WhatsApp coordinator for Fast Track students | `package.fasttrack.features` |

Treat the copy as a backlog: anything above that ships as a claim before the system exists
is a promise the school's staff have to keep manually.

## Success measures

None are instrumented — there is no analytics, no tag manager and no event tracking in the
codebase. If the business wants to measure the goal stated at the top of this page, that
is a deliberate addition, and it interacts with the privacy commitments in
[non-functional requirements](non-functional.md#privacy-and-data-protection).

Candidate measures, for discussion rather than as agreed targets: trial bookings submitted,
booking form abandonment by field, language split of visitors, hotline and WhatsApp
click-through, FAQ searches that return no match (a direct signal of missing content).
