#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  Scripts/release-tag.sh v0.1.1

High-level local release wrapper. Uses NOTARY_PROFILE=panepilot-notary when
available, otherwise falls back to speakmore-notary unless Apple credentials
are explicitly provided in the environment.
USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

log() {
  printf '\n==> %s\n' "$*"
}

TAG="${1:-}"
if [ -z "$TAG" ] || [ "$TAG" = "-h" ] || [ "$TAG" = "--help" ]; then
  usage
  exit 0
fi
[[ "$TAG" =~ ^v[0-9]+(\.[0-9]+){2}([.-][A-Za-z0-9._-]+)?$ ]] || fail "tag must look like v0.1.1"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ -z "${NOTARY_PROFILE+x}" ] && { [ -z "${APPLE_ID:-}" ] || [ -z "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]; }; then
  if xcrun notarytool history --keychain-profile panepilot-notary >/dev/null 2>&1; then
    export NOTARY_PROFILE="panepilot-notary"
  else
    export NOTARY_PROFILE="speakmore-notary"
  fi
fi

WORKTREE_DIR=""
cleanup() {
  if [ -n "$WORKTREE_DIR" ] && [ -d "$WORKTREE_DIR" ]; then
    git worktree remove "$WORKTREE_DIR" --force >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

release_dir="$ROOT_DIR"

if git rev-parse "$TAG" >/dev/null 2>&1; then
  TAG_SHA="$(git rev-list -n 1 "$TAG")"
  HEAD_SHA="$(git rev-parse HEAD)"
  if [ "$TAG_SHA" != "$HEAD_SHA" ] || [ -n "$(git status --porcelain)" ]; then
    WORKTREE_DIR="$(mktemp -d "/tmp/panepilot-release-$TAG.XXXXXX")"
    rmdir "$WORKTREE_DIR"
    log "Create temporary worktree for $TAG"
    git worktree add --detach "$WORKTREE_DIR" "$TAG"
    release_dir="$WORKTREE_DIR"
  fi
else
  [ -z "$(git status --porcelain)" ] || fail "working tree must be clean to create a new release tag"
fi

log "Run local release for $TAG"
(cd "$release_dir" && Scripts/release-local.sh "$TAG")

log "Verify published release"
"$ROOT_DIR/Scripts/verify-release.sh" "$TAG"
