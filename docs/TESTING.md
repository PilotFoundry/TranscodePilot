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

In a restricted or sandboxed build environment (for example the agent session
used for the 2026-11-06 verification), SwiftPM's internal sandbox cannot be
applied; run `make check SWIFT_FLAGS=--disable-sandbox` there. The flag is not
needed in a normal developer terminal.

`make app` builds and verifies the local ad-hoc signed bundle. `make doctor`
checks conversion tool locations. The app requires no Automation, Accessibility,
Screen Recording or Full Disk Access permission.

Manual acceptance before a public release:

- Actual user SVGs: Chinese/Japanese fonts, gradients, masks, filters and clipping.
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
its accessibility tree. It verified real batch conversion (PNG outputs, MP3 codec
and 600.003 s duration), inline width/limit validation with disabled Convert,
estimated output text, the conversion-in-progress close alert, cancel during a
2-hour MP3 conversion (status, child process, temporary directory and output), and
⌘Q during conversion after fixing the previously disabled app-menu Quit item.
It also rendered a real 2700×1030 CJK swimlane SVG at 1× (2700×1030) and 2×
(5400×2060) with all CJK labels and connector lines present; a supplied iShot MP4
was correctly rejected because it contains no audio stream.

The tool is a local verification aid, not a runtime dependency. Not covered: real
SVGs with gradients/masks/filters/alpha, a real MP4 with audio, SVG/bitmap
in-flight cancellation, VoiceOver/light-dark, exFAT or network destinations,
Intel and macOS 14.

Only recorded automated checks count as exercised. Missing fonts may substitute;
the app does not claim pixel equivalence with browsers or other SVG renderers.
