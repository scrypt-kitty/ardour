#!/bin/bash
# Native Ubuntu/Debian build of Ardour from this checkout (tested target: Ubuntu 24.04).
# Usage: scripts/linux/build-ubuntu.sh [all|deps|configure|build|package|clean]
#   env: ARDOUR_JOBS=N  ARDOUR_OPTIMIZE=1  ARDOUR_BACKENDS=jack,alsa,pulseaudio,dummy  ARDOUR_CFG="extra waf args"
set -euo pipefail
cd "$(dirname "$0")/../.."
test -f gtk2_ardour/wscript || { echo "run from an Ardour checkout"; exit 1; }
ACTION=${1:-all}; JOBS=${ARDOUR_JOBS:-$(nproc)}; OPT=${ARDOUR_OPTIMIZE:-0}
BACKENDS=${ARDOUR_BACKENDS:-jack,alsa,pulseaudio,dummy}
PREFIX=${ARDOUR_PREFIX:-$PWD/build/linux-prefix}

PKGS=(build-essential git python3 pkg-config gettext itstool yasm
  libboost-dev libglib2.0-dev libglibmm-2.4-dev libsigc++-2.0-dev libcairo2-dev libcairomm-1.0-dev
  libpango1.0-dev libpangomm-1.4-dev libatk1.0-dev libgdk-pixbuf-2.0-dev
  libasound2-dev libjack-jackd2-dev libpulse-dev libsndfile1-dev libsamplerate0-dev
  libxml2-dev libxslt1-dev libcurl4-openssl-dev libarchive-dev liblo-dev libtag1-dev
  libaubio-dev librubberband-dev libfftw3-dev libusb-1.0-0-dev libudev-dev libreadline-dev
  libserd-dev libsord-dev libsratom-dev liblilv-dev lv2-dev liblrdf0-dev vamp-plugin-sdk
  libwebsockets-dev libfontconfig1-dev libx11-dev libxext-dev libxinerama-dev libxi-dev libxrandr-dev libxcursor-dev
  libcppunit-dev libgnutls28-dev libdbus-1-dev)

deps() {
  local sudo=""; [ "$(id -u)" = 0 ] || sudo=sudo
  local apt="apt-get -o DPkg::Lock::Timeout=900"
  $sudo $apt update
  $sudo env DEBIAN_FRONTEND=noninteractive $apt install -y --no-install-recommends "${PKGS[@]}"
}

configure() {
  local o="" mode="--debug"; [ "$OPT" = 1 ] && { o="-O2"; mode="--optimize"; }
  git describe --tags >/dev/null 2>&1 || { echo "no git tags: run 'git fetch --tags' (Ardour derives its version from git describe)"; exit 1; }
  CFLAGS="$o" CXXFLAGS="$o" python3 waf configure --cxx17 $mode --with-backends="$BACKENDS" \
    --no-phone-home --freedesktop --prefix="$PREFIX" ${ARDOUR_CFG:-}
}
build()   { python3 waf -j"$JOBS"; }
package() { python3 waf install; echo "Installed to $PREFIX; run $PREFIX/bin/ardour9"; }
clean()   { python3 waf distclean || true; rm -rf "$PREFIX"; }

case $ACTION in
  deps) deps;; configure) configure;; build) build;; package) package;; clean) clean;;
  all) deps; configure; build;;
  *) echo "unknown action $ACTION"; exit 2;;
esac
