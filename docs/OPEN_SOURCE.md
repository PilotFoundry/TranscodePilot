# Open-source readiness review — 2026-11-13

This is a candid audit of the repository as an open-source project, not a claim of
production maturity. It complements `docs/RELEASE.md` (release engineering) and
`docs/TODO.md` (implementation backlog).

## Present

- Public MIT-licensed repository:
  <https://github.com/PilotFoundry/TranscodePilot>.
- README in English plus 简体中文, 繁體中文 and 日本語 entry points, screenshots,
  prerequisites and explicit limitations.
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`, `FAQ.md`,
  `ROADMAP.md`, `GOVERNANCE.md`, `PRIVACY.md`, `MAINTAINERS.md` and
  `THIRD_PARTY_NOTICES.md`.
- GitHub issue forms, PR checklist, CODEOWNERS, Discussions and a monthly
  Dependabot configuration for GitHub Actions.
- Hosted CI on `macos-latest` passes checks, app build, metadata/localization
  verification, release build and preview packaging. `main` requires the
  `build-and-verify` status check; force pushes and deletions are disabled.
- GitHub private vulnerability reporting and vulnerability alerts are enabled.
- `CHANGELOG.md`, release verification scripts, ZIP/SHA256 generation, release
  notes, a `v0.1.0` pre-release on GitHub and a release acceptance record.
- Four-language UI and localization parity gate (`102` keys × 4 tables at this
  revision).
- About panel with plist-derived version/build, copyright and a clickable GitHub
  link; Help menu repository entry. The URL is configured through
  `TPProjectURL`.
- Synthetic, committed test fixtures; personal media and personal screenshots are
  not committed.

## Still missing or externally blocked

### Distribution and trust

- The initial [v0.1.0 pre-release](https://github.com/PilotFoundry/TranscodePilot/releases/tag/v0.1.0)
  is ad-hoc signed and not notarized. No Developer ID, DMG, automatic update feed,
  SBOM/provenance or signed checksum attestation exists yet.
- Intel and macOS 14 hardware are unvalidated; the support claim is narrowed to
  locally tested Apple Silicon macOS 27.
- FFmpeg/librsvg are external, unpinned Homebrew dependencies. Their GPL/LGPL
  redistribution obligations are not cleared for a standalone binary; see
  `THIRD_PARTY_NOTICES.md`.
- Engine memory/CPU rlimits remain unimplemented; timeouts, bounded probes and
  bounded child termination are in place.

### CI and supply chain

- The CI runner image and Homebrew engine versions are unpinned; actions are used
  by major tag (`@v7`) rather than commit SHA. Pin these before a production
  release and record engine checksums.
- No automated release workflow, tag signing or release artifact attestation.
- No SBOM, dependency-vulnerability review beyond Dependabot for GitHub Actions,
  no actionlint/shellcheck in CI, and no benchmark/coverage gate.

### Quality and accessibility

- UI queue state-machine tests do not exist; core conversion checks are
  executable-based because CLT has no XCTest.
- Live VoiceOver/focus-order, physical drag/drop and TCC folder-prompt acceptance
  remain manual. AX labels and keyboard Cmd+Return flow are verified.
- No fuzzing, static analysis, automated coverage or real-camera HEIC/ICC corpus.
- Real exFAT/network-volume acceptance remains manual.

### Community and documentation

- Full documentation is English-first; only README entry points are localized.
- Discussions/issues/labels are enabled, but no maintainer rotation, triage
  cadence or public release cadence has been exercised yet.
- No hosted documentation site; docs live in the repository.

## Recommended next steps

1. Pin CI runner image, engine artifacts/checksums and action commit SHAs; add
   actionlint/shellcheck and an SBOM/provenance step.
2. Complete Developer ID signing/notarization before promoting the preview to a
   stable release; do not move or force-push published tags.
3. Complete the manual VoiceOver/focus, TCC, real-volume and clean-Mac gates.
4. Add community triage labels/maintainer rotation and a small release cadence;
   keep the roadmap demand-driven.
5. Revisit full-document localization after the product scope stabilizes.
