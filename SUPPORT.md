# Support

## Requirements

- macOS 14+ target; currently exercised on Apple Silicon macOS 27 only.
- Swift 6 / Apple Command Line Tools or Xcode to build.
- Local `ffmpeg` and `rsvg-convert` (`brew install ffmpeg librsvg`) for conversion.

## Troubleshooting

1. Run `make doctor` and confirm both engines are reported with versions.
2. If an engine is missing, the bottom bar shows a readiness warning; install the
   engine and relaunch. Install commands belong in developer help, not normal
   product copy.
3. “This video has no audio track” means the first audio stream is absent; MKV and
   MP4 use the same first-audio-track policy.
4. Destination volumes without hard-link support are rejected to preserve
   non-overwriting publication. Choose an APFS/local volume.
5. If a failed item is selected, use Retry, or Choose Output Folder for a
   publication/permission failure.

## Known limitations

No Intel/macOS 14 hardware validation, clean-Mac test, notarization or hosted
support. See `docs/RELEASE.md` for the exact external blockers and
`CHANGELOG.md` for the preview scope.
