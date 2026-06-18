#!/bin/bash
# Orchestrated template fetch using gh CLI
# Reads multiple files in parallel batches, applies local caching

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source cache utilities
source "$SCRIPT_DIR/lib/cache.sh"

# GitHub template reference
OWNER="${1:-heandroro}"
REPO="${2:-java-hexagonal-template}"
BRANCH="${3:-main}"
BATCH_SIZE="${4:-4}"
REFRESH_CACHE="${5:-false}"

# Files to fetch (core configuration files + sample modules)
FILES=(
  "TEMPLATE-MANIFEST.json"
  "GENERATOR.json"
  "README.md"
)

# Print usage
usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [owner] [repo] [branch] [batch_size] [refresh_cache]

Fetch template files from GitHub using gh CLI with parallel batching and caching.

Arguments:
  owner        GitHub owner (default: heandroro)
  repo         Repository name (default: java-hexagonal-template)
  branch       Git branch (default: main)
  batch_size   Files per batch (default: 4)
  refresh_cache Force cache refresh (default: false)

Examples:
  $(basename "$0")                                    # Use defaults
  $(basename "$0") heandroro java-hexagonal-template main 4 true  # Refresh cache
EOF
}

# Check gh CLI is available
check_gh_cli() {
  if ! command -v gh &>/dev/null; then
    echo "[error] gh CLI not found. Install from: https://github.com/cli/cli" >&2
    return 1
  fi

  # Test GitHub API access
  if ! gh api user --jq '.login' &>/dev/null; then
    echo "[error] GitHub authentication failed. Run: gh auth login" >&2
    return 1
  fi

  return 0
}

# Fetch file content from GitHub
fetch_file() {
  local file="$1"
  local url="repos/$OWNER/$REPO/contents/$file"

  gh api "$url" --jq '.content | @base64d' 2>/dev/null || {
    echo "[error] Failed to fetch $file" >&2
    return 1
  }
}

# Fetch a batch of files in parallel
fetch_batch() {
  local -a batch=("$@")
  local -a pids=()

  echo "[fetch] Batch (${#batch[@]} files)..." >&2

  for file in "${batch[@]}"; do
    (
      # Subshell: fetch and output with file marker
      {
        echo "==FILE_START:$file=="
        fetch_file "$file"
        echo "==FILE_END:$file=="
      } 2>&1
    ) &
    pids+=($!)
  done

  # Wait for all parallel jobs
  for pid in "${pids[@]}"; do
    wait "$pid" || {
      echo "[error] Batch fetch failed" >&2
      return 1
    }
  done

  return 0
}

# Main function
main() {
  local start_time=$(date +%s)

  echo "[template] Fetching from $OWNER/$REPO@$BRANCH" >&2

  # Check gh CLI
  if ! check_gh_cli; then
    echo '{"error": "gh CLI not available", "fallback": true}'
    return 1
  fi

  # Check cache (unless refresh requested)
  if [[ "$REFRESH_CACHE" != "true" ]] && cache_is_valid; then
    cache_status
    local cached=$(cache_load)
    echo "$cached"
    return 0
  fi

  # Clean expired cache
  cache_clean || true

  # Fetch files in batches
  local output=""
  local files_count=${#FILES[@]}
  local batches=0

  for ((i = 0; i < files_count; i += BATCH_SIZE)); do
    batches=$((batches + 1))
    local batch=("${FILES[@]:i:BATCH_SIZE}")
    local batch_output=$(fetch_batch "${batch[@]}")
    output="${output}${batch_output}"
  done

  # Parse and aggregate results
  local json_output="{}"
  echo "$output" | awk '
    /^==FILE_START:(.+)==$/ {
      current_file = gensub(/^==FILE_START:(.+)==$/, "\\1", 1)
      content = ""
    }
    /^==FILE_END:(.+)==$/ {
      print current_file "|" content
      content = ""
    }
    !/^==FILE_/ {
      if (content) content = content "\n"
      content = content $0
    }
  ' | while IFS='|' read -r file content; do
    if [[ -n "$file" ]]; then
      json_output=$(echo "$json_output" | jq --arg file "$file" --arg content "$content" \
        '.files += {($file): $content}')
    fi
  done

  # Add metadata
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  local size=$(echo -n "$output" | wc -c)
  local size_kb=$((size / 1024))

  json_output=$(echo "$json_output" | jq \
    --arg cached "false" \
    --arg batches "$batches" \
    --arg duration "${duration}s" \
    --arg size "${size_kb}KB" \
    '.metadata = {cached: $cached, batches: $batches, duration: $duration, size: $size}')

  # Cache the result
  cache_save "$json_output"

  # Output result
  echo "$json_output"
  echo "[template] Fetch complete ($batches batches, ${duration}s)" >&2

  return 0
}

# Run main
main "$@"
