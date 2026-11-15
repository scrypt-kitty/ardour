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
  local B=build/win-bundle L=build/win-bundle/lib/ardour9
  mkdir -p "$B"; find "$B" -mindepth 1 -delete; cp -a build/win-prefix/. "$B/"; rm -f "$B/bin/ardour9"  # sh launcher is prefix-bound
  # bundle every MSYS2/UCRT64 runtime DLL reachable from our binaries (iterate to closure)
  local n=-1 m
  while :; do
    find "$B" \( -name '*.exe' -o -name '*.dll' \) -print0 | xargs -0 ldd 2>/dev/null       | awk '/=> \/ucrt64\//{print $3}' | sort -u | while read -r d; do
          [ -e "$L/$(basename "$d")" ] || cp "$d" "$L/"; done
    m=$(ls "$L" | wc -l); [ "$m" = "$n" ] && break; n=$m
  done
  # GTK2 runtime data: pixbuf loaders + their cache, themes/engines
  mkdir -p "$B/lib"; cp -a /ucrt64/lib/gdk-pixbuf-2.0 "$B/lib/" 2>/dev/null || true
  cp -a /ucrt64/lib/gtk-2.0 "$B/lib/" 2>/dev/null || true
  mkdir -p "$B/share"; cp -a /ucrt64/share/glib-2.0 "$B/share/" 2>/dev/null || true
  local X; X=$(cd "$L" && ls ardour-[0-9]*.exe | head -1)
  sed "s/ardour-9\.10\.23\.exe/$X/" scripts/win/ardour.cmd > "$B/ardour.cmd"
  echo "Bundle: $B  (run ardour.cmd; $(ls "$L"/*.dll | wc -l) DLLs in lib/ardour9)"
}
clean() { python waf distclean || true; rm -rf build/win-prefix build/win-bundle; }

case $ACTION in
  deps) deps;; configure) configure;; build) build;; package) package;; clean) clean;;
  all) deps; configure; build;;
esac
