.PHONY: build check app run doctor
build:
	swift build --build-system native
check:
	swift run --build-system native TranscodePilotChecks
app:
	./scripts/build-app
run: app
	open .build/TranscodePilot.app
doctor:
	./scripts/doctor
