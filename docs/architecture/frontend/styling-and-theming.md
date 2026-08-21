# Styling and theming

[← Frontend architecture](README.md)

## Three layers, one entry point

All styling enters through [`src/index.css`](../../../src/index.css):

```css
@import 'tailwindcss';          /* 1. utilities */
@import 'tailwindcss-primeui';  /* 2. token-backed utility classes */
@import './themes/elven-yellow.css'; /* 3. token values */
```

1. **Tailwind 4**, wired by `@tailwindcss/vite`. There is no `tailwind.config.js` — v4 is
   CSS-first, and the project adds no custom utilities beyond what the plugin below
   supplies.
2. **`tailwindcss-primeui`** exposes PrimeUI's design tokens as Tailwind utilities, which
   is why classes like `bg-surface-0`, `text-muted-color`, `border-surface` and
   `text-primary-contrast` work in JSX. Prefer these over raw palette classes: they follow
   the theme, `bg-neutral-100` does not.
3. **`themes/elven-yellow.css`** sets the token values.

## The theme file is the styling API

[`themes/elven-yellow.css`](../../../src/themes/elven-yellow.css) redefines the `--p-*`
custom properties that every Tailwind-mode component already reads — the primary ramp
(muted amber), the surface ramp (warm sand rather than cool grey), `--p-content-border-radius`,
and the semantic aliases (`--p-text-muted-color`, `--p-highlight-background`, …).

This is the reason `components/ui/` can stay close to its generated form: a restyle is a
token change in one file, not an edit spread across twenty components. **Change the theme
before changing a component.**

## Dark mode

Dark mode is class-based, and three places have to agree on that:

| Place | Declaration |
| --- | --- |
| `main.tsx` | `theme.options.darkModeSelector: '.dark'` — tells PrimeReact where to look |
| `index.css` | `@custom-variant dark (&:where(.dark, .dark *))` — tells Tailwind's `dark:` the same |
| `elven-yellow.css` | a `.dark { … }` block re-pointing the semantic tokens |

Note what the `.dark` block does *not* do: the primary and surface ramps themselves are
theme-independent. Only the aliases move — `--p-text-color` flips from `surface-900` to
`surface-0`, `--p-primary-color` from the 500 step to the lighter 400, and highlights
become translucent `color-mix` washes instead of solid tints.

Because the ramps do not move, the page ground has to be switched explicitly, which is
what the `.dark body` rule in `index.css` is for — without it, overscroll reveals sand
behind a dark page.

**The toggle.** `useDarkMode` inside
[`SiteHeader.tsx`](../../../src/components/home/SiteHeader.tsx#L25-L33) seeds its state
from whether `documentElement` already carries the class, then toggles the class in an
effect. Nothing writes to storage and nothing reads `prefers-color-scheme`, so a reload
always lands in light mode. Adding persistence means reading the stored value *before
first paint* — an inline script in `index.html`, not an effect — otherwise the page
flashes light.

## Writing component styles

- Reach for token utilities (`bg-surface-0`, `text-color`) over fixed palette values.
- Merge incoming `className` through `cn` from
  [`lib/utils.ts`](../../../src/lib/utils.ts). It composes PrimeUI's `cn` with
  `tailwind-merge`, so a caller's `p-8` actually replaces a component's `p-6` instead of
  both landing in the class list and letting source order decide.
- Mobile-first: unprefixed classes describe the phone layout, `sm:`/`lg:` widen it. The
  `pb-20 sm:pb-0` on `<main>` exists to clear the phone-only action bar.
- Respect `prefers-reduced-motion` — `index.css` already drops smooth scrolling under it.

## Decorative graphics

The hero illustration
([`DrivingLessonBackdrop.tsx`](../../../src/components/home/DrivingLessonBackdrop.tsx)) is
inline SVG drawn with `stroke="currentColor"`, not an image file. That is deliberate: an
external SVG referenced from `background-image` cannot inherit colour, so it would need a
second dark-mode copy. Inline, it follows the theme and costs no extra request.
