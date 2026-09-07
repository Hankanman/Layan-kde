#!/usr/bin/env python3
"""
Generate Layan-lucide / Layan-lucide-dark, two symbolic KDE Plasma icon
themes built from Lucide (https://lucide.dev) stroke icons.

Reads Lucide SVGs from tools/lucide-src/ (a small, hand-picked subset of the
upstream icon set -- only the icons actually referenced by the mapping table
below are vendored there) and writes a complete KDE icon theme tree into
icons/<theme-name>/, following the "FollowsColorScheme" convention used by
Breeze/Tela so KIconLoader recolours the icons to match the current colour
scheme (System Settings -> Colors) instead of baking in a fixed colour.

Usage:
    tools/gen-lucide-icons.py

No third-party dependencies -- stdlib only. Safe to re-run; it fully
regenerates icons/Layan-lucide{,-dark}/ each time.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
LUCIDE_SRC = REPO_ROOT / "tools" / "lucide-src"
ICONS_ROOT = REPO_ROOT / "icons"

LUCIDE_VERSION = "1.42.0"
LUCIDE_URL = "https://github.com/lucide-icons/lucide"

# ---------------------------------------------------------------------------
# Theme definitions: name -> (Comment, Inherits, default ColorScheme-Text)
# ---------------------------------------------------------------------------
THEMES = {
    "Layan-lucide-dark": {
        "comment": "Layan dark icon theme: Lucide symbolic icons for panel/tray/actions, Tela for full-colour app icons",
        "inherits": "Tela-dark,breeze-dark,hicolor",
        "text": "#eaeaea",
    },
    "Layan-lucide": {
        "comment": "Layan light icon theme: Lucide symbolic icons for panel/tray/actions, Tela for full-colour app icons",
        "inherits": "Tela,breeze,hicolor",
        "text": "#363636",
    },
}

COMMON_COLORS = {
    "Background": "#eff0f1",
    "Highlight": "#5657f5",
    "PositiveText": "#27ae60",
    "NeutralText": "#f67400",
    "NegativeText": "#da4453",
}

# Contexts and the sizes generated for each. Actions/status/devices/panel/
# emblems get 16,22,24; apps/places also get 32,48 (they can double as
# app-grid / file-manager icons at bigger sizes).
CONTEXT_SIZES = {
    "status": [16, 22, 24],
    "actions": [16, 22, 24],
    "devices": [16, 22, 24],
    "panel": [16, 22, 24],
    "emblems": [16, 22, 24],
    "apps": [16, 22, 24, 32, 48],
    "places": [16, 22, 24, 32, 48],
}

CONTEXT_TYPE = {
    "status": "Status",
    "actions": "Actions",
    "devices": "Devices",
    "panel": "Status",
    "emblems": "Emblems",
    "apps": "Applications",
    "places": "Places",
}

# ---------------------------------------------------------------------------
# KDE icon name -> Lucide icon name, grouped by context.
# Each entry: kde_name -> lucide_name. A given kde_name may appear in more
# than one CONTEXT dict below (e.g. same name in both "status" and "panel").
# ---------------------------------------------------------------------------

STATUS: dict[str, str] = {
    # audio
    "audio-volume-high": "volume-2",
    "audio-volume-medium": "volume-1",
    "audio-volume-low": "volume",
    "audio-volume-muted": "volume-x",
    "audio-volume-change": "volume-2",
    "audio-input-microphone": "mic",
    "audio-input-microphone-muted": "mic-off",
    "audio-input-microphone-high": "mic",
    "audio-input-microphone-low": "mic",
    # notifications
    "notifications": "bell",
    "notifications-disabled": "bell-off",
    # bluetooth
    "preferences-system-bluetooth": "bluetooth",
    "preferences-system-bluetooth-activated": "bluetooth-connected",
    "preferences-system-bluetooth-inactive": "bluetooth-off",
    "preferences-system-bluetooth-battery": "bluetooth",
    "network-bluetooth-activated": "bluetooth-connected",
    "network-bluetooth-inactive": "bluetooth-off",
    # network / vpn / flightmode
    "network-vpn": "shield-check",
    "network-flightmode-on": "plane",
    "network-flightmode-off": "wifi",
    "network-unavailable": "wifi-off",
    "network-wired": "ethernet-port",
    "network-wired-activated": "ethernet-port",
    "network-wired-unavailable": "unlink-2",
    "network-wired-available": "ethernet-port",
    "network-wired-activated-limited": "ethernet-port",
    "network-wired-activated-locked": "ethernet-port",
    "network-wireless-available": "wifi",
    "network-wireless-disconnected": "wifi-off",
    "network-wireless-off": "wifi-off",
    "network-wireless-on": "wifi",
    "network-wireless-hotspot": "radio-tower",
    "network-wireless-acquiring": "wifi",
    "network-mobile-available": "signal",
    "network-mobile-on": "signal",
    "network-mobile-off": "signal-zero",
    # brightness / display
    "brightness-high": "sun",
    "brightness-low": "sun-dim",
    "display-brightness": "sun",
    "redshift-status-on": "moon",
    "redshift-status-off": "sun",
    "night-light": "moon",
    # ac adapter
    "ac-adapter": "plug-zap",
    # input indicators
    "input-caps-on": "lock",
    "input-num-on": "hash",
    # dialogs
    "dialog-ok": "check",
    "dialog-cancel": "x",
    "dialog-close": "x",
    "dialog-error": "octagon-alert",
    "dialog-warning": "triangle-alert",
    "dialog-information": "info",
    "dialog-question": "circle-help",
    "dialog-password": "key-round",
    # mail
    "mail-unread": "mail",
    "mail-read": "mail-open",
}

ACTIONS: dict[str, str] = {
    "edit-paste": "clipboard-paste",
    "edit-copy": "copy",
    "edit-cut": "scissors",
    "edit-delete": "trash-2",
    "edit-clear": "eraser",
    "edit-find": "search",
    "edit-undo": "undo",
    "edit-redo": "redo",
    "edit-rename": "pencil",
    "edit-select-all": "list-checks",
    "search": "search",
    "network-disconnect": "unlink-2",
    "network-connect": "link-2",
    "media-eject": "eject",
    "arrow-up": "arrow-up",
    "arrow-down": "arrow-down",
    "arrow-left": "arrow-left",
    "arrow-right": "arrow-right",
    "go-up": "arrow-up",
    "go-down": "arrow-down",
    "go-next": "arrow-right",
    "go-previous": "arrow-left",
    "go-home": "home",
    "go-jump": "arrow-right",
    "media-playback-start": "play",
    "media-playback-pause": "pause",
    "media-playback-stop": "square",
    "media-skip-forward": "skip-forward",
    "media-skip-backward": "skip-back",
    "media-seek-forward": "chevrons-right",
    "media-seek-backward": "chevrons-left",
    "media-record": "circle",
    "media-playlist-shuffle": "shuffle",
    "media-playlist-repeat": "repeat",
    "system-shutdown": "power",
    "system-reboot": "refresh-cw",
    "system-suspend": "moon",
    "system-suspend-hibernate": "moon-star",
    "system-lock-screen": "lock",
    "system-log-out": "log-out",
    "system-switch-user": "users",
    "system-search": "search",
    "system-run": "terminal",
    "system-help": "circle-help",
    "system-users": "users",
    "system-file-manager": "folder",
    "system-monitor": "activity",
    "system-software-update": "download-cloud",
    "configure": "settings",
    "configure-toolbars": "sliders-horizontal",
    "preferences-system": "settings",
    "preferences-desktop": "monitor-cog",
    "preferences-other": "sliders",
    "document-new": "file-plus",
    "document-open": "folder-open",
    "document-save": "save",
    "document-save-as": "save-all",
    "document-print": "printer",
    "document-close": "x",
    "document-properties": "file-text",
    "document-send": "send",
    "document-share": "share-2",
    "document-edit": "pencil",
    "document-open-recent": "history",
    "document-open-folder": "folder-open",
    "document-export": "upload",
    "document-import": "import",
    "view-refresh": "refresh-cw",
    "view-list-icons": "layout-grid",
    "view-list-details": "list",
    "view-list-tree": "list-tree",
    "view-fullscreen": "fullscreen",
    "view-restore": "shrink",
    "view-hidden": "eye-off",
    "view-visible": "eye",
    "view-history": "history",
    "view-sort-ascending": "arrow-up-narrow-wide",
    "view-sort-descending": "arrow-down-wide-narrow",
    "view-grid": "grid",
    "view-filter": "filter",
    "window-close": "x",
    "window-minimize": "minimize-2",
    "window-maximize": "maximize-2",
    "window-restore": "shrink",
    "window-new": "app-window",
    "window-pin": "pin",
    "window-unpin": "pin-off",
    "list-add": "plus",
    "list-remove": "minus",
    "zoom-in": "zoom-in",
    "zoom-out": "zoom-out",
    "zoom-original": "scan",
    "zoom-fit-best": "fullscreen",
    "tools-check-spelling": "wrench",
    "help-about": "info",
    "help-contents": "life-buoy",
    "help-hint": "circle-help",
    "application-menu": "menu",
    "application-exit": "log-out",
    "mail-send": "send",
    "mail-reply-sender": "reply",
}

DEVICES: dict[str, str] = {
    "audio-card": "speaker",
    "audio-headphones": "headphones",
    "audio-speakers": "speaker",
    "input-keyboard": "keyboard",
    "input-keyboard-virtual-on": "keyboard",
    "input-keyboard-virtual-off": "keyboard-off",
    "keyboard-layout": "keyboard",
    "keyboard-current": "keyboard",
    "keyboard-navigation": "keyboard",
    "input-mouse": "mouse",
    "input-touchpad": "touchpad",
    "touchpad_enabled": "touchpad",
    "touchpad_disabled": "touchpad-off",
    "printer": "printer",
    "device-notifier": "usb",
    "drive-removable-media": "usb",
    "camera-on": "camera",
    "camera-off": "camera-off",
    "camera-ready": "camera",
    "camera-web": "camera",
    "video-display": "monitor",
    "video-display-brightness": "sun",
    "display-randr": "monitor",
    "drive-harddisk": "hard-drive",
    "drive-optical": "disc",
    "media-flash": "usb",
    "usb": "usb",
}

APPS: dict[str, str] = {
    "klipper": "clipboard",
    "kdeconnect": "smartphone",
    "kdeconnect-tray": "smartphone",
    "kdeconnect-android": "smartphone",
    "plasmavault": "vault",
    "plasmavault-kde": "vault",
    "plasmavault_error": "vault",
    "printer": "printer",
    "computer": "monitor",
    "computer-laptop": "laptop",
    "phone": "phone",
    "smartphone": "smartphone",
    "tablet": "tablet",
    "start-here-kde": "layout-grid",
    "plasma": "sparkles",
}

PLACES: dict[str, str] = {
    "folder": "folder",
    "folder-open": "folder-open",
    "folder-new": "folder-plus",
    "folder-image": "image",
    "folder-download": "folder-down",
    "folder-documents": "file-text",
    "folder-music": "music",
    "folder-videos": "video",
    "folder-pictures": "image",
    "user-identity": "user",
    "user-desktop": "monitor",
    "user-home": "home",
    "user-trash": "trash",
    "user-trash-full": "trash-2",
}

EMBLEMS: dict[str, str] = {
    "emblem-encrypted": "lock",
    "emblem-unlocked": "unlock",
    "emblem-error": "circle-x",
    "emblem-warning": "triangle-alert",
    "emblem-checked": "check",
    "emblem-important": "circle-alert",
    "emblem-favorite": "star",
    "emblem-shared": "share-2",
    "emblem-mounted": "circle-check",
    "emblem-unmounted": "eject",
    "user-available": "circle-check",
    "user-away": "clock",
    "user-busy": "circle-x",
    "user-offline": "circle",
    "user-invisible": "eye-off",
    "lock": "lock",
    "unlock": "unlock",
    "lock-screen": "lock",
}

# ---------------------------------------------------------------------------
# -symbolic name aliases explicitly required by Plasma/Tela lookups. Each
# entry maps an alias name to (source_kde_name, context) to copy the same
# Lucide icon under a different (symbolic) name.
# ---------------------------------------------------------------------------
SYMBOLIC_ALIASES: dict[str, tuple[str, str]] = {
    "klipper-symbolic": ("klipper", "apps"),
    "printer-symbolic": ("printer", "devices"),
    "kdeconnect-tray-symbolic": ("kdeconnect-tray", "apps"),
    "camera-on-symbolic": ("camera-on", "devices"),
    "camera-off-symbolic": ("camera-off", "devices"),
    "camera-ready-symbolic": ("camera-ready", "devices"),
    "battery-missing-symbolic": ("battery-missing", "status"),
    "configure-symbolic": ("configure", "actions"),
    "document-open-symbolic": ("document-open", "actions"),
    "document-open-folder-symbolic": ("document-open-folder", "actions"),
    "go-next-symbolic": ("go-next", "actions"),
    "go-next-rtl-symbolic": ("go-previous", "actions"),
    "go-previous-symbolic": ("go-previous", "actions"),
    "go-previous-rtl-symbolic": ("go-next", "actions"),
    "window-close-symbolic": ("window-close", "actions"),
    "lock-symbolic": ("lock", "emblems"),
    "search-symbolic": ("search", "actions"),
    "list-add-symbolic": ("list-add", "actions"),
    "start-here-kde-symbolic": ("start-here-kde", "apps"),
    "view-sort-ascending-symbolic": ("view-sort-ascending", "actions"),
    "view-sort-descending-symbolic": ("view-sort-descending", "actions"),
    "network-disconnect-symbolic": ("network-disconnect", "actions"),
    "drive-removable-media-symbolic": ("drive-removable-media", "devices"),
    "folder-symbolic": ("folder", "places"),
    "user-desktop-symbolic": ("user-desktop", "places"),
    "display-randr-symbolic": ("display-randr", "devices"),
    "dialog-scripts-symbolic": ("system-run", "actions"),
}

# Names that must additionally get a panel/ copy (system tray + panel
# widgets look there before falling back to status/apps).
PANEL_NAMES = {
    "audio-volume-high", "audio-volume-medium", "audio-volume-low",
    "audio-volume-muted", "audio-volume-change",
    "audio-input-microphone", "audio-input-microphone-muted",
    "notifications", "notifications-disabled",
    "klipper", "klipper-symbolic",
    "preferences-system-bluetooth", "preferences-system-bluetooth-activated",
    "preferences-system-bluetooth-inactive", "preferences-system-bluetooth-battery",
    "network-bluetooth-activated", "network-bluetooth-inactive",
    "network-vpn", "network-flightmode-on", "network-flightmode-off",
    "network-unavailable", "network-wired", "network-wired-activated",
    "network-wired-unavailable", "network-wired-available",
    "network-wireless-available", "network-wireless-disconnected",
    "network-wireless-off", "network-wireless-on", "network-wireless-hotspot",
    "network-wireless-acquiring", "network-mobile-available",
    "network-mobile-on", "network-mobile-off",
    "network-disconnect", "network-disconnect-symbolic", "network-connect",
    "kdeconnect-tray", "kdeconnect-tray-symbolic",
    "printer", "printer-symbolic",
    "plasmavault", "plasmavault-kde", "plasmavault_error",
    "device-notifier", "drive-removable-media", "drive-removable-media-symbolic",
    "media-eject",
    "camera-on", "camera-on-symbolic", "camera-off", "camera-off-symbolic",
    "camera-ready", "camera-ready-symbolic",
    "display-brightness", "display-randr", "display-randr-symbolic",
    "redshift-status-on", "redshift-status-off", "night-light",
    "input-keyboard", "input-keyboard-virtual-on", "input-keyboard-virtual-off",
    "keyboard-layout", "keyboard-current", "keyboard-navigation",
    "input-caps-on", "input-num-on",
    "battery-missing-symbolic",
    "system-lock-screen", "lock-symbolic", "search-symbolic",
    "configure-symbolic", "start-here-kde-symbolic",
    "window-close-symbolic", "go-next-symbolic", "go-previous-symbolic",
    "list-add-symbolic", "folder-symbolic", "user-desktop-symbolic",
    "view-sort-ascending-symbolic", "view-sort-descending-symbolic",
    "dialog-scripts-symbolic",
}

# ---------------------------------------------------------------------------
# Battery percentage ladder + variants (status context)
# ---------------------------------------------------------------------------
BATTERY_STEPS = list(range(0, 101, 10))


def battery_icon_for(percent: int) -> str:
    if percent <= 10:
        return "battery-warning"
    if percent <= 30:
        return "battery-low"
    if percent <= 70:
        return "battery-medium"
    return "battery-full"


def build_battery_map() -> dict[str, str]:
    m: dict[str, str] = {}
    for pct in BATTERY_STEPS:
        name = f"battery-{pct:03d}"
        icon = battery_icon_for(pct)
        m[name] = icon
        m[f"{name}-charging"] = "battery-charging"
        PANEL_NAMES.add(name)
        PANEL_NAMES.add(f"{name}-charging")
    named = {
        "battery-full": "battery-full",
        "battery-good": "battery-medium",
        "battery-low": "battery-low",
        "battery-caution": "battery-warning",
        "battery-empty": "battery-warning",
        "battery-missing": "battery",
    }
    for name, icon in named.items():
        m[name] = icon
        m[f"{name}-charging"] = "battery-charging"
        PANEL_NAMES.add(name)
        PANEL_NAMES.add(f"{name}-charging")
    return m


# ---------------------------------------------------------------------------
# Wireless / mobile signal-strength ladders (status context)
# ---------------------------------------------------------------------------
WIRELESS_STEPS = [100, 80, 60, 40, 20, 0]


def wifi_icon_for(percent: int) -> str:
    if percent >= 100:
        return "wifi"
    if percent >= 60:
        return "wifi-high"
    if percent >= 20:
        return "wifi-low"
    return "wifi-zero"


def signal_icon_for(percent: int) -> str:
    if percent >= 80:
        return "signal"
    if percent >= 60:
        return "signal-high"
    if percent >= 40:
        return "signal-medium"
    if percent >= 20:
        return "signal-low"
    return "signal-zero"


def build_wireless_map() -> dict[str, str]:
    m: dict[str, str] = {}
    for pct in WIRELESS_STEPS:
        base = f"network-wireless-{pct}"
        icon = wifi_icon_for(pct)
        for suffix in ("", "-locked", "-limited"):
            m[f"{base}{suffix}"] = icon
            PANEL_NAMES.add(f"{base}{suffix}")
        connected = f"network-wireless-connected-{pct:02d}"
        m[connected] = icon
        PANEL_NAMES.add(connected)

        mobile_base = f"network-mobile-{pct}"
        s_icon = signal_icon_for(pct)
        for suffix in ("", "-locked"):
            m[f"{mobile_base}{suffix}"] = s_icon
            PANEL_NAMES.add(f"{mobile_base}{suffix}")
    return m


STATUS.update(build_battery_map())
STATUS.update(build_wireless_map())

# ---------------------------------------------------------------------------
# Assemble the full context -> {kde_name: lucide_name} map
# ---------------------------------------------------------------------------
CONTEXT_MAPS = {
    "status": STATUS,
    "actions": ACTIONS,
    "devices": DEVICES,
    "apps": APPS,
    "places": PLACES,
    "emblems": EMBLEMS,
}

SVG_TAG_RE = re.compile(r"<svg\b[^>]*>(.*)</svg>", re.DOTALL)
COMMENT_RE = re.compile(r"<!--.*?-->", re.DOTALL)


def load_lucide_inner(lucide_name: str) -> str:
    path = LUCIDE_SRC / f"{lucide_name}.svg"
    if not path.is_file():
        raise FileNotFoundError(f"missing vendored Lucide icon: {path}")
    content = path.read_text(encoding="utf-8")
    content = COMMENT_RE.sub("", content)
    match = SVG_TAG_RE.search(content)
    if not match:
        raise ValueError(f"could not parse SVG body from {path}")
    return match.group(1).strip()


def render_svg(lucide_name: str, size: int, text_color: str) -> str:
    inner = load_lucide_inner(lucide_name)
    stroke_width = "2.25" if size == 16 else "2"
    style = (
        f'.ColorScheme-Text {{ color:{text_color}; }} '
        f'.ColorScheme-Background {{ color:{COMMON_COLORS["Background"]}; }} '
        f'.ColorScheme-Highlight {{ color:{COMMON_COLORS["Highlight"]}; }} '
        f'.ColorScheme-PositiveText {{ color:{COMMON_COLORS["PositiveText"]}; }} '
        f'.ColorScheme-NeutralText {{ color:{COMMON_COLORS["NeutralText"]}; }} '
        f'.ColorScheme-NegativeText {{ color:{COMMON_COLORS["NegativeText"]}; }}'
    )
    return (
        f'<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" '
        f'xmlns="http://www.w3.org/2000/svg">\n'
        f'  <style id="current-color-scheme" type="text/css">{style}</style>\n'
        f'  <g class="ColorScheme-Text" fill="none" stroke="currentColor" '
        f'stroke-width="{stroke_width}" stroke-linecap="round" stroke-linejoin="round">\n'
        f'    {inner}\n'
        f'  </g>\n'
        f'</svg>\n'
    )


def used_lucide_names() -> set[str]:
    names: set[str] = set()
    for ctx_map in CONTEXT_MAPS.values():
        names.update(ctx_map.values())
    for src_name, ctx in SYMBOLIC_ALIASES.values():
        names.add(CONTEXT_MAPS[ctx][src_name])
    return names


def write_index_theme(theme_dir: Path, name: str, meta: dict) -> None:
    lines = [
        "[Icon Theme]",
        f"Name={name}",
        f"Comment={meta['comment']}",
        f"Inherits={meta['inherits']}",
        "Example=folder",
        "FollowsColorScheme=true",
        "DesktopDefault=32",
        "DesktopSizes=16,22,24,32,48",
        "ToolbarDefault=22",
        "ToolbarSizes=16,22,24",
        "MainToolbarDefault=22",
        "MainToolbarSizes=16,22,24",
        "SmallDefault=16",
        "SmallSizes=16,22,24",
        "PanelDefault=32",
        "PanelSizes=16,22,24,32,48",
        "",
    ]
    dir_names = []
    for ctx in CONTEXT_SIZES:
        for size in CONTEXT_SIZES[ctx]:
            dir_names.append(f"{ctx}/{size}")
    lines.append("Directories=" + ",".join(dir_names))
    lines.append("")
    for ctx in CONTEXT_SIZES:
        for size in CONTEXT_SIZES[ctx]:
            lines.append(f"[{ctx}/{size}]")
            lines.append(f"Size={size}")
            lines.append(f"Context={CONTEXT_TYPE[ctx]}")
            lines.append("Type=Fixed")
            lines.append("")
    (theme_dir / "index.theme").write_text("\n".join(lines), encoding="utf-8")


def generate_theme(theme_name: str, meta: dict) -> int:
    theme_dir = ICONS_ROOT / theme_name
    if theme_dir.exists():
        import shutil
        shutil.rmtree(theme_dir)
    theme_dir.mkdir(parents=True)

    count = 0

    def write_icon(context: str, kde_name: str, lucide_name: str) -> None:
        nonlocal count
        for size in CONTEXT_SIZES[context]:
            out_dir = theme_dir / context / str(size)
            out_dir.mkdir(parents=True, exist_ok=True)
            svg = render_svg(lucide_name, size, meta["text"])
            (out_dir / f"{kde_name}.svg").write_text(svg, encoding="utf-8")
            count += 1

    for context, ctx_map in CONTEXT_MAPS.items():
        for kde_name, lucide_name in sorted(ctx_map.items()):
            write_icon(context, kde_name, lucide_name)

    for alias_name, (src_name, ctx) in sorted(SYMBOLIC_ALIASES.items()):
        lucide_name = CONTEXT_MAPS[ctx][src_name]
        write_icon(ctx, alias_name, lucide_name)

    # panel/ copies for tray + panel widget names
    def resolve(name: str) -> tuple[str, str] | None:
        for ctx in ("status", "actions", "devices", "apps", "places", "emblems"):
            if ctx in CONTEXT_MAPS and name in CONTEXT_MAPS[ctx]:
                return name, CONTEXT_MAPS[ctx][name]
        if name in SYMBOLIC_ALIASES:
            src_name, ctx = SYMBOLIC_ALIASES[name]
            return name, CONTEXT_MAPS[ctx][src_name]
        return None

    for name in sorted(PANEL_NAMES):
        resolved = resolve(name)
        if resolved is None:
            continue
        _, lucide_name = resolved
        write_icon("panel", name, lucide_name)

    write_index_theme(theme_dir, theme_name.replace("-", " "), meta)
    return count


def main() -> int:
    missing = sorted(n for n in used_lucide_names() if not (LUCIDE_SRC / f"{n}.svg").is_file())
    if missing:
        print("ERROR: missing vendored Lucide source icons:", file=sys.stderr)
        for name in missing:
            print(f"  tools/lucide-src/{name}.svg", file=sys.stderr)
        return 1

    ICONS_ROOT.mkdir(parents=True, exist_ok=True)
    total = 0
    for theme_name, meta in THEMES.items():
        n = generate_theme(theme_name, meta)
        print(f"Generated {theme_name}: {n} icon files")
        total += n
    print(f"Total: {total} icon files across {len(THEMES)} themes")
    print(f"Distinct KDE icon names mapped: "
          f"{len({k for m in CONTEXT_MAPS.values() for k in m}) + len(SYMBOLIC_ALIASES)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
