# Non-functional requirements

[← Business requirements](README.md)

## Language parity

**Requirement.** English, Sinhala and Tamil are equal, not a primary plus two
translations. No section, control, error state or confirmation may appear untranslated.

This is a business requirement rather than a technical one: the school advertises
instruction in all three languages, so a visitor reading Tamil must be able to complete
the entire journey — including the booking form and its confirmation — without meeting
English.

**Consequences for delivery.** Adding a course, branch, package, FAQ or resource means
adding its copy to **all three** catalogues in the same change. A missing key falls back
to English silently, which fails this requirement without failing the build. The three
catalogues are line-for-line parallel and must stay that way. Mechanics are in
[internationalization](../frontend/internationalization.md).

Currency, dates and plurals must follow the reader's language, not the page's default —
the currency prefix differs per language (`Rs` / `රු.` / `ரூ.`).

## Accessibility

**Requirement.** The site must be operable by keyboard and comprehensible to a screen
reader, in all three languages.

Commitments currently honoured — enumerated in
[composition → accessibility](../frontend/composition.md#accessibility-commitments):

- A skip link precedes all content.
- Every section is a landmark associated with its heading.
- Navigation state is exposed via `aria-current`, and the visual style derives from that
  attribute, so appearance cannot drift from what is announced.
- Toggles expose pressed state; icon-only controls carry labels; decorative icons and the
  hero illustration are hidden from assistive technology.
- Star ratings carry a textual equivalent.
- Language options are marked with their own `lang`, so a screen reader pronounces
  "සිංහල" in Sinhala rather than attempting it in the page language.
- Reduced-motion preference disables smooth scrolling.

**Not verified.** There is no automated accessibility check and no audit on record. Colour
contrast in particular is untested across the light and dark token sets.

## Device and reach

**Requirement.** The primary visitor is on a phone, on a Sri Lankan mobile network.

- Layouts are mobile-first, widening at `sm`/`lg`.
- A persistent action bar on phones keeps call, WhatsApp and booking one tap away.
- The hero illustration is inline SVG rather than an image, costing no request and needing
  no dark-mode variant.
- Icons are imported one module per glyph rather than as a barrel.

**Untested.** There is no performance budget, no Lighthouse baseline and no measurement on
a throttled connection. The two Google Fonts families for Sinhala and Tamil are the
largest third-party cost and have not been weighed against the legibility they buy.

## Privacy and data protection

**This is the highest-risk area of the product, and it is currently dormant rather than
solved.**

The booking form tells every visitor: *"No card details and no deposit. Your number is
used only to confirm this lesson."* That is a specific, narrow purpose limitation
([BR-06](domain-and-rules.md#booking)). It is trivially true today because nothing is
transmitted or stored — and it becomes a binding commitment the moment
[FR-201](functional-requirements.md#lead-capture) is wired to a backend.

Before the form submits anywhere, the business must settle:

- **Retention** — how long a phone number is kept after the trial is confirmed or declined.
- **Purpose** — whether numbers may be used for follow-up marketing. The current copy says
  no. Using them for anything else contradicts a promise made at the point of collection.
- **Access** — who in the school can see submitted bookings.
- **Publication** — a privacy policy actually exists at the footer link, which today points
  at `#` ([FR-307](functional-requirements.md#contact-and-conversion-routes)).

Related: no analytics or tracking exists today. Adding any is a privacy decision, not just
a technical one.

Secrets are handled correctly — the PrimeUI licence key comes from a git-ignored
`.env.local`, and `.env.example` documents the variables without values. Note that any
`VITE_`-prefixed variable ships inside the client bundle, so it is configuration, never a
secret.

## Availability and operations

The application is a static bundle with no server-side runtime, so availability is
whatever hosts it. There is currently **no** error tracking, uptime monitoring, or
deployment pipeline recorded in the repository.

The one operational commitment the site makes is human, not technical: a callback within
two hours ([BR-05](domain-and-rules.md#booking)). Nothing in the system measures, routes or
alerts on it.

## Quality gates

There is no test suite. The only automated gates are:

```bash
npm run build   # type-checks with tsc -b, then bundles
npm run lint
```

For a site whose sole conversion path is a five-field form with a real business rule in it
([BR-01](domain-and-rules.md#booking)), the absence of any test around that rule is worth
raising deliberately rather than leaving implicit.
