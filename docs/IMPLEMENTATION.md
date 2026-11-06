# TranscodePilot v0.1

Goal: a local macOS window for SVG/bitmap → PNG/JPEG and MP4 → MP3.

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
