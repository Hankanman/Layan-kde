# Layan-kde review — state of the theme on Fedora 44 / Plasma 6.7

Reviewed: upstream `vinceliuice/Layan-kde` at `a0b6a49` (2025-11-27), forked to `Hankanman/Layan-kde` and cloned here.
Target: Fedora 44, Plasma 6.7.4, KDE Frameworks 6.29, Qt 6.11.2, Kvantum 1.1.6, Plasma Login Manager 6.7.4 (this machine).
Sources: local file audit against the installed Breeze packages, KWin/libplasma binaries, journald on this machine, all 72 upstream issues, all 9 PRs, all 36 forks, and related derivative repos.

---

## 1. Verdict

The theme still installs and mostly renders on Plasma 6.7, because the 2024 "port to Plasma 6" only added `metadata.json` files. Nothing structural was changed since the Plasma 5 era, so a chunk of it is silently ignored or dead on a current Fedora:

- The whole `sddm/` tree (both `5.0` and `6.0`) does nothing on Fedora 44. The system boots Plasma Login Manager, which does not load SDDM QML themes.
- The desktop theme's settings file is still `metadata.desktop`. Plasma 6 reads a `plasmarc` file for those settings, so adaptive transparency, contrast and the default wallpaper hints are all ignored.
- The `opaque/` variant of the panel/dialog SVGs does not exist, so the panel cannot go opaque when a window touches it.
- The splash screen throws a QML ReferenceError on every login (confirmed in this machine's journal).
- The default panel layout references an applet that does not exist (`org.kde.plasma.splitdigitalclock`) and the removed Milou applet, and points at the Elarun wallpaper.
- The Aurorae theme relies on rc keys that the new Aurorae engine shipped in Plasma 6.4+ no longer reads (shadows, text shadows, border widths).
- Three icon SVGs and six Aurorae button SVGs have malformed content that Qt 6.11's stricter SVG parser rejects.

Upstream has been quiet since 2025-11-27 with 41 open issues and 3 open PRs. Nobody has made a "proper" Plasma 6 port; the most useful outside work is in the PolybiusPro, Kattair and kineticz forks and in PR #79.

---

## 2. What is broken (verified)

### 2.1 Plasma desktop theme (`plasma/desktoptheme`)

| # | Problem | Evidence | Fix |
|---|---|---|---|
| B1 | Theme settings ignored. `[ContrastEffect]`, `[AdaptiveTransparency]`, `[Wallpaper]` live in `metadata.desktop`. libplasma 6 reads them from a `plasmarc` file in the theme root (Breeze ships one; `libPlasma.so.6` contains the string `plasmarc` and no `metadata.desktop`). | `/usr/share/plasma/desktoptheme/default/plasmarc` vs `plasma/desktoptheme/Layan/metadata.desktop` | Add `plasmarc` to each variant with the same sections; add `[BlurBehindEffect] enabled=true`. Keep `metadata.desktop` only if Plasma 5 support is still wanted. |
| B2 | No `opaque/` element set. Plasma 5.20+ / 6 looks up `opaque/widgets/panel-background.svg`, `opaque/dialogs/background.svg`, `opaque/widgets/tooltip.svg` when the panel is set to Opaque or adaptive transparency kicks in. Layan only has `solid/` (used when compositing is off) and `translucent/`. | Breeze has `opaque/`, `solid/`, `translucent/`; Layan lacks `opaque/`. Matches upstream issue #46 and #21 reports. | Copy `solid/` to `opaque/` and tune; `solid/` can then be a plain fallback. |
| B3 | Qt 6.11 SVG parser rejects duplicate/empty `<style>` blocks, giving white/grey tooltips. | `common/icons/manjaro.svg`, `common/icons/pamac.svg`, `Layan-light/icons/system.svg` each have two `<style>` elements. Open PR #79 (ayylmaonade, 2026-05-19) fixes exactly this. | Merge PR #79. |
| B4 | Missing element files vs Breeze default: `widgets/frame.svg`, `radiobutton.svg`, `dragger.svg`, `picker.svg`, `media-delegate.svg`, `monitor.svg`, `timer.svg`, `analog_meter.svg`, `branding.svg`, `margins-highlight.svg`, `weather/wind-arrows.svg`, `icons/kup.svg`, `icons/mobile.svg`. Fallback to Breeze works but looks inconsistent (radio buttons, frames, the panel-edit margin highlighter). | `comm` of file lists | Author them or explicitly accept Breeze fallback. `margins-highlight.svg` is what upstream issue #25 (Margins Separator) needs. |
| B5 | `metadata.json` lacks `"X-Plasma-API": "5.0"` that Breeze declares. Harmless today, but it is what KPackage uses to decide the theme is Plasma 6 native. | Breeze `metadata.json` | Add. |

### 2.2 Look-and-feel (`plasma/look-and-feel`)

| # | Problem | Evidence | Fix |
|---|---|---|---|
| B6 | Splash screen animation targets an undefined id. `Splash.qml:88-89` animate `target: bottomRect` but no item with that id exists. | `journalctl --user -b` on this machine: `ksplashqml ... Splash.qml:89: ReferenceError: bottomRect is not defined` (9 occurrences at login). Upstream issue #74. | Either delete the second `PropertyAnimation` or add the missing `Image { id: bottomRect }` (PolybiusPro `67fb41c` does the latter). Also the splash starts on `stage == 1`; Breeze 6 uses stage 2 and fades out on stage 5. |
| B7 | Default layout is broken. `org.kde.plasma.desktop-layout.js` places `org.kde.plasma.splitdigitalclock` (third-party, not installed) and `org.kde.milou` (removed in Plasma 6), and sets the desktop wallpaper to `/usr/share/wallpapers/Elarun/...2560x1600.png` instead of Layan. | grep of the layout file; `/usr/share/plasma/plasmoids` has neither applet. kirodubes and kineticz forks both had to repoint the clock. | Use `org.kde.plasma.digitalclock`, drop Milou (KRunner is global now), set wallpaper via `[Wallpaper] Image=Layan` in `defaults` like Breeze does, or use `loadTemplate("org.kde.plasma.desktop.defaultPanel")` and only adjust what Layan needs. |
| B8 | `defaults` is incomplete for Plasma 6. It does not set `[ksplashrc][KSplash] Theme`, `[Wallpaper] Image`, or the Plasma 6 light/dark pairing keys. It also points the decoration at `library=org.kde.kwin.aurorae` while a live Plasma 6.7 install uses `org.kde.kwin.aurorae.v2` (this machine's kwinrc after applying the theme). | Breeze `contents/defaults`; `kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key library` | Add the missing groups; add `DefaultDarkLookAndFeel`/`DefaultLightLookAndFeel` so the Plasma 6.6+ automatic light/dark switch pairs Layan with Layan-light (PolybiusPro does this). |
| B9 | `defaults` hard-depends on third-party packages that are not on Fedora: `cursorTheme=Layan-white-cursors`, icons `Tela` / `Tela-circle`, `widgetStyle=kvantum-dark`. Applying the global theme on a clean Fedora leaves cursor and icons unset. | file content; PR #70 and the 1103409364 fork exist only to swap these | Either fall back to `breeze_cursors`/`breeze-dark`, or keep the KNS dependencies but restore them correctly (see B10). **Done (plasma6):** KNS dependencies kept for System Settings; `install.sh --apply` detects missing Tela/Layan-cursors and applies Breeze instead. Confirmed live on Fedora 44: applying without Tela left the panel and System Settings without icons. |
| B29 | After switching icon theme while plasmashell runs (which `--apply` does), the system tray reserves space for its items but draws no icons until plasmashell restarts. Not a theme or Kvantum bug: verified on Plasma 6.7.4 that a plain `plasmashell --replace` with the unchanged Layan/LayanDark Kvantum theme restores every tray icon. Also established that Plasma 6.7 never reads `plasma/desktoptheme/*/icons/*.svg` (no entries ever appear in `~/.cache/ksvg-elements`); tray icons come from the icon theme via Kirigami.Icon/KIconLoader. | live test | `install.sh --apply` restarts the shell. **Done (plasma6).** |
| B10 | `X-KPackage-Dependencies` in `metadata.json` still lists the KDE Store IDs. Those trigger a store download on apply. That is fine on Fedora, but the SDDM entry (`sddmtheme.knsrc/.../1325235`) is useless now, and the Store copy of the SDDM theme is stale (issue #78). | metadata.json | Drop the sddm dependency; verify the other IDs still resolve. |
| B11 | No `contents/logout/` in either variant, so the logout/shutdown dialog is Breeze's. Kattair `520f774` added a white-recoloured copy for the light variant. | Breeze L&F has `logout/` | Add Layan-styled logout for both variants. Note that lockscreen theming is no longer part of look-and-feel in Plasma 6. |

### 2.3 Aurorae window decoration (`aurorae/themes`)

Plasma 6.4 replaced the QML Aurorae engine with a C++ one (`org.kde.kwin.aurorae.v2`, present on this machine). It reads a subset of the old rc keys.

| # | Problem | Evidence | Fix |
|---|---|---|---|
| B12 | Keys in `Layanrc` that the v2 engine does not read: `UseTextShadow`, `TextShadowOffsetX/Y`, `ActiveTextShadowColor`, `InactiveTextShadowColor`, `ButtonMarginBottom`, `ButtonMarginleft` (also a typo), `ButtonMarginRight`, `LeftButtons`, `RightButtons`, all `*TabColor` keys. `Shadow` is also unused: v2 synthesises shadows from the decoration frame padding and never reads `shadow-*` SVG elements. `BorderLeft/Right/Top` ARE read (a plain `strings` grep misses them because the compiler merges them into `TitleBorderLeft`). | kwin `v6.7.4` source `src/plugins/kdecorations/aurorae/v2/decorationtheme.cpp`, cross-checked against the installed `.so` | Remove dead keys; accept that button order comes from the KWin KCM. **Done on `plasma6`.** |
| B13 | Dangling `<use xlink:href="#g1000">` in `maximize.svg` and `restore.svg` of all three variants. Qt 6 logs a warning and skips the element. | grep across `aurorae/themes/*/*.svg` | PolybiusPro `5e1e426` removes them. |
| B14 | Missing button SVGs: `help.svg`, `shade.svg`, `menu.svg`, `appmenu.svg` (application menu button). Those buttons render empty if a user adds them in the KCM. Also `metadata.json` declared `KPackageStructure: aurorae`; the registered type is `KWin/Aurorae`, and `metadata.desktop` is still required by the theme provider. | file list; `kpackagetool6 --list-types` | Add buttons, fix the package type, keep `metadata.desktop`. **Done on `plasma6`.** |
| B15 | Long-standing open Aurorae bugs never fixed: blur strip above fullscreen windows (#66), tiling mis-positions titlebar contents (#54). #26 (cannot resize from top edge) is fixed at the engine level in v2, which always adds an invisible resize strip above the top border. | issues; kwin v2 `updateResizeOnlyBorders()` | Re-test #66 and #54 on v2. |

### 2.4 SDDM (`sddm/5.0`, `sddm/6.0`)

| # | Problem | Evidence | Fix |
|---|---|---|---|
| B16 | Not used at all on Fedora 44. `plasmalogin.service` (Plasma Login Manager 6.7.4) is the enabled display manager; `sddm` is not installed. PLM has no theme loader; its KCM only exposes a wallpaper plugin and a "synchronise settings" button. | `systemctl status display-manager`, `rpm -qa`, `kcm_plasmalogin.so` strings, upstream README of `KDE/plasma-login-manager` | Stop shipping SDDM as a first-class component. Provide a Layan login wallpaper and a documented `plasmalogin` sync step instead. kineticz `6688f2d` documents `dnf swap plasma-login-manager sddm` for people who insist on the old theme. |
| B17 | For distros still on SDDM: `Main.qml` uses absolute `/usr/share/sddm/themes/Layan/assets/*.svgz` paths in `icon.name` (breaks NixOS, Debian 13, any user-local install). Open PR #76 and closed PR #77 fix this with `Qt.resolvedUrl("assets/...")`. `theme.conf` has no `showlogo`/`logo` keys although `Main.qml` reads them and `default-logo.svg` is shipped. | diff of Layan vs Layan-light Main.qml; PRs | Merge #76 and extend to Layan-light; add `showlogo=shown`/`logo=default-logo.svg` to `theme.conf`. |
| B18 | `sddm/5.0` is Plasma 5 only (`QtQuick.Controls 1.1`, `QtGraphicalEffects`). Users keep installing it on Plasma 6 and hitting "module QtQuick.Controls version 1.1 is not installed" (issue #68). | file content, issue #68 | Move to a `legacy/` folder or delete. |
| B19 | The `sddm/6.0/install.sh` prompts for the root password interactively and pipes it to `sudo -S`. | file content | Replace with a plain "run with sudo" check. |

### 2.5 Colour schemes (`color-schemes`)

| # | Problem | Evidence | Fix |
|---|---|---|---|
| B20 | `[General] ColorScheme=VimixDarkDoder` is a copy-paste leftover from another theme. | file content | `ColorScheme=Layan`. |
| B21 | `ForegroundLink` is Google-blue `66,133,244` in every section while the accent is purple `86,87,245`. | file content; PolybiusPro `67fb41c` | Use the accent for links (or make it a lighter purple in the dark scheme for contrast). |
| B22 | Key set matches Breeze 6 exactly (Header, Header Inactive, Tooltip, Complementary all present), so nothing is missing here. | `diff` of key lists | None. |

### 2.6 Kvantum (`Kvantum`)

| # | Problem | Evidence | Fix |
|---|---|---|---|
| B23 | Only reachable if the user runs `kvantummanager` manually. `defaults` sets `widgetStyle=kvantum-dark` but the Kvantum theme name is chosen in `~/.config/Kvantum/kvantum.kvconfig`, which nothing in the repo writes. | install.sh, defaults | Have the installer write `[General] theme=LayanDark` (or `Layan`) into `kvantum.kvconfig` when `--apply` is used, or drop Kvantum for Breeze + colour scheme (see M4). |
| B24 | Dolphin URL navigator became opaque after KDE Gear 25.08 (issue #72, open, upstream told the reporter to move the bar). No fork fixes it. | issue | Style the new `KUrlNavigator` toolbar/lineedit combination in the SVG/kvconfig. |
| B25 | Issue #35: dangling gradient references in the Kvantum SVG. Not reproducible in this checkout (all `url(#...)` resolve), so it was fixed at some point; keep a lint step so it does not regress. | grep | Add an SVG reference lint to CI. |

### 2.7 Installer and repo hygiene

| # | Problem | Evidence | Fix |
|---|---|---|---|
| B26 | `install.sh` deletes `${AURORAE_DIR}/Layan*` and `${KVANTUM_DIR}/Layan*` with an unquoted glob; run as root that is `/usr/share/aurorae/themes/Layan*`. It also has no `set -e`, relies on `bash` but README says `sh ./install.sh` (issue #52 crash), has an unused `LAYOUT_DIR`, and never runs `kbuildsycoca6` or offers to apply the theme. | file content | PolybiusPro's rewrite (`set -euo pipefail`, `--system/--user/--apply`, `kbuildsycoca6`, `plasma-apply-lookandfeel`) is a good base. |
| B27 | No packaging or CI: no RPM spec, no Copr, no SVG/QML lint, no screenshots pipeline. The Arch AUR/KDE Store copies drifted from git and caused a whole class of issues (#41, #78). | repo | Add a `.spec` + Copr build, a GitHub Action that runs `xmllint`, `qmllint` and a dangling-id check. |
| B28 | Wallpaper packages ship one 2560x1440 PNG each; `wallpaper/Layan/contents/sceenshot.png` is misspelled. | file list | Add 3840x2160 and 5120x2880 renders and fix the filename. |

---

## 3. What is missing for a "complete" Plasma 6 global theme

Compared with what Breeze, Breeze Dark and Breeze Twilight ship in Plasma 6.7, plus what users have asked for:

| # | Gap | Why it matters | Reference |
|---|---|---|---|
| M1 | **Light/dark automatic pairing.** Plasma 6.6+ can switch global themes with the day/night schedule; that needs `DefaultDarkLookAndFeel`/`DefaultLightLookAndFeel` in `defaults` and a wallpaper package with `images/` and `images_dark/`. | Users on Fedora 44 expect this to just work. | Kattair `9ce241a` (`LayanAutomatic` wallpaper), PolybiusPro defaults, Breeze `Next` wallpaper |
| M2 | **Logout screen** (`contents/logout/Logout.qml`) for both variants. | Currently Breeze's dialog appears inside a Layan session. | Kattair `520f774` |
| M3 | **Login screen for Plasma Login Manager.** A Layan login wallpaper (dark + light) and a documented `plasmalogin` sync, replacing the SDDM directory as the primary path. | It is the only login theming PLM supports. | kineticz README, `KDE/plasma-login-manager` README |
| M4 | **A Kvantum-free application style path.** Kvantum on Plasma 6 has known breakage (Kirigami labels when `QT_STYLE_OVERRIDE` is set, Dolphin URL bar, KCommandBar #38), and Fedora does not preinstall it. The colour scheme + Breeze style is what Breeze Twilight relies on. | Makes the global theme usable on a stock Fedora without an extra package. | akanbaz/shooting-star-theme README |
| M5 | **Konsole colour scheme and profile.** | Most "terminal is not transparent" issues (#21, #23) come from having none. | PolybiusPro `konsole/` |
| M6 | **Accent colour support** (#58, open since 2023). Plasma 6 has system accent colours; the SVGs hardcode `#5657f5`. | Users cannot recolour without editing SVGs (#11, #12, #13). | Use `ColorScheme-Highlight`/`ColorScheme-Accent` stylesheet classes in Plasma SVGs; Kvantum cannot follow accent colour, another reason for M4. |
| M7 | **Colour variants.** Only purple exists; #13 asked for variants in 2020. Vince's other themes (WhiteSur, Graphite) ship a `--color` flag with sed-based recolouring. | | WhiteSur-kde `install.sh` pattern |
| M8 | **KDE-Rounded-Corners / floating panel awareness.** Plasma 6 panels float by default; `panel-background.svg` has `mask-*` and `shadow-*` elements (good) but no `opaque/` variant (B2) and the shadow gradient assumes a docked panel. | | kineticz `a2c5de2`, david-x3d modified-layan |
| M9 | **Missing Plasma SVG elements** listed in B4. | | Breeze default theme |
| M10 | **Missing Aurorae buttons** listed in B14, plus `decoration-maximized` / `decoration-maximized-inactive` elements the v2 engine looks for (it falls back to `decoration`, so corners stay rounded when maximised). | | `strings` of aurorae.v2 |
| M11 | **GRUB / Plymouth / cursor / GTK** are separate vinceliuice repos (`Layan-gtk-theme`, `Layan-cursors`). Nothing in this repo links them or installs them. | A "complete" desktop needs at least the GTK theme for Flatpak/GTK apps and the cursor the `defaults` file already demands. | `X-KPackage-Dependencies` only covers cursors via KNS |
| M12 | **Previews.** `previews/preview.png`, `fullscreenpreview.jpg` and `splash.png` are Plasma 5 screenshots (old panel, Latte-style dock). | System Settings shows outdated pictures. | Re-shoot on Plasma 6.7. |
| M13 | **Tests/CI, packaging, changelog, versioning.** Everything is `Version 0.1`/`1.0`; the two git tags are dates. | | See B27. |

---

## 4. What can be modernised for Plasma 6.7 on Fedora

Ordered by impact.

1. **Restructure around Plasma 6 packaging conventions.** One `plasmarc` per desktop theme, `opaque/` variants, `X-Plasma-API: 5.0`, `metadata.json` only (drop every `metadata.desktop` once Plasma 5 support is dropped), `contents/defaults` with the full Breeze key set, `[Wallpaper] Image=`, `[ksplashrc]`, dark/light pairing.
2. **Make the login screen a Plasma Login Manager story.** Ship `wallpaper/Layan` in the sizes PLM's wallpaper plugin wants, document `systemsettings kcm_plasmalogin` → wallpaper + Synchronise. Keep `sddm/6.0` as an optional extra for non-Fedora distros, with PR #76 merged and `Qt.resolvedUrl` everywhere, and delete `sddm/5.0`.
3. **Aurorae for the v2 engine.** Strip dead rc keys, put shadows in the SVG, add `decoration-maximized*` and `innerborder*` elements, add the missing buttons, fix the dangling `<use>`. Consider offering a Breeze-based alternative: since Plasma 6, a colour scheme with `[WM]` colours plus Breeze decoration with "match titlebar colour" gets most of the Layan look without Aurorae's blur/mask problems (#44, #66).
4. **Colour-scheme-driven SVGs.** All Plasma SVGs already carry a `current-color-scheme` stylesheet; extend it so highlight/accent come from the scheme instead of hardcoded `#5657f5`, enabling Plasma's accent colour (#58). Generate the light/dark/solid variants from one source with a small build script rather than three hand-edited copies (`common/`, `solid/`, `translucent/` are already diverging).
5. **Kvantum as optional, Breeze as default.** `defaults` → `widgetStyle=Breeze`, ship the `.colors` with tuned `[Colors:Header]`/`[WM]`. Keep Kvantum Layan for people who want the translucent windows, with the installer writing `kvantum.kvconfig` for them.
6. **Installer.** Adopt PolybiusPro's rewrite, add `--color`/`--variant` flags like the other vinceliuice themes, run `kbuildsycoca6`, optionally `plasma-apply-lookandfeel -a`, detect Fedora and offer `dnf install kvantum` (kineticz). Add an RPM spec and Copr so Fedora users get updates without the KDE Store lag.
7. **Layout.** Replace the hand-written 200-line layout JS with `loadTemplate("org.kde.plasma.desktop.defaultPanel")` plus targeted tweaks (floating top panel, Layan wallpaper, Kickoff icon), the way Breeze does. That removes the dead `splitdigitalclock`/Milou references and survives future applet renames.
8. **CI.** GitHub Action running `xmllint --noout`, a dangling `id`/`xlink:href` check, `qmllint` on the QML, and a `kpackagetool6 --list`-style validation in a Fedora container. This would have caught B3, B6, B13 and #35.
9. **Docs.** README should say Plasma 6 only, list Fedora package names (`kvantum`, `kvantum-qt6`, `plasma-login-manager`), explain PLM, and link Layan-gtk-theme and Layan-cursors as companions.

---

## 5. Upstream issues and PRs (state on 2026-09-07)

Upstream: 534 stars, 36 forks, 72 issues (41 open), 9 PRs (4 merged, 3 open). Last commit 2025-11-27.

### Open PRs worth merging
- **#79** ayylmaonade — remove duplicate `<style>` tags in three icon SVGs (Qt 6.11 tooltip breakage). Merge as is.
- **#76** gertvermeersch — `Qt.resolvedUrl` for SDDM icon paths (Layan only). Merge and apply to Layan-light.
- **#70** 1103409364 — swaps cursors/icons to Breeze/Papirus. Personal preference; do not merge, but it is evidence for B9.

### Open issues still relevant on Plasma 6.x
| Issue | Topic | Status here |
|---|---|---|
| #74 | Splash `bottomRect` ReferenceError | B6, reproduced |
| #72 | Dolphin URL bar opaque with Kvantum (Gear 25.08+) | B24, unfixed anywhere |
| #68, #73, #78 | SDDM `fontSize`/`iconSource` errors, stale Store copy, users installing `sddm/5.0` | B16-B18 |
| #66 | Blur strip over fullscreen windows (Aurorae) | B15 |
| #26 | Cannot resize from top edge (Aurorae) | B15 |
| #44 | Blur mask in decoration.svg | `mask-*` elements exist now; re-test on v2 |
| #58 | Accent colour support | M6 |
| #11, #12, #13 | Change primary colour / more variants | M7 |
| #25 | Margins Separator widget | B4 (`margins-highlight.svg`) |
| #80 | Audio slider handle at 100 % | not investigated, `slider.svgz` was last touched 2025-11-27 |
| #82 | Andromeda launcher icon tiny | likely `icons/start.svg` sizing, not investigated |
| #32 | Network icon "?" on bridge-only | `icons/network.svg` missing states |
| #41, #21 | Panel corners/transparency lost on AUR installs | B2 plus packaging drift (B27) |
| #35 | Dangling gradient IDs in Kvantum SVG | B25, not reproducible now |
| #38, #24, #19, #20, #45, #48, #54, #57 | Assorted Kvantum/plasma cosmetic bugs | untriaged, mostly Kvantum |
| #30 | Qt 6 support | needs `kvantum-qt6`; on Fedora both Qt 5 and Qt 6 Kvantum are packaged |
| #37 | Flatpak repo | out of scope, but a GTK theme Flatpak exists upstream for GTK |

Closed-but-informative: #59 (the Plasma 6 recipe was only `desktoptojson`), #53 (min panel height = 2× corner radius), #56 (window opacity 0.8, `#31313A`), #71 (Qt 6.9.0 artefacts were QTBUG-135867).

---

## 6. Forks and derivatives with useful work

Of 36 forks, 29 are even or behind, 7 are deleted/private. Five carry real changes:

| Fork / repo | Ahead | Take |
|---|---|---|
| **PolybiusPro/Layan-kde** (2026-05..08) | 7 | Splash fix; Aurorae `<use>` cleanup and opaque hover icons; purple `ForegroundLink`, `ColorScheme=Layan`; Konsole scheme + profile; Plasma 6 dark/light pairing keys in `defaults`; `install.sh` rewrite with `--system/--user/--apply`; removed all SDDM. Best single source to cherry-pick from. |
| **Kattair/Layan-kde** (2026-06) | 4 | `LayanAutomatic` wallpaper with `images_dark/`; light-variant logout screen; Tela for light. |
| **kineticz/Layan-kde** (2026-05) | 4 | Fedora 44 / PLM README section; Fedora Kvantum auto-install; `digitalclock` in layout; but also makes the panel fully opaque and adds a Dutch CPU-monitor applet, so cherry-pick selectively. |
| **1103409364/Layan-kde** | 3 | Same as PR #70 (Breeze cursors, Papirus). |
| **YooLc/Layan-kde** (2023) | 2 | Tighter Aurorae paddings, more translucent titlebar. Plasma 5 era. |
| igorpadua/Layan-kde (2020) | 40 | Dracula re-skin, historical only. |

Non-fork derivatives:
- **kirodubes/kiro-plasma-layan** — Arch package; diagnosed that a git checkout without overlaying `plasma/desktoptheme/common/` yields a broken theme (root cause of #41-style reports); repointed the clock applet; notes the SDDM absolute paths.
- **xerolinux/xero-layan-git** (179 stars) — full rice with vendored Kvantum/Aurorae copies and Fedora + Arch installers; may contain tweaked SVGs.
- **akanbaz/shooting-star-theme** — Layan-based Plasma 6 theme that deliberately uses Breeze instead of Kvantum because of Kirigami breakage.
- **david-x3d/kde-plasma-liquid-glass-theme** — modified Layan desktop theme for a cleaner transparent panel.

---

## 7. Suggested order of work

1. Merge PR #79, cherry-pick PolybiusPro `67fb41c` (splash, colours, defaults, installer) and `5e1e426`/`58d0064` (Aurorae SVGs). Half a day, fixes everything a Fedora user notices on day one.
2. Add `plasmarc` + `opaque/` to both desktop themes; fix the layout JS; add `[Wallpaper]`/`[ksplashrc]`/pairing keys to `defaults`; add Kattair's automatic wallpaper. One day.
3. Rework Aurorae for the v2 engine; add missing buttons and maximised elements. One to two days.
4. Replace the SDDM story with PLM docs + wallpaper; move `sddm/` to `extras/`. Half a day.
5. Logout screen, Konsole scheme, previews, README rewrite. One day.
6. RPM spec + Copr + CI lint. One day.
7. Longer term: accent-colour-aware SVGs, colour variants, Breeze-first application style.
