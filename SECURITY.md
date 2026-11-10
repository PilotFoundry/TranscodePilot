# Security

TranscodePilot is a local desktop app. It makes no network requests, collects no
telemetry, has no accounts and runs no background service.

## Data handling

- Sources are opened read-only and are never deleted or overwritten.
- Output publication uses a same-volume temporary result plus a non-overwriting
  hard link; unsupported volumes are rejected.
- Settings and queue state are local. The queue is session-only; the output folder
  and preferences persist in UserDefaults.
- Engine stderr may include local file paths and is surfaced as diagnostic detail.

## Trust boundaries

- FFmpeg and librsvg are external development dependencies, not bundled.
- SVG validation is a coarse local policy: scripts, external URLs/resources,
  entities, animations and unsafe CSS are rejected, but it is not a general
  renderer sandbox.
- Media probes use explicit demuxers, a protocol whitelist, bounded probe size and
  duration, and timeouts.
- Do not report a vulnerability as fixed from a build check alone; include an
  adversarial fixture and observed behavior.

## Reporting

This is a personal development preview without a hosted security program. For a
local security issue, keep the report private until the owner has reviewed it;
include the app version, macOS version, a minimal reproducer and whether a
network or filesystem boundary was crossed.
