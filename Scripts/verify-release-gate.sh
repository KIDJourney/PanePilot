#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

REMOTE_SHA="${1:-}"
LOCAL_SHA="${2:-HEAD}"
ZERO_SHA="0000000000000000000000000000000000000000"
RELEASE_PATHS=(Package.swift Makefile Sources Resources Scripts Tests .githooks)

if [ -z "$REMOTE_SHA" ] || [ "$REMOTE_SHA" = "$ZERO_SHA" ]; then
  RANGE="$LOCAL_SHA"
else
  RANGE="$REMOTE_SHA..$LOCAL_SHA"
fi

RELEASE_COMMIT="$(git log -1 --format=%H "$RANGE" -- "${RELEASE_PATHS[@]}" || true)"
if [ -z "$RELEASE_COMMIT" ]; then
  echo "PanePilot release gate passed: outgoing main changes are documentation-only."
  exit 0
fi

TAG="$(git tag --points-at "$RELEASE_COMMIT" --list 'v[0-9]*' | sort -V | tail -1)"
if [ -z "$TAG" ]; then
  echo "error: code commit $RELEASE_COMMIT has no release tag; run make release-next before pushing main" >&2
  exit 1
fi

REMOTE_TAG_SHA="$(git ls-remote origin "refs/tags/$TAG" | awk '{print $1}')"
if [ "$REMOTE_TAG_SHA" != "$RELEASE_COMMIT" ]; then
  echo "error: remote tag $TAG does not point to code commit $RELEASE_COMMIT" >&2
  exit 1
fi

DMG_NAME="PanePilot-$TAG.dmg"
CHECKSUM_NAME="$DMG_NAME.sha256"
RELEASE_READY="$(gh release view "$TAG" \
  --repo KIDJourney/PanePilot \
  --json isDraft,assets \
  --jq ".isDraft == false and ([.assets[].name] | index(\"$DMG_NAME\") != null) and ([.assets[].name] | index(\"$CHECKSUM_NAME\") != null)" \
  2>/dev/null || true)"
if [ "$RELEASE_READY" != "true" ]; then
  echo "error: GitHub Release $TAG is missing the published DMG or checksum" >&2
  exit 1
fi

echo "PanePilot release gate passed: $TAG publishes code commit $RELEASE_COMMIT."
