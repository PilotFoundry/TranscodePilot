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

- One clear primary Convert action and an explicit Cancel state.
- Queue/inspector split is understandable, with native controls and status text.
- Inline width/limit errors and estimated output dimensions already reduce
  uncertainty before starting.
- A restrained orange accent and system materials keep the window visually quiet.

Gaps that justify the design workstream:

- No app icon or durable brand presence; About still uses generic presentation.
- The custom header is not native toolbar chrome; File, Window and Help menus are
  missing, so standard macOS discovery paths are absent.
- Typography and spacing are ad hoc; "OUTPUT" all-caps and mixed hierarchical
  emphasis create an unfinished feel.
- Queue rows compress filename, format and status; no counts, thumbnails or clear
  invalid/failed affordances; format pairs such as `PNG → PNG` are noisy.
- Inspector lacks source dimensions, target dimensions, output size and audio
  duration; preview loads the full exported image and can jump layout.
- Disabled states, empty state and error presentation have no explicit recovery
  story; app-owned errors can appear in English.
- Light/dark, four-language overflow, VoiceOver and keyboard focus have not been
  reviewed as a design surface.
- No screenshot matrix, heuristic scorecard or recorded design sign-off exists.

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

## Open decisions

- Brand accent: keep orange, use a PilotFoundry-family accent, or use the system
  accent for controls and reserve orange for brand moments.
- App icon direction and whether the icon uses a letterform, a conversion glyph or
  an abstract marker.
- Native toolbar vs refined custom header.
- Density: comfortable spacing vs compact queue for larger batches.
- Preview prominence: inline card, resizable inspector section or separate sheet.
- Whether preferences stay inline or move to a Settings window as the app grows.
- Whether the design uses only system fonts (current baseline) or a bundled brand
  font; the default is system fonts to avoid distribution and license cost.
