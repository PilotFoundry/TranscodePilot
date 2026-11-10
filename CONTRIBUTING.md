# Contributing

TranscodePilot is a local macOS SwiftUI/AppKit app by PilotFoundry.

## Build

Requires macOS 14+, Swift 6, and local FFmpeg/librsvg for conversion:

```sh
brew install ffmpeg librsvg
make doctor
make check
make app
```

In a restricted agent sandbox, pass `SWIFT_FLAGS=--disable-sandbox` to `make`.
The default SwiftPM backend is used because CLT has no XCTest; regression tests are
the `TranscodePilotChecks` executable.

## Before a change

- Read `docs/CORE.md` before changing product scope.
- Read `docs/DESIGN.md` before changing UI/visual behavior.
- Do not add network requests, telemetry, private APIs or new system permissions.
- Keep sources and existing output untouched; validate results before success.
- Keep `en`, `zh-Hans`, `zh-Hant` and `ja` localization tables in sync.
- Engine diagnostics may be English; app-owned text must be localized.

## Verify

```sh
make check
make app
make verify
make release
make package
```

`make verify` checks plist metadata, MKV document registration, localization
parity, bundle cleanliness, signature and architecture. `make package` writes a
ZIP and SHA256 under `.build/release/`.

## Tests and fixtures

- Synthetic fixtures are committed under
  `Sources/TranscodePilotChecks/Fixtures/`.
- Real user files and personal screenshots stay local and uncommitted.
- Add a regression before or with a behavior change when practical.
- Do not mark visual/accessibility acceptance from a successful build alone;
  record the screenshot/keyboard/VoiceOver evidence required by `docs/TESTING.md`.

## Release

Follow `docs/RELEASE.md`. Do not claim signed/notarized or clean-Mac statuses
without the corresponding credentials and evidence.
