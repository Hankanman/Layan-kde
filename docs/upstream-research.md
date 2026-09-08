# Upstream research: vinceliuice/Layan-kde

Research date: 2026-09-07 (Plasma 6.7 era). All data pulled live via `gh` / `gh api`.

Upstream snapshot: `vinceliuice/Layan-kde` — 534 stars, 36 forks, default branch `master`,
last push **2025-11-27** (`a0b6a49` "Update slider.svgz"). 72 issues, 9 PRs total.
Repo tree: `AUTHORS Kvantum LICENSE README.md aurorae color-schemes install.sh logo.png plasma sddm/{5.0,6.0} uninstall.sh wallpaper`.

Upstream commit log since 2024 (for context on what is/isn't fixed):

| sha | date | message | files |
|---|---|---|---|
| c4cce9d | 2024-01-09 | update | |
| 0909676 | 2024-02-15 | Update network.svg | |
| 7b8c621 | 2024-03-27 | update to plasma 6 (Soudini, PR #62) | metadata.json for aurorae/desktoptheme/look-and-feel/sddm/wallpaper |
| 0118e95 | 2024-05-21 | Merge PR #62 | |
| e8a9ce9 | 2024-07-10 | Fixed #63 (SDDM black screen) | |
| 1eed6f6 | 2024-07-14 | Fixed #64 (Kvantum qBittorrent/Telegram) | |
| 64ae091 | 2024-07-16 | Fixed #61 (plasmavault icon) | |
| 849ae8c | 2024-08-07 | Fixed issues | dialogs/background.svg, panel-background.svg (all 3 variants) |
| c805d53 | 2024-09-07 | update | common/widgets/background.svg (+466), translucent background.svg |
| 6c5f5d3 | 2024-10-09 | Update #15 (uninstall solid) | |
| cccc18d | 2024-12-09 | update | tooltip.svgz ×3, menubaritem.svgz |
| e50db26 | 2024-12-18 | Fixed #67 | sddm/6.0/Layan/Main.qml: `fontSize:` → `font.pointSize:` (10 lines) |
| 78de2c2 | 2024-12-18 | Update Main.qml | same for sddm/6.0/Layan-light |
| 7ae1025 | 2025-01-03 | fix sddm display error (YageGeng, PR #69) | sddm/6.0/*/Main.qml: `iconSource:` → `icon.name:` (and reverted Login `font.pointSize`→`fontSize`, Battery too) |
| 17db8c1 | 2025-02-12 | update | bar_meter_*.svgz |
| ace0b1d | 2025-02-12 | Update Layan.kvconfig | |
| 8a824f1 | 2025-08-11 | update | panel-background.svg (common + translucent), menubaritem.svgz, tasks.svgz |
| a0b6a49 | 2025-11-27 | Update slider.svgz | |

Current upstream `sddm/6.0/Layan/Main.qml` state (verified by fetching the file): imports `QtQuick.Controls 2.15`,
`Qt5Compat.GraphicalEffects`, `org.kde.plasma.plasma5support`, `org.kde.breeze.components`; ActionButtons use
`icon.name: "/usr/share/sddm/themes/Layan/assets/*.svgz"` (absolute path — a file path in `icon.name`) and
`font.pointSize: parseInt(config.fontSize) + 1`; `Login { fontSize: … }` and `Battery { fontSize: … }` retained.
So in git the "Cannot assign to non-existent property fontSize" crash is fixed, **but the KDE Store package is
stale** (issue #78) and the absolute icon paths break on NixOS/non-`/usr/share` layouts (PR #76/#77) and the
`icon.name` file-path hack yields invisible icons on some distros (issue #68, PR #75→#76).

---

## 1. Issues (72 total; 41 open / 31 closed)

Note: #14 returns 404 (deleted). #3, #5, #62, #69, #70, #75, #76, #77, #79 are PRs.

### 1.1 Plasma 6 / Qt 6 port & breakage

| # | State | Date | Problem | Resolution / workaround |
|---|---|---|---|---|
| **#59** | CLOSED 2024-07-14 | 2023-12-22 | Feature request: port to Plasma 6. OP gave the recipe: `desktoptojson` for all metadata.desktop, add `"KPackageStructure": "Plasma/LookAndFeel"` to look-and-feel metadata.json. 17 comments of +1s; DarkXero-dev (XeroLinux) noted context menus flaky until Kvantum was updated. | Fixed by PR #62 (Soudini, merged 2024-05-21); vinceliuice closed 2024-07-14 "Fixed". Link to KDE porting doc: https://develop.kde.org/docs/plasma/theme/theme-porting-to-plasma6/ |
| **#30** | OPEN | 2022-01-24 | "Support for Qt6" — Qt6 apps (qBittorrent) look wrong. | Comment (inari-codes): need Kvantum built for both Qt5 and Qt6; theme cannot fix it alone. Still relevant: today means `kvantum-qt6` package. |
| **#71** | CLOSED 2025-06-20 | 2025-04-05 | Rendering artefacts in KDE apps after Plasma 6.3.4 + Qt 6.9.0 (Arch, AUR `plasma6-themes-layan-git`). Breeze unaffected. | Root cause QTBUG-135867; resolved by Qt 6.9.1. Not a theme bug. |
| **#72** | OPEN | 2025-08-16 | Dolphin location bar became opaque after KDE Gear 25.08 (Layan Dark + Kvantum). | vinceliuice: "move it to the toolbar" (Dolphin setting). Reporter unhappy; the real fix would be in the Kvantum SVG for the new location-bar widget. **Relevant to Plasma 6.x.** |
| **#74** | OPEN | 2025-10-24 | journald: `Splash.qml:88: ReferenceError: bottomRect is not defined` (Fedora Kinoite 43). | No response. Verified in upstream: `Splash.qml` animates `target: bottomRect` (line 88) but never declares an `Image { id: bottomRect }`. PolybiusPro fork fixes this (see §3). **Relevant.** |
| **#82** | OPEN | 2026-08-24 | Andromeda Launcher plasmoid icon renders much smaller than other panel icons only with Layan global theme. | No response. Likely a desktoptheme icon/`icons/start.svg` sizing issue. **Relevant.** |
| **#80** | OPEN | 2026-07-10 | Audio slider handle mis-positioned at 100% (Layan plasma + Kvantum). | No response. Upstream touched `slider.svgz` on 2025-11-27 (`a0b6a49`) — issue postdates it. **Relevant.** |
| **#81** | OPEN | 2026-07-29 | "How do I restore the file menu bar to application windows instead of the task bar?" — user question, likely global-menu applet in the panel layout. | No response. Support question, not a bug. |
| **#66** | OPEN | 2024-09-23 | Fullscreen Kitty shows a blurry strip at top (Plasma 6.1.5, X11) — suspected Aurorae titlebar blur region. Reporter posted a screenshot workaround (KWin rule). | No maintainer response. **Relevant** (Aurorae blur mask). |

### 1.2 SDDM theme

| # | State | Date | Problem | Resolution / workaround |
|---|---|---|---|---|
| **#63** | CLOSED 2024-07-10 | 2024-07-07 | SDDM theme → black screen + cursor on Manjaro, Plasma 6.0.5, Wayland greeter. | Fixed by `e8a9ce9` "Fixed #63". |
| **#67** | CLOSED 2024-12-18 | 2024-10-14 | `Main.qml:214:25: Cannot assign to non-existent property "fontSize"` (Arch). | Comments: so02s → `fontSize`→`font.pointSize`, `iconSource`→`icon.source`; awhitehouse104 → should be `icon.name`. Fixed upstream `e50db26`/`78de2c2`. DragonflyRobotics (2026-03-10): "still a problem, I had to patch" — because Store/AUR copies are stale. |
| **#68** | OPEN | 2024-12-30 | (zh) `fontSize`/`iconSource` don't exist; commenting them out works but all icons missing. Plasma 6.2.4. Later (p1zz4br0etch3n 2025-09-22, Fedora 42): `Main.qml:28:1: module "QtQuick.Controls" version 1.1 is not installed` → user had the **5.0** theme installed on Plasma 6; Mitsu13Ion same. | YageGeng pointed to PR #69 (merged). Remaining sub-issues: icons invisible when `icon.name` is given a path; users installing `sddm/5.0` on Plasma 6. **Relevant.** |
| **#73** | OPEN | 2025-10-22 | Same `fontSize` error. | chalmery (2026-05-28) wrote a full fix write-up: delete `fontSize` in the 8 `ActionButton`s (it's set internally), replace `iconSource` with `icon.name: "system-suspend" / "system-reboot" / "system-shutdown" / "system-user-prompt" / "system-user-list"` (loses Layan's custom svgz icons unless installed into the icon theme). Keep `Login.fontSize` and `Battery.fontSize`. **Relevant.** |
| **#78** | CLOSED 2026-01-23 | 2026-01-23 | Fedora 43: same `fontSize` error; also notes `iconSource` fix in `7ae1025` hasn't propagated to the KDE Store. | Reporter closed it: "issue with the version in the theme store". **Takeaway: the Store package is out of date vs git.** |

### 1.3 Aurorae window decoration / KWin

| # | State | Date | Problem | Resolution / workaround |
|---|---|---|---|---|
| **#4** | CLOSED 2020-02-17 | 2020-01-27 | Can't resize from left/right with border size 0; blur looks odd on dark backgrounds. | Fixed 2020-02-17. HuM4NoiD (2022-04-27) still sees an un-blurred border strip. |
| **#7** | OPEN | 2020-02-22 | Black "korners"/artefacts at titlebar & bottom corners when blur is off / low blur strength. | vinceliuice: KDE bug (bugs.kde.org 418276). NovaViper asked for a no-rounded-corner variant. Largely obsolete on Plasma 6 (KWin masks), but see #44. |
| **#26** | OPEN | 2021-10-14 | Windows can't be resized from the top edge with Layan Aurorae; "No side borders" instead of "No borders" fixes it. | No fix. Aurorae layout (`Layanrc` `BorderTop`/`TitleEdgeTop`) issue. **Still relevant.** |
| **#34** | CLOSED 2022-07-27 | 2022-03-06 | Add `mask` element to `decoration.svg` for KWin 5.25 Korners fix (kwin MR !1961). | Closed (presumably added). |
| **#43** | CLOSED 2022-06-21 | 2022-06-18 | Window decoration transparent instead of blurred (KWin 5.25). | Closed; fixed. |
| **#44** | OPEN | 2022-06-19 | KWin 5.25 uses the `mask` from `decoration.svg` to compute the blur region — without it no blur behind decoration. Reporter offered a PR. | No follow-up. Overlaps #43/#34. Check whether current `decoration.svg` has a proper `mask` element. |
| **#42** | CLOSED 2023-08-06 | 2022-05-23 | At 200% scaling, window shadows only half-painted on Qt windows. | Closed without comment. |
| **#54** | OPEN | 2023-04-01 | Titlebar text/buttons mispositioned after tiling VS Code to a screen edge. | No response. |
| **#55** | CLOSED 2023-06-21 | 2023-04-13 | (zh) Request solid titlebar for the dark theme (flicker with mixed light/dark apps). | Closed; `Layan-solid` aurorae exists. |
| **#60** | OPEN | 2024-01-19 | `aurorae/themes/Layan-solid` exists but `install.sh` has no option to install it. | Actually `install.sh` does `cp -rf aurorae/themes/Layan*` so solid is copied; two users still couldn't find it. Documentation/installer clarity issue. |
| **#27** | CLOSED 2021-11-11 | 2021-11-08 | Frame-rate drop with window animations. | Self-resolved: Sierra Breeze Enhanced "match titlebar to window color" option. |

### 1.4 Plasma desktop theme (panel, tooltips, transparency, icons)

| # | State | Date | Problem | Resolution / workaround |
|---|---|---|---|---|
| **#6** | CLOSED 2020-02-19 | 2020-02-17 | White "corner guard" artefacts on notification/tray popups. | Fixed (tooltip.svg update). |
| **#8** | CLOSED 2020-04-16 | 2020-02-28 | Request no-transparency variant. | Layan-solid created. |
| **#9** | CLOSED 2020-03-11 | 2020-03-10 | Rounded corners without transparency. | KWin limitation. |
| **#10** | CLOSED 2020-04-04 | 2020-03-25 | Can't distinguish minimized vs. not-running tasks. | Fixed. |
| **#15** | CLOSED 2024-10-07 | 2020-09-03 | Uninstall script forgot solid theme. | Fixed `6c5f5d3`. |
| **#16** | CLOSED | 2020-09-03 | Window not transparent (no body). | — |
| **#19** | OPEN | 2021-05-16 | Wallpaper shows through scrollbar region (glitch). | No response. |
| **#20** | OPEN | 2021-06-11 | Selected file has no highlight in Dolphin. | No response (Kvantum/colour scheme). |
| **#21** | OPEN | 2021-06-22 | Panel not transparent/blurred on Manjaro; Konsole background not transparent. | No response. Overlaps Kvantum/Konsole profile absence (no Konsole scheme upstream — PolybiusPro fork adds one). |
| **#22** | OPEN | 2021-08-04 | How to change panel shadow colour to a glow (edited `panel-background.svg` gradient). | No response; advice request. |
| **#25** | OPEN | 2021-09-20 | Margins Separator widget doesn't work in Layan plasma theme. | vinceliuice 2021-09-21 "I'll fix this" — never closed. Needs `widgets/panel-background.svg` margin hints. **Possibly still relevant.** |
| **#29** | OPEN | 2021-12-18 | How to darken widget/notification background in Layan-solid. | No response. |
| **#32** | OPEN | 2022-01-29 | Network tray icon shows "?" with bridge-only connections. | No response (icon `network.svg` lacks bridge states). |
| **#33** | CLOSED 2022-03-10 | 2022-02-14 | Tooltips white bg + white text on panel. | Fixed 2022-03-10. |
| **#36** | CLOSED 2022-03-10 | 2022-03-10 | Same as #33. | Fixed. |
| **#38** | OPEN | 2022-04-11 | KCommandBar (Ctrl+Alt+I) looks bad — 20% transparent text area, no margins. | No response. |
| **#40** | CLOSED 2022-05-18 | 2022-05-18 | (zh) Rime tray icon renders as white square. | Fixed same day. |
| **#41** | OPEN | 2022-05-21 | Panel rounded corners gone (XeroLinux/AUR install); 21 comments; git install works, AUR didn't. | Unresolved as to root cause (AUR PKGBUILD vs. git install; likely `common/` overlay not merged — same finding as kirodubes UPSTREAM.md, see §4). |
| **#45** | OPEN | 2022-06-19 | Popup message text white-on-light, unreadable, dark theme (Manjaro). | No response. |
| **#46** | CLOSED 2022-07-25 | 2022-07-23 | Adaptive panel opacity not working. | Fixed (closed). |
| **#47** | CLOSED 2023-01-09 | 2022-08-12 | Bluetooth tray icon black at 20px / ≥46px panel sizes. | Fixed 2023-01-09. |
| **#48** | OPEN | 2022-08-19 | Left-nav icons black/hard to see. | Comment: icon theme issue, not plasma theme. |
| **#53** | CLOSED 2023-05-03 | 2023-02-16 | Plasma 5.27 forces min panel size 32px. | vinceliuice: panel min height = 2× border-radius; set panel radius to 10px → allows 20px. |
| **#61** | CLOSED 2024-07-16 | 2024-02-25 | Plasma Vault icon dark grey on dark theme. | Fixed `64ae091`. |
| **#65** | CLOSED 2024-09-11 | 2024-09-08 | Can't download window decorations from store.kde.org (broken file). | vinceliuice re-uploaded / fixed the XML. |

### 1.5 Kvantum

| # | State | Date | Problem | Resolution / workaround |
|---|---|---|---|---|
| **#12** | OPEN | 2020-06-26 | Changing colours in kvconfig doesn't change everything (mix of grey/violet). | Colours are baked into the SVG (see #13). |
| **#17** | OPEN | 2020-12-14 | Make toolbar buttons more rounded in Kvantum Layan. | No response. |
| **#23** | OPEN | 2021-08-11 | (zh) Konsole tab bar not transparent until Application Style toggled. xspeed1989 (2025-09-30) asks how it was configured. | No fix. |
| **#28** | CLOSED 2021-11-30 | 2021-11-30 | Dolphin not transparent/blurred. | Self-resolved: fractional scaling 150% broke it; use 100% + Force Font DPI. |
| **#31** | CLOSED 2022-01-30 | 2022-01-26 | Elisa button text cut off. | "Kvantum issue, not theme issue". |
| **#35** | OPEN | 2022-03-07 | `qt.svg: Layan-solid.svg:6535: Could not resolve property: #linearGradient2307 / #radialGradient3660 / #radialGradient1988` warnings. | No fix — dangling gradient references in `Kvantum/Layan-solid/Layan-solid.svg`. Easy cleanup. |
| **#39** | CLOSED 2023-08-06 | 2022-04-28 | systemsettings5 crashes in icon view with Layan Kvantum theme. | Closed without comment. |
| **#49** | CLOSED 2022-09-26 | 2022-09-26 | GMAT tree view unreadable. | App bug. |
| **#50** | OPEN | 2022-10-02 | (zh) Plasma crashes when adding widgets after applying theme. | vinceliuice couldn't reproduce. |
| **#51** | OPEN | 2022-12-09 | (zh) System Settings → Connections crashes with Layan Kvantum theme; other Kvantum themes fine. | No response. Possibly same class as #39. |
| **#56** | CLOSED 2023-05-06 | 2023-05-05 | What's the window transparency value? | 0.8 in the Kvantum SVG; window colour `#31313A`. |
| **#57** | OPEN | 2023-07-16 | Dolphin sidebar selected text colour wrong until second click (light). | micmalti: Dolphin/Kvantum bug (tsujan/Kvantum#937). |
| **#64** | CLOSED 2024-07-14 | 2024-07-13 | (zh) qBittorrent/Telegram need double-click; drag selects whole box; transparent menus. | Fixed `1eed6f6`. |
| **#18** | CLOSED 2023-11-07 | 2021-03-12 | Not enough button padding in Discover/System Settings. | Closed. |
| **#24** | OPEN | 2021-08-15 | Checked text-input styling weird in TodoList plasmoid. | No response. |

### 1.6 Colour scheme / accent colour

| # | State | Date | Problem | Resolution / workaround |
|---|---|---|---|---|
| **#11** | OPEN | 2020-04-24 | How to change the primary (violet) colour? | vinceliuice: edit `.colors`; for Kvantum edit `highlight.color` in kvconfig and every colour in the SVG with a text editor. |
| **#13** | OPEN | 2020-07-07 | Change colour scheme / request more colour variants. 9 comments. | Same advice; xelyos94ro found `window.color` in kvconfig is overridden by the SVG `window` element. No variants ever added. |
| **#58** | OPEN | 2023-08-17 | Suggestion: KDE accent colour support. | No response. **Relevant for Plasma 6** (`AccentColor`/`accentColorFromWallpaper`; Kvantum SVG hardcodes purple). |

### 1.7 Install script / packaging

| # | State | Date | Problem | Resolution / workaround |
|---|---|---|---|---|
| **#1** | CLOSED 2020-01-23 | 2019-10-24 | `WALLPAPER_DIR` undeclared in install.sh. | Fixed. |
| **#2** | CLOSED 2020-01-30 | 2019-10-30 | System-wide install support. | Added (root → `/usr/share`). |
| **#37** | OPEN | 2022-04-06 | Add theme to Flatpak repo. | No response. |
| **#52** | CLOSED 2024-02-25 | 2023-02-15 | `install.sh: 6: [: Illegal number` / `27: Syntax error "("` on Ubuntu-KDE → ran with `sh` not `bash`. | Closed (README says `sh ./install.sh` — still a foot-gun; PolybiusPro adds `set -euo pipefail`, `$EUID`). |

### 1.8 Open issues most relevant to Plasma 6.x today (summary)

1. **SDDM**: #68, #73 (open) + #78's note — Store/AUR copies stale; `icon.name` with absolute file paths is fragile (invisible icons, NixOS). Also Fedora 44+ replaces SDDM with **Plasma Login Manager (PLM)** which ignores custom QML themes (documented in kineticz fork README). `sddm/5.0` should be clearly marked Plasma-5-only or removed (PolybiusPro removed all bundled SDDM).
2. **Splash**: #74 `bottomRect` ReferenceError — trivial fix (declare the Image) or port to `import QtQuick` and Plasma-6 splash stage semantics (PolybiusPro did both).
3. **Dolphin location bar opaque** (#72) — Kvantum needs styling for KDE Gear ≥25.08 URL navigator.
4. **Panel/plasmoid icons**: #82 (Andromeda launcher size), #80 (slider at 100%), #25 (margins separator), #32 (bridge network icon).
5. **Aurorae**: #26 (no top-edge resize), #66 (fullscreen blur strip), #44 (blur mask), #54.
6. **Accent colour** (#58) and colour variants (#11/#13) — long-standing feature request.
7. **Kvantum warnings** (#35) — dangling gradient IDs in `Layan-solid.svg`.
8. **Installer** (#52, #60) — `sh` vs `bash`, unclear solid-decoration install.

---

## 2. Pull requests (9 total: 4 merged, 3 open, 2 closed-unmerged)

| PR | State | Author | Created | Merged | Summary |
|---|---|---|---|---|---|
| **#79** | OPEN | ayylmaonade | 2026-05-19 | — | "fix: remove duplicate `<style>` tags in icon SVGs". Qt 6.11+ SVG parser chokes on empty `<style type="text/css"/>` blocks → grey/white tooltip backgrounds on Plasma 6.6/Qt 6.11 (Arch). Removes duplicates from `plasma/desktoptheme/common/icons/manjaro.svg` (1), `common/icons/pamac.svg` (3), `Layan-light/icons/system.svg` (3); keeps `id="current-color-scheme"` block. No comments. **Highly relevant for Plasma 6.7 / Qt 6.11+.** |
| **#77** | CLOSED (not merged) | duayfabi (fork since deleted) | 2025-12-20 | — | "Fix absolute sddm icon path to work with nixos". Changes `sddm/5.0/*/Main.qml` `iconSource:` and `sddm/6.0/*/Main.qml` `icon.name:` from `/usr/share/sddm/themes/Layan*/assets/X.svgz` to `Qt.resolvedUrl("assets/X.svgz")` (4 files, +4/-4 each). Head sha `f364bf9`. Closed without comment. |
| **#76** | OPEN | gertvermeersch | 2025-12-19 | — | "Fix/debian13 bug" — Debian 13 SDDM fatal "cannot be loaded… Main.qml". Final patch: `sddm/6.0/Layan/Main.qml` only, `icon.name: "/usr/share/…svgz"` → `icon.name: Qt.resolvedUrl("assets/…svgz")` (8 lines). Replaces #75 which made icons invisible. Doesn't touch Layan-light. Based on Manjaro forum thread on `fontSize`. |
| **#75** | CLOSED (not merged) | gertvermeersch | 2025-12-17 | — | Earlier attempt: `icon.name` → `icon.source` (commit `f788194`); author closed it because icons became invisible; superseded by #76 (`34bc31d` "fixed invisible icons"). |
| **#70** | OPEN | 1103409364 | 2025-03-31 | — | "Fix cursor and light theme icons" — changes look-and-feel `defaults`: dark: `cursorTheme=breeze_cursors`, `Theme=Papirus-Dark`; light: `cursorTheme=Breeze_Light`, `Theme=Papirus-Light` (replacing `Layan-white-cursors`, `Tela`/`Tela-circle`). Personal preference, not a fix; note trailing whitespace after cursor names. Unlikely to be merged. |
| **#69** | MERGED 2025-01-05 | YageGeng | 2025-01-03 | `7ae1025` | "fix sddm display error": in both `sddm/6.0/*/Main.qml` change `iconSource:` → `icon.name:` (8 ActionButtons each) and revert `Login { font.pointSize }`→`fontSize`, `Battery { font.pointSize }`→`fontSize` (those components define their own `fontSize`). |
| **#62** | MERGED 2024-05-21 | Soudini | 2024-03-27 | `7b8c621`/`0118e95` | "Update to plasma 6": adds `metadata.json` for aurorae/{Layan,Layan-light,Layan-solid}, desktoptheme/{Layan,Layan-light}, look-and-feel ×2 (with `KPackageStructure`), sddm ×2, wallpaper ×2. Per #59 recipe. Tested with plasma-desktop 6.0.2, kvantum 1.1.0. |
| **#5** | MERGED 2020-02-01 | nhchiu | 2020-02-01 | | "Add an uninstallation script". |
| **#3** | MERGED 2020-01-23 | ShayBox | 2020-01-18 | | "Move Layan folder to themes subdirectory" — `aurorae/Layan` → `aurorae/themes/Layan` so the tree mirrors `/usr/share`. |

---

## 3. Forks (36 listed by API; 7 return 404 — deleted/private)

Compare API run as `repos/OWNER/Layan-kde/compare/vinceliuice:master...OWNER:<default_branch>`.

### 3.1 Forks that are AHEAD of upstream

#### PolybiusPro/Layan-kde (branch `main`, also `feature/f44-update`) — ahead 7, behind 0 — pushed 2026-08-18 — **most significant Plasma 6 modernisation**

Commits:
| sha | date | message |
|---|---|---|
| 67fb41c | 2026-05-23 | Modernize Layan for Plasma 6 with Konsole support and a simpler installer. "Add matching Konsole color schemes and translucent profiles, align accent colors with the Layan purple, refactor install.sh with --apply/--system options, and remove bundled SDDM themes from the repo." |
| d5241d3 | 2026-05-23 | Update readme with images |
| 5ccc703 | 2026-05-23 | Update readme to redirect to original project |
| ece03fa | 2026-05-23 | Remove duplicate preview in README.md |
| 50c9566 | 2026-05-23 | Merge PR #1 from PolybiusPro/feature/f44-update |
| 5e1e426 | 2026-08-18 | Remove dangling xlink:href in maximize/restore SVGs |
| 58d0064 | 2026-08-18 | Make titlebar button hover icons fully opaque |

118 files changed. Key changes:
- **Splash fix (#74)**: `Splash.qml` (both variants): `import QtQuick 2.1` → `import QtQuick`; adds `fillMode: Image.PreserveAspectCrop`; adds the missing `Image { id: bottomRect; anchors.horizontalCenter; y: -height; source: "images/rectangle.svg" }`; replaces `onStageChanged: if (stage == 1)` with `startIntro()` that runs when `stage >= 2` (called from `Component.onCompleted` and `onStageChanged`).
- **Aurorae**: `aurorae/themes/{Layan,Layan-light,Layan-solid}/maximize.svg` & `restore.svg` — removed dangling `<use xlink:href="#g1000">` element (invalid reference); `maximize/minimize/restore.svg` hover icon path `opacity:0.75` → `opacity:1` (Layan & Layan-solid).
- **Colour schemes**: `Layan.colors` — `ForegroundLink` 66,133,244 → 86,87,245 (Layan purple) in every section; Complementary `DecorationFocus/Hover` → 86,87,245; `[General] ColorScheme=VimixDarkDoder` → `Layan`. `LayanLight.colors` Complementary: `DecorationHover` 79,83,91 → 111,110,255, `ForegroundInactive` → 180,180,180, `ForegroundNormal` → 255,255,255.
- **Konsole** (new): `konsole/Layan.colorscheme`, `Layan.profile`, `LayanLight.colorscheme`, `LayanLight.profile` — translucent (Blur=true, Opacity 0.86 light), palette derived from `.colors` (bg 49,49,58 dark / 255,255,255 light, accent 86,87,245).
- **look-and-feel `defaults`**: dark `Theme=Tela` → `Tela-dark`; adds `[kdeglobals][KDE] LookAndFeelPackage=com.github.vinceliuice.Layan`, `DefaultDarkLookAndFeel=…Layan`, `DefaultLightLookAndFeel=…Layan-light`, `AutomaticLookAndFeel=false` (Plasma 6 light/dark pairing keys). Light gets the same 4 keys.
- **metadata.json / metadata.desktop**: removes `X-KPackage-Dependencies` (the `kns://…` store links for colorschemes/plasma-themes/aurorae/wallpaper/sddmtheme/icons/xcursor) and one line from metadata.desktop.
- **install.sh** rewritten: `set -euo pipefail`, `$EUID`, `--system/--user/--apply/--apply-light/-h`, quoted paths, `mkdir -p`, installs `konsole/`, runs `kbuildsycoca6`, optional `plasma-apply-lookandfeel -a`, warns about duplicate `/usr/share` + `~/.local` look-and-feel entries and removes the user copies on system install; drops `LAYOUT_DIR`. `uninstall.sh` `$UID`→`$EUID`, +10 lines (Konsole removal).
- **Removed `sddm/5.0` and `sddm/6.0` entirely** (README says to get SDDM elsewhere) — so not useful as an SDDM fix source.

#### Kattair/Layan-kde (`master`) — ahead 4, behind 0 — pushed 2026-06-14

| sha | date | message |
|---|---|---|
| 9ce241a | 2026-06-13 | Combine existing light and dark wallpapers |
| 0cb3501 | 2026-06-13 | Update install and uninstall scripts |
| 5380408 | 2026-06-14 | Change Layan Light default icons to Tela |
| 520f774 | 2026-06-14 | Copy default Breeze logout and change it to white |

Changes (9 files): new `wallpaper/LayanAutomatic/` (metadata.json + `contents/images/2560x1440.png` + `contents/images_dark/2560x1440.png`) — Plasma 6 light/dark auto-switching wallpaper; `install.sh`/`uninstall.sh` get `install-automatic-wallpaper` / `uninstall-automatic-wallpaper` functions; Layan-light `defaults` `Theme=Tela-circle` → `Tela`; adds `com.github.vinceliuice.Layan-light/contents/logout/{Logout.qml (346 lines), LogoutButton.qml, timer.js}` — a copy of Breeze's Plasma 6 logout screen recoloured white for the light theme.

#### kineticz/Layan-kde (`master`) — ahead 4, behind 0 — pushed 2026-05-22 — **Fedora 44 / PLM notes + opaque panel**

| sha | date | message |
|---|---|---|
| b59cc00 | 2026-05-21 | colors fine tune |
| 15ed54c | 2026-05-21 | update |
| a2c5de2 | 2026-05-21 | fix panel size issue |
| 6688f2d | 2026-05-22 | (nl) Add Fedora 44/PLM documentation and auto-install Kvantum on Fedora via install.sh |

Changes (15 files):
- **README**: new section "Fedora 44+ / Plasma Login Manager (PLM) users" — Fedora 44 replaces SDDM with PLM which is hard-coded to Breeze and **does not support custom QML themes**; PLM picks colour scheme + wallpaper from Plasma settings; to keep the Layan login screen: `sudo dnf swap plasma-login-manager sddm`, then `sudo cp -r sddm/6.0/Layan /usr/share/sddm/themes/` and set `Current=Layan`.
- **install.sh**: `install_fedora_deps()` — detects Fedora via `/etc/os-release`, `dnf install -y kvantum kvantum-qt6` if missing.
- **Panel background** (`common/widgets/panel-background.svg`, `translucent/`, `solid/`): all `ColorScheme-Background` segments `opacity:0.6` → `opacity:1` (fully opaque panel) and shadow/highlight gradients `opacity:0.15` → `0`. I.e. **removes panel translucency** — a personal preference, opposite of most users' wishes (#21, #41).
- **Aurorae `decoration.svg`** (Layan +12/-12, Layan-light +16/-16) and **Kvantum `Layan.svg`/`LayanDark.svg`** (+9/-9 each): colour fine-tuning (exact hex not extracted).
- **Colour schemes**: `ContrastAmount` 0.65→0.6; Inactive `ColorAmount` 0.025→0.175, `ContrastAmount` 0.1→0.2; `BackgroundAlternate` = `BackgroundNormal` (49,49,58 dark / 255,255,255 light).
- **Layouts** (`org.kde.plasma.desktop-layout.js` both variants, +89/-14): replaces `org.kde.plasma.splitdigitalclock` (3rd-party) with stock `org.kde.plasma.digitalclock`; adds `org.kde.plasma.systemmonitor.cpucore` applet with Dutch title and per-core colours; top panel `floating: 1`, `opacity: 0`; adds a second left auto-hide panel with `icontasks`. Light `metadata.json` +10/-4.

#### 1103409364/Layan-kde (`master`) — ahead 5 (3 real + 2 merges), behind 0 — pushed 2026-01-31

`cfbdf84`, `32e5774` (2025-03-30), `dc4d82c` (2025-04-06): look-and-feel `defaults` → `breeze_cursors`/`Papirus-Dark` (dark), `Breeze_Light`/`Papirus-Light` (light). Same content as open PR #70. Merges from upstream 2025-11-23 and 2026-01-31.

#### YooLc/Layan-kde (`master`) — ahead 2, behind 27 — pushed 2023-08-19

`7d9d68a` "Reduce padding", `eee17d5` "Update decoration.svg to make title bar more translucent". `aurorae/themes/Layan/Layanrc`: `BorderLeft/Right` 2→4, `ButtonMargin*` 2→3, `Padding*` 10→7, `TitleEdgeTop(Maximized)` 5→7; `decoration.svg` +28/-21 (more transparent titlebar). Pre-Plasma-6.

#### igorpadua/Layan-kde (`master`) — ahead 40, behind 70 — pushed 2020-10-16 — 9 stars

Not a Layan fix fork: it's **"Dracula-kde" — a Dracula-coloured re-skin** (2020). Renames everything to `Dracula-kde`, `Dracula-kde-green`, adds `Dracula-kde-rounded` aurorae based on WhiteSur, removes upstream `install.sh`/`Layan.colors`. 300 files. Historical only.

#### ayylmaonade/Layan-kde — `master` even; branch `fix/duplicate-style-tags` ahead 1 (`7671e6d`, 2026-05-19) = PR #79.

#### gertvermeersch/Layan-kde — `master` even; branch `fix/debian13-bug` ahead 2 (`f788194` icon.source, `34bc31d` Qt.resolvedUrl) = PR #75/#76.

#### Soudini/Layan-kde — `master` behind 19; branch `plasma-6` ahead 0/behind 23 (already merged as PR #62).

### 3.2 Forks even with or behind upstream (no unique commits)

| owner | branch | pushed | ahead/behind |
|---|---|---|---|
| singaravela45 | master | 2026-04-29 | 0/0 |
| randyprice | master | 2025-11-27 | 0/0 (author of #78) |
| Hankanman | master | 2025-11-27 | 0/0 |
| devAether666 | master | 2025-11-27 | 0/0 |
| d1vbyz3r0 | master | 2025-11-27 | 0/0 |
| gaikwadyash905 | master | 2025-02-12 | 0/2 |
| orphen05 | master | 2024-10-09 | 0/9 |
| RuEijk | master | 2023-09-30 | 0/26 |
| Spiky2 | master | 2023-04-30 | 0/30 |
| MatMB115 | master | 2023-03-08 | 0/32 |
| Rayrsn | master | 2022-07-24 | 0/41 |
| acidburn0zzz | master | 2022-04-07 | 0/46 |
| davigamer987 | master | 2022-02-13 | 0/52 |
| Mondrethos | master | 2021-10-21 | 0/60 |
| anu-prakash-dev | master | 2021-10-03 | 0/61 |
| z9ta | master | 2021-09-04 | 0/62 |
| lymbot | master | 2021-07-30 | 0/64 |
| ayvind | master | 2021-04-26 | 0/65 |
| joseluisgs | master | 2020-11-04 | 0/67 |
| ranatauqeer | master | 2020-01-18 | 0/88 |

### 3.3 Forks returning HTTP 404 (deleted, renamed or private — could not inspect)

gg582 (pushed 2026-06-26), vovkus (2026-06-25), ImThomasThorne (2026-04-30), securenode (2025-11-27), samwhelp (2025-11-27), MX-Goliath (2025-06-21), HerrCraziDev (2022-06-22). Also duayfabi (PR #77 head) — repo deleted.

`sort=stargazers` was not run separately; star counts came from the newest-sorted listing (only igorpadua=9, acidburn0zzz=1, joseluisgs=1 have stars).

---

## 4. Related non-fork repositories

Searches run: `gh search repos "Layan"`, `"Layan kde"`, `"Layan plasma"`, `"Layan theme"`, `"Layan-kde"`, `"layan plasma6"` (last returned nothing).

### Official siblings (vinceliuice)
- **vinceliuice/Layan-gtk-theme** — 611★, pushed 2026-01-31.
- **vinceliuice/Layan-cursors** — 127★, pushed 2024-02-09.

### Plasma 6 derivatives / repackagings (most useful)
- **kirodubes/kiro-plasma-layan** — 0★, pushed 2026-08-20. Arch package "Kiro Layan" Plasma 6 global theme, everything renamed to `Kiro-`/`com.kiroproject.Layan` namespace so it coexists with upstream. Sources: dark variant captured from the **KDE Store install** (not git) because "the AUR build failed; the Store version works" — `UPSTREAM.md` diagnoses that a naive git copy that doesn't overlay `plasma/desktoptheme/common/` into the variant dir produces a broken desktoptheme (plausible root cause of issue #41's AUR-vs-git discrepancy). Kvantum + `sddm/6.0/Layan` taken from git `a0b6a49`; cursors from Layan-cursors `b8c4689`. CHANGELOG 2026-06-22: **fixed the broken panel clock** — upstream layout references 3rd-party `org.kde.plasma.splitdigitalclock`; repointed to `org.kde.plasma.digitalclock` (same fix as kineticz). Dropped the light variant 2026-06-22. Notes SDDM `Main.qml` carries absolute self-paths that had to be repointed.
- **xerolinux/xero-layan-git** — 179★, pushed 2026-09-02. "XeroLinux Layan Rice" (DarkXero-dev of #41/#59). Ships full dotfiles (`Configs/Home/.config/*`, `kdeglobals`, `kwinrc`, `plasma-org.kde.plasma.desktop-appletsrc`), **vendored copies of Kvantum Layan/LayanSolid (with `LayanDark`/`LayanSolidDark` kvconfig+svg) and aurorae Layan/Layan-light/Layan-solid** under `.local/share/aurorae/themes`, GRUB theme, Fedora + Arch installer. Not a fork; may contain locally tweaked SVGs (not diffed).
- **akanbaz/shooting-star-theme** — 0★, pushed 2026-08-01. "Shooting Star — dark Layan-based Plasma 6 Global Theme (CachyOS)". Documents Plasma 6 gotchas: uses `ColorSchemeIsDark`, **Application style Breeze not Kvantum because `QT_STYLE_OVERRIDE=kvantum` breaks Spectacle/Kirigami labels on Plasma 6**; pulls Layan pieces as KPackage/KNS dependencies from `plasma6-themes-layan-git`; separate `install-sddm.sh`.
- **david-x3d/kde-plasma-liquid-glass-theme** — 7★, pushed 2026-05-30 (search shows 2026-07-27). "Liquid Glass" rice using Layan-kde as submodule plus `themes/modified-layan/` — a full modified copy of the Layan **desktoptheme** (widgets/panel-background.svg, background.svg, dialogs, solid/translucent variants, icons, metadata.json) for "a cleaner transparent panel/shell look", with Darkly, BreezeEnhanced, Better Blur DX, KDE Rounded Corners.
- **ryanull24/Vivid-Blur-Dark-Aurorae-Layan-Merge** — 0★, 2026-01-16. Aurorae mash-up: Layan Dark `decoration.svg` + Vivid Blur Dark button SVGs, for KDE 6.5.
- **GokulNathReddy/KDE-Dots** — 1★, 2023-12-27. "Layan KDE Dot-Files" (Plasma 5 era).
- **alanjholiveira/Layan-kde-custom** — 0★, 2020-12-21. Old custom copy.
- **samwhelp/** — several ISO-builder/pacstall recipes bundling Layan: `ubuntu-iso-builder-import-pacstall-kde-plasma-theme-layan` (2026-05-19), `lika-live-build-recipe-kde-theme-layan`, `lika-live-build-flagship-kde-theme-layan` (2025-07-01), `eznixos-adjustment-iso-profile-kde-plasma-layan` (2023). Packaging only.
- **RebornOS-Team/rebornos-kde-layan** — 0★, 2021-06-25. Distro theming package.
- **TouchOfDeath/DragonTheme-Installer** — 0★, 2026-06-10. Plasma 5 one-click installer using Layan cursors/effects.

### Non-KDE ports of the Layan look
- xontab/layan-vscode-theme (5★), Pixelbounds/Kate-Layan, Pixelbounds/Zellij-Layan, Spiffily/mailspring-theme-layan, Shuriken00/layan-metacity (Metacity port of the GTK theme), emma-the-rock/Layan-cursors-for-Windows (9★), BradHeff/Hefftor-Layan-Theme, Neeraj029/layan-theme-files, bader07Asiri/layan-theme (empty desc).

(Everything else in the "Layan" search was unrelated Indonesian "layanan" projects or LayaBox.)

---

## 5. Consolidated list of concrete fixes available outside upstream master

| Area | Problem | Source | Change |
|---|---|---|---|
| Plasma theme / Qt 6.11 | Grey/white tooltips, SVG parse errors | **PR #79** (ayylmaonade `7671e6d`) | Remove empty duplicate `<style>` blocks in `common/icons/manjaro.svg`, `common/icons/pamac.svg`, `Layan-light/icons/system.svg` |
| Splash | `bottomRect is not defined` (#74) | PolybiusPro `67fb41c` | Add `Image{id:bottomRect}`; `import QtQuick`; stage ≥2 trigger; PreserveAspectCrop |
| SDDM 6.0 | Absolute `/usr/share/...` icon paths (NixOS, Debian 13) | PR #76 (gertvermeersch `34bc31d`), PR #77 (duayfabi `f364bf9`) | `icon.name: Qt.resolvedUrl("assets/X.svgz")` (Layan; #77 also Layan-light and 5.0) |
| SDDM 6.0 | `fontSize` crash on Store copy; icons missing | #73 comment (chalmery) | Drop ActionButton `fontSize`; use freedesktop `icon.name` (`system-suspend`, `system-reboot`, `system-shutdown`, `system-user-prompt`, `system-user-list`) |
| SDDM | Fedora 44+ PLM ignores SDDM themes | kineticz `6688f2d` README | Document `dnf swap plasma-login-manager sddm`; colour scheme + wallpaper are all PLM honours |
| Aurorae | Dangling `<use xlink:href="#g1000">` in maximize/restore.svg; 0.75 hover opacity | PolybiusPro `5e1e426`, `58d0064` | Remove `<use>`; opacity 1 |
| Aurorae | Titlebar padding/translucency tweak | YooLc `7d9d68a`, `eee17d5` | `Layanrc` paddings; decoration.svg |
| Colour scheme | Blue `ForegroundLink` (66,133,244) inconsistent with purple; `ColorScheme=VimixDarkDoder` leftover | PolybiusPro `67fb41c` | 86,87,245 everywhere; `ColorScheme=Layan` |
| Look-and-feel | No Plasma 6 dark/light pairing; Tela vs Tela-dark | PolybiusPro | `DefaultDarkLookAndFeel`/`DefaultLightLookAndFeel`/`AutomaticLookAndFeel=false`; `Theme=Tela-dark` |
| Look-and-feel layout | Panel clock broken: layout references 3rd-party `org.kde.plasma.splitdigitalclock` | kirodubes CHANGELOG 2026-06-22; kineticz `a2c5de2` | Use `org.kde.plasma.digitalclock` |
| Look-and-feel | Light theme logout screen | Kattair `520f774` | Adds `contents/logout/Logout.qml` (Breeze copy, white) |
| Wallpaper | Plasma 6 automatic light/dark wallpaper | Kattair `9ce241a` | `wallpaper/LayanAutomatic` with `images/` + `images_dark/` |
| Konsole | No Konsole scheme (#21) | PolybiusPro | `konsole/Layan*.colorscheme` + `.profile` |
| Installer | `sh` vs `bash` (#52), duplicate entries, no apply step, Fedora deps | PolybiusPro `install.sh`; kineticz `install_fedora_deps` | `set -euo pipefail`, `--system/--user/--apply`, `kbuildsycoca6`, `plasma-apply-lookandfeel`; `dnf install kvantum kvantum-qt6` |
| Packaging | AUR/git desktoptheme broken unless `common/` is overlaid into variant dir (#41) | kirodubes UPSTREAM.md | Overlay `plasma/desktoptheme/common/` into `Layan{,-light}/` |
| Plasma 6 Kvantum | `QT_STYLE_OVERRIDE=kvantum` breaks Kirigami/Spectacle labels | akanbaz/shooting-star-theme README | Don't set the env var; set widget style via kdeglobals only |

No fork or PR addresses: Dolphin location bar (#72), Andromeda icon size (#82), slider at 100% (#80), margins separator (#25), top-edge resize (#26), fullscreen blur strip (#66), accent colour (#58), Kvantum `Layan-solid.svg` dangling gradients (#35).
