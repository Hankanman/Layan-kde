# Layan KDE

Layan is a flat, purple-accented global theme for KDE Plasma: a Plasma
desktop theme, Aurorae window decoration, Kvantum application style,
colour schemes, a global theme (look-and-feel), wallpapers, a Konsole
profile and an optional SDDM theme.

This is a Plasma 6 fork of [vinceliuice/Layan-kde](https://github.com/vinceliuice/Layan-kde)
(the original author's Plasma 5/6 theme), modernised for current Plasma 6
releases. **Plasma 6 only** -- Plasma 6.4+ is recommended, and it is
tested on **Plasma 6.7.4 / Fedora 44 / KDE Frameworks 6.29 / Qt 6.11**.
Plasma 5 support (the old `sddm/5.0` theme) has been dropped; see
`REVIEW.md` and `CHANGELOG.md` for the full list of Plasma 6 fixes in this
fork.

## What's in the box

- **Plasma desktop theme** -- `Layan` (dark) and `Layan-light`, covering
  panel, dialog, tooltip and widget SVGs.
- **Aurorae window decoration** -- `Layan`, `Layan-light`, `Layan-solid`.
- **Kvantum application style** -- `Layan` and `LayanSolid`, each with a
  dark and light kvconfig.
- **Colour schemes** -- `Layan.colors` and `LayanLight.colors`.
- **Global theme (look-and-feel)** -- `com.github.vinceliuice.Layan` /
  `-light`, bundling the desktop theme, colour scheme, splash screen and
  logout screen into one entry in System Settings.
- **Wallpapers** -- `Layan`, `Layan-light`, and (once merged) an automatic
  light/dark wallpaper package for Plasma 6.6+'s day/night theme
  switching.
- **Konsole** -- a Layan colour scheme and profile (once merged), so a
  fresh Konsole window is transparent/themed out of the box instead of
  defaulting to a solid terminal.
- **`extras/sddm/`** -- an optional SDDM theme for distributions that
  still use SDDM as their display manager. Not installed by default and
  not useful on Fedora 44+ (see below).

## Fedora package names

Kvantum is not preinstalled on Fedora. Install it with:

```sh
sudo dnf install kvantum kvantum-qt5
```

(`kvantum` provides the Qt6 engine and `kvantummanager`; `kvantum-qt5`
adds the Qt5 platform theme plugin so Qt5 apps pick it up too.)
`./install.sh --install-deps` will do this for you on Fedora if Kvantum
is missing.

## Installing

```sh
./install.sh              # installs for the current user (~/.local)
sudo ./install.sh --system   # installs for all users (/usr/share)
```

Useful flags:

| Flag | Effect |
|---|---|
| `--system` | Install under `/usr/share` (requires root) |
| `--user` | Install under `~/.local` (default) |
| `--apply` | Activate the dark Layan global theme after installing, and point Kvantum at `LayanDark` |
| `--apply-light` | Activate `Layan-light`, and point Kvantum at `Layan` |
| `--no-kvantum` | Skip installing the Kvantum theme |
| `--sddm` | Also install `extras/sddm` into `/usr/share/sddm/themes` (requires root, and only if SDDM is present) |
| `--install-deps` | On Fedora, run `sudo dnf install -y kvantum kvantum-qt5` if Kvantum isn't installed |
| `-h`, `--help` | Show all options |

Run `./install.sh --help` for the full list. `uninstall.sh` accepts the
matching `--system`/`--user`/`--no-kvantum`/`--sddm` flags to remove
exactly what was installed.

```sh
./uninstall.sh
sudo ./uninstall.sh --system
```

Both scripts require `bash` (they refuse to run under `sh`), use
`set -euo pipefail`, and only ever remove the exact theme files they
install -- no `rm -rf` glob deletes globs of unrelated files.

After installing, apply the theme from **System Settings → Appearance →
Global Theme**, or use `--apply` / `--apply-light` above, or run:

```sh
plasma-apply-lookandfeel -a com.github.vinceliuice.Layan
```

## Kvantum vs. Breeze

Kvantum is what gives Layan its translucent windows and rounded, blurred
menus. It is optional:

- **Kvantum** (`kvantummanager` → **Layan**/**LayanDark**, or
  `--apply`/`--apply-light` above) gives the full translucent look, but
  Kvantum on Plasma 6 has known rough edges: the Dolphin URL bar can
  render opaque on recent KDE Gear releases, and some Kirigami-based apps
  mis-render their labels.
- **Breeze + the Layan colour scheme** (the default `widgetStyle` if you
  skip Kvantum) is the safer default on Plasma 6 -- you get Layan's
  purple accent and window/panel colours without Kvantum's edge cases.

**Do not set `QT_STYLE_OVERRIDE=kvantum`** as an environment variable --
it forces Kvantum onto Kirigami/QML apps globally and is what causes the
worst of the Kirigami label breakage. Let `kvantummanager` and
`kvantum.kvconfig` (which `install.sh --apply` writes for you) select the
style instead of overriding it process-wide.

## The login screen (Fedora 44+ / Plasma Login Manager)

Fedora 44 and other current distributions use **Plasma Login Manager**
(`plasmalogin.service`), not SDDM. Plasma Login Manager does not load
SDDM themes, so `extras/sddm/` has no effect there. See
[`docs/login-screen.md`](docs/login-screen.md) for how to theme the login
screen you actually have (wallpaper + the Login Screen settings page),
and how to switch back to SDDM if you want the full themed greeter.

## Companion themes

Layan KDE only covers the Plasma shell. For a fully matching desktop,
pair it with vinceliuice's other Layan packages:

- [Layan-gtk-theme](https://github.com/vinceliuice/Layan-gtk-theme) --
  matching GTK theme, so GTK/Flatpak apps (and the GTK portions of a
  Plasma session) look consistent with the Qt/Kvantum side.
- [Layan-cursors](https://github.com/vinceliuice/Layan-cursors) -- the
  cursor theme the desktop theme's `defaults` originally expected.

## Recommendations

- Install [Tela icon theme](https://github.com/vinceliuice/Tela-icon-theme)
  for a more consistent look with the rest of the theme.

The global theme's `defaults` name the Tela icons and Layan cursors.
The easiest way to get both is to let the installer fetch them:

```sh
./install.sh --full --apply          # --full = --with-icons --with-cursors
```

This shallow-clones the upstream Tela and Layan-cursors repos and installs
them into the same scope (`--user` or `--system`) as the rest of the theme;
`./uninstall.sh --full` removes them again. Applying from System Settings
fetches them from the KDE Store instead. If neither has happened and the
themes are missing, `--apply` falls back to Breeze icons and cursors and
tells you how to switch.

## Credits

Layan KDE originates from
[vinceliuice/Layan-kde](https://github.com/vinceliuice/Layan-kde). This
fork carries forward that design and focuses on making it work correctly
on current Plasma 6 releases -- see `REVIEW.md` for the audit this fork
is based on and `CHANGELOG.md` for what changed.

## Donate

If you like this project, consider supporting the original author:

<span class="paypal"><a href="https://www.paypal.me/vinceliuice" title="Donate to this project using Paypal"><img src="https://www.paypalobjects.com/webstatic/mktg/Logo/pp-logo-100px.png" alt="PayPal donate button" /></a></span>

## License

GNU GPL v3

## Preview

![Layan preview](../master/plasma/look-and-feel/com.github.vinceliuice.Layan/contents/previews/fullscreenpreview.jpg)
