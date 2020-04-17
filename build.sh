#!/bin/bash

echo
echo "Build Start"

rm -r -f dist

set -euo pipefail

ARCH_LIST="arm aarch64 x86 x86-64"
MAKE=`which make`

for arch in ${ARCH_LIST}; do
  export ARCH=${arch}
  $MAKE clean build
done

rm -r -f target

echo
echo "Build complete, you can find the packages under the dist directory"

echo "how to install new package on synology x86 devices via commandline:"
echo "sudo synopkg install dist/AirConnect-x86-64-XXX.spk"
# sudo synopkg install dist/AirConnect-x86-64-${VERSION}.spk
