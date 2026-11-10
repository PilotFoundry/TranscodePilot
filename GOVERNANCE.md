# Governance

TranscodePilot is a small, local-first project maintained by PilotFoundry
contributors. The current preview has a **single-maintainer** decision model;
as the contributor base grows this document should be revised.

## Decisions

- Product scope and release blockers are tracked in `docs/CORE.md` and
  `docs/TODO.md`; design decisions live in `docs/DESIGN.md`.
- Changes require a focused issue/PR, tests where practical, and review by a
  maintainer.
- The project values source preservation, local-only processing, honest error
  reporting and reproducible release checks over feature breadth.

## Contribution terms

- Contributions are accepted under the MIT license in `LICENSE`; no CLA is
  currently required.
- No telemetry, network resource fetching, private APIs or new permissions.
- Do not commit personal media, private screenshots, credentials, signing
  identities or build artifacts.
- Follow `CODE_OF_CONDUCT.md` and `CONTRIBUTING.md`.

## Releases and security

- Release authority rests with the maintainer(s) named in the repository release
  record. The current preview is ad-hoc signed and not notarized.
- Security reports should follow `SECURITY.md` and stay private until reviewed.
- If the project is published, branch protection and a maintainer list should be
  configured before accepting external releases.

## Changes to this document

Open a governance issue/PR explaining the change and its effect on contributors,
release authority or security.
