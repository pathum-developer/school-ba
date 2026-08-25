# Functional requirements

[← Business requirements](README.md)

Numbered so they can be referenced from tickets and from the API design when `school-ba`
grows endpoints.

**Status vocabulary**

| Status | Meaning |
| --- | --- |
| **Built** | Implemented and working against local content |
| **Content-only** | The interface exists, but nothing backs it — no system receives or serves the data |
| **Placeholder** | Present in the UI pointing at `#`, awaiting a real destination |
| **Not built** | Promised in copy, no interface |

## Discovery and content

| ID | Requirement | Status |
| --- | --- | --- |
| FR-101 | Present courses grouped by licence class (Car & Van, Motorcycle, Three-wheeler, Lorry & Bus), each showing the DMT class code, lesson count, indicative weeks, transmission, inclusions and full course price | Built |
| FR-102 | Mark the most-booked course in each class, and the most-chosen package | Built |
| FR-103 | Present three packages with full pricing, per-lesson breakdown and feature list | Built |
| FR-104 | Let a visitor switch package pricing between pay-in-full and three instalments, showing the monthly figure | Built |
| FR-105 | State explicitly that government fees (medical, DMT registration, test fees) are excluded from package prices | Built |
| FR-106 | Present the licensing journey as six sequential steps, each with timing, description, and what the school handles on the student's behalf | Built |
| FR-107 | List all locations with address, opening hours, per-location phone number, the licence classes taught there, and location-specific perks | Built |
| FR-108 | Distinguish a practice yard from a full branch | Built |
| FR-109 | Present student reviews with per-review rating, licence class and branch, plus a computed average across all reviews | Built |
| FR-110 | Provide a searchable FAQ, matching on question, answer and keyword text, with a match count and a fallback to the hotline when nothing matches | Built |
| FR-111 | List learning-hub resources grouped by kind (video tutorials, exam papers, road rules, articles) with a duration or length indicator | Built |
| FR-112 | Make each learning-hub resource openable | **Content-only** — cards render an "Open" affordance; no resource has a destination |

## Lead capture

| ID | Requirement | Status |
| --- | --- | --- |
| FR-201 | Accept a trial-lesson booking: course, branch, preferred start date, name, mobile number | **Content-only** — the form validates completeness and shows a confirmation, but **submits to nothing**. See [state and data → the API seam](../frontend/state-and-data.md#the-api-seam). |
| FR-202 | Offer only branches that teach the selected course's licence class, and clear an already-selected branch that becomes invalid | Built — enforced in [`BookingCard`](../../../src/components/home/BookingCard.tsx) |
| FR-203 | Constrain the preferred start date to between today and one year ahead | Built |
| FR-204 | Show a running summary of the selected course — licence class, lessons, weeks, price — as the visitor fills the form | Built |
| FR-205 | Require no payment, no card details and no account to book | Built (by construction) |
| FR-206 | Confirm the booking on screen, restating course, branch, date and the number that will be called | Built |
| FR-207 | State the callback commitment (within two hours) at the point of booking | Built |
| FR-208 | Deliver the booking to staff — CRM, inbox, or notification | **Not built** |
| FR-209 | Handle and communicate a failed submission | **Not built** — there is no failure path because there is no submission |

> FR-201 and FR-208 together are the site's critical gap: a visitor is told "we call within
> two hours" and nobody is told to call.

## Contact and conversion routes

| ID | Requirement | Status |
| --- | --- | --- |
| FR-301 | Offer the hotline as a tap-to-call link from the header, footer and phone action bar | Built |
| FR-302 | Offer WhatsApp contact from the footer and phone action bar | Built |
| FR-303 | Offer per-branch tap-to-call | Built |
| FR-304 | Link each location to directions in Google Maps | Built |
| FR-305 | Offer email contact | Built |
| FR-306 | Keep a booking call-to-action reachable from anywhere on the page, including a persistent action bar on phones | Built |
| FR-307 | Publish privacy policy, terms and conditions, and refunds/cancellations | **Placeholder** — all three link to `#` |
| FR-308 | Link the school's social profiles | **Placeholder** — Facebook, YouTube and Instagram link to `#` |

## Language and presentation

| ID | Requirement | Status |
| --- | --- | --- |
| FR-401 | Deliver the entire site in English, Sinhala and Tamil, with no untranslated content | Built |
| FR-402 | Let a visitor switch language at any point, from both the page and the mobile menu | Built |
| FR-403 | Remember the chosen language across visits | Built — persisted to local storage |
| FR-404 | Default to the browser's language when no choice has been made | Built |
| FR-405 | Render Sinhala and Tamil legibly regardless of installed system fonts | Built — see [internationalization](../frontend/internationalization.md#scripts-and-fonts) |
| FR-406 | Search the FAQ in the reader's own language | Built — matching runs over translated text |
| FR-407 | Offer a light and a dark presentation | Built, **not remembered across visits** |

## Referenced but not built

Interfaces the copy promises that do not exist here. Listed so they are not mistaken for
oversights: see [product scope → out of scope](product-scope.md#out-of-scope-today).

| ID | Capability |
| --- | --- |
| FR-501 | Student portal — lesson slots, rescheduling up to 12 hours before |
| FR-502 | Learning hub delivery — video playback, instantly-marked mock papers, timed flashcards |
| FR-503 | Payment and instalment collection |
| FR-504 | Licence dispatch tracking and student notification |
