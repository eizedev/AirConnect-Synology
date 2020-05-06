#!/bin/bash

echo "#### BUILD start...####"
echo "[$(date +%Y-%m-%d:%H:%M:%S)]"
echo ""

rm -r -f dist

set -euo pipefail

ARCH_LIST="arm arm5 aarch64 x86 x86-64 ppc static"
ARCH_STATIC_AIRCAST="aircast-bsd-x64-static"
ARCH_STATIC_AIRUPNP="airupnp-x86-64-static"
MAKE=$(which make)

for arch in ${ARCH_LIST}; do
  export ARCH=${arch}
  export ARCH_STATIC_AIRCAST=${ARCH_STATIC_AIRCAST}
  export ARCH_STATIC_AIRUPNP=${ARCH_STATIC_AIRUPNP}
  $MAKE clean build
done

rm -r -f target

echo
echo "Build complete, you can find the packages under the dist directory"

echo "how to install new package on synology x86 devices via commandline:"
echo "sudo synopkg install dist/AirConnect-x86-64-XXX.spk"
# sudo synopkg install dist/AirConnect-x86-64-${VERSION}.spk
