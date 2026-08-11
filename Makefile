.PHONY: build test app package release release-tag verify-release launch-release validate-docs clean

build:
	swift build

test:
	swift test

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
