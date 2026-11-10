# Privacy

TranscodePilot is local-first:

- No network requests, telemetry, analytics, accounts, cloud processing or
  background service.
- Sources are opened read-only and are not uploaded anywhere.
- Queue state is session-only. The output folder path, format/size preferences and
  engine readiness state are stored in local `UserDefaults`.
- Conversion engines (`ffmpeg`, `ffprobe`, `rsvg-convert`) run as local child
  processes and may emit local paths in diagnostic stderr; app-owned errors are
  localized and engine details are shown only as diagnostics.
- Screenshots committed to the repository are generated from synthetic fixtures;
  personal screenshots and media are not committed.

If a future version adds network functionality, this document and the product
principles must change together, with explicit opt-in.
