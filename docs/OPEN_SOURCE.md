# Open-source readiness review — 2026-11-10

This is a candid audit of the repository as an open-source project, not a claim of
production maturity. It complements `docs/RELEASE.md` (release engineering) and
`docs/TODO.md` (implementation backlog).

## Present

- MIT `LICENSE` with a 2026 PilotFoundry copyright line.
- README in English plus 简体中文, 繁體中文 and 日本語 entry points, screenshots,
  prerequisites and explicit limitations.
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`, `FAQ.md`,
  `ROADMAP.md`, `GOVERNANCE.md`, `PRIVACY.md` and `THIRD_PARTY_NOTICES.md`.
- GitHub issue forms, a PR checklist and a monthly Dependabot configuration for
  GitHub Actions.
- CI workflow for checks, app build, metadata/localization verification, release
  build and preview packaging.
- `CHANGELOG.md`, release verification scripts, ZIP/SHA256 generation and a release
  acceptance record.
- Four-language UI and localization parity gate (`102` keys × 4 tables at this
  revision).
- About panel with plist-derived version/build, copyright and a clickable GitHub
  link; Help menu repository entry. The intended URL is configured through
  `TPProjectURL`.
- Synthetic, committed test fixtures; personal media and personal screenshots are
  not committed.

## Still missing or externally blocked

### Repository and community

- **No public remote.** `git remote -v` is empty; the About/README GitHub URL is the
  intended canonical location and will remain unavailable until publication is
  authorized.
- No tags, GitHub Releases, issue labels, Discussions, CODEOWNERS or maintainer
  list. The single-maintainer governance model is documented but not yet enforced
  by branch protection/rulesets.
- No GitHub Security Advisories / private reporting enabled until publication.
- Full documentation is English-first; only README entry points are localized.

### Supply chain and release

- CI installs unpinned Homebrew FFmpeg/librsvg and uses major-tag action versions;
  pin engine artifacts and action commit SHAs before a public release.
- CI has not run on a hosted runner in this session; branch protection and required
  checks cannot be verified locally.
- Release is ad-hoc signed and not notarized; no Developer ID, no DMG, no automatic
  update feed, no SBOM/provenance/signed checksum attestation.
- No clean-Mac, Intel or macOS 14 hardware validation; support is explicitly
  narrowed to locally tested Apple Silicon macOS 27.
- FFmpeg/librsvg are not bundled and their GPL/LGPL redistribution obligations are
  not cleared for a standalone binary; see `THIRD_PARTY_NOTICES.md`.
- Engine memory/CPU rlimits remain unimplemented; timeouts, bounded probes and
  bounded child termination are in place.

### Quality and accessibility

- UI queue state-machine tests do not exist; core conversion checks are
  executable-based because CLT has no XCTest.
- Live VoiceOver/focus-order, physical drag/drop and TCC folder-prompt acceptance
  remain manual. AX labels and keyboard Cmd+Return flow are verified.
- No automated code coverage, fuzzing, static analysis, shellcheck/actionlint or
  benchmark suite.
- No real-camera HEIC/ICC corpus or real exFAT/network-volume acceptance.

## Recommended next steps

1. Publish the repository under the authorized `PilotFoundry/transcodepilot` URL,
   add branch protection/rulesets and required CI checks.
2. Enable GitHub private vulnerability reporting, add tags/Releases and pin CI
   engines/actions.
3. Clear code-signing/notarization and third-party redistribution before any
   standalone binary; keep the ad-hoc preview label until then.
4. Add CODEOWNERS/maintainer list, issue labels and a small public roadmap cadence.
5. Close the manual accessibility/volume/TCC gates and add UI e2e coverage.
