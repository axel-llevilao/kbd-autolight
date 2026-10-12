#!/usr/bin/env bash
# Builds build/kbd-autolight_<version>_all.deb from this repository.
# Requirements: dpkg-deb and gettext (sudo apt install dpkg-dev gettext).
set -euo pipefail
cd "$(dirname "$0")"

# ---- edit these before publishing -------------------------------------------
MAINTAINER="${MAINTAINER:-Axel <axel-llevilao@users.noreply.github.com>}"
HOMEPAGE="${HOMEPAGE:-https://github.com/axel-llevilao/kbd-autolight}"
# -----------------------------------------------------------------------------

NAME=kbd-autolight
VERSION="$(cat VERSION)"
PLASMOID_ID="$(python3 -c 'import json; print(json.load(open("plasmoid/metadata.json"))["KPlugin"]["Id"])')"
PKG="build/pkg"

command -v msgfmt >/dev/null || { echo "msgfmt not found: sudo apt install gettext" >&2; exit 1; }

rm -rf build
mkdir -p "$PKG/DEBIAN"

# Program, user service, settings
install -Dm755 src/kbd-autolight                "$PKG/usr/bin/kbd-autolight"
install -Dm644 systemd/kbd-autolight.service    "$PKG/usr/lib/systemd/user/kbd-autolight.service"
install -Dm644 config/kbd-autolight.conf        "$PKG/etc/kbd-autolight.conf"

# Plasma applet
APPLET="$PKG/usr/share/plasma/plasmoids/$PLASMOID_ID"
install -Dm644 plasmoid/metadata.json           "$APPLET/metadata.json"
install -Dm644 plasmoid/contents/ui/main.qml    "$APPLET/contents/ui/main.qml"

# Translations
for po in po/*.po; do
    lang="$(basename "$po" .po)"
    dir="$PKG/usr/share/locale/$lang/LC_MESSAGES"
    mkdir -p "$dir"
    msgfmt --check -o "$dir/plasma_applet_$PLASMOID_ID.mo" "$po"
done

# Documentation
DOC="$PKG/usr/share/doc/$NAME"
install -Dm644 README.md "$DOC/README.md"
install -Dm644 LICENSE   "$DOC/copyright"
sed "s|Axel <axel-llevilao@users.noreply.github.com>|$MAINTAINER|" packaging/changelog | gzip -9n > "$DOC/changelog.gz"
chmod 644 "$DOC/changelog.gz"
install -d "$PKG/usr/share/man/man1"
gzip -9n -c packaging/kbd-autolight.1 > "$PKG/usr/share/man/man1/kbd-autolight.1.gz"
chmod 644 "$PKG/usr/share/man/man1/kbd-autolight.1.gz"

# Control files
SIZE="$(du -sk --exclude=DEBIAN "$PKG" | cut -f1)"
sed -e "s|@VERSION@|$VERSION|" -e "s|@MAINTAINER@|$MAINTAINER|" \
    -e "s|@HOMEPAGE@|$HOMEPAGE|" -e "s|@SIZE@|$SIZE|" \
    packaging/control.in > "$PKG/DEBIAN/control"
install -m755 packaging/postinst "$PKG/DEBIAN/postinst"
echo "/etc/kbd-autolight.conf" > "$PKG/DEBIAN/conffiles"

# Directories 755, files 644 unless set above
find "$PKG" -type d -exec chmod 755 {} +

OUT="build/${NAME}_${VERSION}_all.deb"
dpkg-deb --root-owner-group -Zxz --build "$PKG" "$OUT" >/dev/null
echo "Built $OUT"
