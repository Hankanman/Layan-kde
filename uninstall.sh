#!/usr/bin/env bash
#
# Uninstall the Layan KDE theme components installed by install.sh.
#
# Run with bash, not sh -- see the guard below.

if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "Error: this script must be run with bash, not sh." >&2
  echo "  bash ./uninstall.sh   or   ./uninstall.sh" >&2
  exit 1
fi

set -euo pipefail

ROOT_UID=0

THEME_NAME=Layan
COLOR_VARIANTS=('' '-light')

INSTALL_SCOPE=""
USE_KVANTUM=1
UNINSTALL_SDDM=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Removes the Layan KDE theme files installed by install.sh.

Options:
  --system      Remove the system-wide install under /usr/share (requires root)
  --user        Remove the current user's install under ~/.local (default)
  --no-kvantum  Skip removing the Kvantum theme
  --sddm        Also remove extras/sddm from /usr/share/sddm/themes (requires root)
  -h, --help    Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system) INSTALL_SCOPE=system; shift ;;
    --user) INSTALL_SCOPE=user; shift ;;
    --no-kvantum) USE_KVANTUM=0; shift ;;
    --sddm) UNINSTALL_SDDM=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$INSTALL_SCOPE" ]]; then
  if [[ "$EUID" -eq "$ROOT_UID" ]]; then
    INSTALL_SCOPE=system
  else
    INSTALL_SCOPE=user
  fi
fi

if [[ "$INSTALL_SCOPE" == "system" && "$EUID" -ne "$ROOT_UID" ]]; then
  echo "Error: system-wide uninstall requires root. Run: sudo $0 --system" >&2
  exit 1
fi

if [[ "$INSTALL_SCOPE" == "system" ]]; then
  AURORAE_DIR="/usr/share/aurorae/themes"
  SCHEMES_DIR="/usr/share/color-schemes"
  PLASMA_DIR="/usr/share/plasma/desktoptheme"
  LOOKFEEL_DIR="/usr/share/plasma/look-and-feel"
  KVANTUM_DIR="/usr/share/Kvantum"
  WALLPAPER_DIR="/usr/share/wallpapers"
  KONSOLE_DIR="/usr/share/konsole"
else
  AURORAE_DIR="${HOME}/.local/share/aurorae/themes"
  SCHEMES_DIR="${HOME}/.local/share/color-schemes"
  PLASMA_DIR="${HOME}/.local/share/plasma/desktoptheme"
  LOOKFEEL_DIR="${HOME}/.local/share/plasma/look-and-feel"
  KVANTUM_DIR="${HOME}/.config/Kvantum"
  WALLPAPER_DIR="${HOME}/.local/share/wallpapers"
  KONSOLE_DIR="${HOME}/.local/share/konsole"
fi

remove_exact() {
  # Remove an exact file or directory name; never glob.
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    echo "Removing ${path}"
    rm -rf -- "$path"
  fi
}

echo "Uninstalling '${THEME_NAME}' KDE theme (${INSTALL_SCOPE}-wide)..."

for variant in "Layan" "Layan-light" "Layan-solid"; do
  remove_exact "${AURORAE_DIR}/${variant}"
done

for color in "${COLOR_VARIANTS[@]}"; do
  else_color=""
  [[ "$color" == "-light" ]] && else_color="Light"
  remove_exact "${SCHEMES_DIR}/${THEME_NAME}${else_color}.colors"
  remove_exact "${PLASMA_DIR}/${THEME_NAME}${color}"
  remove_exact "${LOOKFEEL_DIR}/com.github.vinceliuice.${THEME_NAME}${color}"
  remove_exact "${WALLPAPER_DIR}/${THEME_NAME}${color}"
done

# Extra wallpaper packages this repo ships (e.g. LayanAutomatic)
remove_exact "${WALLPAPER_DIR}/LayanAutomatic"

if [[ "$USE_KVANTUM" -eq 1 ]]; then
  remove_exact "${KVANTUM_DIR}/Layan"
  remove_exact "${KVANTUM_DIR}/LayanSolid"
fi

for f in "Layan.colorscheme" "LayanLight.colorscheme" "Layan.profile" "LayanLight.profile"; do
  remove_exact "${KONSOLE_DIR}/${f}"
done

if [[ "$UNINSTALL_SDDM" -eq 1 ]]; then
  if [[ "$EUID" -ne "$ROOT_UID" ]]; then
    echo "Warning: --sddm requires root; skipping extras/sddm removal." >&2
  else
    remove_exact "/usr/share/sddm/themes/Layan"
    remove_exact "/usr/share/sddm/themes/Layan-light"
  fi
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi

echo "Uninstall finished."
