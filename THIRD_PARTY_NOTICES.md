# Third-party notices

TranscodePilot application source is licensed under the MIT license in
[LICENSE](LICENSE). This file summarizes external components and assets.

## Not bundled in this preview

- **FFmpeg / ffprobe** — installed separately by the user. The Homebrew build used
  during development is GPL-enabled. FFmpeg is a trademark of Fabrice Bellard and
  the FFmpeg project. Distribution of FFmpeg binaries or builds must satisfy the
  applicable GPL/LGPL terms and provide corresponding source/notices.
- **librsvg / rsvg-convert** — installed separately; licensed LGPL-2.1-or-later
  (project terms may vary by build). Distribution must satisfy its notice/source
  requirements.
- **System frameworks** — AppKit, SwiftUI, ImageIO, CoreGraphics, Foundation and
  related Apple frameworks are provided by macOS and are not redistributed.
- **System fonts** — text rendering uses installed fonts; no fonts are bundled.

## Project assets

- The geometric application icon (`assets/AppIcon.svg`, generated `AppIcon.icns`)
  and documentation screenshots are original PilotFoundry project assets and are
  covered by the project license unless a file states otherwise.
- Synthetic test fixtures under `Sources/TranscodePilotChecks/Fixtures/` are
  original project assets.
- No personal user media or personal screenshots are committed.

## Verifying before distribution

Before publishing a standalone binary, re-audit engine versions and licenses,
bundle all required libraries/fonts/configuration, provide source availability and
notices, and record the exact build inputs. `docs/RELEASE.md` tracks this blocker.
