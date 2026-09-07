# Vendored Lucide icons

This directory contains a hand-picked subset of [Lucide](https://github.com/lucide-icons/lucide)
static SVG icons (`lucide-static` package), **version 1.42.0**, used as the
source material for `tools/gen-lucide-icons.py`.

Only the icons actually referenced by that script's KDE-name -> Lucide-name
mapping table are vendored here (not the full ~1500-icon set) to keep the
repository small. If the mapping table is extended to reference a new Lucide
icon, copy the matching `<name>.svg` file from the upstream
`lucide-static/icons/` directory into this folder.

Lucide is distributed under the ISC License -- see `LICENSE` in this
directory. Icons are unmodified except for the wrapper `<svg>`/`<style>`
markup added at generation time by `tools/gen-lucide-icons.py` (colour,
size and KDE `ColorScheme-Text` stylesheet); the icon paths themselves are
copied verbatim from upstream.
