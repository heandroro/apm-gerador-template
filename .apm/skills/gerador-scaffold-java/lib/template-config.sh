#!/bin/bash
# Template configuration — centralized source of truth for template repository details
# Source this file in other scripts to avoid hardcoding template owner/repo/branch

# Template Repository Configuration
# These values can be overridden via environment variables
export TEMPLATE_OWNER="${TEMPLATE_OWNER:-heandroro}"
export TEMPLATE_REPO="${TEMPLATE_REPO:-java-hexagonal-template}"
export TEMPLATE_BRANCH="${TEMPLATE_BRANCH:-main}"

# Template Repository URL (derived from above)
export TEMPLATE_REPO_URL="https://github.com/${TEMPLATE_OWNER}/${TEMPLATE_REPO}.git"

# Files to fetch from template repository
declare -gx TEMPLATE_FILES=(
  "TEMPLATE-MANIFEST.json"
  "GENERATOR.json"
  "README.md"
)

# Cache directory for template files (relative to skill directory)
export TEMPLATE_CACHE_DIR=".cache/files"

# Cache metadata file (tracks last fetch time)
export TEMPLATE_CACHE_META="${TEMPLATE_CACHE_DIR}/files.meta"

# Cache TTL in seconds (24 hours)
export TEMPLATE_CACHE_TTL=$((24 * 60 * 60))

# Echo config for debugging (when sourced with VERBOSE=1)
if [[ "${VERBOSE:-}" == "1" ]]; then
  echo "[template-config] Loaded:" >&2
  echo "  Owner:  $TEMPLATE_OWNER" >&2
  echo "  Repo:   $TEMPLATE_REPO" >&2
  echo "  Branch: $TEMPLATE_BRANCH" >&2
  echo "  URL:    $TEMPLATE_REPO_URL" >&2
  echo "  Cache:  $TEMPLATE_CACHE_DIR" >&2
  echo "  TTL:    $TEMPLATE_CACHE_TTL seconds" >&2
fi
