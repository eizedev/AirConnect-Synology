# Syno package structure: https://help.synology.com/developer-guide/synology_package/package_structure.html
VERSION=${RELEASE_VERSION}-$(shell date '+%Y%m%d')

LICENSE:
	curl -s -L https://github.com/philippe44/AirConnect/raw/master/LICENSE -O

target:
	mkdir -p target

dist:
	mkdir -p dist

target/package.tgz: target
	$(if ${RELEASE_VERSION},$(info AirConnect Version: ${RELEASE_VERSION}),$(error Must specify RELEASE_VERSION))
	$(if ${ARCH},$(info Arch: ${ARCH}),$(error Must specify ARCH))
	cp bin/airupnp-linux-${ARCH} target/airupnp
	chmod +x target/airupnp
	cp bin/aircast-linux-${ARCH} target/aircast
	chmod +x target/aircast
	cp -a etc target/etc
	cp -a log target/log
	cd target && tar czf package.tgz airupnp aircast etc/ log/
	rm -r target/airupnp target/aircast target/etc target/log

target/scripts: target
	cp -a scripts target

target/WIZARD_UIFILES: target
	cp -a WIZARD_UIFILES target

target/conf: target
	cp -a conf target

target/LICENSE: target
	curl -s -L https://github.com/philippe44/AirConnect/raw/master/LICENSE -o target/LICENSE

target/CHANGELOG: target
	curl -s -L https://github.com/philippe44/AirConnect/raw/master/CHANGELOG -o target/CHANGELOG

target/PACKAGE_ICON.PNG: target
	cp PACKAGE_ICON.PNG target/PACKAGE_ICON.PNG
	cp PACKAGE_ICON_256.PNG target/PACKAGE_ICON_256.PNG

target/INFO: target
	$(if ${INFO_ARCH},$(info INFO_ARCH: ${INFO_ARCH}),$(error Must specify INFO_ARCH))
	$(if ${INFO_FIRMWARE},$(info INFO_FIRMWARE: ${INFO_FIRMWARE}),$(error Must specify INFO_FIRMWARE))
	cp INFO target/INFO
	sed -i.bak -e 's/#VERSION#/${VERSION}/' target/INFO
	sed -i.bak -e 's/#INFO_ARCH#/${INFO_ARCH}/' target/INFO
	sed -i.bak -e 's/#INFO_FIRMWARE#/${INFO_FIRMWARE}/' target/INFO
	rm target/INFO.bak

dist/AirConnect-dsm7-${ARCH}-${VERSION}.spk: target/package.tgz target/scripts target/WIZARD_UIFILES target/conf target/LICENSE target/CHANGELOG target/INFO target/PACKAGE_ICON.PNG dist
	$(if ${ARCH},$(info dist - Arch: ${ARCH}),$(error dist - Must specify ARCH))
	cd target && tar -cf AirConnect-dsm7-${ARCH}-${VERSION}.spk *
	mv target/AirConnect-dsm7-${ARCH}-${VERSION}.spk dist/

.PHONY: arm
arm:
	$(eval export INFO_ARCH=ipq806x armada370 armadaxp armada375 armada38x alpine alpine4k monaco comcerto2k hi3535 dakota ipq806x northstarplus)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: arm-static
arm-static:
	$(eval export INFO_ARCH=ipq806x armada370 armadaxp armada375 armada38x alpine alpine4k monaco comcerto2k hi3535 dakota ipq806x northstarplus noarch)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: armv5
armv5:
	$(eval export INFO_ARCH=88f6282 88f6281 88f628x)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: armv5-static
armv5-static:
	$(eval export INFO_ARCH=88f6282 88f6281 88f628x)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: armv6
armv6:
	$(eval export INFO_ARCH=88f6282 88f6281 88f628x)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: armv6-static
armv6-static:
	$(eval export INFO_ARCH=88f6282 88f6281 88f628x)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: aarch64
aarch64:
	$(eval export INFO_ARCH=rtd1296 rtd1619b armada37xx)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: aarch64-static
aarch64-static:
	$(eval export INFO_ARCH=rtd1296 rtd1619b armada37xx noarch)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: powerpc
powerpc:
	$(eval export INFO_ARCH=qoriq Ppc853x)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: powerpc-static
powerpc-static:
	$(eval export INFO_ARCH=qoriq Ppc853x noarch)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: x86
x86:
	$(eval export INFO_ARCH=x86 cedarview bromolow evansport braswell broadwell dockerx64 kvmx64 denverton grantley broadwellnk Broadwellntbap)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: x86-static
x86-static:
	$(eval export INFO_ARCH=x86 cedarview bromolow evansport braswell broadwell dockerx64 kvmx64 denverton grantley broadwellnk Broadwellntbap)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: x86_64
x86_64:
	$(eval export INFO_ARCH=x86_64 x64 cedarview bromolow avoton braswell broadwell apollolake dockerx64 epyc7002 r1000 kvmx64 denverton grantley broadwellnk broadwellnkv2 Broadwellntbap v1000 geminilake purley)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: x86_64-static
x86_64-static:
	$(eval export INFO_ARCH=x86_64 x64 cedarview bromolow avoton braswell broadwell apollolake dockerx64 epyc7002 r1000 kvmx64 denverton grantley broadwellnk broadwellnkv2 Broadwellntbap v1000 geminilake purley)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: build
build: ${ARCH} dist/AirConnect-dsm7-${ARCH}-${VERSION}.spk

.PHONY: clean
clean:
	rm -rf target

.PHONY: clean-dist
clean-dist:
	rm -rf dist

.PHONY: clean-bin
clean-bin:
	rm -rf bin

.PHONY: build-all
build-all: clean-dist
	./build.sh

.PHONY: shellcheck
shellcheck:
	shellcheck -s sh scripts/* build.sh WIZARD_UIFILES/*
