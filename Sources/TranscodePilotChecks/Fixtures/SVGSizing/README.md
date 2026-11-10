# SVG sizing fixtures

These fixtures pin the agreed sizing rules used by `TranscodePilotChecks`:

| File | Rule under test |
| --- | --- |
| `units-mm.svg` | physical units at 96 dpi → 96×48 |
| `viewbox-only.svg` | missing dimensions use viewBox size |
| `percentage.svg` | percentages resolve against viewBox size |
| `one-dimension.svg` | one missing dimension derives from viewBox aspect |
| `fractional.svg` | fractional dimensions and renderer rounding |
| `unsupported-percent.svg` | percentage without viewBox is rejected |
| `no-dimensions.svg` | no dimensions and no viewBox is rejected |

`make check` also verifies that an explicit requested width is exact, while scale
mode uses renderer zoom and reports actual output dimensions.
