#!/bin/bash

echo "#### BUILD start...####"
echo "[$(date +%Y-%m-%d:%H:%M:%S)]"
echo ""

rm -r -f dist

set -euo pipefail

ARCH_LIST="arm arm5 aarch64 x86 x86-64 ppc ppc-static"
REVISION_STATIC_AIRCAST="078c212b609ea36a442206545a45ed565bc78732"
REVISION_STATIC_AIRUPNP="5068a3e0e9ce07db1057c2f63e83911360f21c0d"
MAKE=$(which make)

for arch in ${ARCH_LIST}; do
  export ARCH=${arch}
  export REVISION_STATIC_AIRCAST=${REVISION_STATIC_AIRCAST}
  export REVISION_STATIC_AIRUPNP=${REVISION_STATIC_AIRUPNP}
  $MAKE clean build
done

rm -r -f target

echo
echo "Build complete, you can find the packages under the dist directory"

echo "how to install new package on synology x86 devices via commandline:"
echo "sudo synopkg install dist/AirConnect-x86-64-XXX.spk"
# sudo synopkg install dist/AirConnect-x86-64-${VERSION}.spk
