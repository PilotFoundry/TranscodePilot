SWIFT ?= swift
SWIFT_FLAGS ?=

.PHONY: build check app run release package verify doctor icon clean
build:
	$(SWIFT) build $(SWIFT_FLAGS)
check:
	$(SWIFT) run $(SWIFT_FLAGS) TranscodePilotChecks
app:
	SWIFT="$(SWIFT)" SWIFT_FLAGS="$(SWIFT_FLAGS)" ./scripts/build-app
run: app
	open .build/TranscodePilot.app
release:
	SWIFT="$(SWIFT)" SWIFT_FLAGS="$(SWIFT_FLAGS)" BUILD_CONFIG=release ./scripts/build-app
package: release
	./scripts/package-release
verify:
	./scripts/verify-release .build/TranscodePilot.app
doctor:
	./scripts/doctor
icon:
	./scripts/build-icon
clean:
	rm -rf .build
