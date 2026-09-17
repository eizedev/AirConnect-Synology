#!/bin/bash

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

echo "how to install new package on synology x86 devices via commandline:"
echo "sudo synopkg install dist/AirConnect-dsm7-x86-64-XXX.spk"
# sudo synopkg install dist/AirConnect-x86-64-${VERSION}.spk
