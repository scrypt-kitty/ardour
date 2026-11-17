#!/bin/bash
# Native macOS build of Ardour for Apple Silicon (arm64) with Homebrew. UNTESTED on real hardware:
# written against Ardour's wscript (--arm64, coreaudio backend) but not run on a Mac yet.
# Usage: scripts/macos/build-macos.sh [all|deps|configure|build|package|clean]
#   env: ARDOUR_JOBS=N  ARDOUR_OPTIMIZE=1  ARDOUR_CFG="extra waf args"
set -euo pipefail
cd "$(dirname "$0")/../.."
test -f gtk2_ardour/wscript || { echo "run from an Ardour checkout"; exit 1; }
[ "$(uname -s)" = Darwin ] || { echo "macOS only"; exit 1; }
[ "$(uname -m)" = arm64 ] || echo "warning: not an arm64 host; --arm64 cross-builds need arm64 Homebrew libs"
command -v brew >/dev/null || { echo "install Homebrew first: https://brew.sh"; exit 1; }
ACTION=${1:-all}; JOBS=${ARDOUR_JOBS:-$(sysctl -n hw.ncpu)}; OPT=${ARDOUR_OPTIMIZE:-0}
HB=$(brew --prefix)
PREFIX=${ARDOUR_PREFIX:-$PWD/build/macos-prefix}

# Ardour still needs the sigc++2-era C++ bindings (glibmm-2.4 API); Homebrew ships them as versioned, keg-only formulae.
FORMULAE=(pkgconf python boost glib glibmm@2.66 libsigc++@2 cairomm@1.14 pangomm@2.46 cairo pango atk gdk-pixbuf
  libsndfile libsamplerate libxml2 libxslt curl liblo aubio fftw taglib rubberband libarchive hidapi
  lv2 serd sord sratom lilv libusb readline cppunit libwebsockets gettext itstool yasm nasm)

deps() {
  xcode-select -p >/dev/null 2>&1 || xcode-select --install
  brew install "${FORMULAE[@]}"
}

pkgpath() {
  local p="" f
  for f in glibmm@2.66 libsigc++@2 cairomm@1.14 pangomm@2.46 libxml2 libarchive curl gettext; do
    [ -d "$HB/opt/$f/lib/pkgconfig" ] && p="$HB/opt/$f/lib/pkgconfig:$p"
  done
  echo "$p$HB/lib/pkgconfig:$HB/share/pkgconfig"
}

configure() {
  git describe --tags >/dev/null 2>&1 || { echo "no git tags: run 'git fetch --tags'"; exit 1; }
  local o="" mode="--debug"; [ "$OPT" = 1 ] && { o="-O2"; mode="--optimize"; }
  export PKG_CONFIG_PATH="$(pkgpath)"
  export PATH="$HB/opt/gettext/bin:$PATH"
  CFLAGS="$o -I$HB/include" CXXFLAGS="$o -I$HB/include" LDFLAGS="-L$HB/lib" \
  ./waf configure --cxx17 $mode --arm64 --with-backends=coreaudio,dummy --no-phone-home \
    --also-include="$HB/include" --prefix="$PREFIX" ${ARDOUR_CFG:-}
}
build()   { export PKG_CONFIG_PATH="$(pkgpath)"; ./waf -j"$JOBS"; }
package() {
  ./waf install
  echo "Installed to $PREFIX. A signed/notarized .app + dmg needs tools/osx_packaging and Ardour's own"
  echo "dependency stack (not Homebrew); this script stops at a runnable prefix."
}
clean()   { ./waf distclean || true; rm -rf "$PREFIX"; }

case $ACTION in
  deps) deps;; configure) configure;; build) build;; package) package;; clean) clean;;
  all) deps; configure; build;;
  *) echo "unknown action $ACTION"; exit 2;;
esac
