# Architecture

Design documentation for the **school** project — the notes that explain *why* the code
is shaped the way it is, kept next to the code rather than in a wiki that drifts.

| Area | Location | Covers |
| --- | --- | --- |
| Business requirements | [`business-requirements/`](business-requirements/) | What the product must do and the rules it must honour — the *what* and *why* |
| Frontend | [`frontend/`](frontend/) | `school-ui` — the React single-page application, the *how* |
| Backend | [`backend/`](backend/) | `school-ba` — the Spring Boot API and backend architecture |

Read business requirements first if you are new to the project; read frontend first if you
are about to change code.

## Scope of these documents

These describe **structure and rationale**, not usage. Setup instructions, scripts and
day-to-day commands live in the [root README](../../README.md); assistant-specific rules
live in [CLAUDE.md](../../CLAUDE.md).

A document here should answer one of:

- What is the product supposed to do, and what has it promised its users?
- What are the layers, and which way may dependencies point between them?
- Why was this approach chosen over the obvious alternative?
- What is deliberately absent, and what would have to change to add it?

If a fact can be read directly off the code in a few seconds, it belongs in a code
comment instead.

## A note on the business requirements

They were **reconstructed from the built product**, not supplied by the business. They are
a draft for validation and are marked as such throughout — see the provenance note at the
top of [business-requirements/README.md](business-requirements/README.md).
