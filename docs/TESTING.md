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
- Quit/close while converting: cancellation wait, termination, blocked window
  close and Dock reopen. (Code implemented; GUI acceptance pending.)
- Inline invalid-width/output-limit messages, estimated dimensions and disabled
  Convert on invalid items.
- Light/dark appearance, keyboard navigation, VoiceOver and four localizations.
- Drag/drop, Open With, per-file/batch settings, cancel/retry and Finder reveal.
- Read-only source, full disk, exFAT/network destination (filesystem policy still
  pending), disconnected output volume and filename collisions.
- Intel, macOS 14, portable engine packaging, notices and Gatekeeper first launch.

Only recorded automated checks count as exercised. Missing fonts may substitute;
the app does not claim pixel equivalence with browsers or other SVG renderers.
