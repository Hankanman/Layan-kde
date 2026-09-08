# Packaging

RPM packaging for `layan-kde`, targeting Fedora 44 (noarch).

Produces three packages from `layan-kde.spec`:

- `layan-kde` — Aurorae, Plasma color schemes, Plasma desktop theme
  (Layan/Layan-light), look-and-feel, wallpapers, and (if present)
  Konsole files.
- `layan-kde-kvantum` — Kvantum theme files (`Requires: kvantum`).
- `layan-kde-sddm` — SDDM login theme, packaged from `extras/sddm/6.0`
  once that directory exists (falls back to the legacy `sddm/6.0` path,
  and to a doc-only package if neither is present, so the build never
  fails).

## Build locally

Requires `rpm-build` and `rpmdevtools` (`dnf install rpm-build
rpmdevtools`).

```sh
# From the repo root:
rpmdev-setuptree                       # creates ~/rpmbuild/{SOURCES,SPECS,...}
git archive --prefix=Layan-kde-1.0/ \
    -o ~/rpmbuild/SOURCES/layan-kde-1.0.tar.gz HEAD
rpmbuild -bb packaging/layan-kde.spec
```

The built RPMs land in `~/rpmbuild/RPMS/noarch/`. List a package's
contents with:

```sh
rpm -qlp ~/rpmbuild/RPMS/noarch/layan-kde-1.0-1.*.noarch.rpm
```

To build against an isolated `_topdir` instead of `~/rpmbuild` (useful in
CI or when testing without touching your home directory):

```sh
TOPDIR=$(mktemp -d)
mkdir -p "$TOPDIR"/{SOURCES,SPECS,BUILD,RPMS,SRPMS,BUILDROOT}
git archive --prefix=Layan-kde-1.0/ -o "$TOPDIR/SOURCES/layan-kde-1.0.tar.gz" HEAD
rpmbuild -bb --define "_topdir $TOPDIR" packaging/layan-kde.spec
```

Validate the spec itself with `rpmlint` if installed:

```sh
rpmlint packaging/layan-kde.spec
```

## Releasing a new version

1. Tag the release: `git tag v1.1 && git push origin v1.1`.
2. `Source0` in the spec points at
   `https://github.com/Hankanman/Layan-kde/archive/refs/tags/v%{version}.tar.gz`,
   so bump `Version` in `layan-kde.spec` to match the tag before building
   against the real (non-local) source.

## Copr

[Copr](https://copr.fedorainfracloud.org/) is Fedora's community build
service; it is the standard way to get `dnf`-installable updates to
users without waiting on Fedora's official repos.

1. Install the client and log in once:

   ```sh
   sudo dnf install copr-cli
   copr-cli auth  # or copy ~/.config/copr from copr.fedorainfracloud.org/api/
   ```

2. Create the project:

   ```sh
   copr-cli create layan-kde \
       --chroot fedora-44-x86_64 --chroot fedora-rawhide-x86_64 \
       --description "Layan flat theme for KDE Plasma" \
       --instructions "dnf copr enable <your-fedora-account>/layan-kde"
   ```

3. Point it at this GitHub repo so it rebuilds on every push/tag (Copr's
   own webhook, not a GitHub Action). The SCM-package subcommand and its
   exact flags vary by `copr-cli` version, so check `copr-cli
   add-package-scm --help`; the shape is:

   ```sh
   copr-cli add-package-scm layan-kde \
       --name layan-kde \
       --clone-url https://github.com/Hankanman/Layan-kde.git \
       --type git \
       --spec packaging/layan-kde.spec
   copr-cli build-package layan-kde --name layan-kde
   ```

   Point the clone URL/commit at whatever branch should be built by
   default (e.g. `main` once `plasma6` merges).

4. In the Copr web UI, open the project's **Settings → Integrations**
   tab and copy the generated webhook URL, then add it under the GitHub
   repo's **Settings → Webhooks** (content type
   `application/json`, event: "Just the push event" or "Send me
   everything"). Pushes and tags then trigger a Copr rebuild
   automatically.
5. Trigger the first build manually to confirm the chroot and spec path
   are correct:

   ```sh
   copr-cli build layan-kde --nowait \
       packaging/layan-kde.spec  # or a source tarball URL
   ```

Users then install with:

```sh
sudo dnf copr enable <your-fedora-account>/layan-kde
sudo dnf install layan-kde layan-kde-kvantum
```
