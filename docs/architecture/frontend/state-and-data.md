# State and data

[← Frontend architecture](README.md)

## State strategy

Two kinds of state, two answers.

**Server state** — anything whose authority is `school-ba` — belongs to TanStack Query. It
is cached, shared, invalidated and cleared as one thing. See [API layer](api-layer.md).

**Client state** has no store and needs none. Nothing client-side is shared between
sections, and it lives at the lowest level that can hold it:

| State | Where | Mechanism |
| --- | --- | --- |
| The catalogue, and every future server read | `api/queries` | `useQuery`, keyed and cached |
| Booking form fields | `BookingCard` | `useState` per field |
| Derived form values (options, filtered branches, selected records) | `BookingCard` | `useMemo` |
| Mobile menu open, dark mode | `SiteHeader` | `useState` + effect |
| Active nav section | `SiteHeader` | `IntersectionObserver` in an effect |
| Viewport width tests | `useMediaQuery` | `useSyncExternalStore` over `matchMedia` |
| Active language | i18next | `useTranslation()`, persisted to `localStorage` |
| Theme tokens | CSS | `.dark` class on `documentElement` |

Two of these are worth noting as patterns:

**`useMediaQuery` uses `useSyncExternalStore`, not `useState` + a listener.** `matchMedia`
is an external store, and the built-in hook gets tearing and subscription cleanup right for
free. Its third argument — the server snapshot — returns `false`, matching the mobile-first
default.

**The active nav section is observed, not computed.** `useActiveSection` uses an
`IntersectionObserver` with `rootMargin: '-20% 0px -55% 0px'`, biasing the viewport towards
its upper half so a section counts as active once its heading is comfortably on screen. No
scroll handler, no layout thrash.

## Authenticated state (future)

The current public page has no session state. When the
[authenticated shell](app-shell.md) is built, session bootstrap becomes shared server
state and must follow the
[administration requirements](../business-requirements/administration-requirements.md).
The client needs identity, immutable account type, effective grants separated by scope and
branch, usable working contexts, and enough session metadata to react to invalidation. One
role name or one flat permission array cannot represent the authorization model.

The selected branch is user-interface context, not authority. Queries and cache keys must
include the resolved `SCHOOL`, exact `BRANCH`, or `SELF` authorization context and any
school-scope branch focus filter. A focus filter never converts a school grant into a
branch grant. Changing context must not reuse protected data fetched under another context
unless the new request is independently authorized. Sign-out, session invalidation, or an
authorization-revision failure clears protected cached data.

Do not persist credentials, MFA challenges, portal invitation tokens, or authorization
grants in `localStorage`. The final session transport is still an explicit backend
decision. Invitation tokens should remain transient, be redeemed once, and be removed from
the visible URL/history flow as soon as redemption starts.

## The content layer

The shapes are in [`src/domain/school.ts`](../../../src/domain/school.ts); one instance of
them — `school`, `courses`, `packages`, `branches`, `journey`, `resources`, `testimonials`,
`faqs`, `stats` and `licenceClasses` — is in
[`src/data/school.ts`](../../../src/data/school.ts), which is now fixtures for the mock API
rather than the site's content. The rule below is unchanged by that move, and applies to
what the API returns.

The organising rule is a split by language-dependence:

> **The record holds what does *not* change with the language. `locales/*.json` holds
> everything a reader actually reads.**

So a `Course` carries its id, licence class, DMT code, lesson count, week count, price and
transmission — and no name, summary or feature list. Those are looked up as
`course.${id}.name`. A `Testimonial` keeps `name` and `initials` (personal names are not
translated) but points at a `branchId` so the location name follows the active language.

The payoff: adding a fourth language never touches `school.ts`, and changing a price never
touches a catalogue.

### Relationships are modelled, not duplicated

Records reference each other by id, and the UI derives from those references. `Branch.offers`
lists a course id and the price that branch charges for it, and everything else is read off
that: which licence classes a branch teaches, what a course costs there, and the "from"
price on a card. That is what lets the picker drop an already-chosen branch when the licence
class changes to one it does not teach, and it is why a branch's classes and its prices
cannot disagree — there is only one list.

The derivations that do this reading are in `domain/school.ts` and take the catalogue as an
argument. They used to close over module-level arrays, which is exactly the coupling that
stops working once the data arrives per request.

## The API seam

**This section is now history.** The seam described here has been built — see
[API layer](api-layer.md) for what exists. What follows is what was predicted and how it
turned out, because the differences are the interesting part.

`school.ts` was written as **a stand-in for the API**, not as a fixture to throw away, and
that held: its `interface`s moved to `src/domain/school.ts` unchanged and became the
response contracts, and its records became the mock server's fixtures.

Three predictions and their outcomes:

1. *"`Section` is the natural place to standardise a skeleton and an error message."*
   Correct, and done — `Section` takes `loading`, `error`, `skeleton` and `onRetry`. The
   cost is that it now imports `ApiError`, so it is no longer a pure layout primitive.
2. *"Sections currently import records at module scope."* The awkward part was not the
   imports but the **helpers**: `priceAt`, `coursesAtBranch` and the rest closed over
   module-level arrays. That reads well when the data is a constant and stops working the
   moment it arrives per request. They were split — pure functions taking their data in
   `domain/school.ts`, bound wrappers left in `data/school.ts` so unmigrated sections keep
   compiling.
3. *"`BookingCard.handleSubmit` is the one write."* Superseded. Trial booking is being
   removed; registration is the first write.

> **"Reconsider no library" was the right call to flag, and the answer is yes.** TanStack
> Query owns server state; local `useState` still owns client state. The deciding argument
> was not convenience but the requirement in the section above: *sign-out, session
> invalidation, or an authorization-revision failure clears protected cached data*. That is
> one line against a query cache and nearly unimplementable against `useState` scattered
> through every component, because there is no single thing to clear.

## The booking form

[`BookingCard.tsx`](../../../../school-ui/src/components/home/BookingCard.tsx) is the only interactive
feature and the closest thing to business logic in the app:

- Option lists are rebuilt via `useMemo` keyed on `t`, because labels are translated —
  computing them once at module scope would freeze them in the initial language.
- `complete` gates submission on all five fields being non-empty. There is no field-level
  validation (see [Deliberate omissions](README.md#deliberate-omissions)).
- Editing any field clears `submitted`, so a stale confirmation never sits under a
  half-edited form.
- Date bounds are computed once at module scope: never in the past, never more than a year
  out.
- The `DatePicker` change event type is spelled out locally (`DatePickerChangeEvent`)
  because the handler is not contextually typed — the component's props carry an index
  signature. Types are derived from the local `ui/` component via `ComponentProps`, keeping
  the file entirely on the Tailwind-mode import surface rather than reaching into the
  `primereact` package.
