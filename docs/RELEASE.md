# Release engineering

## Current artifact

`TranscodePilot 0.1.0` is a development preview, ad-hoc signed and **not
notarized**. It is built locally on Apple Silicon macOS 27 and targets macOS 14.
No Intel or macOS 14 hardware validation has been performed, so no support claim
is made for those systems.

Local release artifact:

```sh
make check
make app
make verify
make release
make package
```

This writes `.build/release/TranscodePilot-<version>-<arch>.zip` and `.sha256`.
`make verify` checks plist metadata, MKV registration, four localization tables,
bundle cleanliness, ad-hoc signature and architecture.

## Versioning and tags

- `CFBundleShortVersionString` is the semantic release version; `CFBundleVersion`
  is a monotonically increasing build number.
- A release updates `Info.plist`, `CHANGELOG.md` and this acceptance record, then
  tags the commit `vX.Y.Z` after CI/verification passes.
- Current preview: `0.1.0` build `1`; the public repository is
  `PilotFoundry/TranscodePilot`. The initial `v0.1.0` tag/Releases are maintained
  on GitHub after CI passes.
- Never move or force-push a published tag; publish checksums with the artifact.

## Manual install check

1. Unzip the artifact and confirm the app launches.
2. Run a local SVG/PNG/MP4/MKV conversion with the engines installed.
3. Confirm sources and existing outputs are unchanged.
4. Run the screenshot matrix and keyboard/VoiceOver checklist in
   `docs/TESTING.md`.

## External blockers (not completed here)

| Item | Why blocked | Required action |
| --- | --- | --- |
| Developer ID signing/notarization | No Developer ID credentials or notary access in this environment | Provide credentials, sign with hardened runtime, notarize and staple |
| Intel + macOS 14 validation | No Intel or macOS 14 hardware | Build/test on those systems or narrow support further |
| Clean-Mac test | No clean Mac target | Test unsigned/local-brew-free install on a clean machine |
| Portable FFmpeg/librsvg bundles | Distribution/licensing and reproducible engine builds are unresolved | Choose audited builds, bundle dependencies, audit licenses/notices and pin versions |
| CI engine pinning | Workflow installs Homebrew engines; no pinned artifacts | Provision pinned engine versions and record their checksums |
| Domain/trademark | Preliminary searches are not legal clearance | Register/verify domain and complete formal trademark review |
| Organization profile | Depends on remote publication | Update PilotFoundry profile after publishing |
| Localized release pages | README entry points are added; hosted localized pages do not exist | Publish localized pages after content stabilizes |
| Branch protection mirror | Protected on GitHub; no local enforcement | Keep required checks enabled when collaborators join |

## Release acceptance record — 2026-11-13

- Source published to <https://github.com/PilotFoundry/TranscodePilot>.
- Hosted CI passed at `226070e55ce066c662a0bd221f2201b8f325849e` on
  `macos-latest`; `main` requires `build-and-verify`.
- Initial [v0.1.0](https://github.com/PilotFoundry/TranscodePilot/releases/tag/v0.1.0)
  development preview is published as a GitHub pre-release with ZIP/SHA256 assets;
  asset digest `sha256:fa235da03d3d2188adfed1de8ce45754dcfe396511019764f5f42930267406ec`.
  It remains ad-hoc signed and not notarized.
- Remote/tag/Release publication is recorded here; signed stable distribution
  remains blocked on Developer ID/notarization.

## Release acceptance record — 2026-11-10

- `make check`: PASS (4 groups).
- `make app`: PASS; ad-hoc signature verified.
- `make verify`: PASS; 102 localization keys × 4 tables; MKV document type present.
- `make release` / `make package`: PASS; ZIP + SHA256 generated and re-verified.
- GUI: MKV, real 1.29 GB MKV, real 1.2 GB MP4, SVG sizing, huge-file MP3, effects
  visual pass, in-flight bitmap/SVG cancel, corrupt failure/recovery, close-alert
  sheet, Cmd+Return keyboard flow and D1 screenshot matrix were exercised locally.
- Open manual gate: live VoiceOver/focus order, TCC folder prompts, real
  exFAT/network volume, engine rlimit caps, clean-Mac/14/Intel and notarization.
