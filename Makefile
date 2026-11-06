SWIFT ?= swift
SWIFT_FLAGS ?=

.PHONY: build check app run doctor clean
build:
	$(SWIFT) build $(SWIFT_FLAGS)
check:
	$(SWIFT) run $(SWIFT_FLAGS) TranscodePilotChecks
app:
	SWIFT="$(SWIFT)" SWIFT_FLAGS="$(SWIFT_FLAGS)" ./scripts/build-app
run: app
	open .build/TranscodePilot.app
doctor:
	./scripts/doctor
clean:
	rm -rf .build
