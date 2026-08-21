# State and data

[← Frontend architecture](README.md)

## State strategy

There is **no state management library, and no need for one yet**. Nothing is shared
between sections; the only meaningful state in the app belongs to one form. State lives at
the lowest level that can hold it:

| State | Where | Mechanism |
| --- | --- | --- |
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

## The content layer

[`src/data/school.ts`](../../../src/data/school.ts) holds the site's structural content:
`school`, `courses`, `packages`, `branches`, `journey`, `resources`, `testimonials`, `faqs`,
`stats` and `licenceClasses`.

The organising rule is a split by language-dependence:

> **`data/school.ts` holds what does *not* change with the language. `locales/*.json` holds
> everything a reader actually reads.**

So a `Course` carries its id, licence class, DMT code, lesson count, week count, price and
transmission — and no name, summary or feature list. Those are looked up as
`course.${id}.name`. A `Testimonial` keeps `name` and `initials` (personal names are not
translated) but points at a `branchId` so the location name follows the active language.

The payoff: adding a fourth language never touches `school.ts`, and changing a price never
touches a catalogue.

### Relationships are modelled, not duplicated

Records reference each other by id, and the UI derives from those references. `Branch.teaches`
lists licence classes, which is what lets `BookingCard` filter branches to those that can
actually teach the selected course — and drop an already-chosen branch when the licence
class changes to one it does not teach. `CoursesSection` builds its tabs from
`licenceClasses` and filters `courses` per tab, so a new course appears under the right tab
with no further wiring.

## The API seam

`school.ts` is written as **a stand-in for the API**, not as a fixture to throw away:

> Once `school-ba` exposes endpoints these shapes are what the API should return, with the
> copy served per-locale alongside.

That makes the migration path concrete:

1. `VITE_API_BASE_URL` is already declared in `.env.example` (`http://localhost:8080`) and
   read nowhere yet.
2. The exported `interface`s become the response contracts. Keep the id-and-relationship
   discipline — the frontend's filtering logic depends on it.
3. Sections currently import records at module scope. Fetching means introducing loading
   and error states section by section; `Section` is the natural place to standardise a
   skeleton and an error message so eight sections do not each invent one.
4. `BookingCard.handleSubmit` is the one write. It presently sets `submitted` and fires a
   toast; it would become a POST whose failure path needs a `severity: 'error'` toast to
   match the success one.

Server state arriving is also the moment to reconsider "no library" — a fetching/caching
layer solves problems local `useState` does not. That is a decision to make deliberately,
recorded here, rather than by accretion.

## The booking form

[`BookingCard.tsx`](../../../src/components/home/BookingCard.tsx) is the only interactive
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
