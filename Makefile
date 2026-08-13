.PHONY: build test verify-hotkey-dispatch verify-shortcut-recording verify-window-move verify-login-item verify-update-helper app package release release-tag verify-release launch-release validate-docs clean

build:
	swift build

test:
	swift test

verify-hotkey-dispatch:
	Scripts/verify-window-automation.sh dispatch

verify-shortcut-recording:
	Scripts/verify-window-automation.sh recording

verify-window-move:
	Scripts/verify-window-automation.sh move

verify-login-item:
	Scripts/verify-login-item.sh

verify-update-helper:
	Scripts/verify-update-helper.sh

app:
	Scripts/build-app.sh

package:
	Scripts/package-app.sh

release:
	@test -n "$(TAG)" || (echo "usage: make release TAG=v0.1.1" >&2; exit 1)
	@Scripts/release-local.sh "$(TAG)"

release-tag:
	@test -n "$(TAG)" || (echo "usage: make release-tag TAG=v0.1.1" >&2; exit 1)
	@Scripts/release-tag.sh "$(TAG)"

verify-release:
	@test -n "$(TAG)" || (echo "usage: make verify-release TAG=v0.1.1" >&2; exit 1)
	@Scripts/verify-release.sh "$(TAG)"

launch-release:
	@test -n "$(TAG)" || (echo "usage: make launch-release TAG=v0.1.1" >&2; exit 1)
	@Scripts/launch-release-app.sh "$(TAG)"

validate-docs:
	scripts/validate-docs.sh

clean:
	rm -rf .build dist
