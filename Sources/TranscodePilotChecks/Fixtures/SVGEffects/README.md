# SVG effects fixtures

Synthetic, non-personal SVGs used by `TranscodePilotChecks` on every `make check`.
They stay inside the documented SVG trust boundary: no external references,
scripts, `foreignObject`, or animation.

| File | Exercises | Expected observation |
| --- | --- | --- |
| `linear-gradient.svg` | linear gradient + transparent background | left red, middle purple, right outside the rect transparent |
| `radial-gradient.svg` | radial gradient | white center, transparent corner |
| `blur-filter.svg` | `feGaussianBlur` | opaque red center, partial alpha just outside the rect |
| `color-matrix-filter.svg` | `feColorMatrix` | red input becomes green output |
| `mask.svg` | luminance mask | left half transparent, right half blue |
| `clip-path.svg` | circle clip path | transparent corner, orange center |
| `transparency.svg` | fill-opacity | PNG has partial alpha; JPEG flattens onto white |

Pixel assertions live in `Checks.swift`. Tolerances are intentionally loose
because filter rasterization can vary slightly between librsvg versions.
