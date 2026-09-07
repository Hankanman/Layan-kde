#!/usr/bin/env bash
# Layan-kde lint: static checks for SVG/SVGZ correctness, KPackage metadata,
# shell scripts, QML, and ini-style config files.
#
# Exits non-zero if any error-level finding was recorded. Warnings do not
# affect the exit code but are printed in the summary.
#
# Usage: tools/lint.sh [path...]     (defaults to the repo root)

set -euo pipefail

# ---------------------------------------------------------------------------
# setup
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
cd "${REPO_ROOT}"

TARGETS=("${@:-.}")

ERRORS=0
WARNINGS=0

# Track which optional tools are present so we only report each "not found"
# warning once.
declare -A MISSING_TOOL_WARNED=()

err() {
  printf 'ERROR: %s\n' "$1" >&2
  ERRORS=$((ERRORS + 1))
}

warn() {
  printf 'WARN:  %s\n' "$1" >&2
  WARNINGS=$((WARNINGS + 1))
}

info() {
  printf '%s\n' "$1"
}

missing_tool_warning() {
  local tool="$1" reason="$2"
  if [[ -z "${MISSING_TOOL_WARNED[${tool}]:-}" ]]; then
    warn "'${tool}' not installed — ${reason}"
    MISSING_TOOL_WARNED[${tool}]=1
  fi
}

# find files matching a glob-ish name pattern, excluding .git
find_files() {
  local pattern="$1"
  local root
  for root in "${TARGETS[@]}"; do
    find "${root}" -type f -name "${pattern}" -not -path '*/.git/*' 2>/dev/null
  done
}

info "== Layan-kde lint =="
info "Repo root: ${REPO_ROOT}"
info ""

# ---------------------------------------------------------------------------
# 1. SVG / SVGZ well-formedness
# ---------------------------------------------------------------------------

HAVE_XMLLINT=1
command -v xmllint >/dev/null 2>&1 || HAVE_XMLLINT=0

info "-- SVG/SVGZ well-formedness --"

SVG_COUNT=0
SVGZ_COUNT=0

if [[ "${HAVE_XMLLINT}" -eq 1 ]]; then
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    SVG_COUNT=$((SVG_COUNT + 1))
    if ! xmllint --noout "$f" 2>/tmp/lint_xmllint_err.$$; then
      err "malformed SVG: $f -- $(tr '\n' ' ' </tmp/lint_xmllint_err.$$)"
    fi
    rm -f /tmp/lint_xmllint_err.$$
  done < <(find_files '*.svg')

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    SVGZ_COUNT=$((SVGZ_COUNT + 1))
    if ! gzip -t "$f" 2>/tmp/lint_gzip_err.$$; then
      err "corrupt gzip in SVGZ: $f -- $(tr '\n' ' ' </tmp/lint_gzip_err.$$)"
      rm -f /tmp/lint_gzip_err.$$
      continue
    fi
    rm -f /tmp/lint_gzip_err.$$
    if ! zcat "$f" 2>/dev/null | xmllint --noout - 2>/tmp/lint_xmllint_err.$$; then
      err "malformed SVGZ (decompressed XML): $f -- $(tr '\n' ' ' </tmp/lint_xmllint_err.$$)"
    fi
    rm -f /tmp/lint_xmllint_err.$$
  done < <(find_files '*.svgz')
else
  missing_tool_warning "xmllint" "skipping SVG/SVGZ XML well-formedness checks"
fi

info "checked ${SVG_COUNT} .svg, ${SVGZ_COUNT} .svgz files"
info ""

# ---------------------------------------------------------------------------
# 2. Dangling reference check (url(#id), xlink:href="#id", href="#id")
# ---------------------------------------------------------------------------

info "-- dangling SVG references --"

check_dangling_refs() {
  local f="$1" content="$2"
  # collect ids defined in the file
  local ids
  ids=$(printf '%s' "$content" | grep -oE 'id="[^"]+"' | sed -E 's/id="([^"]+)"/\1/' | sort -u || true)

  # collect referenced ids: url(#id), xlink:href="#id", href="#id"
  local refs
  refs=$(printf '%s' "$content" | grep -oE '(url\(#[^)"'"'"']+\)|xlink:href="#[^"]+"|href="#[^"]+")' \
    | sed -E 's/url\(#([^)"'"'"']+)\)/\1/; s/xlink:href="#([^"]+)"/\1/; s/href="#([^"]+)"/\1/' || true)

  [[ -z "$refs" ]] && return 0

  local ref
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    if ! grep -qxF "$ref" <<<"$ids"; then
      err "dangling reference #${ref} in $f"
    fi
  done <<<"$refs"
}

if [[ "${HAVE_XMLLINT}" -eq 1 || 1 -eq 1 ]]; then
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    check_dangling_refs "$f" "$(cat "$f")"
  done < <(find_files '*.svg')

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    check_dangling_refs "$f" "$(zcat "$f" 2>/dev/null || true)"
  done < <(find_files '*.svgz')
fi

info ""

# ---------------------------------------------------------------------------
# 3. Duplicate <style> element check
#    (Qt 6.11's SVG parser rejects a document with more than one <style>
#     element -- see commit 7671e6d on this branch.)
# ---------------------------------------------------------------------------

info "-- duplicate <style> elements --"

check_dup_style() {
  local f="$1" content="$2"
  local count
  count=$(printf '%s' "$content" | grep -oE '<style[ >]' | wc -l | tr -d ' ' || true)
  if [[ "${count}" -gt 1 ]]; then
    err "duplicate <style> elements (${count}) in $f -- Qt 6.11 SVG parser rejects this"
  fi
}

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  check_dup_style "$f" "$(cat "$f")"
done < <(find_files '*.svg')

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  check_dup_style "$f" "$(zcat "$f" 2>/dev/null || true)"
done < <(find_files '*.svgz')

info ""

# ---------------------------------------------------------------------------
# 4. metadata.json checks
# ---------------------------------------------------------------------------

info "-- metadata.json --"

HAVE_JQ=1
command -v jq >/dev/null 2>&1 || HAVE_JQ=0

if [[ "${HAVE_JQ}" -eq 1 ]]; then
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if ! jq empty "$f" >/tmp/lint_jq_err.$$ 2>&1; then
      err "invalid JSON: $f -- $(tr '\n' ' ' </tmp/lint_jq_err.$$)"
    fi
    rm -f /tmp/lint_jq_err.$$
  done < <(find_files 'metadata.json')
else
  missing_tool_warning "jq" "skipping metadata.json validation"
fi

# every plasma/look-and-feel/*/metadata.json must have KPackageStructure
for root in "${TARGETS[@]}"; do
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if [[ "${HAVE_JQ}" -eq 1 ]]; then
      structure=$(jq -r '.KPackageStructure // empty' "$f" 2>/dev/null || true)
      if [[ -z "$structure" ]]; then
        err "missing KPackageStructure in $f"
      fi
    fi
  done < <(find "${root}" -type f -path '*/plasma/look-and-feel/*/metadata.json' -not -path '*/.git/*' 2>/dev/null)
done

# each desktoptheme variant dir needs metadata.json (and warn-only plasmarc)
# NB: match direct children of a "desktoptheme" dir only (not nested dirs
# like .../desktoptheme/Layan/widgets), regardless of how deep the repo
# root sits, so -maxdepth can't be used here.
for root in "${TARGETS[@]}"; do
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    base="$(basename "$d")"
    [[ "$base" == "common" ]] && continue
    if [[ ! -f "$d/metadata.json" ]]; then
      err "desktoptheme variant $d is missing metadata.json"
    fi
    if [[ ! -f "$d/plasmarc" ]]; then
      warn "desktoptheme variant $d is missing plasmarc (expected to be added separately)"
    fi
  done < <(find "${root}" -type d -regex '.*/plasma/desktoptheme/[^/]+' -not -path '*/.git/*' 2>/dev/null)
done

info ""

# ---------------------------------------------------------------------------
# 5. Shell scripts: bash -n, shellcheck if available
# ---------------------------------------------------------------------------

info "-- shell scripts --"

HAVE_SHELLCHECK=1
command -v shellcheck >/dev/null 2>&1 || HAVE_SHELLCHECK=0

SH_COUNT=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  SH_COUNT=$((SH_COUNT + 1))
  if ! bash -n "$f" 2>/tmp/lint_bashn_err.$$; then
    err "bash -n failed: $f -- $(tr '\n' ' ' </tmp/lint_bashn_err.$$)"
  fi
  rm -f /tmp/lint_bashn_err.$$
  if [[ "${HAVE_SHELLCHECK}" -eq 1 ]]; then
    if ! shellcheck "$f" >/tmp/lint_shellcheck_out.$$ 2>&1; then
      err "shellcheck findings in $f:"
      sed 's/^/    /' /tmp/lint_shellcheck_out.$$ >&2
    fi
    rm -f /tmp/lint_shellcheck_out.$$
  fi
done < <(find_files '*.sh')

if [[ "${HAVE_SHELLCHECK}" -eq 0 ]]; then
  missing_tool_warning "shellcheck" "skipping shell static analysis (bash -n still ran)"
fi

info "checked ${SH_COUNT} shell scripts"
info ""

# ---------------------------------------------------------------------------
# 6. QML: qmllint if available, else warn
# ---------------------------------------------------------------------------

info "-- QML --"

HAVE_QMLLINT=1
command -v qmllint >/dev/null 2>&1 || HAVE_QMLLINT=0

QML_COUNT=0
if [[ "${HAVE_QMLLINT}" -eq 1 ]]; then
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    QML_COUNT=$((QML_COUNT + 1))
    if ! qmllint "$f" >/tmp/lint_qmllint_out.$$ 2>&1; then
      err "qmllint findings in $f:"
      sed 's/^/    /' /tmp/lint_qmllint_out.$$ >&2
    fi
    rm -f /tmp/lint_qmllint_out.$$
  done < <(find_files '*.qml')
  info "checked ${QML_COUNT} QML files"
else
  QML_COUNT=$(find_files '*.qml' | wc -l | tr -d ' ')
  missing_tool_warning "qmllint" "skipping QML lint (Fedora: dnf install qt6-qtdeclarative-devel); ${QML_COUNT} .qml files not checked"
fi

info ""

# ---------------------------------------------------------------------------
# 7. ini sanity: *.colors, *rc, contents/defaults, *.kvconfig
# ---------------------------------------------------------------------------

info "-- ini-style config sanity --"

check_ini() {
  local f="$1"
  local lineno=0
  local bad=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))
    # strip trailing CR (in case of CRLF)
    line="${line%$'\r'}"
    # blank line
    [[ -z "${line//[[:space:]]/}" ]] && continue
    # comment line (# or ;)
    [[ "$line" =~ ^[[:space:]]*[#\;] ]] && continue
    # section header: [anything]
    if [[ "$line" =~ ^[[:space:]]*\[.+\][[:space:]]*$ ]]; then
      continue
    fi
    # key=value (key may contain []_ letters, digits, spaces, dots, brackets for locale suffixes)
    if [[ "$line" == *"="* ]]; then
      continue
    fi
    bad=$((bad + 1))
    err "ini syntax: $f:${lineno}: not a [Section] or key=value line: ${line}"
  done <"$f"
}

INI_COUNT=0
# NOTE: must use process substitution (not a pipe into `while`) so that
# `err`/`warn` run in this shell and update ERRORS/WARNINGS, not a subshell.
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  # skip binary/non-text files defensively
  if ! grep -Iq . "$f" 2>/dev/null; then
    continue
  fi
  INI_COUNT=$((INI_COUNT + 1))
  check_ini "$f"
done < <(
  {
    find_files '*.colors'
    find_files '*rc'
    find_files 'defaults'
    find_files '*.kvconfig'
  } | sort -u
)

info "checked ${INI_COUNT} ini-style files"
info ""

# ---------------------------------------------------------------------------
# summary
# ---------------------------------------------------------------------------

info "== Summary =="
info "Errors:   ${ERRORS}"
info "Warnings: ${WARNINGS}"

if [[ "${ERRORS}" -gt 0 ]]; then
  exit 1
fi
exit 0
