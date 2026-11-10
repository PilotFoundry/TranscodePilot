# TranscodePilot v0.1

Goal: a local macOS window for SVG/bitmap → PNG/JPEG and MP4/MKV → MP3.

Architecture: Swift Package with an AppKit/SwiftUI executable, UI-independent
conversion core, and an assert-based checks executable (compatible with CLT).
ImageIO handles bitmaps; locally installed librsvg and FFmpeg handle SVG/audio.
No network access, telemetry, login item, destructive overwrite, or private API.

## Execution checklist

- [x] Core: validate dimensions, formats and SVG resources; fail checks first,
  then implement actual conversions and non-overwriting output publication.
  Files: `Conversion.swift`, `ProcessRunner.swift`, `SVGDocument.swift`, `Checks.swift`.
- [x] App: file import/drop, batch queue, per-file options, preview, cancellation,
  retry, output directory and Finder reveal. Files: `AppModel.swift`, `MainView.swift`,
  `main.swift`, `Localizable.strings` in four locales.
- [x] Delivery: app bundle, dependency diagnostics, build/check commands,
  license and README. Files: `scripts/`, `Makefile`, `Info.plist`, documentation.
- [x] Verify: `make check`, `make app`, signature/bundle validation and app launch.
  Document manual visual/accessibility and distribution checks still pending.
- [x] Phase 1 review batch (2026-11-06): local Git baseline and reproducible build
  flags; bounded input preflight and shared conversion planning; sanitized stored
  preferences and inline validation/estimates; bitmap cancellation checks and a
  real child grace wait; cancel-then-quit, close blocking and Dock reopen.

## Acceptance

Checks create real SVG/bitmap/video fixtures and reopen outputs to verify pixels,
alpha flattening and MP3 duration. Reject external SVG resources and unsupported
HTML/script content; limit image allocation, time out child processes, preserve
source/existing output, remove temporary files, and stop children on cancellation.

Development dependencies are explicit, not bundled. Public standalone distribution
requires separately audited portable engines, licenses, architectures and signing.
No release upload, remote repository creation or domain purchase in this task.

## Recorded verification — 2026-11-05

- `make check`: PASS for real SVG/bitmap/MP4 fixtures, including EXIF rotation.
- `make app`: PASS; ad-hoc bundle signature verifies.
- `make doctor`: PASS for local ffmpeg, ffprobe and rsvg-convert.
- Application launched and process remained running. Visual interaction,
  VoiceOver, Intel and macOS 14 acceptance remain unexecuted.
- CLT build uses SwiftPM's native backend explicitly; Swift 6.4 emits a
  deprecation notice for that backend, but compilation and checks pass.
  (Superseded on 2026-11-06: the default SwiftPM backend is used now.)

## Phase 1 — 2026-11-06

- Git baseline commit recorded locally; no remote exists. `Makefile` and
  `scripts/build-app` accept optional `SWIFT_FLAGS`; the default SwiftPM backend
  is used (the `native` backend is deprecated).
- Core: `InputFile` rejects unreadable/empty/non-regular files and checks SVG
  size before `Data(contentsOf:)`; `SourceInspector`/`ConversionPlanner` share
  dimension limits with the conversion path; stored scale/quality/bitrate
  values are sanitized; bitmap conversions check cancellation between stages;
  cancelled child processes get a real grace period before SIGKILL.
- App: invalid/oversized widths and output-limit failures show inline, estimated
  output dimensions are displayed, and Convert is disabled while any pending
  item is invalid; conversion during quit is cancelled and termination is
  retried after cleanup (up to 5 s); window close is blocked while converting;
  Dock reopen restores the window; localization lookup no longer force-unwraps.
- GUI acceptance (2026-11-10) found and fixed a disabled app-menu Quit item. It is
  now explicitly targeted at NSApp, and the termination wait uses main-queue
  scheduling rather than a default-mode timer.
- Checks: added empty/oversized/corrupt/directory inputs, extreme aspect ratio,
  symlink source, cancelled conversion, planner estimates and preference
  sanitizing.

### Recorded verification — 2026-11-06

- `make doctor`: PASS.
- `make check SWIFT_FLAGS=--disable-sandbox`: PASS (three PASS groups).
- `make app SWIFT_FLAGS=--disable-sandbox`: PASS; ad-hoc signature verifies.
- App smoke launch: process started; no visual or interaction acceptance performed.
- Four `Localizable.strings` tables: 45 keys each, key sets identical;
  `plutil -lint` passes.
- Environment caveat: plain `make check`/`make app` fail inside this agent session
  because SwiftPM invokes `sandbox-exec`; `--disable-sandbox` is only for this
  restricted environment. CLT has no XCTest, so checks stay executable-based.
- Still manual/pending: real quit/close interaction acceptance, VoiceOver and
  light/dark review, user-provided SVG/MP4 samples, exFAT/network destinations,
  Intel and macOS 14.

## GUI acceptance — 2026-11-10

`agent-desktop` 1.2.0 drove the built bundle through its AX tree (headless refs;
Accessibility and Screen Recording granted by the user). This tool is a
development verification aid, not an application dependency.

- Real UI batch conversion: photo/SVG/MP4 → PNG/MP3; outputs reopened from disk;
  MP3 codec and 600.003 s duration verified.
- Inline validation: width -1/16385 → localized width error and disabled Convert;
  width 16000 → 40 MP limit error and disabled Convert; width 0 → 6,000 × 4,000
  estimate and enabled Convert. SVG 800×500 at 2× → 1,600 × 1,000; at width 4000
  → 4,000 × 2,500.
- Window close during conversion: alert “正在转换 / 请等待当前转换完成，或先取消转换。”;
  window remains and conversion continues.
- Cancel during a 2-hour MP3 GUI conversion: status “已取消”, no ffmpeg child, no
  `.transcodepilot-*` directory, no partial MP3.
- Quit during conversion after the fix: ⌘Q exits in ~0.4 s, child process gone,
  temporary directory gone, no partial output.
- Real user SVG (2700×1030 CJK swimlane): rendered correctly at 1× (2700×1030)
  and 2× (5400×2060); nodes, CJK labels and connector lines were visually present.
- Real user MP4 (iShot screen recording): ffprobe reports only an h264 video
  stream and no audio; the app correctly reports “This video has no audio track.”
  and produces no output.
- Real user MP4 with audio (HEVC + AAC mono, 11.467755 s audio): converted through
  the UI to MP3 192 kbps, 44.1 kHz mono, 11.469206 s (~1.5 ms longer); source hash
  unchanged, no child process or temporary directory left.
- Real user complex-path SVG (“Airy Blue Sky with Puffy Clouds”, 1672×941, 381
  paths, opaque): rendered at 1× (1672×941) and 4× (6688×3764); paths, colors and
  edges were visually complete.
- Generated MKV sample (H.264 + AAC 440 Hz first track, 880 Hz second track):
  converted to an 8.000 s MP3; FFT dominant frequency was 440 Hz, confirming
  first-track selection; source hash unchanged.
- Smallest home MKV (23.5-minute screen recording, 81.7 MB, stereo AAC):
  converted through the GUI to a 1410.667 s MP3 (source duration 1410.734 s);
  source hash unchanged; the personal MP3 output was deleted after verification.
- Remaining manual acceptance: real SVGs with gradients/masks/filters/alpha,
  SVG/bitmap in-flight cancellation, VoiceOver/light-dark, exFAT/network
  destinations, Intel and macOS 14.

## SVG effects fixture corpus — 2026-11-10

- Added `Sources/TranscodePilotChecks/Fixtures/SVGEffects/` (synthetic SVGs plus a
  README): linear and radial gradients, Gaussian blur, `feColorMatrix`, mask,
  clipPath and fill-opacity transparency.
- `make check` now converts every fixture and samples real output pixels:
  gradient stops, transparent regions, blur bleed, red-to-green matrix output,
  masked halves, clipped corners, partial alpha and JPEG white flattening.
- These fixtures are intentionally part of the checks target resources, so
  `make check` exercises them on every conversion iteration.

## Design shell — 2026-11-10

- Replaced the custom in-window header with a native unified `NSToolbar`
  (Add Files, Output Folder); the window title is now the native titlebar.
- Added standard app menu items, File/Window/Help menus, explicit Close/Minimize/
  Zoom actions, window frame autosave and a Help sheet.
- Added a PilotFoundry-family geometric exchange-arrow app icon:
  `assets/AppIcon.svg`, `scripts/build-icon`, bundled `AppIcon.icns`, and
  `CFBundleIconFile`; the empty state and the running app's Dock tile use the
  bundled icon explicitly (`NSApp.applicationIconImage`).
- Controls now use the system accent; orange is reserved for the brand icon.
  Added shared spacing/radius/palette tokens in `DesignSystem.swift`.
- Verified menu Quit exits immediately (`agent-desktop` click on Quit item);
  light default-size screenshots of empty and populated states were captured.
- Still pending: D1 full light/dark/min-size/four-locale screenshot matrix,
  D4–D10 visual/UX tasks and design scorecard sign-off.

## SVG sizing and MKV — 2026-11-10

- SVG parser now resolves `px`, physical units at a 96 dpi reference, `viewBox`
  dimensions, percentages against a viewBox, one missing dimension from the
  viewBox aspect, and fractional sizes. Percentage/unitless SVGs without a
  viewBox and SVGs without dimensions/viewBox are rejected with app-owned
  messages.
- Explicit width is rendered with renderer width-only and verified to be exact;
  scale mode uses renderer zoom. Output dimensions are read back before
  publication, so requested and actual size cannot silently diverge.
- Added `Fixtures/SVGSizing/` and `checkSVGSizing`: physical units, viewBox-only,
  percentage, one-dimension, fractional, explicit width, unsupported percentage
  and missing-dimension rejection. `make check` passes.
- Added MKV support: `.mkv` files use the MP3 path with an explicit `matroska`
  demuxer for both ffprobe and ffmpeg; file picker, document types, empty-state
  format list and README are updated.
- Verification: `make check` PASS; GUI converted a synthetic MKV → MP3 in about
  1.1 s; GUI sizing fixture rendered 96 × 48 px at 1× with the same estimate.

## P0 hardening batch — 2026-11-10

- SVG boundary: root namespace validation, additional animation/handler tags,
  CDATA-aware style collection and self-contained CSS at-rules are now handled.
  Added `Fixtures/SVGSecurity` with foreign-namespace, animation, discard and
  external-href rejections plus a safe `@media` acceptance case.
- Output publication: the destination volume must report hard-link support before
  conversion starts; APFS temp/publication checks still pass. Real exFAT/network
  volume acceptance remains outstanding because the local disk-image mount was
  not available.
- Media trust: ffprobe/ffmpeg use the protocol whitelist, explicit demuxer and
  bounded probe size/duration; corrupt MP4/MKV containers are rejected by checks.
- Residual risk remains documented: SVG validation is a coarse local policy, not a
  general sandbox around the external renderer.

## Error UX and recovery — 2026-11-10

- Core failures now carry a typed `ConversionErrorCode` and optional technical
  detail. App-owned text is localized in en / zh-Hans / zh-Hant / ja; engine stderr
  remains English detail by policy. A disk-full publication failure has its own
  code, distinct from output-folder permission and volume-support failures.
- Failed items show Retry; publication failures additionally offer Choose Output
  Folder. Validation errors remain inline and disable Convert.
- GUI acceptance: a corrupt MP4 produced the localized “转换引擎失败。” message with
  English engine detail and a working Retry button.

## Queue and workflow — 2026-11-10

- Added Retry for failed items and Convert Again for completed items, plus
  Clear Completed / Clear All queue actions.
- Files added while a conversion is running join the next run; the active job
  list is snapshotted. Drag/drop URLs are collected by index so queue ordering is
  independent of provider completion order. Completed/failed/pending counts are
  shown in the queue footer.
- apply-to-similar now skips completed items, preserving their output.
- Width and scale are persisted; photos default to 1× while SVG/video keep 2×.
- Engine readiness is shown in the bottom bar; About version comes from
  `Info.plist`.
