# Product principles

TranscodePilot is PilotFoundry's focused native macOS media converter.

1. Shorten frequent conversion workflows; add formats only for demonstrated needs.
2. Keep files local. No telemetry, remote config or silent remote SVG resources.
3. Show actual formats, pixels and output state; verify output before success.
4. Preserve source files and existing output. Keep failures retryable.
5. Prefer native controls and a quiet window over permanent background presence.
6. Reuse mature engines. Keep UI, queue and conversion code independently readable.
7. State dependencies, unsupported inputs and unexecuted acceptance checks honestly.

v0.1 includes SVG/PNG/JPEG/HEIC → PNG/JPEG and MP4 → MP3. Editing, general video
transcoding, documents, cloud conversion, watch folders and automatic updates are
outside this version. Distribution and new formats require separate acceptance.
