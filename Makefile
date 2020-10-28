# Syno package structure: https://help.synology.com/developer-guide/synology_package/package_structure.html
# Git commit SHA from https://github.com/philippe44/AirConnect/commits/master/bin
REPO_REVISION=a5620b56f3dca43f326cdcfbf58f7accfcd8c0c3
#REPO_REVISION2=ba623f7f8b93a060c3af54d35fee9b28eeddb1fe
VERSION=0.2.28.3-$(shell date '+%Y%m%d')

LICENSE:
	curl -s -L https://github.com/philippe44/AirConnect/raw/${REPO_REVISION}/LICENSE -O

target:
	mkdir -p target

dist:
	mkdir -p dist

target/package.tgz: target
	$(if ${ARCH},$(info Arch: ${ARCH}),$(error Must specify ARCH))
	curl -s -L https://github.com/philippe44/AirConnect/raw/${REPO_REVISION}/bin/airupnp-${ARCH} -o target/airupnp
	chmod +x target/airupnp
	curl -s -L https://github.com/philippe44/AirConnect/raw/${REPO_REVISION}/bin/aircast-${ARCH} -o target/aircast
	chmod +x target/aircast
	cd target && tar czf package.tgz airupnp aircast
	rm target/airupnp target/aircast

target/scripts: target
	cp -a scripts target

target/LICENSE: target
	curl -s -L https://github.com/philippe44/AirConnect/raw/${REPO_REVISION}/LICENSE -o target/LICENSE

target/PACKAGE_ICON.PNG: target
	cp PACKAGE_ICON.PNG target/PACKAGE_ICON.PNG

target/INFO: target
	$(if ${INFO_ARCH},$(info INFO_ARCH: ${INFO_ARCH}),$(error Must specify INFO_ARCH))
	$(if ${INFO_FIRMWARE},$(info INFO_FIRMWARE: ${INFO_FIRMWARE}),$(error Must specify INFO_FIRMWARE))
	cp INFO target/INFO
	sed -i.bak -e 's/#VERSION#/${VERSION}/' target/INFO
	sed -i.bak -e 's/#INFO_ARCH#/${INFO_ARCH}/' target/INFO
	sed -i.bak -e 's/#INFO_FIRMWARE#/${INFO_FIRMWARE}/' target/INFO
	rm target/INFO.bak

dist/AirConnect-${ARCH}-${VERSION}.spk: target/package.tgz target/scripts target/LICENSE target/INFO target/PACKAGE_ICON.PNG dist
	$(if ${ARCH},$(info dist - Arch: ${ARCH}),$(error dist - Must specify ARCH))
	cd target && tar -czf AirConnect-${ARCH}-${VERSION}.spk *
	mv target/AirConnect-${ARCH}-${VERSION}.spk dist/

.PHONY: arm
arm:
	$(eval export INFO_ARCH=ipq806x armada370 armadaxp armada375 armada38x alpine alpine4k monaco comcerto2k hi3535 dakota ipq806x northstarplus)
	$(eval export INFO_FIRMWARE=5.0-4458)
	@true

.PHONY: arm-static
arm-static:
	$(eval export INFO_ARCH=ipq806x armada370 armadaxp armada375 armada38x alpine alpine4k monaco comcerto2k hi3535 dakota ipq806x northstarplus noarch)
	$(eval export INFO_FIRMWARE=5.0-4458)
	@true

.PHONY: arm5
arm5:
	$(eval export INFO_ARCH=88f6282 88f6281 88f628x)
	$(eval export INFO_FIRMWARE=5.0-4458)
	@true

.PHONY: aarch64
aarch64:
	$(eval export INFO_ARCH=rtd1296 armada37xx)
	$(eval export INFO_FIRMWARE=5.0-4458)
	@true

.PHONY: aarch64-static
aarch64-static:
	$(eval export INFO_ARCH=rtd1296 armada37xx noarch)
	$(eval export INFO_FIRMWARE=5.0-4458)
	@true

.PHONY: ppc
ppc:
	$(eval export INFO_ARCH=qoriq Ppc853x)
	$(eval export INFO_FIRMWARE=5.0-4458)
	@true

.PHONY: ppc-static
ppc-static:
	$(eval export INFO_ARCH=qoriq Ppc853x noarch)
	$(eval export INFO_FIRMWARE=5.0-4458)
	@true

.PHONY: x86
x86:
	$(eval export INFO_ARCH=x86 cedarview bromolow evansport avoton braswell broadwell apollolake dockerx64 kvmx64 denverton grantley broadwellnk Broadwellntbap)
	$(eval export INFO_FIRMWARE=5.0-4458)
	@true

.PHONY: x86-64
x86-64:
	$(eval export INFO_ARCH=x86_64 x64 cedarview bromolow avoton braswell broadwell apollolake dockerx64 kvmx64 denverton grantley broadwellnk Broadwellntbap)
	$(eval export INFO_FIRMWARE=6.0-7321)
	@true

.PHONY: build
build: ${ARCH} dist/AirConnect-${ARCH}-${VERSION}.spk

.PHONY: clean
clean:
	rm -rf target

.PHONY: clean-dist
clean-dist:
	rm -rf dist

.PHONY: build-all
build-all: clean-dist
	./build.sh

.PHONY: shellcheck
shellcheck:
	shellcheck -s sh scripts/*
