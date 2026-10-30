#!/usr/bin/env bash
# Pre-release gate. Run locally before tagging, and again by release.yml. Reports every problem, then fails.
# Usage: release-check.sh   (set RELEASE_TAG=v1.2.3 to also check that the tag matches the version)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failed=0
problem() { printf 'release-check: %s\n' "$1" >&2; failed=1; }

if ! command -v node >/dev/null 2>&1; then
  printf 'release-check: node is required\n' >&2
  exit 3
fi

version="$(node -p "require('./package.json').version")"
printf 'Checking release %s\n' "$version"

if [[ -n "${RELEASE_TAG:-}" && "$RELEASE_TAG" != "v$version" ]]; then
  problem "tag $RELEASE_TAG does not match package.json version $version"
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [[ -n "$(git status --porcelain)" ]]; then
    problem "working tree has uncommitted changes"
  fi
else
  problem "not a git repository"
fi

if ! grep -q "^## \[$version\]" CHANGELOG.md 2>/dev/null; then
  problem "CHANGELOG.md has no section for $version"
fi

# --release turns leftover <placeholder> values into errors.
if ! bash scripts/validate-data.sh --release; then
  problem "profile data failed validation (see above)"
fi

# Needs network. An offline run can report a false "not published" result.
if npm view "labbai-irfan@$version" version >/dev/null 2>&1; then
  problem "labbai-irfan@$version is already published; bump the version"
fi

if (( failed )); then
  printf 'release-check: FAILED\n' >&2
  exit 1
fi
printf 'release-check: OK\n'
