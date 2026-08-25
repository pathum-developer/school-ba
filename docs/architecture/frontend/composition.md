# Composition

[← Frontend architecture](README.md)

How the source is layered, and which way dependencies are allowed to point.

## Layers

| Layer | Directory | Owns |
| --- | --- | --- |
| Entry | `src/main.tsx`, `src/App.tsx` | React root, providers, page order |
| Sections | `src/components/home/` | Page-specific composition and behaviour |
| Primitives | `src/components/ui/` | Project-owned PrimeReact Tailwind-mode components |
| Server data | `src/api/` | The axios client, endpoints, query hooks — see [API layer](api-layer.md) |
| Domain | `src/domain/` | Response types and the pure functions that read them |
| Fixtures | `src/data/`, `src/mocks/` | One instance of the domain records, and the mock server serving it |
| Translation | `src/i18n/`, `src/locales/` | Every user-visible string, both layers |
| Utilities | `src/hooks/`, `src/lib/`, `src/config/` | Browser-facing hooks, the `cn` class merger, environment |

## Dependency rule

Dependencies point **downward only**:

```
main → App → home/, app/ → ui/ → lib/
                ↘ api/ → domain/, config/
                ↘ domain/, i18n/, hooks/, lib/
```

Concretely:

- `ui/` never imports from `home/`, `api/` or `data/`. A primitive that knows about courses
  is no longer a primitive.
- `domain/` imports nothing from the application at all — it is types and pure functions,
  and both `api/` and the sections depend on it so that neither depends on the other.
- `api/endpoints/` imports no React; only `api/queries/` does. An endpoint stays callable
  from a loader, a mutation or a test.
- Nothing outside `api/http.ts` imports `axios`.
- `i18n/` may read `domain/` (`useMoney` calls `formatAmount`), never the reverse.
- Sections do not import each other. The one cross-section value is
  `BOOKING_TOAST_GROUP`, exported by `BookingCard` and consumed by `App` to mount the
  matching `Toaster` — the toast outlet lives at the root so it is not clipped by section
  layout.

## `components/ui/` — generated, not hand-written

These files come from the PrimeReact registry via the shadcn CLI:

```bash
npx shadcn@latest add https://primereact.dev/r/<component>.json
```

They are treated as **generated code that this repo happens to own**. Keeping them close
to their generated form is what makes re-running the CLI a readable diff rather than a
merge. Two consequences are already encoded in the tooling:

- [`eslint.config.js`](../../../eslint.config.js) disables `react-refresh/only-export-components`
  for `src/components/ui/**`, because registry files export variant helpers alongside the
  component.
- Registry output targets a looser TypeScript config than this project's. Under
  `verbatimModuleSyntax` and `noUnusedLocals` a freshly added file usually needs type-only
  imports marked and an unused `import * as React` removed before `npm run build` passes.

Restyling belongs in the [theme file](styling-and-theming.md), not in these components.

## `components/home/` — three kinds of file

Not everything under `home/` is a page section. Three roles share the directory:

**Sections** (`HeroSection`, `CoursesSection`, `FaqSection`, …) map one-to-one onto a
block of the page and onto a nav anchor. Each renders through `Section` and reads its own
slice of the catalogue — through `useCatalog()` once migrated, from `data/school.ts` until
then.

**Layout primitives.** [`Section.tsx`](../../../src/components/home/Section.tsx) fixes the
heading rhythm — eyebrow, `h2`, description, optional aside, `mt-10` body — and wires
`aria-labelledby` from a derived `${id}-heading`. Every section lines up because none of
them positions its own heading. It also owns the loading, error and retry bodies, so eight
sections do not invent eight of each; that is the one place the layer boundary is crossed
deliberately, and the cost is that `Section` imports `ApiError`.

**Composition wrappers.** [`FormSelect.tsx`](../../../src/components/home/FormSelect.tsx)
pre-assembles the `Select → Portal → Positioner → Popup → List → Option` stack that the
booking form would otherwise repeat verbatim three times, and adds the two-line
label/hint option rendering. It exists because the repetition was real, not on the chance
it might be.

The same reasoning produces small local hooks rather than a shared hooks file:
`useDarkMode` and `useActiveSection` live inside `SiteHeader.tsx` because only the header
uses them. `useMediaQuery` sits in `src/hooks/` because it is genuinely general — it
exists for components taking a *numeric* prop that has no responsive Tailwind variant,
such as `Carousel`'s `slidesPerPage`.

## Icons

Icons are imported one module per glyph (`@primeicons/react/check-circle`), never as a
barrel, so the bundle carries only what is used. Decorative icons always take
`aria-hidden="true"`; an icon carrying meaning gets a label on its control instead.

Where PrimeIcons has no suitable glyph the design adapts rather than substituting a
misleading one — `CourseCard` shows the licence class code as its badge because there is
no motorcycle or three-wheeler icon.

## Accessibility commitments

Worth knowing before editing, because they are easy to break silently:

- A skip link is the first focusable element in `App`.
- Every `Section` associates its heading with the region via `aria-labelledby`.
- The active nav item is marked with `aria-current`, and styled off that attribute
  (`aria-[current]:…`) rather than a parallel class — the visual state cannot drift from
  the announced one.
- Toggles expose `aria-pressed` (theme toggle, language options).
- Each language option carries its own `lang` attribute, which drives both screen-reader
  pronunciation and font selection. See [Internationalization](internationalization.md#scripts-and-fonts).
