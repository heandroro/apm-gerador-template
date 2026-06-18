#!/bin/bash
# Cache utilities for template data
# Provides functions for 24-hour local caching of GitHub template files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CACHE_DIR="${PROJECT_ROOT}/.cache"
CACHE_FILE="${CACHE_DIR}/template-files.json.gz"
CACHE_META="${CACHE_DIR}/cache.meta"

# Create cache directory
mkdir -p "$CACHE_DIR"

# Check if cache exists and is valid (< 24 hours)
cache_is_valid() {
  if [[ ! -f "$CACHE_META" ]]; then
    return 1
  fi

  local cached_time=$(cat "$CACHE_META" 2>/dev/null || echo "0")
  local current_time=$(date +%s)
  local age=$((current_time - cached_time))
  local max_age=$((24 * 60 * 60))  # 24 hours in seconds

  [[ $age -lt $max_age ]]
}

# Load cache from disk and decompress
cache_load() {
  if [[ ! -f "$CACHE_FILE" ]]; then
    return 1
  fi

  gunzip -c "$CACHE_FILE"
}

# Save data to cache with gzip compression
cache_save() {
  local data="$1"

  # Save compressed data
  echo "$data" | gzip > "$CACHE_FILE"

  # Save timestamp
  date +%s > "$CACHE_META"

  echo "[cache] Template files saved (size: $(du -h "$CACHE_FILE" | cut -f1))" >&2
}

# Clean expired cache
cache_clean() {
  if [[ -f "$CACHE_META" ]]; then
    local cached_time=$(cat "$CACHE_META")
    local current_time=$(date +%s)
    local age=$((current_time - cached_time))
    local max_age=$((24 * 60 * 60))

    if [[ $age -ge $max_age ]]; then
      rm -f "$CACHE_FILE" "$CACHE_META"
      echo "[cache] Expired cache cleaned" >&2
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

    echo "[cache] Valid cache found (${hours}h old, size: $size)"
    return 0
  else
    echo "[cache] No valid cache found"
    return 1
  fi
}
