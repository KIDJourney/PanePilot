.PHONY: build test app package validate-docs clean

build:
	swift build

test:
	swift test

app:
	Scripts/build-app.sh

package:
	Scripts/package-app.sh

validate-docs:
	scripts/validate-docs.sh

clean:
	rm -rf .build dist
