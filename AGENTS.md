# TranscodePilot

Read `docs/CORE.md` before changing scope and `docs/DESIGN.md` before UI/visual
changes. Independent PilotFoundry application; do not edit sibling SwitchPilot
directories as part of routine development.

- SwiftUI/AppKit window, ImageIO bitmaps, external librsvg/FFmpeg engines.
- Preserve sources and existing output; validate real output before success.
- No telemetry, network resource fetching, private APIs or new system permissions.
- Keep four localization tables in sync. Engine error details may be English.
- Treat aesthetics/UIUX as release criteria: screenshot review, keyboard and
  VoiceOver passes, and four-language overflow checks are part of acceptance.
- Run `make check`, `make app`, `make doctor` after conversion changes.
- No standalone distribution claims: development engines are locally installed.
- Do not commit `.build/`, app bundles, signing identities or personal fixtures.
