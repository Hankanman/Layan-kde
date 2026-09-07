# Changelog

All notable changes to this fork are documented here. See `REVIEW.md` for
the audit this branch is based on (item IDs like `B16`/`M3` below refer to
its numbering).

## Unreleased (`plasma6` branch)

Modernisation for Plasma 6.7 / Fedora 44, following the plan in
`REVIEW.md` section 7:

- **Installer can fetch Tela icons and Layan cursors (B9)**
  - New `install.sh --with-icons`, `--with-cursors` and `--full` shallow-clone
    vinceliuice's Tela-icon-theme and Layan-cursors repos and install them
    into the chosen scope, so `./install.sh --full --apply` yields the
    complete intended look on a clean machine. `uninstall.sh` gained the
    same flags to remove them.
- **Installer icon/cursor fallback (B9)**
  - `install.sh --apply` / `--apply-light` now checks whether the Tela icon
    theme and Layan cursor theme named in the look-and-feel `defaults` are
    installed. If not, it applies `breeze-dark`/`breeze` icons and
    `breeze_cursors` instead of leaving Plasma pointing at missing themes,
    which made most shell icons (system tray, launcher, System Settings)
    disappear.
- **Installer and repo hygiene (B23, B26)**
  - Rewrote `install.sh` and `uninstall.sh`: `#!/usr/bin/env bash`,
    `set -euo pipefail`, refuse to run under `sh`, `$EUID`-based root
    detection, fully quoted paths, and exact-name deletes only (no
    unquoted `Layan*` glob deletes).
  - Added `--system`/`--user`, `--apply`/`--apply-light` (runs
    `plasma-apply-lookandfeel` and writes `~/.config/Kvantum/kvantum.kvconfig`
    via `kwriteconfig6`), `--no-kvantum`, `--sddm` (installs
    `extras/sddm`, root + existing SDDM install required), `--install-deps`
    (Fedora: `sudo dnf install -y kvantum kvantum-qt5`), and `-h/--help`.
  - Both scripts now run `kbuildsycoca6 --noincremental` after
    installing/removing files.
  - Installer detects Fedora and hints at installing Kvantum via `dnf`
    instead of installing packages unconditionally.
  - Installer/uninstaller are guarded (`[[ -d ]]`/`[[ -f ]]`) so they
    work whether or not the Konsole, `LayanAutomatic` wallpaper and
    `plasmarc` files from sibling in-flight branches have landed yet.
- **SDDM (B16, B17, B18, B19)**
  - Moved `sddm/` to `extras/sddm/` -- it is an optional extra, not a
    first-class component, since Fedora 44+ uses Plasma Login Manager
    instead of SDDM.
  - Deleted `extras/sddm/5.0` (Plasma 5 / `QtQuick.Controls 1.1` only;
    caused upstream issue #68 on Plasma 6).
  - Fixed `extras/sddm/6.0/{Layan,Layan-light}/Main.qml`: replaced
    hardcoded `/usr/share/sddm/themes/<name>/assets/*.svgz` paths in
    `icon.name` with `Qt.resolvedUrl("assets/...")` so the theme works
    from any install location, extending the existing Layan-only fix to
    Layan-light too.
  - Added `showlogo=shown` and `logo=default-logo.svg` to both
    `theme.conf` files, matching what `Main.qml` already reads.
  - Replaced the interactive, `sudo -S`-piped `extras/sddm/6.0/install.sh`
    with a plain root-check script.
  - Added `extras/sddm/README.md` documenting this is only for
    distributions still on SDDM.
- **Login screen docs (M3)**
  - Added `docs/login-screen.md` explaining that Fedora 44+ uses Plasma
    Login Manager, which does not load SDDM themes, how to theme it via
    the Login Screen settings page (wallpaper + settings sync), and the
    `dnf swap plasma-login-manager sddm` route back to the old theme.
- **Docs (M4, M11)**
  - Rewrote `README.md`: Plasma 6 only (6.4+ recommended, tested on
    6.7/Fedora 44), full component list (including Konsole, automatic
    wallpaper, logout screen, `extras/sddm`), Fedora package names,
    install/uninstall usage with the new flags, a Kvantum-vs-Breeze note
    (including the `QT_STYLE_OVERRIDE=kvantum` Kirigami warning), links
    to `docs/login-screen.md`, `Layan-gtk-theme` and `Layan-cursors` as
    companion themes, and credit to upstream `vinceliuice/Layan-kde`.
  - Added this changelog.

### Not done in this pass

- Kvantum-free-by-default application style switch (M4, "Breeze as
  default") is documented but not made the default `widgetStyle` --
  that's a `plasma/look-and-feel` change owned by another workstream.
- Konsole install paths are wired up and guarded, but the actual
  `konsole/*.colorscheme`/`*.profile` files are produced on a separate
  branch and were not present to test against at the time of this work.
- `extras/sddm/6.0/install.sh` and `install.sh --sddm` were checked with
  `bash -n` only; they were not run against a real SDDM install (none is
  present on this Fedora 44 / Plasma Login Manager machine).
