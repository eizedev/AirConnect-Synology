# Syno package structure: https://help.synology.com/developer-guide/synology_package/package_structure.html

# Pinned upstream release. The tag is what the files are fetched from; the
# version is what upstream's own CHANGELOG lists its entries under, and what
# upstream-check.yml builds the release tag from. They are the same string
# today, but upstream is free to publish a tag that is not its version.
UPSTREAM_TAG=$(shell sed -n 's/.*"tag"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' ../../upstream.json)
UPSTREAM_VERSION=$(shell sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' ../../upstream.json)

# The package version is the upstream version plus the build date, read from
# the same upstream.json field that upstream-check.yml uses for the release
# tag, so a release cannot carry a git tag and a package version that
# disagree. RELEASE_VERSION overrides it for a local build of something that
# is not pinned here.
PKG_VERSION=$(or ${RELEASE_VERSION},${UPSTREAM_VERSION})
VERSION=${PKG_VERSION}-$(shell date '+%Y%m%d')

# Derived from INFO rather than repeated here: distributor_url is this
# packaging repo, maintainer_url is upstream. blob/HEAD resolves to each
# repo's default branch, so no branch name is baked in either.
PKG_REPO_URL=$(shell sed -n 's/^distributor_url="\(.*\)"$$/\1/p' INFO)
UPSTREAM_REPO_URL=$(shell sed -n 's/^maintainer_url="\(.*\)"$$/\1/p' INFO)
PKG_NAME=$(notdir ${PKG_REPO_URL})
PKG_ID=$(shell sed -n 's/^package="\(.*\)"$$/\1/p' INFO)
UPSTREAM_NAME=$(notdir ${UPSTREAM_REPO_URL})

LICENSE:
	curl -s -L ${UPSTREAM_REPO_URL}/raw/$(or ${UPSTREAM_TAG},HEAD)/LICENSE -O

target:
	mkdir -p target

dist:
	mkdir -p dist

target/package.tgz: target
	$(if ${PKG_VERSION},$(info ${UPSTREAM_NAME} Version: ${PKG_VERSION}),$(error No upstream version - is ../../upstream.json readable? Set RELEASE_VERSION to override))
	$(if ${ARCH},$(info Arch: ${ARCH}),$(error Must specify ARCH))
	cp bin/airupnp-linux-${ARCH} target/airupnp
	chmod +x target/airupnp
	cp bin/aircast-linux-${ARCH} target/aircast
	chmod +x target/aircast
	cp -a log target/log
	cd target && tar czf package.tgz airupnp aircast log/
	rm -r target/airupnp target/aircast target/log

target/scripts: target
	cp -a scripts target

target/WIZARD_UIFILES: target
	cp -a WIZARD_UIFILES target

target/conf: target
	cp -a conf target

target/LICENSE: target
	curl -s -L ${UPSTREAM_REPO_URL}/raw/${UPSTREAM_TAG}/LICENSE -o target/LICENSE

# From the pinned upstream tag rather than master, so the bundled CHANGELOG
# (and the "What's New" text built from it below) matches the binaries.
target/CHANGELOG: target
	curl -s -L ${UPSTREAM_REPO_URL}/raw/${UPSTREAM_TAG}/CHANGELOG -o target/CHANGELOG

target/PACKAGE_ICON.PNG: target
	cp PACKAGE_ICON.PNG target/PACKAGE_ICON.PNG
	cp PACKAGE_ICON_256.PNG target/PACKAGE_ICON_256.PNG

target/INFO: target target/CHANGELOG
	$(if ${INFO_ARCH},$(info INFO_ARCH: ${INFO_ARCH}),$(error Must specify INFO_ARCH))
	$(if ${INFO_FIRMWARE},$(info INFO_FIRMWARE: ${INFO_FIRMWARE}),$(error Must specify INFO_FIRMWARE))
	cp INFO target/INFO
	sed -i.bak -e 's/#VERSION#/${VERSION}/' target/INFO
	sed -i.bak -e 's/#INFO_ARCH#/${INFO_ARCH}/' target/INFO
	sed -i.bak -e 's/#INFO_FIRMWARE#/${INFO_FIRMWARE}/' target/INFO
	rm target/INFO.bak
	$(if ${PKG_REPO_URL},,$(error INFO has no distributor_url))
	$(if ${UPSTREAM_REPO_URL},,$(error INFO has no maintainer_url))
	printf 'changelog="%s"\n' "$$(./info_changelog.sh \
		${PKG_NAME} ../../CHANGELOG.md ${PKG_REPO_URL}/blob/HEAD/CHANGELOG.md \
		${UPSTREAM_NAME} target/CHANGELOG ${UPSTREAM_REPO_URL}/blob/HEAD/CHANGELOG \
		${PKG_VERSION})" >> target/INFO

dist/${PKG_ID}-dsm7-${ARCH}-${VERSION}.spk: target/package.tgz target/scripts target/WIZARD_UIFILES target/conf target/LICENSE target/CHANGELOG target/INFO target/PACKAGE_ICON.PNG dist
	$(if ${ARCH},$(info dist - Arch: ${ARCH}),$(error dist - Must specify ARCH))
	cd target && tar -cf ${PKG_ID}-dsm7-${ARCH}-${VERSION}.spk *
	mv target/${PKG_ID}-dsm7-${ARCH}-${VERSION}.spk dist/

.PHONY: arm
arm:
	$(eval export INFO_ARCH=ipq806x armada370 armadaxp armada375 armada38x alpine alpine4k monaco comcerto2k hi3535 dakota northstarplus hawkeye)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: arm-static
arm-static:
	$(eval export INFO_ARCH=ipq806x armada370 armadaxp armada375 armada38x alpine alpine4k monaco comcerto2k hi3535 dakota northstarplus hawkeye noarch)
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

.PHONY: aarch64
aarch64:
	$(eval export INFO_ARCH=rtd1296 rtd1619b armada37xx cypress)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: aarch64-static
aarch64-static:
	$(eval export INFO_ARCH=rtd1296 rtd1619b armada37xx cypress noarch)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: powerpc
powerpc:
	$(eval export INFO_ARCH=qoriq ppc853x)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: powerpc-static
powerpc-static:
	$(eval export INFO_ARCH=qoriq ppc853x noarch)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: x86
x86:
	$(eval export INFO_ARCH=x86 cedarview bromolow evansport braswell broadwell dockerx64 kvmx64 denverton grantley broadwellnk broadwellntbap)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: x86-static
x86-static:
	$(eval export INFO_ARCH=x86 cedarview bromolow evansport braswell broadwell dockerx64 kvmx64 denverton grantley broadwellnk broadwellntbap)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: x86_64
x86_64:
	$(eval export INFO_ARCH=x86_64 x64 cedarview bromolow avoton braswell broadwell apollolake dockerx64 epyc7002 r1000 r1000nk kvmx64 denverton grantley broadwellnk broadwellnkv2 broadwellntbap v1000 v1000nk geminilake geminilakenk purley)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: x86_64-static
x86_64-static:
	$(eval export INFO_ARCH=x86_64 x64 cedarview bromolow avoton braswell broadwell apollolake dockerx64 epyc7002 r1000 r1000nk kvmx64 denverton grantley broadwellnk broadwellnkv2 broadwellntbap v1000 v1000nk geminilake geminilakenk purley)
	$(eval export INFO_FIRMWARE=7.0-40000)
	@true

.PHONY: build
build: ${ARCH} dist/${PKG_ID}-dsm7-${ARCH}-${VERSION}.spk

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
	shellcheck -s sh scripts/* build.sh info_changelog.sh WIZARD_UIFILES/*
