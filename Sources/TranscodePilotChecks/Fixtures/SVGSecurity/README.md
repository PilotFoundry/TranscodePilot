# SVG trust-boundary fixtures

These synthetic fixtures exercise the local SVG validation policy used by
`TranscodePilotChecks`. They do not claim a complete SVG sandbox: the renderer is
an external process and the app relies on a coarse lexical/namespace policy plus
a restricted set of renderer features.

| File | Expected |
| --- | --- |
| `foreign-namespace-root.svg` | rejected: root is not the SVG namespace |
| `animate-motion.svg` | rejected: unsupported animation |
| `animate-color.svg` | rejected: unsupported animation |
| `discard.svg` | rejected: unsupported animation |
| `xlink-href.svg` | rejected: external linked resource |
| `safe-media-query.svg` | accepted: self-contained CSS at-rule, green output |

Actual file/network denial by the renderer is not proven by these fixtures; it is
recorded as residual risk in `docs/TODO.md` and `README.md`.
