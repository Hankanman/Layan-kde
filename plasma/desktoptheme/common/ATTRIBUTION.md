# Attribution

Layan is licensed GPL-3.0 (see the repository root). The Plasma desktop
theme element files listed below were originally authored by the KDE
Visual Design Group for the **Breeze** desktop theme
(`plasma/desktoptheme/default`, package `plasma-workspace`), licensed
LGPL, and are compatible with GPL-3.0 redistribution. They were added
here because Layan did not ship them, which caused Plasma to silently
fall back to Breeze for these elements mid-theme (REVIEW.md B4/M9).

Source: `/usr/share/plasma/desktoptheme/default/` on Fedora 44
(plasma-workspace, Plasma 6.7.4), decompressed from `.svgz`.

## Adapted from Breeze (geometry/ids kept, recoloured to Layan)

- `common/widgets/frame.svg`
- `common/widgets/radiobutton.svg`
- `common/widgets/dragger.svg`
- `common/widgets/picker.svg`
- `common/widgets/media-delegate.svg`
- `common/widgets/timer.svg`
- `common/widgets/analog_meter.svg`
- `common/widgets/margins-highlight.svg`
- `common/weather/wind-arrows.svg`
- `common/icons/kup.svg`
- `common/icons/mobile.svg`

For each of these, the `current-color-scheme` `<style>` block (there is
exactly one per file) was replaced with Layan's palette:

```css
.ColorScheme-Text          { color: #31313A; }
.ColorScheme-Background    { color: #f4f4f9; }
.ColorScheme-Highlight     { color: #5657f5; }
.ColorScheme-ViewText      { color: #31313A; }
.ColorScheme-ViewBackground{ color: #f4f4f9; }
.ColorScheme-ButtonText    { color: #31313A; }
.ColorScheme-ButtonBackground { color: #f4f4f9; }
.ColorScheme-Frame         { color: #31313A; }
```

Any hardcoded Breeze-blue accent hex codes (`#3daee9`, `#1e92ff`) found
outside the stylesheet (gradient stops, inline `style="color:..."`
overrides that win specificity over the class) were changed to Layan's
accent `#5657f5`. Element ids, geometry and transforms were left
untouched so panel/frame geometry matches what Plasma expects from a
Breeze-shaped element file.

Corner radius: these are small 9-patch/icon-scale element files (1px
borders, sub-10px tiles); applying a literal 10px corner radius would
break their geometry, so it was not applied here. The 10px corner
radius called for by the modernisation review is carried by the
full-size frame backgrounds instead (`common/{solid,opaque,translucent}/
widgets/panel-background.svg`, `dialogs/background.svg`).

## Original Layan artwork (not adapted from Breeze)

- `common/widgets/monitor.svg`
- `common/widgets/branding.svg`

Breeze's `widgets/monitor.svgz` and `widgets/branding.svgz` are each a
single embedded base64 raster image with no reusable element ids
(monitor.svgz decompresses to ~1.2MB), which is not practical to ship,
recolour, or theme via `current-color-scheme` classes. These two were
authored fresh as small vector Layan assets instead, keeping the same
canvas size as the Breeze originals (200x140 and 80x15 respectively).
