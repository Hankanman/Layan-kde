%global forgeurl https://github.com/Hankanman/Layan-kde

Name:           layan-kde
Version:        1.0
Release:        1%{?dist}
Summary:        Layan flat theme for KDE Plasma

License:        GPL-3.0-only
URL:            %{forgeurl}
Source0:        %{forgeurl}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz

BuildArch:      noarch

# Whether extras/sddm has landed in this source tree yet. install.sh is
# being rewritten concurrently to move sddm/ -> extras/sddm/; until that
# lands we detect the directory at build time instead of hard-failing.
%global sddm_srcdir extras/sddm/6.0

Requires:       plasma-workspace
Recommends:     kvantum
Suggests:       kvantum

%description
Layan is a flat design theme for the KDE Plasma desktop. This package
installs the Aurorae window decoration, Plasma color schemes, the Plasma
desktop theme (Layan and Layan-light), the look-and-feel package, and the
wallpapers. Kvantum theme files are packaged separately in
layan-kde-kvantum, and (when present in the source tree) the SDDM theme is
packaged separately in layan-kde-sddm.

%package kvantum
Summary:        Kvantum theme files for the Layan KDE theme
Requires:       kvantum
# The base package is not required for a pure Kvantum-only install, but in
# practice the two are used together.
Recommends:     %{name} = %{version}-%{release}

%description kvantum
Kvantum SVG/kvconfig theme files for Layan and LayanSolid, for use with
the Kvantum engine (Requires: kvantum).

%package sddm
Summary:        SDDM login theme for the Layan KDE theme
Requires:       sddm

%description sddm
SDDM (Simple Desktop Display Manager) login screen theme for Layan and
Layan-light, for distributions that use SDDM rather than Plasma Login
Manager.

%prep
%autosetup -n Layan-kde-%{version}

%build
# Nothing to build: this is a collection of SVGs, QML and config files.

%install
# --- Aurorae window decorations -------------------------------------------
install -d -m0755 %{buildroot}%{_datadir}/aurorae/themes
cp -a aurorae/themes/. %{buildroot}%{_datadir}/aurorae/themes/

# --- Plasma color schemes ---------------------------------------------------
install -d -m0755 %{buildroot}%{_datadir}/color-schemes
cp -a color-schemes/*.colors %{buildroot}%{_datadir}/color-schemes/

# --- Kvantum theme files -----------------------------------------------------
install -d -m0755 %{buildroot}%{_datadir}/Kvantum
cp -a Kvantum/. %{buildroot}%{_datadir}/Kvantum/

# --- Plasma desktop themes ---------------------------------------------------
# Mirrors install.sh: for each variant, start from common/, overlay the
# variant-specific files, then drop in the matching .colors file as
# "colors" in the theme root.
install -d -m0755 %{buildroot}%{_datadir}/plasma/desktoptheme
for variant in Layan Layan-light; do
    dest=%{buildroot}%{_datadir}/plasma/desktoptheme/${variant}
    install -d -m0755 "${dest}"
    cp -a plasma/desktoptheme/common/. "${dest}/"
    cp -a plasma/desktoptheme/${variant}/. "${dest}/"
done
cp -a color-schemes/Layan.colors \
    %{buildroot}%{_datadir}/plasma/desktoptheme/Layan/colors
cp -a color-schemes/LayanLight.colors \
    %{buildroot}%{_datadir}/plasma/desktoptheme/Layan-light/colors

# --- Plasma look-and-feel ----------------------------------------------------
install -d -m0755 %{buildroot}%{_datadir}/plasma/look-and-feel
cp -a plasma/look-and-feel/. %{buildroot}%{_datadir}/plasma/look-and-feel/

# --- Wallpapers ---------------------------------------------------------------
install -d -m0755 %{buildroot}%{_datadir}/wallpapers
cp -a wallpaper/. %{buildroot}%{_datadir}/wallpapers/

# --- Optional file lists -----------------------------------------------------
# konsole/ and the sddm source directory may or may not exist yet in this
# checkout (both are being added/moved by concurrent work). Build the file
# lists for those pieces dynamically so `rpmbuild -bb` always succeeds:
# whichever pieces are missing simply produce a smaller (or, for the sddm
# subpackage, a doc-only) package instead of failing the build. Some rpm
# versions error on an empty `%%files -f <list>` file, so both lists always
# get at least one unconditional entry.
cat > main.files <<EOF
%{_datadir}/aurorae/themes/Layan
%{_datadir}/aurorae/themes/Layan-light
%{_datadir}/aurorae/themes/Layan-solid
%{_datadir}/color-schemes/*.colors
%{_datadir}/plasma/desktoptheme/Layan
%{_datadir}/plasma/desktoptheme/Layan-light
%{_datadir}/plasma/look-and-feel/*
%{_datadir}/wallpapers/*
EOF

# --- Konsole colour scheme / profile (optional, may not exist yet) ----------
if [ -d konsole ]; then
    install -d -m0755 %{buildroot}%{_datadir}/konsole
    cp -a konsole/. %{buildroot}%{_datadir}/konsole/
    echo '%{_datadir}/konsole' >> main.files
fi

# --- SDDM theme (subpackage, only if the source tree has it) ---------------
# install.sh is being reworked concurrently to move sddm/ -> extras/sddm/.
# Build against whichever layout is present so this spec doesn't hard-fail
# while that move is in flight.
if [ -d %{sddm_srcdir} ]; then
    sddm_src=%{sddm_srcdir}
elif [ -d sddm/6.0 ]; then
    sddm_src=sddm/6.0
else
    sddm_src=""
fi

install -d -m0755 %{buildroot}%{_datadir}/doc/%{name}-sddm
if [ -n "${sddm_src}" ]; then
    install -d -m0755 %{buildroot}%{_datadir}/sddm/themes
    cp -a "${sddm_src}"/. %{buildroot}%{_datadir}/sddm/themes/
    echo "Layan-kde SDDM theme, installed from ${sddm_src}." \
        > %{buildroot}%{_datadir}/doc/%{name}-sddm/README
    echo '%{_datadir}/sddm/themes/*' > sddm.files
else
    echo 'SDDM theme not present in this source tree yet (extras/sddm has not landed).' \
        > %{buildroot}%{_datadir}/doc/%{name}-sddm/README
    : > sddm.files
fi
echo '%{_datadir}/doc/%{name}-sddm/README' >> sddm.files

%files -f main.files
%license LICENSE
%doc README.md

%files kvantum
%{_datadir}/Kvantum/*

%files sddm -f sddm.files

%post
/usr/bin/kbuildsycoca6 >/dev/null 2>&1 || :

%postun
/usr/bin/kbuildsycoca6 >/dev/null 2>&1 || :

%changelog
* Mon Sep 07 2026 Layan-kde packaging <noreply@anthropic.com> - 1.0-1
- Initial RPM packaging of the Layan-kde theme.
