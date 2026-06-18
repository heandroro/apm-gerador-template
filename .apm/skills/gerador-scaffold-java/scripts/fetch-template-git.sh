#!/bin/bash
# Fetch template files from local git clone (fallback when gh CLI unavailable)
# Uses --depth=1 --single-branch --filter=blob:none --sparse for ~30-50MB footprint

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source template configuration (centralized source of truth)
source "$SCRIPT_DIR/../lib/template-config.sh"

# Local clone path (separate from cache dir, since this is persistent repo)
TEMPLATE_REPO_PATH="${PROJECT_ROOT}/template-repo"
TEMPLATE_REPO_URL="${TEMPLATE_REPO_URL:-https://github.com/${TEMPLATE_OWNER}/${TEMPLATE_REPO}.git}"
TEMPLATE_REPO_BRANCH="${TEMPLATE_BRANCH:-main}"
CACHE_META="${TEMPLATE_REPO_PATH}/.cache-time"
MAX_AGE="${TEMPLATE_CACHE_TTL:-$((24 * 60 * 60))}"  # 24 hours in seconds

# Files to fetch from template repo (from template-config.sh)
FILES=("${TEMPLATE_FILES[@]}")

# Helper: Read file from repo
read_file_from_repo() {
  local file="$1"
  local repo_path="$2"

  if [[ ! -f "$repo_path/$file" ]]; then
    echo "[error] File not found in repo: $file" >&2
    return 1
  fi

  cat "$repo_path/$file"
}

# Check if cached repo exists and is valid (< 24 hours old)
cache_is_valid() {
  if [[ ! -f "$CACHE_META" ]]; then
    return 1
  fi

  local cached_time=$(cat "$CACHE_META" 2>/dev/null || echo "0")
  local current_time=$(date +%s)
  local age=$((current_time - cached_time))

  [[ $age -lt $MAX_AGE ]]
}

# Initialize and configure sparse checkout
configure_sparse_checkout() {
  local repo_path="$1"

  git -C "$repo_path" config core.sparseCheckout true 2>/dev/null || true
  git -C "$repo_path" sparse-checkout set . 2>/dev/null || true
}

# Clone template repo (optimized for minimal size: ~30-50MB)
clone_template_repo() {
  local repo_path="$1"
  local parent_dir="$(dirname "$repo_path")"

  mkdir -p "$parent_dir"

  echo "[git] Cloning template repo (optimized, ~30-50MB)..." >&2
  echo "[git] This may take 2-5 minutes on first run..." >&2

  git clone \
    --depth=1 \
    --single-branch \
    --branch="$TEMPLATE_REPO_BRANCH" \
    --filter=blob:none \
    --sparse \
    "$TEMPLATE_REPO_URL" \
    "$repo_path" 2>/dev/null || {
    echo "[error] Failed to clone template repository" >&2
    return 1
  }

  configure_sparse_checkout "$repo_path"

  # Mark cache as fresh
  date +%s > "$CACHE_META"

  echo "[git] Template repo cloned successfully" >&2
}

# Update template repo (git pull for incremental sync)
update_template_repo() {
  local repo_path="$1"

  echo "[git] Updating template repo..." >&2

  git -C "$repo_path" pull --ff-only 2>/dev/null || {
    echo "[warning] Failed to update repo, using cached version" >&2
    return 1
  }

  # Mark cache as fresh
  date +%s > "$CACHE_META"

  echo "[git] Template repo updated successfully" >&2
}

# Main function
main() {
  # Check if repo exists and is fresh
  if [[ -d "$TEMPLATE_REPO_PATH" ]]; then
    if cache_is_valid; then
      local size=$(du -sh "$TEMPLATE_REPO_PATH" 2>/dev/null | cut -f1)
      echo "[git] Using cached template repo ($size)" >&2

      # Read and output files
      local json='{"files": {}}'
      for file in "${FILES[@]}"; do
        local content=$(read_file_from_repo "$file" "$TEMPLATE_REPO_PATH" || echo "")
        if [[ -z "$content" ]]; then
          echo "[error] Could not read $file from cached repo" >&2
          return 1
        fi
        json=$(echo "$json" | jq \
          --arg file "$file" \
          --arg content "$content" \
          '.files[$file] = $content')
      done

      # Add metadata
      json=$(echo "$json" | jq \
        --arg source "git-clone" \
        --arg status "0" \
        '.metadata = {source: $source} | .status = ($status | tonumber)')

      echo "$json"
      return 0
    fi

    # Cache expired, update
    if update_template_repo "$TEMPLATE_REPO_PATH"; then
      # Read and output files
      local json='{"files": {}}'
      for file in "${FILES[@]}"; do
        local content=$(read_file_from_repo "$file" "$TEMPLATE_REPO_PATH" || echo "")
        if [[ -z "$content" ]]; then
          echo "[error] Could not read $file after update" >&2
          return 1
        fi
        json=$(echo "$json" | jq \
          --arg file "$file" \
          --arg content "$content" \
          '.files[$file] = $content')
      done

      # Add metadata
      json=$(echo "$json" | jq \
        --arg source "git-pull" \
        --arg status "0" \
        '.metadata = {source: $source} | .status = ($status | tonumber)')

      echo "$json"
      return 0
    else
      # Update failed, return error
      echo '{"error": "Failed to update cached repository", "fallback": false, "status": 1}' >&2
      return 1
    fi
  fi

  # Clone for first time
  if clone_template_repo "$TEMPLATE_REPO_PATH"; then
    # Read and output files
    local json='{"files": {}}'
    for file in "${FILES[@]}"; do
      local content=$(read_file_from_repo "$file" "$TEMPLATE_REPO_PATH" || echo "")
      if [[ -z "$content" ]]; then
        echo "[error] Could not read $file after clone" >&2
        return 1
      fi
      json=$(echo "$json" | jq \
        --arg file "$file" \
        --arg content "$content" \
        '.files[$file] = $content')
    done

    # Add metadata
    json=$(echo "$json" | jq \
      --arg source "git-clone-first" \
      --arg status "0" \
      '.metadata = {source: $source} | .status = ($status | tonumber)')

    echo "$json"
    return 0
  else
    # Clone failed
    echo '{"error": "Failed to clone template repository", "fallback": false, "status": 1}' >&2
    return 1
  fi
}

# Run main
main "$@"
