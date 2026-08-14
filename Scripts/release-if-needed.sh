#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [ "${PANEPILOT_SKIP_AUTO_RELEASE:-0}" = "1" ]; then
  exit 0
fi

BRANCH="$(git symbolic-ref --quiet --short HEAD || true)"
if [ "$BRANCH" != "main" ]; then
  echo "PanePilot auto release skipped: current branch is ${BRANCH:-detached}, not main."
  exit 0
fi

RELEASE_PATHS=(Package.swift Makefile Sources Resources Scripts Tests .githooks)
PREVIOUS_TAG="$(git describe --tags --abbrev=0 --match 'v[0-9]*' HEAD^ 2>/dev/null || true)"
if [ -n "$PREVIOUS_TAG" ]; then
  RANGE="$PREVIOUS_TAG..HEAD"
else
  RANGE="HEAD"
fi

if [ -z "$(git diff-tree --no-commit-id --name-only -r "$RANGE" -- "${RELEASE_PATHS[@]}")" ]; then
  echo "PanePilot auto release skipped: commit contains documentation-only changes."
  exit 0
fi

HEAD_TAG="$(git tag --points-at HEAD --list 'v[0-9]*' | sort -V | tail -1)"
if [ -n "$HEAD_TAG" ] && gh release view "$HEAD_TAG" --repo KIDJourney/PanePilot >/dev/null 2>&1; then
  echo "PanePilot auto release satisfied: $HEAD_TAG already publishes HEAD."
  exit 0
fi

LATEST_TAG="$(git describe --tags --abbrev=0 --match 'v[0-9]*' HEAD^ 2>/dev/null || echo v0.0.0)"
VERSION="${LATEST_TAG#v}"
IFS=. read -r MAJOR MINOR PATCH <<< "$VERSION"
[[ "$MAJOR" =~ ^[0-9]+$ && "$MINOR" =~ ^[0-9]+$ && "$PATCH" =~ ^[0-9]+$ ]] || {
  echo "error: latest release tag is not a stable semantic version: $LATEST_TAG" >&2
  exit 1
}
NEXT_TAG="v$MAJOR.$MINOR.$((PATCH + 1))"

if [ "${PANEPILOT_AUTO_RELEASE_DRY_RUN:-0}" = "1" ]; then
  echo "PanePilot auto release dry run: HEAD requires $NEXT_TAG."
  exit 0
fi

echo "PanePilot code change requires a formal release. Publishing $NEXT_TAG locally."
PANEPILOT_RELEASE_IN_PROGRESS=1 make release-tag TAG="$NEXT_TAG"
PANEPILOT_RELEASE_IN_PROGRESS=1 make launch-release TAG="$NEXT_TAG"
echo "PanePilot auto release complete: $NEXT_TAG"
