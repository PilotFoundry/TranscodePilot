# Verification

`make check` creates temporary real fixtures, converts them, reopens outputs and
checks:

- SVG raster dimensions/alpha, JPEG white background, bitmap scaling and EXIF
  rotation, plus planner output estimates.
- Non-overwriting names, source preservation, symlinked sources and temporary
  cleanup.
- Unsafe SVG rejection, oversized/empty/corrupt/directory inputs and extreme
  aspect ratios.
- MP3 codec, silent-video rejection, child-process cancellation grace, cancelled
  conversion before publication and sanitized stored preferences.
- MKV audio extraction through the explicit matroska demuxer.
- Corrupt MP4/MKV containers are rejected; media probing is bounded.
- SVG security fixtures: foreign namespace, animation variants, discard and
  external href are rejected; self-contained `@media` remains accepted.
- Preference sanitizing includes kind-aware scale defaults and saved-width bounds.
- Source mutation detection and age-based temporary-directory cleanup.
- SVG sizing fixtures: physical units at 96 dpi, viewBox-only, percentage,
  missing-one-dimension, fractional sizes, explicit requested width and rejection
  of unsupported percentage/missing-dimension documents.
- SVG effects corpus: linear/radial gradients, Gaussian blur, feColorMatrix, mask,
  clipPath and fill-opacity transparency, including PNG alpha sampling and JPEG
  white flattening. Fixtures live in
  `Sources/TranscodePilotChecks/Fixtures/SVGEffects/` and run on every `make check`;
  add a case or adjust an assertion there when renderer behavior changes.

In a restricted or sandboxed build environment (for example the agent session
used for the 2026-11-06 verification), SwiftPM's internal sandbox cannot be
applied; run `make check SWIFT_FLAGS=--disable-sandbox` there. The flag is not
needed in a normal developer terminal.

`make app` builds and verifies the local ad-hoc signed bundle. `make doctor`
checks conversion tool locations. The app requires no Automation, Accessibility,
Screen Recording or Full Disk Access permission.

Manual acceptance before a public release:

- Actual user SVGs: Chinese/Japanese fonts, gradients, masks, filters and clipping.
- SVG sizing: physical units, percentage+viewBox, missing dimension and explicit
  requested width (automated fixtures cover the rules; real files remain useful).
- ~~Quit/close while converting: cancellation wait, termination, blocked window
  close and Dock reopen.~~ Verified 2026-11-10 with agent-desktop: close alert,
  idle close/quit, and ⌘Q during conversion. (Dock reopen remains defensive and
  was not separately exercised.)
- ~~Inline invalid-width/output-limit messages, estimated dimensions and disabled
  Convert on invalid items.~~ Verified 2026-11-10 with agent-desktop.
- Light/dark appearance, keyboard navigation, VoiceOver and four localizations.
- Drag/drop, Open With, per-file/batch settings, cancel/retry and Finder reveal.
- Read-only source, full disk, exFAT/network destination (filesystem policy still
  pending), disconnected output volume and filename collisions.
- Intel, macOS 14, portable engine packaging, notices and Gatekeeper first launch.

GUI acceptance (2026-11-10): `agent-desktop` 1.2.0 exercised the built bundle via
its accessibility tree, including the localized corrupt-container failure and
Retry recovery button; app-owned errors displayed Chinese text while engine
detail remained English. The tool also verified:
its accessibility tree. It verified real batch conversion (PNG outputs, MP3 codec
and 600.003 s duration), inline width/limit validation with disabled Convert,
estimated output text, the conversion-in-progress close alert, cancel during a
2-hour MP3 conversion (status, child process, temporary directory and output), and
⌘Q during conversion after fixing the previously disabled app-menu Quit item.
It also rendered a real 2700×1030 CJK swimlane SVG at 1× (2700×1030) and 2×
(5400×2060) with all CJK labels and connector lines present. A supplied iShot MP4
was correctly rejected because it contains no audio stream. A second supplied MP4
with AAC mono audio converted to MP3 192 kbps, 44.1 kHz mono, 11.469206 s versus an
11.467755 s source audio track, with the source hash unchanged. A complex-path
SVG (“Airy Blue Sky with Puffy Clouds”, 1672×941, 381 paths, opaque) rendered at
1× (1672×941) and 4× (6688×3764) with all paths and colors present. A generated
MKV with two AAC tracks produced an 8.000 s MP3 dominated by the 440 Hz first
track; the smallest real home MKV (23.5-minute screen recording) produced a
1410.667 s MP3 versus a 1410.734 s source, and its personal output was deleted.

The tool is a local verification aid, not a runtime dependency. Synthetic
gradient/filter/mask/clip/transparency fixtures are covered by `make check`;
real-file visual acceptance of those effects is still pending. Not covered:
SVG/bitmap in-flight cancellation, VoiceOver/light-dark, exFAT or network
destinations, Intel and macOS 14.

Design/UIUX acceptance is defined in `docs/DESIGN.md`. Before a public release:

- Capture the screen/state matrix at 900×620 and 760×540, light and dark, in all
  four locales (empty, queue, inspector, invalid, converting, failed, done, alert).
  Light empty/populated screenshots exist from 2026-11-10; the rest is pending.
- Score the six review lenses 0–2; no zeroes, and the primary flow plus error
  states must score 2.
- Complete a keyboard-only pass and a VoiceOver pass; record what was and was not
  exercised. Build success is not visual acceptance.

Only recorded automated checks count as exercised. Missing fonts may substitute;
the app does not claim pixel equivalence with browsers or other SVG renderers.
