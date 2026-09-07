#!/usr/bin/env bash
#
# Install the Layan KDE theme (Plasma desktop theme, colour scheme,
# global theme, Aurorae window decoration, Kvantum, wallpapers, Konsole).
#
# Run with bash, not sh -- see the guard below.

if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "Error: this script must be run with bash, not sh." >&2
  echo "  bash ./install.sh   or   ./install.sh" >&2
  exit 1
fi

set -euo pipefail

ROOT_UID=0
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

THEME_NAME=Layan
COLOR_VARIANTS=('' '-light')

INSTALL_SCOPE=""
APPLY_THEME=""
USE_KVANTUM=1
INSTALL_SDDM=0
INSTALL_DEPS=0
WITH_ICONS=0
WITH_CURSORS=0

TELA_REPO="https://github.com/vinceliuice/Tela-icon-theme"
LAYAN_CURSORS_REPO="https://github.com/vinceliuice/Layan-cursors"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Installs the Layan KDE theme: Plasma desktop theme, colour scheme,
look-and-feel (global theme), Aurorae window decoration, Kvantum theme,
wallpapers, and Konsole colour scheme/profile (once present in this repo).

Options:
  --system        Install for all users under /usr/share (requires root)
  --user          Install for the current user under ~/.local (default)
  --apply         Activate the Layan (dark) global theme after installing
  --apply-light   Activate the Layan-light global theme after installing
  --no-kvantum    Skip installing the Kvantum theme
  --sddm          Also install extras/sddm (requires root; only if
                  /usr/share/sddm/themes exists -- see extras/sddm/README.md)
  --install-deps  On Fedora, run 'sudo dnf install -y kvantum kvantum-qt5'
                  if Kvantum is not already installed
  --with-icons    Also fetch and install the Tela icon theme (Tela,
                  Tela-dark, Tela-light) from ${TELA_REPO}
  --with-cursors  Also fetch and install the Layan cursor themes from
                  ${LAYAN_CURSORS_REPO}
  --full          Shorthand for --with-icons --with-cursors
  -h, --help      Show this help

--with-icons / --with-cursors / --full need git and network access. They
clone the upstream repos to a temporary directory and install into the same
scope (--user or --system) as the rest of the theme.

Examples:
  ./install.sh
  sudo ./install.sh --system --full
  ./install.sh --full --apply
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system) INSTALL_SCOPE=system; shift ;;
    --user) INSTALL_SCOPE=user; shift ;;
    --apply) APPLY_THEME=dark; shift ;;
    --apply-light) APPLY_THEME=light; shift ;;
    --no-kvantum) USE_KVANTUM=0; shift ;;
    --sddm) INSTALL_SDDM=1; shift ;;
    --install-deps) INSTALL_DEPS=1; shift ;;
    --with-icons) WITH_ICONS=1; shift ;;
    --with-cursors) WITH_CURSORS=1; shift ;;
    --full) WITH_ICONS=1; WITH_CURSORS=1; shift ;;
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
  echo "Error: system-wide install requires root. Run: sudo $0 --system" >&2
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
  ICONS_DIR="/usr/share/icons"
else
  AURORAE_DIR="${HOME}/.local/share/aurorae/themes"
  SCHEMES_DIR="${HOME}/.local/share/color-schemes"
  PLASMA_DIR="${HOME}/.local/share/plasma/desktoptheme"
  LOOKFEEL_DIR="${HOME}/.local/share/plasma/look-and-feel"
  KVANTUM_DIR="${HOME}/.config/Kvantum"
  WALLPAPER_DIR="${HOME}/.local/share/wallpapers"
  KONSOLE_DIR="${HOME}/.local/share/konsole"
  ICONS_DIR="${HOME}/.local/share/icons"
fi

mkdir -p "${AURORAE_DIR}" "${SCHEMES_DIR}" "${PLASMA_DIR}" "${LOOKFEEL_DIR}" "${WALLPAPER_DIR}" "${KONSOLE_DIR}"
[[ "$USE_KVANTUM" -eq 1 ]] && mkdir -p "${KVANTUM_DIR}"

# ---------------------------------------------------------------------------
# Aurorae window decoration: Layan, Layan-light, Layan-solid
# ---------------------------------------------------------------------------
install_aurorae() {
  for variant in "Layan" "Layan-light" "Layan-solid"; do
    local src="${SRC_DIR}/aurorae/themes/${variant}"
    [[ -d "$src" ]] || continue
    echo "Installing Aurorae theme: ${variant}"
    rm -rf "${AURORAE_DIR:?}/${variant}"
    cp -r "$src" "${AURORAE_DIR}/${variant}"
  done
}

# ---------------------------------------------------------------------------
# Colour schemes, plasma desktop theme, look-and-feel, wallpaper per variant
# ---------------------------------------------------------------------------
install_variant() {
  local name="$1"
  local color="$2"
  local else_color=""
  [[ "$color" == "-light" ]] && else_color="Light"

  echo "Installing ${name}${color}..."

  local scheme_file="${SRC_DIR}/color-schemes/${name}${else_color}.colors"
  if [[ -f "$scheme_file" ]]; then
    rm -f "${SCHEMES_DIR:?}/${name}${else_color}.colors"
    cp "$scheme_file" "${SCHEMES_DIR}/"
  fi

  local theme_src="${SRC_DIR}/plasma/desktoptheme/${name}${color}"
  if [[ -d "$theme_src" ]]; then
    local theme_dest="${PLASMA_DIR}/${name}${color}"
    rm -rf "${theme_dest:?}"
    mkdir -p "$theme_dest"
    [[ -d "${SRC_DIR}/plasma/desktoptheme/common" ]] && cp -r "${SRC_DIR}/plasma/desktoptheme/common/." "$theme_dest/"
    cp -r "${theme_src}/." "$theme_dest/"
    # Keep behaviour: install the .colors file into the theme as "colors"
    [[ -f "$scheme_file" ]] && cp "$scheme_file" "${theme_dest}/colors"
    # plasmarc, when the desktoptheme agent has added it (B1)
    [[ -f "${theme_src}/plasmarc" ]] && cp "${theme_src}/plasmarc" "${theme_dest}/plasmarc"
  fi

  local lookfeel_src="${SRC_DIR}/plasma/look-and-feel/com.github.vinceliuice.${name}${color}"
  if [[ -d "$lookfeel_src" ]]; then
    rm -rf "${LOOKFEEL_DIR:?}/com.github.vinceliuice.${name}${color}"
    cp -r "$lookfeel_src" "${LOOKFEEL_DIR}/com.github.vinceliuice.${name}${color}"
  fi

  local wallpaper_src="${SRC_DIR}/wallpaper/${name}${color}"
  if [[ -d "$wallpaper_src" ]]; then
    rm -rf "${WALLPAPER_DIR:?}/${name}${color}"
    cp -r "$wallpaper_src" "${WALLPAPER_DIR}/${name}${color}"
  fi
}

# ---------------------------------------------------------------------------
# Any extra wallpaper packages under wallpaper/ not covered by the name/color
# loop above (e.g. wallpaper/LayanAutomatic)
# ---------------------------------------------------------------------------
install_extra_wallpapers() {
  [[ -d "${SRC_DIR}/wallpaper" ]] || return 0
  local dir base
  for dir in "${SRC_DIR}"/wallpaper/*/; do
    [[ -d "$dir" ]] || continue
    base="$(basename "$dir")"
    case "$base" in
      "${THEME_NAME}"|"${THEME_NAME}-light") continue ;;
    esac
    echo "Installing wallpaper: ${base}"
    rm -rf "${WALLPAPER_DIR:?}/${base}"
    cp -r "$dir" "${WALLPAPER_DIR}/${base}"
  done
}

# ---------------------------------------------------------------------------
# Kvantum: Layan + LayanSolid
# ---------------------------------------------------------------------------
install_kvantum() {
  [[ "$USE_KVANTUM" -eq 1 ]] || return 0
  for variant in "Layan" "LayanSolid"; do
    local src="${SRC_DIR}/Kvantum/${variant}"
    [[ -d "$src" ]] || continue
    echo "Installing Kvantum theme: ${variant}"
    rm -rf "${KVANTUM_DIR:?}/${variant}"
    cp -r "$src" "${KVANTUM_DIR}/${variant}"
  done
}

# ---------------------------------------------------------------------------
# Konsole colour scheme + profile (from the konsole/ agent, once merged)
# ---------------------------------------------------------------------------
install_konsole() {
  [[ -d "${SRC_DIR}/konsole" ]] || return 0
  echo "Installing Konsole colour schemes and profiles..."
  local f base
  for f in "${SRC_DIR}"/konsole/*; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f")"
    cp "$f" "${KONSOLE_DIR}/${base}"
  done
}

echo "Installing '${THEME_NAME}' KDE theme (${INSTALL_SCOPE}-wide)..."

install_aurorae
install_kvantum
for color in "${COLOR_VARIANTS[@]}"; do
  install_variant "${THEME_NAME}" "${color}"
done
install_extra_wallpapers
install_konsole

# ---------------------------------------------------------------------------
# extras/sddm (opt-in, requires root and an existing SDDM install)
# ---------------------------------------------------------------------------
if [[ "$INSTALL_SDDM" -eq 1 ]]; then
  if [[ "$EUID" -ne "$ROOT_UID" ]]; then
    echo "Warning: --sddm requires root; skipping extras/sddm install." >&2
    echo "  Run: sudo extras/sddm/6.0/install.sh" >&2
  elif [[ ! -d "/usr/share/sddm/themes" ]]; then
    echo "Warning: /usr/share/sddm/themes does not exist (SDDM not installed); skipping." >&2
  elif [[ -x "${SRC_DIR}/extras/sddm/6.0/install.sh" ]]; then
    "${SRC_DIR}/extras/sddm/6.0/install.sh"
  fi
fi

# ---------------------------------------------------------------------------
# Fedora: hint about Kvantum instead of installing packages automatically,
# unless --install-deps was passed.
# ---------------------------------------------------------------------------
if [[ "$USE_KVANTUM" -eq 1 && -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" == "fedora" ]]; then
    if ! rpm -q kvantum >/dev/null 2>&1; then
      if [[ "$INSTALL_DEPS" -eq 1 ]]; then
        echo "Fedora detected: installing kvantum kvantum-qt5..."
        sudo dnf install -y kvantum kvantum-qt5
      else
        echo "Hint: Kvantum is not installed. On Fedora, run:"
        echo "  sudo dnf install kvantum kvantum-qt5"
        echo "or re-run this installer with --install-deps."
      fi
    fi
  fi
fi

# ---------------------------------------------------------------------------
# --with-icons / --with-cursors: fetch and install the matching Tela icons
# and Layan cursors that the look-and-feel defaults reference.
# ---------------------------------------------------------------------------
FETCH_TMP=""
cleanup_fetch_tmp() { [[ -n "$FETCH_TMP" ]] && rm -rf -- "$FETCH_TMP"; }
trap cleanup_fetch_tmp EXIT

fetch_repo() {
  # fetch_repo URL DEST -- shallow-clone URL into DEST
  if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required for --with-icons/--with-cursors." >&2
    return 1
  fi
  echo "Fetching $1 ..."
  git clone --quiet --depth 1 "$1" "$2"
}

install_tela_icons() {
  local src="${FETCH_TMP}/Tela-icon-theme"
  fetch_repo "$TELA_REPO" "$src" || return 1
  echo "Installing Tela icon theme into ${ICONS_DIR}"
  mkdir -p "$ICONS_DIR"
  # 'standard' installs Tela, Tela-dark and Tela-light.
  bash "${src}/install.sh" -d "$ICONS_DIR" standard
}

install_layan_cursors() {
  local src="${FETCH_TMP}/Layan-cursors"
  fetch_repo "$LAYAN_CURSORS_REPO" "$src" || return 1
  echo "Installing Layan cursor themes into ${ICONS_DIR}"
  mkdir -p "$ICONS_DIR"
  # Mirror upstream install.sh, but honour our --user/--system scope.
  local d
  for d in dist:Layan-cursors dist-border:Layan-border-cursors dist-white:Layan-white-cursors; do
    local from="${src}/${d%%:*}" to="${ICONS_DIR}/${d##*:}"
    [[ -d "$from" ]] || { echo "Warning: ${from} missing in upstream repo; skipping." >&2; continue; }
    rm -rf -- "$to"
    cp -r "$from" "$to"
  done
}

if [[ "$WITH_ICONS" -eq 1 || "$WITH_CURSORS" -eq 1 ]]; then
  FETCH_TMP="$(mktemp -d)"
  if [[ "$WITH_ICONS" -eq 1 ]]; then
    install_tela_icons || echo "Warning: Tela icon install failed; continuing." >&2
  fi
  if [[ "$WITH_CURSORS" -eq 1 ]]; then
    install_layan_cursors || echo "Warning: Layan cursors install failed; continuing." >&2
  fi
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------------------
# --apply / --apply-light: activate the global theme and set Kvantum's theme
# ---------------------------------------------------------------------------
if [[ -n "$APPLY_THEME" ]]; then
  if [[ "$APPLY_THEME" == "light" ]]; then
    LOOKFEEL_ID="com.github.vinceliuice.Layan-light"
    KVANTUM_THEME="Layan"
  else
    LOOKFEEL_ID="com.github.vinceliuice.Layan"
    KVANTUM_THEME="LayanDark"
  fi

  if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
    plasma-apply-lookandfeel -a "$LOOKFEEL_ID" && echo "Applied global theme: ${LOOKFEEL_ID}"
  else
    echo "Warning: plasma-apply-lookandfeel not found; theme installed but not activated." >&2
  fi

  # The look-and-feel defaults name the Tela icon theme and the Layan cursor
  # theme. System Settings fetches them from the KDE Store when it applies the
  # theme, but plasma-apply-lookandfeel does not, so on a machine without them
  # Plasma is left pointing at themes that do not exist and most shell icons
  # (system tray, launcher, System Settings) vanish. Detect that and fall back
  # to Breeze so the desktop is always usable.
  theme_dir_exists() {
    local kind="$1" name="$2" d
    for d in "${HOME}/.local/share/${kind}" "${HOME}/.${kind}" "/usr/share/${kind}" "/usr/local/share/${kind}"; do
      [[ -d "${d}/${name}" ]] && return 0
    done
    return 1
  }

  if [[ "$APPLY_THEME" == "light" ]]; then
    WANT_ICONS="Tela"; FALLBACK_ICONS="breeze"
    WANT_CURSORS="Layan-white-cursors"; FALLBACK_CURSORS="breeze_cursors"
  else
    WANT_ICONS="Tela-dark"; FALLBACK_ICONS="breeze-dark"
    WANT_CURSORS="Layan-white-cursors"; FALLBACK_CURSORS="breeze_cursors"
  fi

  if ! theme_dir_exists icons "$WANT_ICONS"; then
    echo "Icon theme ${WANT_ICONS} is not installed; using ${FALLBACK_ICONS} instead."
    echo "  (re-run with --with-icons --apply to fetch and use it)"
    CHANGEICONS=""
    for c in /usr/libexec/plasma-changeicons /usr/lib64/libexec/plasma-changeicons /usr/lib/x86_64-linux-gnu/libexec/plasma-changeicons /usr/lib/libexec/plasma-changeicons; do
      [[ -x "$c" ]] && { CHANGEICONS="$c"; break; }
    done
    if [[ -n "$CHANGEICONS" ]]; then
      "$CHANGEICONS" "$FALLBACK_ICONS" || true
    elif command -v kwriteconfig6 >/dev/null 2>&1; then
      kwriteconfig6 --file kdeglobals --group Icons --key Theme "$FALLBACK_ICONS"
    fi
  fi

  if ! theme_dir_exists icons "$WANT_CURSORS"; then
    echo "Cursor theme ${WANT_CURSORS} is not installed; using ${FALLBACK_CURSORS} instead."
    echo "  (re-run with --with-cursors --apply to fetch and use it)"
    if command -v plasma-apply-cursortheme >/dev/null 2>&1; then
      plasma-apply-cursortheme "$FALLBACK_CURSORS" || true
    elif command -v kwriteconfig6 >/dev/null 2>&1; then
      kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "$FALLBACK_CURSORS"
    fi
  fi

  if [[ "$USE_KVANTUM" -eq 1 ]] && command -v kwriteconfig6 >/dev/null 2>&1; then
    KVANTUM_CONFIG="${HOME}/.config/Kvantum/kvantum.kvconfig"
    mkdir -p "$(dirname "$KVANTUM_CONFIG")"
    kwriteconfig6 --file "$KVANTUM_CONFIG" --group General --key theme "$KVANTUM_THEME"
    echo "Set Kvantum theme to ${KVANTUM_THEME} in ${KVANTUM_CONFIG}"
  fi
fi

echo "Install finished."
if [[ -z "$APPLY_THEME" ]]; then
  echo "To activate the global theme, run:"
  echo "  plasma-apply-lookandfeel -a com.github.vinceliuice.Layan"
  echo "or re-run this installer with --apply / --apply-light."
fi
