#!/bin/bash

echo "[$(date +%Y-%m-%d" "%H:%M:%S)] #### Start BUILD... ####"

rm -r -f dist

set -eu

ARCH_LIST="arm arm-static arm5 aarch64 aarch64-static x86 x86-64 ppc ppc-static"
MAKE=$(which make)

for arch in ${ARCH_LIST}; do
  export ARCH=${arch}
  $MAKE clean build
done

rm -r -f target

echo
echo "$(date +%Y-%m-%d" "%H:%M:%S)] #### Build complete, you can find the packages under the dist directory"

echo "how to install new package on synology x86 devices via commandline:"
echo "sudo synopkg install dist/AirConnect-dsm7-x86-64-XXX.spk"
# sudo synopkg install dist/AirConnect-x86-64-${VERSION}.spk
