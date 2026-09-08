# Layan SDDM theme (optional extra)

This directory is **only for distributions that still use SDDM** as their
display manager. It is not part of the default Layan install.

Fedora 44 and later use **Plasma Login Manager** (`plasmalogin.service`)
instead of SDDM, and Plasma Login Manager does not load SDDM QML themes at
all -- installing this theme has no effect there. If you are on Fedora 44+
/ Plasma 6.7, see [`docs/login-screen.md`](../../docs/login-screen.md) for
how to theme the login screen you actually have, and only come back here if
you deliberately switch your system back to SDDM
(`sudo dnf swap plasma-login-manager sddm`).

## Contents

- `6.0/` -- the Plasma 6 SDDM theme (`Layan`, `Layan-light`), for the C++
  QML SDDM greeter shipped with SDDM 0.20+ / Plasma 6. This is the only
  version still maintained here.

The old Plasma 5 theme (`5.0/`, built on `QtQuick.Controls 1.1` and
`QtGraphicalEffects`) has been removed. It only ever worked with the legacy
Qt5 SDDM greeter and produced `module QtQuick.Controls version 1.1 is not
installed` errors on any Plasma 6 / Qt 6 SDDM install (upstream
[issue #68](https://github.com/vinceliuice/Layan-kde/issues/68)). If you
need it, it is still available in git history before this branch.

## Installing

Requires SDDM to already be installed and active as your display manager.

```sh
sudo extras/sddm/6.0/install.sh
```

This copies `Layan` and `Layan-light` into `/usr/share/sddm/themes/`. Then
pick one as the active theme, e.g. in `/etc/sddm.conf.d/10-theme.conf`:

```ini
[Theme]
Current=Layan
```

`extras/sddm/6.0/install.sh` only copies files -- it does not install SDDM,
enable it as your display manager, or edit `sddm.conf` for you.
