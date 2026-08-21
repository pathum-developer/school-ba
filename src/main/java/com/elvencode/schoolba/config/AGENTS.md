# Config Package Instructions

This package owns Spring configuration code.

## Package Scope

- Put Spring configuration classes under `config`.
- Put security configuration under `config.security`.
- Put web configuration under `config.web`.
- Do not put domain business logic in this package.

## Design Rules

- Keep configuration classes focused on framework wiring.
- Prefer explicit bean names or method names when a bean is not self-explanatory.
- Keep authentication workflow logic in `auth`; keep only Spring Security wiring in `config.security`.
