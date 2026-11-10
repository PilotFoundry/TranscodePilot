# Design direction and UI/UX quality

Updated: 2026-11-10. Status: baseline direction and review checklist. Read with
`docs/CORE.md` and `docs/TODO.md`; design work is part of the v0.1 release gate.

## Why this document exists

A converter is judged by two things: whether the output is correct and whether the
user can trust the app while producing it. Visual craft and interaction quality
are therefore trust signals, not decoration. This document defines the target
character, the review lens, and the acceptance method for TranscodePilot's
aesthetics and UI/UX.

## Product character

TranscodePilot is a **calm, precise local conversion workbench**, not a dashboard,
editor or marketing surface.

- Character: quiet, legible, native, tactile-but-understated, lightly branded.
- Priorities, in order: honest output/state, one obvious primary action, native
  macOS behavior, speed to repeat a conversion, PilotFoundry family recognition.
- Avoid: novelty controls, decorative animation, fake progress percentages, custom
  chrome that violates macOS conventions, and marketing copy in the working window.

## Review lens

Every design review covers these dimensions:

1. **Product fit** — does it feel like a considered conversion tool for repeated
   use, rather than a generic file dropper?
2. **Visual craft** — typography, spacing, alignment, color, icon weight, density,
   light/dark parity.
3. **Information hierarchy** — primary action, status, source/target facts and
   errors are visible in the right order.
4. **Interaction/UX** — flow, feedback, reversibility, recovery, keyboard and menus.
5. **Accessibility and localization** — labels, contrast, VoiceOver, focus,
   four-language copy, CJK line height and pluralization.
6. **Native consistency** — window behavior, menus, terminology and control patterns.

## Draft visual system

### Typography roles

- Window/context title: 15 pt semibold.
- Section eyebrow: 11–12 pt semibold; use one consistent case, not arbitrary
  all-caps.
- Body/control label: 13 pt.
- Caption/secondary: 11 pt.
- Dimensions, sizes, paths and format pairs: monospaced 11–12 pt.
- Use no more than three type roles in one panel; avoid more than one accent size
  per window.

### Spacing and layout

- 4/8/12/16/24 spacing scale; panel padding 20 or 24, consistent across panels.
- Align fields, labels and preview edges to the same grid.
- Default window 900×620 and minimum 760×540 must both be reviewed, not just one.
- Empty state, queue and inspector must keep their primary actions reachable at the
  minimum size without horizontal scrolling.

### Color, shape, icons

- Prefer system semantic colors for backgrounds, separators and text.
- One accent color for primary action, selection and drag target; status colors
  (blue/green/orange/red) must remain distinguishable in light and dark and never
  be the only carrier of meaning.
- Do not hard-code many hex colors. Record any brand accent as a token.
- Native control geometry; 8 pt corners for preview/result cards; avoid heavy
  shadows and decorative gradients.
- SF Symbols in a consistent weight; a custom app icon is required before release.
- No emoji in product UI. Icons require labels or help text.

### Motion and progress

- Minimal, interruptible motion; respect Reduce Motion.
- Show active task and completion states, never a fabricated percent.
- Disabled states need a reason (inline validation or help text), not just gray.

## Information architecture

- **Window**: header/toolbar, queue, inspector, bottom action bar, status.
- Decide whether the current custom header becomes a native toolbar; this is a D3
  decision, not an incidental style choice.
- **Queue row**: filename primary, format transition and status secondary, invalid
  badge, selection state, optional bounded thumbnail. Avoid cramming full paths or
  long errors into one line.
- **Inspector**: group Source / Output / Result. Show source dimensions, target or
  estimated dimensions, output size and audio duration; hide controls that cannot
  apply to the selected format; show error and recovery next to the affected
  control when possible.
- **Bottom bar**: output destination is secondary; Convert is primary; during a run
  Cancel replaces Convert and the active task remains visible; counts/status sit
  nearby.
- **Empty state**: supported formats, add/drop guidance, local-engine boundary; no
  installation commands in the normal end-user path.
- **State vocabulary**: Ready / Converting / Cancelling / Cancelled / Failed /
  Done / Invalid; labels localized consistently and used by both UI and tests.

## Screen and state inventory

Review each state at default and minimum window size, 1× and Retina, light and dark,
and in English, 简体中文, 繁體中文 and 日本語:

- empty queue;
- queue with mixed image/video files and selection;
- inspector for image, SVG and audio;
- invalid width/output limit;
- converting with active task and cancel;
- cancelled with retry remaining;
- completed with bounded preview and reveal/open actions;
- failed with engine/app error and recovery;
- unsupported files notice;
- drag-over target and rejected drop;
- conversion-in-progress close alert;
- About and menu bar;
- quit/reopen and last-window-close behavior.

## Current baseline review — 2026-11-10

Strengths observed in the current implementation:

- Native toolbar with title, Add Files and Output Folder; File/Window/Help menus
  and the standard app menu now exist, so macOS discovery paths are present.
- A distinct PilotFoundry-family app icon is bundled and used in the empty state.
- System accent drives primary controls; orange appears only in the brand icon.
- One clear primary Convert action and an explicit Cancel state.
- Queue/inspector split is understandable, with native controls and status text.
- Inline width/limit errors and estimated output dimensions already reduce
  uncertainty before starting.

Gaps that justify the remaining design workstream:

- Typography and spacing are still ad hoc; "OUTPUT" all-caps and mixed
  hierarchical emphasis create an unfinished feel; D1 tokens are not applied
  comprehensively yet.
- Queue rows compress filename, format and status; no counts, thumbnails or clear
  invalid/failed affordances; format pairs such as `PNG → PNG` are noisy.
- Inspector lacks source dimensions, target dimensions, output size and audio
  duration; preview loads the full exported image and can jump layout.
- Disabled states, empty state and error presentation have no explicit recovery
  story; app-owned errors can appear in English.
- Light/dark, minimum-size, four-language overflow, VoiceOver and keyboard focus
  have not been reviewed as a design surface; only light default-size screenshots
  exist for the empty and populated states.
- No complete screenshot matrix, heuristic scorecard or recorded design sign-off
  exists.

Verdict: functionally credible, but not yet a considered product experience. D1–D10
address this before v0.1 is called complete.

## Design tasks

- **D1 — Visual audit and tokens:** screenshot matrix, type/spacing/color/icon
  tokens, light/dark rules, documented in this file.
- **D2 — Brand and app icon:** distinct PilotFoundry-family icon, bundle assets,
  About panel, Finder/Dock presence.
- **D3 — Window chrome and macOS conventions:** toolbar vs custom header, File/
  Window/Help menus, Close/Minimize/Zoom, frame restoration, discoverable quit.
- **D4 — Empty state and first-run guidance:** formats, add/drop, local-engine
  boundary; no marketing or installer copy in the normal flow.
- **D5 — Queue rows and batch status:** counts, ordering, invalid/failed badges,
  bounded thumbnails/checkerboard, no full-size decode in `View.body`.
- **D6 — Inspector information architecture:** Source/Output/Result, dimensions,
  duration, output size, bounded preview, errors/recovery.
- **D7 — Action hierarchy and feedback:** primary/cancel/per-item actions,
  disabled reasons, drag-over feedback, no fake progress.
- **D8 — Light/dark, typography and localization:** contrast, case discipline,
  CJK line height, plurals and overflow in four languages.
- **D9 — Accessibility and keyboard:** icon labels, focus order, keyboard-only
  primary flow, VoiceOver names/states, Reduce Motion, hit targets.
- **D10 — Design acceptance gate:** screenshot/scorecard/review record and
  `TESTING.md` updates; build success is not visual acceptance.

## Design acceptance

- Capture at least the screen inventory above at 900×620 and 760×540, light and
  dark, four locales; keep them as local review artifacts (no personal screenshots
  committed).
- Score each review lens 0–2. Release gate: no zeroes; the primary flow and error
  states must score 2.
- Run a keyboard-only pass and a VoiceOver pass; record what was and was not
  exercised.
- Review against CORE.md: sources preserved, output verified, failures honest.
- Record the outcome in `TESTING.md`/`IMPLEMENTATION.md`; do not claim acceptance
  from build success alone.

## Resolved decisions — 2026-11-10

- **Accent:** system accent for controls, selection and drag feedback; orange is
  reserved for the brand mark and app icon.
- **App icon:** geometric exchange/conversion arrows in the PilotFoundry family
  visual language — dark green squircle, cream arrows, orange arrowhead accent.
  Source is `assets/AppIcon.svg`; `scripts/build-icon` regenerates the icns.
- **Window chrome:** native toolbar, not a custom header.
- **Dock tile:** the running app sets `NSApp.applicationIconImage` from the
  bundled icns, so a rebuilt icon is reflected without waiting for a LaunchServices
  cache refresh.
- **Density:** comfortable spacing for everyday small batches.
- **Preview:** inline result card.
- Default font remains the system font; a bundled brand font is not planned.

Implementation status (2026-11-10): native toolbar with Add Files/Output Folder,
File/Window/Help menus, standard app menu, window frame autosave, app icon bundle
and explicit empty-state icon are implemented. D1–D8 are implemented; D9 keyboard
and AX-label work is verified, with live VoiceOver/focus-order acceptance still
manual; D10's scorecard is recorded below.

## D1 review matrix — 2026-11-10

Local artifacts live in `.build/design/d1/` (ignored, not committed): light/dark
empty, valid, invalid, converting, failed, done, alert-sheet, minimum-window and
four-language captures. Reviews drove these fixes:

- Queue grammar now says “1 file” / “N files” instead of “1 files”.
- Section eyebrows changed from all-caps `SOURCE`/`OUTPUT` to sentence case.
- Queue footer shows Done/Failed/Pending counts even during a conversion.
- Output path is shown in full (home-abbreviated, middle-truncated) instead of only
  the last path component.
- Result card moved directly below Source so the preview/actions are visible
  without scrolling; bounded 512 px preview uses a checkerboard for alpha.
- Queue rows use bounded 64 px ImageIO thumbnails; no full-size decode in body.
- Close-while-converting now uses a non-blocking sheet instead of `runModal()`.
- Window restoration centers the window when no connected screen contains it.

## Design acceptance scorecard (2026-11-10)

Scores: 0 = unacceptable, 1 = acceptable with follow-up, 2 = meets the release bar.

| Lens | Score | Notes |
| --- | --- | --- |
| Product character | 2 | Native macOS shell, branded icon, local-first copy |
| Hierarchy | 2 | Convert primary; result card near Source; recovery actions local |
| Density | 1 | Comfortable default; inspector needs scrolling at minimum height |
| Feedback | 2 | Inline invalid reasons, spinner/Cancel, Retry, honest errors |
| Light/dark | 2 | Reviewed both appearances; checkerboard remains legible |
| Localization | 2 | Four-language empty/populated captures; plural grammar fixed |
| Accessibility | 1 | Labels + keyboard pass for primary flow; VoiceOver/focus pending |
| Error UX | 2 | Localized app-owned text, engine detail, recovery actions |
| macOS conventions | 2 | Native toolbar/menus, close alert, Cmd+Return/Cmd+O |
| Conservation | 2 | Source read-only copy, non-overwriting publication |

Gate: no zeroes; primary flow and error states score 2. Final sign-off remains
open only for the live VoiceOver/focus-order pass.

## Open decisions

- Icon refinement and About-panel presentation after the next visual review.
- Whether preferences stay inline or move to a Settings window as the app grows.
- Dark-mode accent treatment (system accent is the baseline).
