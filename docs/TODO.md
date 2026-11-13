# TranscodePilot backlog

Updated: 2026-11-10. Scope: independent PilotFoundry macOS media converter.
This is a delivery backlog, not a claim that every potential defect has been
reproduced. Checked items record existing/verified work; unchecked items remain.
Read `docs/CORE.md` and `docs/DESIGN.md` before changing product scope or UI.

## Current status — 2026-11-10

- Local Git baseline exists (`main`, no remote); all changes are committed in
  verified steps.
- Phase 1 reliability work is implemented: bounded inputs, source inspection,
  shared conversion planning, inline width/limit errors and estimated size,
  sanitized preferences, bitmap cancellation checks, child-process grace wait,
  and cancel-then-quit/close behavior.
- GUI acceptance was performed with `agent-desktop` 1.2.0: real batch conversion,
  inline validation, close alert, cancel, and quit-during-conversion. A disabled
  app-menu Quit item was found and fixed (`termination target + main-queue
  polling`); ⌘Q now exits in ~0.4 s during conversion with no child/temp leaks.
- Real files verified: CJK swimlane SVG at 1×/2×; complex-path cloud SVG at
  1×/4×; no-audio MP4 correctly rejected; HEVC+AAC MP4 → MP3 at 192 kbps with a
  ~1.5 ms duration difference. Source hashes unchanged.
- A reusable synthetic SVG effects corpus is in
  `Sources/TranscodePilotChecks/Fixtures/SVGEffects/`: gradients, blur,
  feColorMatrix, mask, clipPath and fill-opacity/JPEG flattening. A sizing corpus
  in `Fixtures/SVGSizing/` covers physical units, viewBox/percentage/missing
  dimensions, explicit width and fractional output.
- `make check` has four PASS groups; MKV → MP3 and SVG sizing are covered.
- Remaining P0 blockers: SVG trust residual risk and non-APFS real-volume
  acceptance (mount unavailable in this environment). In-flight SVG/bitmap
  cancellation, huge MP4/MKV conversion and a generated+real effects visual pass
  are now verified; app-owned error UX, typed failures and recovery actions are
  implemented.
- Design/UIUX is now a first-class workstream; its baseline and review method are
  in `docs/DESIGN.md`.

### Autonomous execution summary — 2026-11-10

All locally actionable P0/P1/P2 work and the D1–D8 design pass are implemented,
tested and documented. Local evidence: `make check` (4 PASS groups), `make app`,
`make verify` (102 keys × 4 tables), `make release`/`make package` (ZIP + SHA256),
D1 screenshot matrix, AX-label and Cmd+Return keyboard pass, in-flight bitmap/SVG
cancel, graceful quit during conversion, 1.2–1.29 GB real MP4/MKV conversions and
an effects visual pass.

Remaining items are external, hardware/credential/manual, or demand-driven rather
than code gaps:

- P0: real exFAT/network-volume acceptance (mount unavailable here); full SVG
  renderer-sandbox proof (documented residual risk).
- D9/D10: live VoiceOver/focus-order pass (AX labels and keyboard flow are done).
- P1: TCC folder-prompt acceptance; engine rlimit memory/CPU caps; engine-missing
  and output-disconnect injections; UI queue state-machine tests; drag/drop
  physical pass; exported-file drag/copy is conditional on real-use need.
- P2: remote publication, Developer ID/notarization, Intel/macOS 14 and clean-Mac
  validation, pinned/portable engine builds and legal/license/domain decisions.
- P3: demand-driven formats/Quick Actions/presets/embedded images; explicitly not
  v0.1 blockers.

### Completed milestones

- [x] Local Git baseline, reproducible `SWIFT_FLAGS`, default SwiftPM backend.
- [x] Bounded input preflight, shared planner, sanitized preferences.
- [x] Inline width/limit validation, estimated output dimensions, safe quality
  formatting and disabled Convert on invalid items.
- [x] Bitmap stage cancellation checks and a real child-process grace wait.
- [x] Cancel-then-quit/close fix, main-queue termination polling, GUI verification.
- [x] Real-file pass: CJK and complex-path SVGs at 1×/2×/4×, no-audio MP4
  rejection, AAC-audio MP4 → MP3 with duration check.
- [x] Reusable synthetic SVG effects corpus in `make check`.
- [x] Design shell: native toolbar, File/Window/Help menus, standard app menu,
  branded app icon and system-accent controls.
- [x] MKV → MP3 audio extraction through the same first-audio-track path.
- [x] SVG sizing rules: 96 dpi units, viewBox/percentage/missing dimensions,
  width-only explicit sizing, zoom scaling and requested-vs-actual checks.
- [x] Typed app failures, localized app-owned errors, English engine detail and
  Retry / choose-output-folder recovery actions.
- [x] Queue controls, stable drop ordering, apply-to-similar scope, saved width /
  kind-aware scale defaults, engine warning and plist-backed About version.
- [x] Crash-temp cleanup, disk-space preflight, source signatures, stronger output
  verification and PATH-aware engine discovery.
- [x] Regression extras: HEIC, Display P3, mirrored EXIF, CJK, CDATA rejection,
  multiple audio tracks, bitrate tolerance, long/non-ASCII paths, timeout, denied
  write and concurrent collisions.
- [x] Release pipeline: clean Release bundle, metadata/localization/signature
  verification, ZIP+SHA256 packaging, CI workflow and release/security/support docs.
- [x] Final local acceptance: huge MP4/MKV, in-flight bitmap/SVG cancel, graceful
  quit, effects visual pass and 40 MP/SVG performance samples.
- [x] D1–D8 design pass with local screenshot matrix, AX labels, keyboard-only
  Cmd+Return conversion and a recorded heuristic scorecard.
- [x] About panel shows plist version/build, copyright and a clickable GitHub link;
  Help exposes the repository. Added OSS community/compliance files and a candid
  readiness review in `docs/OPEN_SOURCE.md`.
- [x] Real progress bars: FFmpeg-derived percentage for MP3 and stage progress for
  bitmap/SVG, in queue rows and the bottom bar.
- [x] Real conversion progress: FFmpeg progress for MP3 and phase progress for
  bitmap/SVG, shown in queue rows and the bottom bar with a determinate bar.
- [x] Ad-hoc app build/signature; four `make check` PASS groups; doctor pass.

## Next landing plan

### Iteration A (recommended next): design baseline + SVG sizing

1. **Design baseline (D1):** D2/D3 are implemented (icon, native toolbar,
   standard menus); finish D1 by capturing the remaining review matrix (invalid,
   converting, done, failed, alert; light/dark; default/min window sizes; four
   locales) and applying tokens more comprehensively in `docs/DESIGN.md`.
2. **SVG sizing (P0):** implemented 2026-11-10 — 96 dpi units, viewBox/percentage/
   missing dimensions, explicit width, zoom scaling and requested-vs-actual checks;
   verified by `Fixtures/SVGSizing`.
3. **UI integration:** estimates and conversion sizing share the same parser and
   planner; the UI verification checked the 96 × 48 estimate and output for a
   25.4 mm × 12.7 mm fixture.
4. Exit criteria: `make check` PASS; sizing cases added to the checks corpus;
   screenshots reviewed at default/min sizes; design decisions recorded.

### Iteration B: trust, filesystem, error UX, hardening

1. Audit SVG trust boundary (namespaces, decoded CSS, CDATA/comments, URL forms,
   XML entities, animation variants) and add adversarial fixtures; decide and
   record the residual-risk position for the renderer.
2. Add MP4/FFmpeg input preflight and bounded probe/scan behavior; test corrupt
   MP4, large files and protocol restrictions.
3. Decide and implement non-APFS destination policy (recommended: preflight and
   reject with a localized recovery action for v0.1).
4. Introduce typed app errors (engine detail vs app-owned code) and localize
   app-owned failures with recovery actions.
5. Clear hardening items that affect daily trust: stale temp cleanup, disk-full,
   source TOCTOU/type checks, filename limits.

Exit criteria: request/response behavior covered by checks; no raw English
app-owned errors in the normal path; non-APFS behavior verified on a real volume
(user-assisted); rejection/cleanup evidence recorded.

### Iteration C: UI/UX completion

1. Execute design tasks D4–D10: empty state, queue rows/thumbnails/status/counts,
   inspector information architecture, primary-action hierarchy, light/dark,
   four-language copy/overflow, accessibility and keyboard/VoiceOver.
2. Complete workflow behavior: single-task retry/clear, mid-run add policy,
   apply-to-similar scope, saved width/defaults, output path disambiguation and
   engine readiness.
3. Add a real effect SVG sample if available; otherwise record the synthetic
   corpus as the engine-behavior acceptance and keep real visual acceptance
   pending.

Exit criteria: design review scorecard has no zeroes; user can complete the
primary flow with keyboard only; screenshots and accessibility notes recorded.

### Iteration D: release engineering (P2)

CI, pinned portable engines, license/notices, Release build, clean packaging,
ZIP/checksum, clean-Mac test, signing/notarization (if credentials), localized
README/screenshots/changelog and release record. External decisions: remote
repository, domain/trademark, Developer ID, Intel/macOS 14 hardware.

### v0.1 release gate

- All P0 blockers checked and verified by a real or automated acceptance record.
- D1–D10 accepted; manual checklist (light/dark, keyboard/VoiceOver, four
  locales, real samples, volume behavior) recorded.
- No known data-loss, source-overwrite, silent-corruption or quit/cancel leak.
- Distribution claims match what was actually exercised.

## Agreed decisions — 2026-11-06 (still current)

- Quit during conversion: auto-cancel, wait up to 5 s for child/temporary cleanup,
  then quit; closing the window is blocked while converting; Dock reopen restores
  the window.
- Hard-link-less destinations: preflight and reject in v0.1; copy fallback is
  deferred.
- SVG sizing rules for the next phase: physical units at 96 dpi; explicit width
  via renderer width-only; scale via `--zoom`; percentages/missing sizes
  documented; requested width exact, height tolerance ±1 px.
- Real-file samples stay local (Downloads or `.build`), are not committed, and
  source hashes are recorded before/after.
- This sandboxed agent session builds with `SWIFT_FLAGS=--disable-sandbox`; the
  default SwiftPM backend is used, and CLT has no XCTest, so checks stay
  executable-based.

## P0 — v0.1 release blockers (reliability/security)

- [ ] **Audit SVG trust boundary:** namespace/root validation, animation variants,
  CDATA-aware style handling and self-contained at-rules are now covered by
  `Fixtures/SVGSecurity`; external URLs/scripts/entities remain rejected. Real
  renderer file/network denial is still not proven — lexical checks are not a
  general SVG sandbox; residual risk must stay documented.
- [x] **Cancel during actual conversions:** GUI cancel was exercised during a
  40 MP bitmap encode and a 40 MP filtered SVG render; both reached Cancelled with
  no published output, no temp directory and an unchanged source. Quit during an
  FFmpeg conversion exited in ~0.5 s with no child/temp leak.
- [ ] **Output filesystem compatibility:** hard-link volume preflight is
  implemented and rejects destinations whose volume does not report hard-link
  support. APFS tests pass; real exFAT/FAT/network-volume acceptance is blocked
  because this environment cannot mount a local disk image. The exact remaining
  action is to repeat the rejection test on a real exFAT/network volume.
- [x] **User-friendly failures:** typed `ConversionErrorCode` values distinguish
  settings/input/missing-engine/no-audio/invalid-SVG/permission/disk-full/output
  verification cases; app-owned text is localized in four languages, engine
  stderr remains English detail, and failed items offer Retry plus Choose Output
  Folder for publication failures. Corrupt-container GUI acceptance completed.
- [x] **MP4/FFmpeg trust boundary and resource limits:** protocol whitelist,
  explicit demuxers, bounded probe size/duration and timeouts are in place; corrupt
  containers are covered. A 1.29 GB MKV with three audio tracks and a 1.2 GB MP4
  both converted to 1410.8 s / 192 kbps MP3 in ~11.5 s with source hash unchanged.
  Output-size caps remain a documented residual policy decision rather than a
  separate hard limit.
- [x] **Real-file visual acceptance of effects:** a generated effects SVG
  (gradient, blur, mask, clipPath, alpha, CJK text) and the real complex-path
  “Airy Blue Sky” SVG were rendered and visually inspected. The effects sample is
  local/uncommitted; broader real-user samples remain optional.

## P1 — Design, aesthetics and UI/UX

The design direction and current baseline review are in `docs/DESIGN.md`. These
tasks are required for "complete the v0.1 experience", not optional polish.

- [x] **D1 — Visual audit and design tokens:** screenshot matrix captured at
  default and minimum size, light/dark, four locales, and empty/valid/invalid/
  converting/failed/done/alert states; tokens and review notes are in `DESIGN.md`.
- [x] **D2 — Brand and app icon:** geometric exchange-arrow icon in the
  PilotFoundry green/cream language, orange arrowhead accent, `assets/AppIcon.svg`,
  `scripts/build-icon`, bundled icns, empty-state brand mark; About panel inherits
  the app icon. The Dock tile is set explicitly at launch and was verified in a
  captured Dock screenshot.
- [x] **D3 — Window chrome and macOS conventions:** native unified toolbar
  (Add Files, Output Folder), standard app menu, File/Window/Help menus,
  Close/Minimize/Zoom, window frame autosave and verified menu Quit behavior.
- [x] **D4 — Empty state and first-run guidance:** formats, add/drop and the
  local-processing/source-preservation boundary are shown without marketing or
  install copy.
- [x] **D5 — Queue row and batch status design:** filename/format/status, invalid
  badge, selection state, completed/failed/pending counts, stable drop ordering,
  64 px ImageIO thumbnails and checkerboard previews; no full-size decode in the
  row body.
- [x] **D6 — Inspector information architecture:** Source / Output / Result are
  grouped; source/target dimensions, video duration, output size and bounded
  512 px preview are shown; result actions are inline.
- [x] **D7 — Action hierarchy and feedback:** one primary Convert, clear Cancel,
  per-item Retry/Convert Again, Clear Completed/All, output-folder affordance,
  drag-over feedback and inline invalid reasons.
- [x] **D8 — Light/dark, typography and localization:** light and dark captures,
  sentence-case section labels, file/file pluralization, four-language empty and
  populated states, CJK line-height review, monospaced dimensions/paths.
- [ ] **D9 — Accessibility and keyboard:** AX labels are added for rows, pickers,
  fields, previews and icon-only controls; Cmd+Return keyboard-only conversion was
  verified. Live VoiceOver announcements, full focus-order review and Reduce Motion
  remain manual acceptance.
- [ ] **D10 — Design acceptance gate:** screenshot matrix, heuristic scorecard and
  review record are in `DESIGN.md`/`TESTING.md`; final gate remains open until the
  manual VoiceOver/focus-order pass is recorded.

## P1 — Workflow and product behavior

- [x] Add single-task retry/reconvert and clear-completed/clear-queue actions.
- [x] Preserve access to existing output while changing options: the previous
  result card stays reachable until a new run publishes its replacement.
- [x] Define queue behavior for files added mid-run: new files join the next run;
  drop ordering is stable and completed/failed/pending counts are shown.
- [x] Clarify apply-to-similar scope: completed work is no longer reset.
- [x] Preserve useful size preferences explicitly: width and scale are saved;
  photos default to 1× while SVG/video keep 2×.
- [x] Display output path unambiguously (home-abbreviated full path with middle
  truncation); moved/deleted results are shown as unavailable, and missing or
  unwritable destinations are rejected before conversion.
- [x] Show engine readiness before conversion in the bottom bar; install commands
  remain in developer help rather than the normal recovery flow.
- [ ] Verify drag/drop, Finder Open With and opening files before window creation;
  reject directories/unsupported items with useful feedback.
- [x] Read the About-panel version from `Info.plist`.
- [ ] Offer dragging/copying exported files if real use shows Finder reveal is slow.

## P1 — Reliability hardening (from the 2026-11-06 review)

- [x] Stale temporary output cleanup: age-based cleanup (>24 h) removes
  `.transcodepilot-*` and `transcodepilot-process-*` without touching active work.
- [x] Disk-space preflight and write-failure recovery; disk-full is a separate
  typed failure from permission/volume errors.
- [x] Source TOCTOU and actual type verification: fresh size/mtime signature is
  rechecked before publication; engines probe/decode actual content.
- [x] Output filename limits: very long Unicode names are converted with a
  UTF-8-byte-bounded stem; checks assert the resulting filename stays ≤255 bytes.
  Case-insensitive/NFC/NFD and non-APFS fallback remain future volume-specific work.
- [x] Stronger production output verification: MP3 codec + duration, decoded
  image dimensions, and existing publication checks.
- [x] Engine discovery and version readiness: `Tools.find` includes PATH;
  `scripts/doctor` checks bundled Helpers first and prints versions.
- [ ] TCC-protected folders and persisted output paths: stale/revoked output
  folders are handled and output paths are shown in full. Desktop/Downloads TCC
  acceptance remains manual because it may prompt the user.
- [ ] Engine resource limits and residual-risk documentation: timeouts, probe
  bounds and bounded child termination are implemented and the renderer trust
  boundary is documented, but explicit memory/CPU rlimit caps for rsvg/ffmpeg
  remain unimplemented.

## P1 — Meaningful regression coverage

- [x] Assert actual transparent/colored pixels plus enlarged-SVG edge sharpness;
  HEIC/Display P3 and synthetic effects are covered. A real camera opaque/alpha
  file remains optional manual evidence.
- [x] Cover HEIC (ImageIO-generated), PNG → JPG, JPEG → PNG, mirrored EXIF,
  Display P3 → sRGB conversion and the documented metadata policy. Real camera
  HEIC/ICC files remain a manual acceptance item.
- [x] Cover CJK SVGs and CDATA/decoded external-resource rejection.
- [x] Test actual output duration, bitrate tolerance, multiple audio streams,
  corrupt MP4/MKV, long filenames and non-ASCII/space-containing paths.
- [ ] Test timeout, real conversion cancellation, denied write, engine missing,
  concurrent filename collisions, output disconnect and cleanup after failure.
  Timeout, in-flight cancellation, denied write, concurrent collisions and quit
  termination are covered; engine-missing and output-disconnect need
  injected/manual fixtures.
- [ ] Cover queue state transitions and termination; GUI quit during conversion is
  manually verified (~0.5 s, no temp/child leak), but core tests still do not
  exercise the UI model.
- [x] Put localization parity, plist/bundle/signature checks into repeatable
  commands via `make verify` and `scripts/verify-release`.
- [x] Document remaining manual checks honestly in `docs/TESTING.md` and
  `docs/RELEASE.md`; build success is not treated as visual/VoiceOver acceptance.

## P2 — Public source and portable release

- [x] Create `PilotFoundry/TranscodePilot`, configure remote, publish source and
  maintain the public repository (remote, tags, Releases, CI, branch protection).
- [x] Add CI workflow for core checks, app packaging, localization and policy
  validation; hosted CI passes on `macos-latest`. Engine pinning remains deferred.
- [x] Publish tags/GitHub Releases, CODEOWNERS/maintainers, Discussions, private
  vulnerability reporting, Dependabot and required status checks on `main`.
- [ ] Choose distributable FFmpeg/librsvg builds, minimum OS and architectures;
  bundle all needed libraries/fonts/config without Homebrew absolute paths.
- [ ] Audit engine licenses/configuration and supply third-party notices, source
  availability/build instructions and other applicable redistribution obligations.
- [x] Build Release configuration; Debug remains for development.
- [x] Clean/repeatable app packaging: the bundle is recreated from scratch before
  copying resources; the deprecated build backend was already replaced.
- [x] Release ZIP/checksum/version validation implemented and re-verified locally.
  Clean-Mac installation remains external.
- [x] Narrowed the support claim to tested Apple Silicon macOS 27; macOS 14 and
  Intel remain unvalidated, with no support claim.
- [ ] Sign/notarize if Developer ID credentials become available; otherwise
  describe the ad-hoc preview and Gatekeeper behavior accurately. Ad-hoc preview
  is documented; credentials are absent.
- [x] Localized README entry points, screenshots, changelog, support/security
  guidance, contribution instructions and release acceptance record added.
- [ ] Update PilotFoundry organization profile when the project is published.
- [ ] Recheck/register selected domain if desired; complete formal trademark
  review in intended markets. Earlier searches were preliminary, not clearance.

## P3 — Demand-driven additions (not v0.1 blockers)

- [ ] Rank additional formats using actual usage: WebP input/output, MOV/M4A/WAV
  audio extraction/conversion, then other genuinely recurring combinations.
- [ ] Define a local manual usage ledger (no telemetry) so format decisions are
  evidence-based.
- [ ] Consider Finder Quick Actions / Shortcuts after the window workflow is stable.
- [ ] Evaluate safe embedded SVG image support; evaluate HTML/foreignObject only
  against real samples and a renderer with an explicit local resource policy.
- [ ] Add useful named presets only after repeated parameter patterns emerge.

## Explicitly deferred

Cloud/accounts, telemetry, editor timelines, watch folders, plugin frameworks,
unbounded parallel conversion, document conversion and an all-format promise.
No background service or permanent menu-bar item without demonstrated need.
