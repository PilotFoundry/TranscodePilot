# Changelog

## 0.1.0 — development preview (2026-11-10)

### Conversion

- Static SVG → PNG/JPEG, including gradients, filters, masks, clipping and
  transparency; viewBox, percentage, physical-unit and explicit-width sizing.
- PNG/JPEG/HEIC → PNG/JPEG with proportional resizing and EXIF orientation.
- MP4/MKV → MP3, first audio track, 128/192/320 kbps.
- Non-overwriting output names, source preservation and verified publication.

### Reliability and security

- Bounded media probes, explicit demuxers, protocol whitelist and corrupt-input
  rejection.
- SVG trust-boundary validation, adversarial fixtures and documented residual
  renderer risk.
- Source size/mtime revalidation before publication, disk-space preflight and
  stale temporary-directory cleanup.
- Typed app errors, localized app-owned messages and recovery actions.

### App and design

- Native toolbar, app menu, File/Window/Help menus, branded Dock icon.
- Queue counts, stable drop ordering, retry/reconvert, clear actions, bounded
  thumbnails and inline result preview.
- Real conversion progress: FFmpeg progress for MP3, stage progress for
  bitmap/SVG, shown in queue rows and the bottom bar.
- Light/dark and four-language review; English, 简体中文, 繁體中文, 日本語.

### Packaging

- Release configuration, clean bundle creation, metadata/localization/signature
  verification, ZIP + SHA256 packaging and GitHub Actions CI workflow.
- Ad-hoc signed preview only; not notarized. External FFmpeg/librsvg are not
  bundled.

### Known limitations

- No Intel or macOS 14 hardware validation yet; local macOS 27 Apple Silicon is
  the tested system.
- No clean-Mac, notarization or remote-publish validation.
- SVG validation is not a general renderer sandbox.
- HEIC camera/ICC real-file coverage remains a manual acceptance item.
