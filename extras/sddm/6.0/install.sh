#!/usr/bin/env bash
#
# Install the Layan SDDM theme (Plasma 6 QML engine, sddm/6.0) system-wide.
#
# This is only useful on distributions that still use SDDM as the display
# manager. Fedora 44+ ships Plasma Login Manager instead, which does not
# load SDDM themes at all -- see extras/sddm/README.md and
# docs/login-screen.md for that story.

if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "Error: this script must be run with bash, not sh." >&2
  exit 1
fi

set -euo pipefail

THEME_DIR="/usr/share/sddm/themes"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: sudo $(basename "$0")

Installs the Layan and Layan-light SDDM themes into ${THEME_DIR}.
Requires root, and requires SDDM to be the active display manager
(this script does not install or configure SDDM itself).
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

if [[ "${EUID}" -ne 0 ]]; then
  echo "Error: this script must be run as root, e.g.:" >&2
  echo "  sudo $0" >&2
  exit 1
fi

if [[ ! -d "${THEME_DIR}" ]]; then
  echo "Error: ${THEME_DIR} does not exist. Is SDDM installed?" >&2
  exit 1
fi

echo "Installing Layan SDDM themes into ${THEME_DIR}..."

rm -rf "${THEME_DIR}/Layan" "${THEME_DIR}/Layan-light"
cp -r "${SRC_DIR}/Layan" "${THEME_DIR}/Layan"
cp -r "${SRC_DIR}/Layan-light" "${THEME_DIR}/Layan-light"

echo "Done. Set the active theme in /etc/sddm.conf.d/, e.g.:"
echo "  [Theme]"
echo "  Current=Layan"
