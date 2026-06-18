#!/bin/bash
# Orchestrated template fetch using gh CLI with intelligent retry and per-file caching
#
# API Contract:
#
#   COMMAND
#   -------
#   .apm/scripts/fetch-template.sh [owner] [repo] [branch] [batch_size] [refresh_cache] [max_retries]
#
#   PARAMETERS (all optional, defaults shown)
#   --------
#   owner         = heandroro
#   repo          = java-hexagonal-template
#   branch        = main
#   batch_size    = 4              (files per parallel batch)
#   refresh_cache = false          (set true to ignore existing cache)
#   max_retries   = 2              (exponential backoff: 2^retry seconds)
#
#   EXIT STATUS
#   -----------
#   0 = Complete success (all files obtained)
#   1 = Complete failure (no files obtained, gh CLI unavailable or auth failed)
#   2 = Partial success (some files obtained, some missing)
#
#   JSON OUTPUT (stdout)
#   ----
#   {
#     "files": {
#       "TEMPLATE-MANIFEST.json": "{ ...file content... }",
#       "GENERATOR.json": "{ ...file content... }",
#       ...
#     },
#     "missing": ["file-C", "file-D"],  // Only present if status = 2
#     "metadata": {
#       "source": "gh-cli",
#       "batches": 4,
#       "duration": "5s"
#     },
#     "status": 0
#   }
#
#   CACHE STRUCTURE
#   ---------------
#   .cache/
#   ├── files/                          // Per-file cache (primary)
#   │   ├── TEMPLATE-MANIFEST.json      // File content
#   │   ├── GENERATOR.json              // File content
#   │   ├── README.md                   // File content
#   │   ├── file-C.err                  // Error marker (if fetch failed)
#   │   └── files.meta                  // Timestamp (24h TTL)
#   └── (legacy: template-files.json.gz, cache.meta — unused after switch to gh-cli)
#
#   RETRY LOGIC
#   -----------
#   Batch 1: Fetch 4 files in parallel
#     → Success: save to .cache/files/*.json
#     → Failure: save error marker to .cache/files/*.err
#
#   Auto-retry (if failures detected):
#     → Sleep 2s (exponential: 2^retry_count seconds)
#     → Retry ONLY failed files (not successful ones)
#     → Repeat up to max_retries times
#
#   After max_retries exhausted:
#     → Successful files: in JSON output
#     → Failed files: listed in "missing" array (status = 2)
#
#   FALLBACK
#   --------
#   If gh CLI not found or auth fails → Return JSON with status = 1
#   SKILL.md will detect status = 1 and fallback to GitHub MCP
#
#   EFFICIENCY
#   ----------
#   • First run: Fetches files via gh CLI (parallel batches)
#   • Second+ run: Reads from .cache/files/ (24h TTL), ~1ms per file
#   • Cache hit vs miss: If cached, returns in ~100ms vs ~3-5s for network fetch
#
#   Example for SKILL.md:
#     if [ $exit_status -eq 0 ]; then
#       # Use all files from JSON
#       MANIFEST=$(echo "$json" | jq -r '.files["TEMPLATE-MANIFEST.json"]')
#     elif [ $exit_status -eq 2 ]; then
#       # Use cached files, fallback MCP for missing
#       missing=$(echo "$json" | jq -r '.missing[]')
#       for file in $missing; do
#         # Call MCP get_file_contents for this file
#       done
#     else
#       # Use MCP for all files
#     fi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Cache locations
FILES_CACHE_DIR="${PROJECT_ROOT}/cache/files"
mkdir -p "$FILES_CACHE_DIR"

# GitHub template reference
OWNER="${1:-heandroro}"
REPO="${2:-java-hexagonal-template}"
BRANCH="${3:-main}"
BATCH_SIZE="${4:-4}"
REFRESH_CACHE="${5:-false}"
MAX_RETRIES="${6:-2}"

# Files to fetch (core configuration files + sample modules)
FILES=(
  "TEMPLATE-MANIFEST.json"
  "GENERATOR.json"
  "README.md"
)

# Check gh CLI is available
check_gh_cli() {
  if ! command -v gh &>/dev/null; then
    echo "[error] gh CLI not found. Install from: https://github.com/cli/cli" >&2
    return 1
  fi

  if ! gh api user --jq '.login' &>/dev/null; then
    echo "[error] GitHub authentication failed. Run: gh auth login" >&2
    return 1
  fi

  return 0
}

# Fetch and cache a single file
fetch_file_with_cache() {
  local file="$1"
  local retry_count="${2:-0}"
  local cache_file="$FILES_CACHE_DIR/$file.json"
  local err_file="$FILES_CACHE_DIR/$file.err"

  # Try to load from cache first (if not refreshing)
  if [[ "$REFRESH_CACHE" != "true" ]] && [[ -f "$cache_file" ]]; then
    cat "$cache_file"
    rm -f "$err_file" 2>/dev/null || true
    return 0
  fi

  # Fetch from GitHub
  local url="repos/$OWNER/$REPO/contents/$file"
  if gh api "$url" --jq '.content | @base64d' > "$cache_file" 2>/dev/null; then
    rm -f "$err_file" 2>/dev/null || true
    cat "$cache_file"
    return 0
  else
    # Save error state
    echo "Failed to fetch $file (attempt $((retry_count + 1)))" > "$err_file"
    return 1
  fi
}

# Fetch a batch of files in parallel, with per-file caching
fetch_batch() {
  local -a batch=("$@")
  local -a pids=()
  local -a temp_files=()

  echo "[fetch] Batch (${#batch[@]} files)..." >&2

  for file in "${batch[@]}"; do
    local temp_file=$(mktemp)
    temp_files+=("$temp_file")

    (
      if fetch_file_with_cache "$file" > "$temp_file" 2>/dev/null; then
        echo "==SUCCESS:$file=="
      else
        echo "==FAIL:$file=="
      fi
    ) &
    pids+=($!)
  done

  # Wait for all parallel jobs
  for pid in "${pids[@]}"; do
    wait "$pid" || true
  done

  # Output results
  for temp_file in "${temp_files[@]}"; do
    cat "$temp_file"
    rm -f "$temp_file"
  done
}

# Detect failed files from error markers
get_failed_files() {
  if [[ ! -d "$FILES_CACHE_DIR" ]]; then
    return 1
  fi

  local failed=()
  for err_file in "$FILES_CACHE_DIR"/*.err 2>/dev/null; do
    [[ -f "$err_file" ]] || continue
    local filename=$(basename "$err_file" .err)
    failed+=("$filename")
  done

  if [[ ${#failed[@]} -gt 0 ]]; then
    printf '%s\n' "${failed[@]}"
    return 0
  fi

  return 1
}

# Retry only failed files with exponential backoff
retry_failed_files() {
  local retry_count="$1"
  local failed_files=()

  # Get list of failed files
  while IFS= read -r file; do
    failed_files+=("$file")
  done < <(get_failed_files)

  if [[ ${#failed_files[@]} -eq 0 ]]; then
    return 0  # No failures
  fi

  echo "[retry] Attempting ${#failed_files[@]} failed files (retry $retry_count/$MAX_RETRIES)..." >&2

  # Exponential backoff: 2^retry_count seconds (2s, 4s, 8s, ...)
  local backoff=$((2 ** retry_count))
  sleep "$backoff"

  # Retry failed files
  for file in "${failed_files[@]}"; do
    fetch_file_with_cache "$file" "$retry_count" > /dev/null 2>&1 || true
  done

  return 0
}

# Build JSON output from cached files
build_json_output() {
  local json_output='{"files": {}}'
  local missing_files=()
  local successful_files=()

  for file in "${FILES[@]}"; do
    local cache_file="$FILES_CACHE_DIR/$file.json"
    local err_file="$FILES_CACHE_DIR/$file.err"

    if [[ -f "$cache_file" ]]; then
      local content=$(cat "$cache_file")
      json_output=$(echo "$json_output" | jq \
        --arg file "$file" \
        --arg content "$content" \
        '.files[$file] = $content')
      successful_files+=("$file")
    else
      missing_files+=("$file")
    fi
  done

  # Add missing array if there are failures
  if [[ ${#missing_files[@]} -gt 0 ]]; then
    local missing_json=$(printf '%s\n' "${missing_files[@]}" | jq -R . | jq -s .)
    json_output=$(echo "$json_output" | jq --argjson missing "$missing_json" '.missing = $missing')
  fi

  echo "$json_output"
}

# Determine exit status based on success/failure counts
get_exit_status() {
  local successful=0
  local failed=0

  for file in "${FILES[@]}"; do
    if [[ -f "$FILES_CACHE_DIR/$file.json" ]]; then
      successful=$((successful + 1))
    else
      failed=$((failed + 1))
    fi
  done

  if [[ $failed -eq 0 ]]; then
    return 0  # Status 0: complete success
  elif [[ $successful -eq 0 ]]; then
    return 1  # Status 1: complete failure
  else
    return 2  # Status 2: partial success
  fi
}

# Main function
main() {
  local start_time=$(date +%s)

  echo "[template] Fetching from $OWNER/$REPO@$BRANCH" >&2

  # Try gh CLI first
  if ! check_gh_cli; then
    # gh CLI not available, fallback to git clone
    echo "[template] gh CLI not available, using git clone fallback..." >&2
    local git_script="$SCRIPT_DIR/fetch-template-git.sh"

    if [[ ! -f "$git_script" ]]; then
      echo '{"error": "gh CLI and git clone fallback script not found", "status": 1}' >&2
      return 1
    fi

    # Call git clone fallback script
    "$git_script"
    return $?
  fi

  # Clean old error files if doing fresh fetch
  if [[ "$REFRESH_CACHE" == "true" ]]; then
    rm -f "$FILES_CACHE_DIR"/*.err 2>/dev/null || true
  fi

  # Fetch files in batches
  local files_count=${#FILES[@]}
  local batches=0
  local retry_attempt=0

  for ((i = 0; i < files_count; i += BATCH_SIZE)); do
    batches=$((batches + 1))
    local batch=("${FILES[@]:i:BATCH_SIZE}")
    fetch_batch "${batch[@]}" > /dev/null
  done

  # Retry failed files if any
  while [[ $retry_attempt -lt $MAX_RETRIES ]] && get_failed_files > /dev/null 2>&1; do
    retry_attempt=$((retry_attempt + 1))
    retry_failed_files "$retry_attempt"
  done

  # Build output JSON
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  local json_output=$(build_json_output)

  # Add metadata
  json_output=$(echo "$json_output" | jq \
    --arg batches "$batches" \
    --arg duration "${duration}s" \
    '.metadata = {source: "gh-cli", batches: $batches, duration: $duration}')

  # Determine final status
  local final_status=0
  get_exit_status || final_status=$?

  # Add status to JSON
  json_output=$(echo "$json_output" | jq \
    --arg status "$final_status" \
    '.status = ($status | tonumber)')

  # Output result
  echo "$json_output"

  # Log summary
  local successful=0
  local failed=0
  for file in "${FILES[@]}"; do
    if [[ -f "$FILES_CACHE_DIR/$file.json" ]]; then
      successful=$((successful + 1))
    else
      failed=$((failed + 1))
    fi
  done

  if [[ $failed -eq 0 ]]; then
    echo "[template] Fetch complete ($successful/$files_count files, ${duration}s)" >&2
  else
    echo "[template] Fetch partial ($successful/$files_count files, $failed missing, ${duration}s)" >&2
  fi

  return "$final_status"
}

# Run main
main "$@"
