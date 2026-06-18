#!/bin/bash
# Cache utilities for template data
# Provides functions for 24-hour local caching of GitHub template files (per-file)
#
# IMPORTANT: This file sources template-config.sh to get centralized cache paths

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source template configuration for centralized cache paths
source "$SCRIPT_DIR/template-config.sh"

# Derive full cache paths from template-config.sh settings
CACHE_DIR="${PROJECT_ROOT}/${TEMPLATE_CACHE_DIR%/*}"  # Remove /files suffix
FILES_CACHE_DIR="${PROJECT_ROOT}/${TEMPLATE_CACHE_DIR}"  # e.g. .apm/skills/.../cache/files
FILES_CACHE_META="${PROJECT_ROOT}/${TEMPLATE_CACHE_META}"  # e.g. .apm/skills/.../cache/files/files.meta

# Legacy monolithic cache (no longer used, kept for cleanup)
CACHE_FILE="${CACHE_DIR}/template-files.json.gz"
CACHE_META="${CACHE_DIR}/cache.meta"

# Create cache directories
mkdir -p "$CACHE_DIR" "$FILES_CACHE_DIR"

# Check if monolithic cache exists and is valid (LEGACY — no longer used)
cache_is_valid() {
  if [[ ! -f "$CACHE_META" ]]; then
    return 1
  fi

  local cached_time=$(cat "$CACHE_META" 2>/dev/null || echo "0")
  local current_time=$(date +%s)
  local age=$((current_time - cached_time))
  local max_age="${TEMPLATE_CACHE_TTL:-$((24 * 60 * 60))}"  # From template-config.sh

  [[ $age -lt $max_age ]]
}

# Check if per-file cache exists and is valid (uses TEMPLATE_CACHE_TTL from template-config.sh)
files_cache_is_valid() {
  if [[ ! -f "$FILES_CACHE_META" ]]; then
    return 1
  fi

  local cached_time=$(cat "$FILES_CACHE_META" 2>/dev/null || echo "0")
  local current_time=$(date +%s)
  local age=$((current_time - cached_time))
  local max_age="${TEMPLATE_CACHE_TTL:-$((24 * 60 * 60))}"  # Default to 24h if not set

  [[ $age -lt $max_age ]]
}

# Load monolithic cache from disk and decompress
cache_load() {
  if [[ ! -f "$CACHE_FILE" ]]; then
    return 1
  fi

  gunzip -c "$CACHE_FILE"
}

# Load per-file cache (returns directory path if valid)
files_cache_load() {
  if files_cache_is_valid; then
    echo "$FILES_CACHE_DIR"
    return 0
  fi
  return 1
}

# Save data to monolithic cache with gzip compression
cache_save() {
  local data="$1"

  echo "$data" | gzip > "$CACHE_FILE"
  date +%s > "$CACHE_META"

  echo "[cache] Template files saved (size: $(du -h "$CACHE_FILE" | cut -f1))" >&2
}

# Mark per-file cache as valid (after successful fetch)
files_cache_mark_valid() {
  date +%s > "$FILES_CACHE_META"
  echo "[cache] Per-file cache marked valid" >&2
}

# Clean expired monolithic cache (LEGACY — no longer used)
cache_clean() {
  if [[ -f "$CACHE_META" ]]; then
    local cached_time=$(cat "$CACHE_META")
    local current_time=$(date +%s)
    local age=$((current_time - cached_time))
    local max_age="${TEMPLATE_CACHE_TTL:-$((24 * 60 * 60))}"  # From template-config.sh

    if [[ $age -ge $max_age ]]; then
      rm -f "$CACHE_FILE" "$CACHE_META"
      echo "[cache] Expired monolithic cache cleaned" >&2
      return 1
    fi
  fi

  return 1
}

# Clean expired per-file cache (uses TEMPLATE_CACHE_TTL from template-config.sh)
files_cache_clean() {
  if [[ -f "$FILES_CACHE_META" ]]; then
    local cached_time=$(cat "$FILES_CACHE_META")
    local current_time=$(date +%s)
    local age=$((current_time - cached_time))
    local max_age="${TEMPLATE_CACHE_TTL:-$((24 * 60 * 60))}"  # Default to 24h if not set

    if [[ $age -ge $max_age ]]; then
      rm -f "$FILES_CACHE_DIR"/*.json "$FILES_CACHE_DIR"/*.err "$FILES_CACHE_META"
      echo "[cache] Expired per-file cache cleaned" >&2
      return 1
    fi
  fi

  return 1
}

# Report cache status
cache_status() {
  if cache_is_valid; then
    local size=$(du -h "$CACHE_FILE" | cut -f1)
    local cached_time=$(cat "$CACHE_META")
    local current_time=$(date +%s)
    local age=$((current_time - cached_time))
    local hours=$((age / 3600))

    echo "[cache] Valid monolithic cache found (${hours}h old, size: $size)"
    return 0
  else
    echo "[cache] No valid monolithic cache found"
    return 1
  fi
}

# Report per-file cache status
files_cache_status() {
  if files_cache_is_valid; then
    local file_count=$(ls -1 "$FILES_CACHE_DIR"/*.json 2>/dev/null | wc -l)
    local cached_time=$(cat "$FILES_CACHE_META")
    local current_time=$(date +%s)
    local age=$((current_time - cached_time))
    local hours=$((age / 3600))

    echo "[cache] Valid per-file cache found (${hours}h old, $file_count files)"
    return 0
  else
    echo "[cache] No valid per-file cache found"
    return 1
  fi
}
