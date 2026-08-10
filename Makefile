.PHONY: build test app clean

build:
	swift build

test:
	swift test

app:
	Scripts/build-app.sh

clean:
	rm -rf .build dist
