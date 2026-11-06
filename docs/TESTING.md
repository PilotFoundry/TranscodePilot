# Verification

`make check` creates temporary real fixtures, converts them, reopens outputs and
checks SVG raster dimensions/alpha, JPEG white background, bitmap scaling,
non-overwriting names, source preservation, unsafe SVG rejection, MP3 codec,
silent video rejection, cancellation and temporary cleanup.

`make app` builds and verifies the local ad-hoc signed bundle. `make doctor`
checks conversion tool locations. The app requires no Automation, Accessibility,
Screen Recording or Full Disk Access permission.

Manual acceptance before a public release:

- Actual user SVGs: Chinese/Japanese fonts, gradients, masks, filters and clipping.
- Light/dark appearance, keyboard navigation, VoiceOver and four localizations.
- Drag/drop, Open With, per-file/batch settings, cancel/retry and Finder reveal.
- Read-only source, full disk, disconnected output volume and filename collisions.
- Intel, macOS 14, portable engine packaging, notices and Gatekeeper first launch.

Only recorded automated checks count as exercised. Missing fonts may substitute;
the app does not claim pixel equivalence with browsers or other SVG renderers.
