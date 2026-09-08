# The login screen on Fedora 44+ / Plasma 6.7

Fedora 44 does not use SDDM by default. It ships **Plasma Login Manager**
(package `plasma-login-manager`, service `plasmalogin.service`), a
different display manager that KDE introduced alongside Plasma 6.7. On
this machine:

```
$ rpm -q plasma-login-manager sddm
plasma-login-manager-6.7.4-1.fc44.x86_64
package sddm is not installed
$ systemctl status display-manager
● plasmalogin.service - Plasma Login Manager
     Active: active (running)
```

Plasma Login Manager does not load SDDM QML themes -- it has no theme
loader at all. That means the `extras/sddm/` theme in this repository
(and any SDDM theme in general) has **no effect** on a stock Fedora 44
install. This is the situation described in upstream
[issue #68](https://github.com/vinceliuice/Layan-kde/issues/68),
[#73](https://github.com/vinceliuice/Layan-kde/issues/73) and
[#78](https://github.com/vinceliuice/Layan-kde/issues/78).

## Theming the login screen you actually have

Plasma Login Manager takes its look from a Plasma-side KCM rather than a
theme file. The relevant System Settings page is registered as:

```
$ cat /usr/share/applications/kcm_plasmalogin.desktop
[Desktop Entry]
...
Name=Login Screen
Exec=systemsettings kcm_plasmalogin
```

so you can open it directly with `systemsettings kcm_plasmalogin`, or
from System Settings' search box by typing "Login Screen".

The KCM (`kcm_plasmalogin.so`) exposes wallpaper and accent-colour
settings for the login screen (`WallpaperSettings`, `WallpaperIntegration`
and `accentColor` are all defined in the plugin), and it can copy your
current Plasma session's appearance to the login screen: the plugin
implements a `synchronizeSettings` action, and its own error string --
"Unable to synchronise Plasma settings because the 'plasmalogin' user
does not exist" -- confirms that a synchronise/apply action exists for
copying colour scheme, cursor theme and font settings from your logged-in
session to the login screen. We are not quoting an exact button label
here because we could not extract the on-screen string from the compiled
plugin; look for a synchronise/apply control on that settings page.

To get the Layan look on the login screen:

1. Install this theme, including the wallpaper package, e.g.:
   ```sh
   ./install.sh --user      # or --system
   ```
2. Open **System Settings → Colors & Themes → Login Screen** (or run
   `systemsettings kcm_plasmalogin`).
3. Pick the Layan wallpaper (installed from `wallpaper/Layan`, or
   `wallpaper/Layan-light` / `wallpaper/LayanAutomatic` if present) as the
   login screen's background.
4. Use the settings page's synchronise/apply action so your current
   session's colour scheme, cursor theme and fonts carry over to the
   login screen -- this is the closest Plasma Login Manager gets to a
   full theme, since it does not support custom QML greeters, buttons or
   layouts the way SDDM did.

Buttons, layout and fonts on the Plasma Login Manager screen stay the
stock KDE look; there are no hooks to replace them (see kineticz's
Fedora 44 README notes, which describe the same limitation).

## If you want the old, fully-themed SDDM login screen

Plasma Login Manager can be swapped back out for SDDM:

```sh
sudo dnf swap plasma-login-manager sddm
```

Then install the Layan SDDM theme from this repo:

```sh
sudo extras/sddm/6.0/install.sh
```

and set it active, e.g. in `/etc/sddm.conf.d/10-theme.conf`:

```ini
[Theme]
Current=Layan
```

See [`extras/sddm/README.md`](../extras/sddm/README.md) for details. Note
that swapping back to SDDM is a distribution-level change outside what
this theme's installer manages -- do it deliberately, and be aware Fedora
may re-select `plasma-login-manager` on future upgrades unless you `dnf
mark` your preference.
