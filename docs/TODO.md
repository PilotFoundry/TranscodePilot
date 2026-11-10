# TranscodePilot backlog

Updated: 2026-11-10. Scope: independent PilotFoundry macOS media converter.
This is a source review backlog, not a claim that every potential defect has
been reproduced. Checked items record existing work; unchecked items remain.

## Current baseline

- [x] Native AppKit/SwiftUI application window and file import/drop implementation.
- [x] SVG → PNG/JPEG using locally installed librsvg.
- [x] PNG/JPEG/HEIC → PNG/JPEG using ImageIO.
- [x] MP4 first audio track → MP3 using locally installed FFmpeg.
- [x] Batch queue, per-file settings, apply-to-similar, cancel/retry implementation.
- [x] Source preservation, collision avoidance and exported image preview.
- [x] Four base UI localization tables and local ad-hoc app packaging.
- [x] Core fixture checks passed during initial implementation; app launched.
- [x] Local Git baseline recorded on 2026-11-06; baseline checks re-run during
  review (see `docs/IMPLEMENTATION.md` and `docs/TESTING.md`).

## Review decisions — 2026-11-06

Scope and defaults agreed before implementation:

- Phase 0: local Git baseline and reproducible build flags; Phase 1: bounded
  inputs, inline validation/estimates, cancellation and clean quit/close.
  SVG sizing, trust-boundary validation and non-APFS publication come next.
- Quit during conversion: auto-cancel, wait up to 5 s for child/temporary
  cleanup, then quit; closing the window is blocked while converting; Dock
  reopen restores the window.
- Hard-link-less destinations: preflight and reject in v0.1; a copy fallback is
  deferred.
- SVG sizing rules for the next phase: physical units at 96 dpi; explicit width
  via rsvg width-only; scale via `--zoom`; percentages/missing sizes documented;
  requested width exact, height tolerance ±1 px.
- Real-file samples remain pending from the user and must not be committed.
- This sandboxed agent session runs SwiftPM with `SWIFT_FLAGS=--disable-sandbox`;
  the default SwiftPM backend is now used (native backend deprecated), and CLT
  has no XCTest, so regression checks stay executable-based.

## GUI verification — 2026-11-10

Verified against the built bundle with `agent-desktop` 1.2.0 (accessibility tree,
headless refs/clicks; Accessibility and Screen Recording granted by the user):

- Batch converted photo/SVG/MP4 through the real UI; PNG outputs, MP3 codec and
  600.003 s duration verified from disk.
- Inline validation: width -1 and 16385 show the localized width error and disable
  Convert; width 16000 shows the 40 MP limit error and disables Convert; width 0
  restores the 6,000 × 4,000 estimate and enables Convert.
- Closing the window during conversion shows “正在转换 / 请等待当前转换完成，或先取消转换。”
  and keeps the app alive.
- Cancel during a 2-hour MP3 conversion: status “已取消”, no ffmpeg process, no
  `.transcodepilot-*` directory, no partial MP3.
- Found and fixed a real quit defect: the app-menu Quit item had no target and was
  disabled, so ⌘Q did nothing. After targeting NSApp and moving the termination
  wait to main-queue scheduling, ⌘Q during conversion exits in about 0.4 s with
  no child or temporary-file leaks.
- Real-file pass: the user's 2700×1030 CJK swimlane SVG rendered correctly at
  1× (2700×1030) and 2× (5400×2060); all CJK labels and connector lines were
  visually present. A supplied MP4 without audio was correctly rejected with
  “This video has no audio track.” and produced no MP3. A second supplied MP4
  (HEVC + AAC mono) converted to MP3 at 192 kbps, 44.1 kHz mono, 11.469206 s
  versus an 11.467755 s source audio track (about 1.5 ms difference). The
  “Airy Blue Sky with Puffy Clouds” SVG (1672×941, 381 paths) rendered correctly
  at 1× (1672×941) and 4× (6688×3764), with no missing paths or blank regions.
- Not yet covered: real SVGs with gradients/masks/filters/alpha (the samples above
  do not contain those features), SVG/bitmap in-flight cancellation,
  VoiceOver/light-dark, and exFAT/network volumes.

## P0 — Reliable daily use

- [x] **Initialize local Git and record the reviewed baseline:** `git init -b main`
  and a local baseline commit are recorded; no remote exists. `.build/`, app
  bundles and personal fixtures remain ignored; later changes are committed in
  small verified steps.

- [x] **Quit/close during conversion:** cancel, wait for cleanup, then complete the
  requested quit. Closing the window during conversion is blocked with an alert;
  idle close/quit and quit-during-conversion are now verified. A disabled app-menu
  Quit item was found during GUI acceptance and fixed by targeting NSApp and
  scheduling the termination wait on the main queue.
- [x] **Parameter validation before Start:** show invalid/negative/oversized width
  inline, disable conversion when invalid, and show estimated output dimensions.
  Clamp restored preferences; an invalid stored quality must not crash `Int(...)`.
  Completed during Phase 1 and GUI-verified on 2026-11-10 (inline width/limit
  messages, planner-based estimate, disabled Convert, sanitized stored preferences
  and safe quality formatting).
- [x] **Bound resource use before decoding:** check SVG file size before
  `Data(contentsOf:)`; validate finite/positive source dimensions before division
  or conversion to Int. Test extreme aspect ratios and malformed image headers.
  Completed during Phase 1 (on-disk size/regular-file preflight, shared planner
  limits, extreme-aspect and malformed-input coverage).
- [ ] **Audit SVG trust boundary:** validate namespace handling, decoded CSS,
  CDATA/comments, URLs, XML entities and unsupported animation variants; explicitly
  detect missing content where feasible. Test actual file/network resource denial.
  Current lexical checks are not a general SVG sandbox.
- [ ] **Define SVG sizing correctly:** px, viewBox-only, missing one dimension,
  percentages, physical units and fractional sizes. Do not reinterpret mm/cm SVG
  dimensions as viewBox pixels without a clear rule. Confirm requested vs actual size.
- [ ] **Cancel during actual conversions:** test FFmpeg, SVG rendering and bitmap
  processing. Check cancellation between decode/draw/encode stages; currently bitmap
  work can continue until final publication. Fix child grace delay using a wait that
  is not immediately cancelled; current `try? Task.sleep` skips its intended delay.
  Phase 1 added bitmap stage checks and a real grace wait. GUI cancellation of an
  FFmpeg MP3 conversion is verified (status, child process, temporary directory and
  output checks); SVG/bitmap in-flight cancellation acceptance remains.
- [ ] **Output filesystem compatibility:** add safe non-overwriting publication for
  exFAT/FAT/network volumes or reject unsupported destinations before processing.
  Keep APFS atomic publication and collision safety.
- [ ] **Real-file acceptance:** collect non-sensitive representative SVGs and MP4s;
  compare gradients, masks, filters, CJK typography, alpha edges and audio duration.
  Partial 2026-11-10: CJK swimlane and complex-path cloud SVGs rendered correctly
  at 1×/2×/4×; a no-audio MP4 was correctly rejected; a second MP4 with AAC audio
  converted to MP3 at 192 kbps with a ~1.5 ms duration difference. Synthetic
  gradient/filter/mask/clip/transparency fixtures now run in `make check`, but
  real-file visual acceptance of those effects is still pending. Samples stay
  local and are not committed.
- [ ] **User-friendly failures:** localize app-owned errors, distinguish missing
  engine/no audio/invalid SVG/permission/disk-full cases, and offer a recovery action.

## New findings from the 2026-11-06 review

These were found while reviewing the plan and are not yet scheduled.

- [ ] **FFmpeg/MP4 trust boundary and resource limits:** extension-only dispatch,
  no input/output size cap, raw engine stderr shown, and ffprobe/ffmpeg scanning
  are not bounded beyond timeouts. Add preflight and corrupt/huge MP4 checks.
- [ ] **Stale temporary output cleanup:** `.transcodepilot-*` and
  `transcodepilot-process-*` can survive a crash or force-quit; define age-based
  cleanup without touching active instances.
- [ ] **Disk-space preflight and write-failure recovery:** distinguish disk-full
  from permission errors and recover cleanly.
- [ ] **Source TOCTOU and type verification:** revalidate the source before
  conversion; consider checking the actual format instead of the extension alone.
- [ ] **Output filename limits:** long names, NFC/NFD, case-insensitive volumes,
  and any future exFAT fallback.
- [ ] **Stronger production output verification:** image outputs currently verify
  dimensions only; audio verifies duration only. Verify decoded content/codec.
- [ ] **Engine discovery and version readiness:** `Tools.find` ignores PATH,
  `scripts/doctor` and bundled Helpers disagree, and engine versions are unchecked.
- [ ] **TCC-protected folders and persisted output paths:** test Desktop/Documents/
  Downloads access and stale/revoked output folders.
- [ ] **Engine resource limits and residual-risk documentation:** memory/CPU limits
  for rsvg/ffmpeg and an honest statement of the residual trust boundary.

## P1 — Complete the v0.1 experience

- [ ] Run an actual light/dark UI review at minimum and default window sizes.
- [ ] Add a distinct PilotFoundry-family app icon and bundle icon assets.
- [ ] Show source dimensions, target dimensions, output size and audio duration.
- [ ] Use bounded thumbnails outside `View.body`; avoid repeatedly loading full
  40 MP outputs when queue/selection changes. Use a checkerboard for transparency.
- [ ] Add single-task retry/reconvert and clear-completed/clear-queue actions.
  Preserve access to existing output while changing options where practical.
- [ ] Define queue behavior for files added mid-run: next run vs current run;
  keep drop ordering stable and show completed/failed/remaining counts.
- [ ] Clarify apply-to-similar scope: currently it affects all format-compatible
  inputs, including completed items; avoid unexpectedly resetting completed work.
- [ ] Preserve useful size preferences explicitly; width currently is not saved.
  Separate sensible SVG and bitmap defaults so photos are not enlarged by default.
- [ ] Display output path unambiguously when two folders have the same name;
  handle moved/deleted output and revoked/unmounted destination gracefully.
- [ ] Show engine readiness in the app before conversion; keep install commands
  in developer help, not the normal end-user recovery flow for a packaged release.
- [ ] Add File/Window menus, Close/Minimize commands and accessible labels for
  icon-only controls; verify keyboard focus, shortcuts and VoiceOver announcements.
- [ ] Verify drag/drop, Finder Open With and opening files before window creation;
  reject directories/unsupported items with useful feedback.
- [ ] Read version from Info.plist rather than hardcoding About-panel version.
- [ ] Finish four-language copy, pluralization and overflow acceptance. Add an
  explicit language selector only if needed; system-following is the baseline.
- [ ] Offer dragging/copying exported files if real use shows Finder reveal is slow.

## P1 — Meaningful regression coverage

- [ ] Assert actual transparent pixels and colored content, not only an alpha
  channel or image dimensions. Check edge sharpness at enlarged SVG dimensions.
- [ ] Cover real HEIC, PNG → JPG, JPEG → PNG, mirrored EXIF orientations, ICC/P3
  input and the documented sRGB/metadata/HDR policy.
- [ ] Cover viewBox/units/filters/CJK SVGs and decoded/CDATA external-resource cases.
  Synthetic gradient/filter/mask/clip/transparency fixtures are covered; viewBox/
  units, automated CJK and decoded/CDATA cases remain.
- [ ] Test actual output duration, bitrate tolerance, multiple audio streams,
  corrupt MP4s, long filenames and non-ASCII/space-containing paths.
- [ ] Test timeout, real conversion cancellation, denied write, engine missing,
  concurrent filename collisions, output disconnect and cleanup after failure.
- [ ] Cover queue state transitions and termination; core tests do not test UI model.
- [ ] Put localization parity, plist/bundle/signature checks into repeatable commands.
  These were run ad hoc during the initial build.
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
- [ ] Make app packaging clean/repeatable so removed resources do not remain in
  an old bundle. Replace deprecated build backend when the CLT environment permits.
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
- [ ] Consider Finder Quick Actions / Shortcuts after the window workflow is stable.
- [ ] Evaluate safe embedded SVG image support; evaluate HTML/foreignObject only
  against real samples and a renderer with an explicit local resource policy.
- [ ] Add useful named presets only after repeated parameter patterns emerge.

## Explicitly deferred

Cloud/accounts, telemetry, editor timelines, watch folders, plugin frameworks,
unbounded parallel conversion, document conversion and an all-format promise.
No background service or permanent menu-bar item without demonstrated need.

## Suggested order

1. Initialize Git and record the local baseline. (Done 2026-11-06.)
2. P0 correctness/security + matching regression checks. Phase 1 completed
   bounded inputs, inline validation/estimates, cancellation internals and
   quit/close; next are SVG sizing/trust, non-APFS publication, real-file
   acceptance and app-owned error localization.
3. Real daily-use acceptance, queue polish and native UI/accessibility.
4. Portable engine packaging, CI and public preview release.
5. Add formats one at a time based on the weekly usage ledger.
