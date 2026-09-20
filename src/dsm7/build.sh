#!/bin/sh

echo "[$(date +%Y-%m-%d" "%H:%M:%S)] #### Start BUILD... ####"

rm -r -f dist

set -eu

# Derived from the Makefile itself (every target that sets INFO_ARCH is a
# real architecture build) instead of a second hand-maintained copy of the
# list - a stale copy here is exactly what broke CI when armv6 was removed
# from the Makefile but a separate hardcoded list elsewhere still expected it.
ARCH_LIST=$(awk '/^\.PHONY: /{t=$2} /INFO_ARCH=/{print t}' Makefile)
MAKE=$(which make)

for arch in ${ARCH_LIST}; do
  export ARCH="${arch}"
  $MAKE clean build
done

rm -r -f target

echo
echo "$(date +%Y-%m-%d" "%H:%M:%S)] #### Build complete, you can find the packages under the dist directory"

ls -1 dist/*.spk

echo
echo "To install one on a Synology device from the command line, pick the package"
echo "matching your model (see doc/ARCHITECTURES.md):"
echo "  sudo synopkg install <one of the files above>"
