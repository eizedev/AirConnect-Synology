#!/bin/bash

echo "[$(date +%Y-%m-%d" "%H:%M:%S)] #### Start BUILD... ####"

rm -r -f dist

set -euo pipefail

ARCH_LIST="arm arm5 aarch64 x86 x86-64 ppc ppc-static"
MAKE=$(which make)

for arch in ${ARCH_LIST}; do
  export ARCH=${arch}
  export REVISION_STATIC_AIRCAST=${REVISION_STATIC_AIRCAST}
  export REVISION_STATIC_AIRUPNP=${REVISION_STATIC_AIRUPNP}
  $MAKE clean build
done

rm -r -f target

echo
echo "$(date +%Y-%m-%d" "%H:%M:%S)] #### Build complete, you can find the packages under the dist directory"

echo "how to install new package on synology x86 devices via commandline:"
echo "sudo synopkg install dist/AirConnect-x86-64-XXX.spk"
# sudo synopkg install dist/AirConnect-x86-64-${VERSION}.spk
