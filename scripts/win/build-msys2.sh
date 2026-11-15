#!/bin/bash
# Native Windows build of Ardour in an MSYS2 UCRT64 shell (unofficial path; upstream
# cross-compiles from Linux). Usage: build-msys2.sh [all|deps|configure|build|package|clean]
set -euo pipefail
cd "$(dirname "$0")/../.."
test -f gtk2_ardour/wscript || { echo "run from an Ardour checkout"; exit 1; }
[ "${MSYSTEM:-}" = UCRT64 ] || { echo "open a UCRT64 shell"; exit 1; }
ACTION=${1:-all}; JOBS=${ARDOUR_JOBS:-$(nproc)}; OPT=${ARDOUR_OPTIMIZE:-0}
P=mingw-w64-ucrt-x86_64

PKGS=(base-devel git patch gettext-devel
  $P-toolchain $P-python $P-pkgconf $P-yasm $P-nasm
  $P-boost $P-glib2 $P-libsigc++ $P-glibmm $P-cairo $P-cairomm $P-pango $P-pangomm $P-atk $P-gdk-pixbuf2
  $P-libsndfile $P-libsamplerate $P-libxml2 $P-libxslt $P-curl $P-liblo $P-aubio
  $P-fftw $P-taglib $P-rubberband $P-libarchive $P-hidapi $P-libusb
  $P-lv2 $P-serd $P-sord $P-sratom $P-lilv $P-portaudio $P-flac $P-libogg
  $P-libvorbis $P-opus $P-readline $P-cppunit $P-dlfcn $P-libwebsockets $P-nsis $P-drmingw)

deps() { pacman -Sy --noconfirm && pacman -S --noconfirm --needed "${PKGS[@]}"; }

configure() {
  local o="-Og"; [ "$OPT" = 1 ] && o="-O2"
  export CC="$(cygpath -m "$(command -v gcc)")" CXX="$(cygpath -m "$(command -v g++)")"
  CFLAGS="-mstackrealign $o" CXXFLAGS="-mstackrealign $o" \
  python waf configure --dist-target=mingw --keepflags \
    --with-backends=dummy,portaudio --no-dr-mingw --no-phone-home \
    --cxx17 --windows-key=Super --check-c-compiler=gcc --check-cxx-compiler=g++ \
    --prefix="$PWD/build/win-prefix" ${ARDOUR_CFG:-}
}
build() { python waf -j"$JOBS"; }
package() {
  python waf install
  mkdir -p build/win-bundle && cp -a build/win-prefix/. build/win-bundle/
  echo "Staged in build/win-bundle (add MinGW runtime DLLs: ldd the ardour exe)."
}
clean() { python waf distclean || true; rm -rf build/win-prefix build/win-bundle; }

case $ACTION in
  deps) deps;; configure) configure;; build) build;; package) package;; clean) clean;;
  all) deps; configure; build;;
esac
