# Authenticated app shell

[← Frontend architecture](README.md)

> **Status: proposal.** None of this is built. The application today is a single public
> page with no router, no authentication and no session state. Who the users are and what
> they may do is summarized in
> [roles and permissions](../business-requirements/roles-and-permissions.md); the
> [administration requirements](../business-requirements/administration-requirements.md)
> are authoritative for account and authorization behavior.

## Verdict on the proposed layout

**The shell is right.** Top bar, persistent left navigation, content region — it is the
standard for a role-based back office because it is genuinely the best fit: navigation
stays visible, deep linking works, and the content region is the only thing that changes
between pages.

Three changes are worth making before it gets built.

### 1. Keep the rail, but make navigation responsive

The icon rail was chosen deliberately to survive on a phone. That is the right instinct
about the right constraint — most of these users are phone-primary — but it treats "one
narrow pattern everywhere" as the way to be mobile-friendly, and on a phone the rail is
the wrong shape. Four reasons, in order of weight.

**Horizontal space is scarce and cannot be scrolled; vertical space is abundant and
already scrolls.** On a 360 px budget Android — the realistic low end here — a 56 px rail
is 16% of the screen, gone on every page, permanently. Content gets roughly 280 px to work
in, and a lesson row or payment table is cramped at that width. A bottom bar costs ~56 px
of *height* on an 800 px screen: 7%, taken from the axis that scrolls anyway. Same
component, far cheaper budget.

**Touch has no hover, so an icon rail's labels are unavailable exactly where they are
needed most.** The usual mitigation for an unlabelled rail is a tooltip. Tooltips are a
mouse affordance. On the phone and tablet the rail was chosen for, there is nothing to
hover — the icons are unlabelled and stay that way.

**The left edge is the hardest place for a thumb to reach; the bottom is the easiest.** A
vertical rail on the left puts primary navigation in the worst ergonomic zone on a phone.
A bottom bar puts it in the best one, which is why both iOS and Android converged there.

**A bottom bar is compact *and* labelled.** The trade-off between "narrow enough for a
phone" and "labelled enough to be learnable" only exists in a *vertical* strip, where a
label has to fit across the short axis. Lay the same icons out horizontally with a small
label underneath and both constraints are satisfied at once. There is no need to choose.

So: **keep the rail — as one breakpoint of a responsive system rather than the only
pattern.** It is genuinely the best fit at tablet and small-laptop widths, which is
precisely where a branch coordinator's device sits. See
[responsive navigation](#responsive-navigation) for the full breakdown.

One constraint that holds at every width: **a rail cannot carry twenty destinations.**
School staff have roughly that many, and there are no distinct icons for "courses" versus
"packages" versus "branches" that anyone will read correctly. Whatever the phone does, the
widest breakpoint has to be able to show labels.

The grouping in the mockup is good and worth keeping at every width: primary destinations,
a gap, secondary destinations, then account and sign-out pinned to the bottom.

### 2. Drop the separate breadcrumb card

The mockup has breadcrumbs floating in their own white card above the content card. That
is two containers, two shadows and two sets of padding to say one line.

It also assumes hierarchy that mostly does not exist. Most destinations are flat —
Dashboard, Today, Payments — where a breadcrumb reads `Home / Payments` and carries no
information.

Replace it with a **page header inside the content region**: title, optional subtitle, and
the page's primary actions on the right. Show breadcrumbs only where there is real depth
to climb, which in practice is the record pages:

```
Students / Nimali Perera / Lesson 12
```

The public site already has this pattern in
[`Section`](../../../../school-ui/src/components/home/Section.tsx) — one component fixing heading
rhythm so every page lines up without positioning its own title. The app wants the same
component, with an actions slot.

### 3. Put working context in the top bar

The mockup's top bar has logo, search, notifications and avatar. For this application that
is missing the thing staff most need to see: **which branch am I acting in?**

Staff can hold different branch-scoped roles in several assigned branches and may also hold
a school-scoped role. The active working context must therefore stay visible. If it is not
on screen, someone will eventually enrol a student at the wrong branch. Selecting a
context changes what the UI is working on; it never creates authority or merges grants
from different roles. The top bar should carry:

| Element | Why |
| --- | --- |
| Working context | Student `SELF`, staff `SCHOOL`, or one exact authorized branch; `SCHOOL` may add a branch focus filter that grants no authority |
| Language switcher | The trilingual requirement does not stop at login — see below |
| Notifications | Booking callbacks are time-critical ([BR-05](../business-requirements/domain-and-rules.md#booking)) |
| Account menu | Profile, theme, sign out |
| Search | Only once there is something worth searching — do not ship an empty search box |

**Language must carry into the app.** The public site is fully trilingual and the school
teaches in all three languages, so a Tamil-reading student meeting an English-only
dashboard the moment they sign in is the requirement failing at the last step.
[`LanguageSwitcher`](../../../../school-ui/src/components/home/LanguageSwitcher.tsx) already exists and
already persists across visits.

## Shell anatomy

```
┌──────────────────────────────────────────────────────┐
│ Logo    ⌕    Branch ▾   Lang   Bell   Avatar ▾       │  top bar
├────────┬─────────────────────────────────────────────┤
│        │  Page title              [Primary action]   │  page header
│  Nav   │  Optional subtitle / breadcrumb when deep   │
│        ├─────────────────────────────────────────────┤
│  ...   │                                             │
│        │  Page content                               │
│ ─────  │                                             │
│ Acct   │                                             │
└────────┴─────────────────────────────────────────────┘
```

Only the content region re-renders between pages. The shell holds session identity,
scope-separated effective grants, authorized working contexts, and navigation state, so
switching pages does not re-fetch who you are. Protected data remains server state and is
keyed by the active context.

## Navigation is data, not markup

Declare destinations as a list, each carrying the permission and context it requires, and
render by filtering. Never build one sidebar per persona or role bundle; configurable
roles and multi-branch assignments would make those sidebars drift immediately.

```ts
type AuthorizationContext =
    | { scope: 'SCHOOL'; focusBranchId?: string }
    | { scope: 'BRANCH'; branchId: string }
    | { scope: 'SELF' };

interface NavItem {
    to: string;
    labelKey: string;             // i18next key, never a literal
    icon: ComponentType;
    permission: Permission;
    context: 'ACTIVE' | 'SELF' | 'SCHOOL';
    group: 'primary' | 'secondary' | 'account';
}
```

Filtering one list with `useCan(permission, resolvedContext)` gives each session the right
navigation without branching on a role name. The session cannot be represented by one flat
permission array: `CO_STUDENT_VIEW` may be effective at `SCHOOL`, at one `BRANCH`, at
several branches, or in none. A new ordinary role changes effective grants rather than
frontend code. Preserve individual grant boundaries; `useCan` must not combine a
permission from one role grant with scope or delegation rights from another. A school
focus branch filters the view but leaves the authorization scope as `SCHOOL`. See the
[authorization model](../business-requirements/roles-and-permissions.md#authorization-model).

Two rules that keep it honest:

- **Every label is an i18next key.** A literal string here is an untranslated sidebar.
- **Empty groups collapse.** A student with nothing in `secondary` should not see its
  divider.

### Where each working context lands

Signing in should land on the most relevant authorized destination in the selected working
context, not on a generic dashboard:

| Context/persona | Landing page | Because |
| --- | --- | --- |
| Student `SELF` | Next lesson | The one thing the student signed in to check |
| Instructor in a `BRANCH` | Today's assigned schedule | Their whole job, in one list |
| Branch operations in a `BRANCH` | Callback queue | Time-critical, and the promise the business made |
| `SCHOOL` | Cross-branch overview | School-scoped work needs an all-branch view |

If staff have several usable contexts, restore the last still-authorized context or ask
them to choose. The root path resolves from effective grants and active context, never a
single role name. A remembered branch ID must be revalidated against each new session.

## Enforcing access

**Three layers. Only the third is security.**

| Layer | Purpose | Consequence if missing |
| --- | --- | --- |
| 1. Navigation filtering | Do not offer what cannot be used | Clutter, and dead ends |
| 2. Route guards | A typed URL or stale bookmark gets a clean 403 | A blank or broken page |
| 3. **Server authorization** | **Actually prevents access** | **Data breach** |

Layers 1 and 2 are user experience. A hidden menu item is not protection — the route still
exists in the bundle, and anyone can type the URL or edit the JavaScript. **Every request
must be authorized server-side, every time**, including scope: not just "may this user view
students" but "may this user view *this* student".

Never ship a client-side permission check without the matching server-side one. Ship the
server-side one alone if you have to choose.

## Responsive navigation

The public site is mobile-first with a phone action bar, and students and instructors are
phone-primary. **Decide the mobile shell now**, because retrofitting navigation is
expensive.

Navigation changes shape three times. The destination list does not change — only how it
is presented, which is what makes [nav-as-data](#navigation-is-data-not-markup) worth the
small effort.

| Width | Pattern | Labels | Why |
| --- | --- | --- | --- |
| Phone (`< sm`) | **Bottom tab bar**, 4–5 items, overflow into a drawer | Under each icon | Best thumb zone; costs height, not width |
| Tablet (`sm`–`lg`) | **Icon rail** — the mockup, as drawn | On press, and on the active item | Width is affordable; vertical strip suits a landscape tablet |
| Desktop (`≥ lg`) | **Labelled sidebar**, collapsible back to the rail | Always | Room for twenty destinations and no ambiguity |

Two consequences worth planning for:

**The phone tab bar needs a hard cap of five.** More than that and the labels stop fitting.
Each persona and working context therefore needs a declared priority order: the top four or five
destinations become tabs, everything else goes behind a "More" entry that opens a drawer.
That priority is a product decision per context, not something to derive from list order by
accident.

**The rail still needs labels on touch.** At tablet width, show the label on press-and-hold
and keep the active item's label visible permanently, so there is always at least one
worked example on screen tying an icon to its meaning.

### What already exists

Three pieces of this are in the codebase today:

- [`MobileCtaBar`](../../../../school-ui/src/components/home/MobileCtaBar.tsx) is the public site's
  phone-only bottom bar. The authenticated tab bar is its direct sibling — same position,
  same reasoning, and `App` already carries the `pb-20 sm:pb-0` pattern that keeps content
  clear of it.
- [`Drawer`](../../../../school-ui/src/components/ui/drawer.tsx) already backs the mobile menu in
  `SiteHeader`, and can back the "More" overflow unchanged.
- [`useMediaQuery`](../../../../school-ui/src/hooks/useMediaQuery.ts) exists precisely for switching on
  a breakpoint in JavaScript rather than a CSS class — which is what choosing between three
  different nav components requires.

The phone pattern is therefore not a new invention. It is the pattern this product already
uses, carried across the login boundary.

## What this changes in the current codebase

The shell is not a new section on the existing page — it is the first thing that makes this
a multi-page application. Five things follow.

**A router is required.** None is installed. `App.tsx` composes the home page directly, so
its body lifts into a public route and the shell becomes a second route tree.

**Session and permissions are genuinely global state.**
[State and data](state-and-data.md#state-strategy) records a deliberate decision — local
`useState`, no store, revisit when server state arrives. **This is that moment.** Session
identity, scope-separated grants, usable branch contexts, and the active context are read
almost everywhere and owned by nobody in particular. Revisit state management as a
decision rather than letting a global store emerge accidentally. The client must never
combine a permission from one grant with scope from another.

**Loading and error states become unavoidable.** Every page will fetch. Standardise the
skeleton and the error state in the page-header component, or eight pages will each invent
their own.

**The catalogue moves behind the API.** Course and package prices live in
`src/data/school.ts` today. Once school staff can edit prices, that file stops being the
source of truth and the [API seam](state-and-data.md#the-api-seam) has to be real.

**Translation volume grows sharply.** Three catalogues currently hold 316 parallel lines
for one page. An application of twenty pages multiplies that, and the parity requirement
does not relax. Plan for translation as a delivery step with an owner, not as something
done at the end of a ticket.

Nothing about the visual design needs to change: the token system, `cn`, dark mode and the
PrimeReact Tailwind-mode components all carry over unchanged. `Avatar`, `Drawer`,
`Divider`, `Tabs`, `Timeline` and `Toast` already exist in
[`components/ui/`](../../../../school-ui/src/components/ui/).

## PrimeReact component map

Everything in the shell is a PrimeReact Tailwind-mode component from the registry. Only
the phone tab bar is hand-written, because no registry component covers it.

| Shell element | Component | Notes |
| --- | --- | --- |
| Shell root | `SidebarLayout` | Holds sidebar + main as one layout |
| Sidebar | `Sidebar` with `collapsible="icon"` | **This is the rail.** Expanded shows labels, collapsed shows icons — one component covering both desktop and tablet |
| Rail edge / drag handle | `SidebarRail` | |
| Collapse toggle | `SidebarTrigger as={Button}` | Lives in the top bar |
| Nav groups | `SidebarGroup`, `SidebarGroupLabel`, `SidebarGroupContent` | Empty groups are filtered out before render |
| Nav items | `SidebarMenu`, `SidebarMenuItem`, `SidebarMenuButton isActive` | |
| Counts on nav items | `SidebarMenuBadge` | Callback queue, unpaid instalments |
| Nested destinations | `SidebarMenuSub`, `SidebarMenuSubItem`, `SidebarMenuSubButton` | Available, unused so far |
| Identity in sidebar footer | `Avatar`, `AvatarFallback` | |
| Account menu | `Popover` + `PopoverTrigger as={Button}` + portal/positioner/popup stack | |
| Breadcrumb | `Breadcrumb`, `BreadcrumbList`, `BreadcrumbItem`, `BreadcrumbLink`, `BreadcrumbCurrent`, `BreadcrumbSeparator` | Only on record pages with real depth |
| Content region | `SidebarMain` | |
| Toasts | `Toaster` | Already root-mounted on the public site |
| Phone tab bar | *hand-written* | No registry equivalent; mirrors `MobileCtaBar` |

`Sidebar` carries no generated API prop table, so `validate_usage` returns
`api-unavailable` rather than confirming props. Every part and prop used above is taken
from the component's own documented example — treat that as the source, not this table.

### Adding these components

```bash
npx shadcn@latest add https://primereact.dev/r/sidebar.json \
    https://primereact.dev/r/popover.json \
    https://primereact.dev/r/breadcrumb.json
```

All three needed the fix-ups the [frontend README](../../../../school-ui/README.md) already documents: type-only
imports marked for `verbatimModuleSyntax`, and the unused `import * as React` removed for
`noUnusedLocals`.

## Files

```
src/
├── app/
│   ├── AppLayout.tsx      # shell root — sidebar + top bar + content + tab bar
│   ├── AppSidebar.tsx     # permission-filtered navigation
│   ├── AppTopBar.tsx      # trigger, branch context, language, notifications, account
│   ├── AppBottomNav.tsx   # phone tab bar
│   ├── PageHeader.tsx     # title, breadcrumb, actions
│   └── navigation.ts      # the nav list — data, permission-tagged
└── auth/
    ├── permissions.ts     # Permission union, Scope, EffectiveGrant, Session
    └── useSession.ts      # session context, useCan()
```

`useSession` throws outside a signed-in route, and no provider fills it yet — the shell
compiles and lints but is not mounted, because mounting it means choosing a router. That
choice is deliberately left open.

## Suggested build order

1. **Sign-in, MFA challenge, session bootstrap, and the permission-aware shell.** This
   follows the backend seed manifest, first-super-admin bootstrap, and minimum staff
   invitation/assignment workflows; it must not invent a temporary role-name bypass.
2. **Callback queue for authorized branch staff.** Smallest operational slice that closes
   [FR-208](../business-requirements/functional-requirements.md#lead-capture) and makes the
   public site's two-hour promise real. It needs one seeded operational permission and an
   explicit booking-branch policy.
3. Enrolment, student records, profile lifecycle, and verified contacts.
4. Scheduling, attendance, instructor assignment.
5. Payments and instalments.
6. Student portal invitation, account binding, and self-service.
7. Remaining school administration and reporting.

Starting with the student portal is tempting because it is the most visible, but it depends
on students existing in the system, which depends on enrolment, which depends on the
callback queue. Build the order the data arrives in.
