# Build and tooling

[← Frontend architecture](README.md)

Commands and setup steps live in the [root README](../../../README.md). This page covers
*why the tooling is configured the way it is* — the parts that surprise people.

## Vite

[`vite.config.ts`](../../../vite.config.ts) carries two plugins and one alias:

- `@vitejs/plugin-react` — React fast refresh, on Vite 8's Oxc pipeline.
- `@tailwindcss/vite` — Tailwind 4 as a build plugin rather than a PostCSS step, which is
  why no `postcss.config.js` or `tailwind.config.js` exists.
- `resolve.alias`: `@` → `./src`, resolved through `fileURLToPath` so it is absolute on
  Windows too.

Requires Node 20.19+ (or 22.12+) for Vite 8.

## Three TypeScript configs, and the alias declared twice

This trips people up, so it is worth stating plainly.

| File | Role |
| --- | --- |
| `tsconfig.json` | Solution file: `"files": []` plus project references. **Compiles nothing.** |
| `tsconfig.app.json` | The real config for `src/` — what `tsc -b` and the editor use |
| `tsconfig.node.json` | Config for `vite.config.ts`, which runs in Node |

The `@/*` path mapping appears in **both** the root config and `tsconfig.app.json`. That is
not a leftover. The root copy exists purely so tooling that reads the root config — the
shadcn CLI used to add PrimeReact components — can resolve the alias; the compiler never
reads it, because `files` is empty. Editing one without the other silently half-breaks
resolution.

`npm run build` runs `tsc -b && vite build`, so **type errors fail the build**. Vite alone
would strip types without checking them.

### Strictness worth knowing about

`tsconfig.app.json` turns on more than the defaults, and generated registry code routinely
trips over the first two:

- `verbatimModuleSyntax` — type-only imports must be written `import type`.
- `noUnusedLocals` / `noUnusedParameters` — an unused `import * as React` is an error.
- `erasableSyntaxOnly` — no enums or parameter properties; syntax must be removable by a
  transpiler that does not type-check.
- `noFallthroughCasesInSwitch`.

## ESLint

[`eslint.config.js`](../../../eslint.config.js) is ESLint 10 flat config: JS recommended,
`typescript-eslint` recommended, `react-hooks`, and `react-refresh`'s Vite preset, over
`**/*.{ts,tsx}` with `dist` ignored.

One scoped override: `react-refresh/only-export-components` is off for
`src/components/ui/**`, because registry components export variant helpers next to the
component and the files are kept close to their generated form. See
[Composition](composition.md#componentsui--generated-not-hand-written).

Inline suppressions are rare and each carries its reason. The one in `i18n/config.ts` is
instructive: `Locale.use()` is not a React hook — the rules-of-hooks rule matches it only
on the `use` name.

## Environment variables

Declared in [`.env.example`](../../../.env.example); real values go in `.env.local`, which
is git-ignored by the `*.local` rule. Only `VITE_`-prefixed variables reach client code,
and **anything exposed this way ships in the bundle** — it is configuration, never a
secret.

Every one of them is read in one place — [`src/config/env.ts`](../../../src/config/env.ts)
— so a missing variable fails once at startup naming itself, rather than turning up as
`undefined` inside a request URL.

| Variable | Status |
| --- | --- |
| `VITE_PRIMEUI_LICENSE_KEY` | Passed to `PrimeReactProvider`. Without it PrimeReact renders an "Invalid PrimeUI License" badge. |
| `VITE_API_BASE_URL` | Defaults to the relative `/api`, which the dev server proxies to `http://localhost:8080`. See [API layer](api-layer.md). |
| `VITE_API_MOCK` | `false` disables the mock API. Mocks are on by default in development and never in a production build. |

### The dev proxy

[`vite.config.ts`](../../../vite.config.ts) forwards `/api` to `http://localhost:8080` so
the browser only ever sees one origin in development. This is not just CORS convenience:
the `school_refresh` cookie is `SameSite=Strict`, so a page on `:5173` calling `:8080`
directly is a cross-site request and the browser withholds the cookie — refresh and logout
would fail locally in a way they never fail in production.

## Verifying a change

There is no test suite, so the gates are:

```bash
npm run build   # tsc -b, then the production bundle
npm run lint
```

Per [CLAUDE.md](../../../CLAUDE.md), the browser MCP servers declared in `.mcp.json`
(chrome-devtools, playwright) are **opt-in per request** for AI assistants working in this
repo — verification defaults to reading code, building and linting, not driving a browser.

## Static assets

`public/` is served as-is (`favicon.svg`, `icons.svg`). `index.html` preconnects to Google
Fonts and loads the Noto Sans Sinhala and Tamil faces — see
[Internationalization](internationalization.md#scripts-and-fonts).

`src/assets/` currently holds only unreferenced scaffold leftovers (`hero.png`,
`react.svg`, `vite.svg`).
