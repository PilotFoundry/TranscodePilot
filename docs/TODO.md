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
  feColorMatrix, mask, clipPath and fill-opacity/JPEG flattening. `make check`
  now has four PASS groups. Test coverage is automated and repeatable.
- Remaining P0 blockers: SVG trust boundary, SVG sizing, in-flight SVG/bitmap
  cancellation acceptance, non-APFS publication, app-owned error UX/localization,
  MP4/FFmpeg trust boundary, and real-file visual acceptance of effects.
- Design/UIUX is now a first-class workstream; its baseline and review method are
  in `docs/DESIGN.md`.

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
- [x] Ad-hoc app build/signature; four `make check` PASS groups; doctor pass.

## Next landing plan

### Iteration A (recommended next): design baseline + SVG sizing

1. **Design baseline (D1/D2/D3):** capture the current app in the review matrix
   (empty, queue, inspector, invalid, converting, done, failed, alert; light/dark;
   default/min window sizes; four locales), decide accent/brand direction and
   custom-header vs native-toolbar, record tokens in `docs/DESIGN.md`.
2. **SVG sizing (P0):** implement the agreed rules — 96 dpi physical units,
   explicit width through renderer width-only, scale through zoom, documented
   percentage/missing-size behavior, requested width exact and height tolerance
   ±1 px; verify requested vs actual output.
3. **UI integration:** make estimated dimensions, source dimensions and errors
   use the same sizing/validation source so the inspector never contradicts the
   converted output.
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

- [ ] **Audit SVG trust boundary:** validate namespace handling, decoded CSS,
  CDATA/comments, URLs, XML entities and unsupported animation variants; explicitly
  detect missing content where feasible. Test actual file/network resource denial.
  Current lexical checks are not a general SVG sandbox.
- [ ] **Define SVG sizing correctly:** px, viewBox-only, missing one dimension,
  percentages, physical units and fractional sizes. Do not reinterpret mm/cm SVG
  dimensions as viewBox pixels without a clear rule. Confirm requested vs actual
  size; the real 1×/2×/4× samples already exposed renderer rounding and unit
  ambiguity.
- [ ] **Cancel during actual conversions:** GUI cancel of FFmpeg is verified; add
  targeted SVG/bitmap in-flight cancellation acceptance and verify checks between
  decode/draw/encode stages.
- [ ] **Output filesystem compatibility:** add safe non-overwriting publication for
  exFAT/FAT/network volumes or reject unsupported destinations before processing.
  Keep APFS atomic publication and collision safety.
- [ ] **User-friendly failures:** localize app-owned errors, distinguish missing
  engine/no audio/invalid SVG/permission/disk-full cases, and offer a recovery
  action. Engine detail may remain English; app-owned text must not.
- [ ] **MP4/FFmpeg trust boundary and resource limits:** preflight input type/size,
  bound probe/scan behavior, keep protocol restrictions, truncate/attribute engine
  stderr, and test corrupt/huge MP4s.
- [ ] **Real-file visual acceptance of effects:** synthetic fixtures cover renderer
  behavior, but real SVGs with gradients/masks/filters/transparency still need a
  visual pass. Sample files stay local and uncommitted.

## P1 — Design, aesthetics and UI/UX

The design direction and current baseline review are in `docs/DESIGN.md`. These
tasks are required for "complete the v0.1 experience", not optional polish.

- [ ] **D1 — Visual audit and design tokens:** record the current app in the
  screenshot matrix; define typography roles, spacing scale, semantic color,
  icon weight, corner radii and light/dark rules. Add tokens to `DESIGN.md`.
- [ ] **D2 — Brand and app icon:** create a distinct PilotFoundry-family icon and
  bundle assets; update About panel and icon presence in Finder/Dock. Do not copy
  sibling-app artwork.
- [ ] **D3 — Window chrome and macOS conventions:** decide native toolbar vs
  custom header; add File/Window/Help menus, Close/Minimize/Zoom, window frame
  restoration, and ensure quit/close semantics are discoverable.
- [ ] **D4 — Empty state and first-run guidance:** explain supported formats,
  add/drop behavior and the local-engine boundary in the empty state without
  marketing copy; avoid install commands in the normal end-user path.
- [ ] **D5 — Queue row and batch status design:** readable filename/format/status,
  invalid badge, selection state, completed/failed/remaining counts, stable drop
  ordering and optional bounded thumbnails (checkerboard for transparency).
  Do not decode full 40 MP previews inside `View.body`.
- [ ] **D6 — Inspector information architecture:** group Source / Output / Result;
  show source and target dimensions, output size and audio duration; keep only
  relevant controls visible; bound previews and add a clear result/reveal action.
- [ ] **D7 — Action hierarchy and feedback:** one primary Convert action, clear
  Cancel state, per-item retry/reconvert and clear-completed actions, output-folder
  affordance, drag-over feedback, and copy that explains why a control is disabled.
- [ ] **D8 — Light/dark, typography and localization:** actual light/dark review,
  contrast targets, no all-caps inconsistency, CJK line height, four-language
  pluralization/overflow and monospaced dimensions/paths.
- [ ] **D9 — Accessibility and keyboard:** labels/hints for icon-only controls,
  focus order, keyboard-only primary flow, VoiceOver names/states/announcements,
  Reduce Motion behavior and adequate hit targets.
- [ ] **D10 — Design acceptance gate:** maintain the screenshot matrix, heuristic
  scorecard and review record; update `TESTING.md`; do not treat build success as
  visual acceptance.

## P1 — Workflow and product behavior

- [ ] Add single-task retry/reconvert and clear-completed/clear-queue actions.
  Preserve access to existing output while changing options where practical.
- [ ] Define queue behavior for files added mid-run: next run vs current run;
  keep drop ordering stable and show completed/failed/remaining counts.
- [ ] Clarify apply-to-similar scope: avoid unexpectedly resetting completed work.
- [ ] Preserve useful size preferences explicitly; width is not saved. Separate
  sensible SVG and bitmap defaults so photos are not enlarged by default.
- [ ] Display output path unambiguously when two folders share a name; handle
  moved/deleted output, revoked destination and unmounted volumes gracefully.
- [ ] Show engine readiness before conversion; keep install commands in developer
  help, not the normal end-user recovery flow for a packaged release.
- [ ] Verify drag/drop, Finder Open With and opening files before window creation;
  reject directories/unsupported items with useful feedback.
- [ ] Read version from `Info.plist` rather than hardcoding the About-panel version.
- [ ] Offer dragging/copying exported files if real use shows Finder reveal is slow.

## P1 — Reliability hardening (from the 2026-11-06 review)

- [ ] Stale temporary output cleanup: `.transcodepilot-*` and
  `transcodepilot-process-*` can survive crash/force-quit; define age-based
  cleanup that never touches active instances.
- [ ] Disk-space preflight and write-failure recovery; distinguish disk-full from
  permission errors.
- [ ] Source TOCTOU and actual type verification: revalidate before conversion;
  do not rely on extension alone.
- [ ] Output filename limits: long names, NFC/NFD, case-insensitive volumes and
  future non-APFS fallback.
- [ ] Stronger production output verification: decoded content/audio codec, not
  only dimensions/duration.
- [ ] Engine discovery and version readiness: `Tools.find` ignores PATH;
  `scripts/doctor` and bundled Helpers disagree; versions are unchecked.
- [ ] TCC-protected folders and persisted output paths: test
  Desktop/Documents/Downloads access and stale/revoked output folders.
- [ ] Engine resource limits and residual-risk documentation: memory/CPU caps for
  rsvg/ffmpeg and an honest statement of the remaining trust boundary.

## P1 — Meaningful regression coverage

- [ ] Assert actual transparent pixels and colored content, not only an alpha
  channel or image dimensions. Synthetic effects fixtures now do this; add HEIC
  and real opaque/alpha edge cases. Check edge sharpness at enlarged SVG sizes.
- [ ] Cover real HEIC, PNG → JPG, JPEG → PNG, mirrored EXIF orientations, ICC/P3
  input and the documented sRGB/metadata/HDR policy.
- [ ] Cover viewBox/units/CJK SVGs and decoded/CDATA external-resource cases.
  Synthetic gradient/filter/mask/clip/transparency fixtures are covered; viewBox/
  units, automated CJK and decoded/CDATA cases remain.
- [ ] Test actual output duration, bitrate tolerance, multiple audio streams,
  corrupt MP4s, long filenames and non-ASCII/space-containing paths.
- [ ] Test timeout, real conversion cancellation, denied write, engine missing,
  concurrent filename collisions, output disconnect and cleanup after failure.
- [ ] Cover queue state transitions and termination; core tests still do not test
  the UI model (GUI quit behavior is manually verified).
- [ ] Put localization parity, plist/bundle/signature checks into repeatable
  commands. These were run ad hoc during initial build.
- [ ] Document remaining manual checks honestly; do not equate successful launch
  with visual, keyboard, drag/drop or accessibility acceptance.

## P2 — Public source and portable release

- [ ] Create `PilotFoundry/transcodepilot`, configure remote, and publish source
  when authorized. No remote repository exists as part of this implementation.
- [ ] Add CI for core checks, app packaging, localization and policy validation;
  provision pinned engine versions on CI rather than relying on a local Mac.
- [ ] Choose distributable FFmpeg/librsvg builds, minimum OS and architectures;
  bundle all needed libraries/fonts/config without Homebrew absolute paths.
- [ ] Audit engine licenses/configuration and supply third-party notices, source
  availability/build instructions and other applicable redistribution obligations.
- [ ] Build Release configuration; retain Debug for development only.
- [ ] Make app packaging clean/repeatable so removed resources do not remain in an
  old bundle. Replace deprecated build backend. (Backend replacement is done;
  packaging cleanup remains.)
- [ ] Add release ZIP/checksum/version validation; test installing on a clean Mac
  with no Homebrew, project checkout or build directory.
- [ ] Validate Intel and macOS 14 or narrow the support claim to tested systems.
- [ ] Sign/notarize if Developer ID credentials become available; otherwise
  describe the ad-hoc preview and Gatekeeper behavior accurately.
- [ ] Add localized README entry points, screenshots, changelog, support/security
  guidance, contribution instructions and release acceptance record.
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
