# FAQ

## Is processing local?

Yes. The app makes no network requests, collects no telemetry and has no accounts
or background service. FFmpeg and librsvg run as local child processes.

## Will it modify or delete my source file?

No. Sources are opened read-only. Existing output names are preserved using
non-overwriting names (`-1`, `-2`, …).

## Why does it need FFmpeg and librsvg?

They are the conversion engines for audio/video and SVG respectively. They are
external development dependencies in this preview and are not bundled.

## Why is the preview ad-hoc signed and not notarized?

No Developer ID credentials are available in the current build environment. The
release is explicitly labelled as an unsigned local preview; Gatekeeper behavior
may require manual approval.

## Does it support Intel Macs or macOS 14?

The deployment target is macOS 14, but the current preview has only been exercised
on Apple Silicon macOS 27. Those systems are unvalidated, not supported claims.

## Which audio track is used for MP4/MKV?

The first audio stream only, at 128/192/320 kbps MP3.

## Why does an SVG fail to open?

Scripts, animation, external resources, HTML/foreignObject, linked images and
unsafe CSS are rejected by design; sizing also requires dimensions or a viewBox.
The app is not a general SVG renderer sandbox.

## Why does an output volume get rejected?

Publication uses hard links for non-overwriting atomic names. Volumes that do not
support hard links (for example FAT/exFAT/network shares) are rejected until a safe
fallback is implemented and accepted on real devices.

## Where are the security and contribution policies?

See [SECURITY.md](SECURITY.md), [CONTRIBUTING.md](CONTRIBUTING.md) and
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
