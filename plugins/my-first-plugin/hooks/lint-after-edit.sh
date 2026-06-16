#!/bin/bash
# PostToolUse hook: runs a linter after Claude writes or edits a file.
#
# Registered in hooks/hooks.json for the "Write|Edit" matcher.
#
# Behavior:
#   - Reads the hook payload (JSON) from stdin and extracts tool_input.file_path.
#   - Picks a linter based on the file extension, but ONLY if that linter is
#     actually installed/available. This is an example/learning hook, so it
#     stays quiet (exit 0) whenever there's nothing it can or should do.
#   - If the linter finds problems, the findings are printed to stderr and the
#     script exits 2, which feeds the output back to Claude as actionable
#     context (per the PostToolUse hook contract: exit 0 = informational,
#     shown in transcript; exit 2 = stderr is returned to Claude).
#
# Test it manually:
#   echo '{"tool_name":"Write","tool_input":{"file_path":"some/file.js"}}' \
#     | bash hooks/lint-after-edit.sh

set -euo pipefail

input=$(cat)

# Extract tool_input.file_path from the JSON payload. Prefer jq, but fall
# back to node/python3 since jq isn't always preinstalled (e.g. on Windows).
# node is tried before python3 because on stock Windows, "python3" often
# resolves to a non-functional Microsoft Store shim rather than a real
# interpreter.
if command -v jq >/dev/null 2>&1; then
  file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || file_path=""
elif command -v node >/dev/null 2>&1; then
  file_path=$(echo "$input" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{console.log(JSON.parse(d).tool_input?.file_path||"")}catch{console.log("")}})' 2>/dev/null) || file_path=""
elif command -v python3 >/dev/null 2>&1; then
  file_path=$(echo "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input", {}).get("file_path", ""))' 2>/dev/null) || file_path=""
else
  # No JSON parser available — nothing we can safely do.
  exit 0
fi

# Nothing to lint.
if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  exit 0
fi

run_lint() {
  # run_lint <description> <command...>
  local description="$1"
  shift
  echo "Linting $file_path with $description..."
  "$@"
}

output=""
status=0

case "$file_path" in
  *.js | *.jsx | *.ts | *.tsx)
    if command -v eslint >/dev/null 2>&1; then
      output=$(run_lint "eslint" eslint "$file_path" 2>&1) || status=$?
    elif command -v npx >/dev/null 2>&1 && npx --no-install eslint --version >/dev/null 2>&1; then
      # Only use npx once we've confirmed eslint actually resolves locally —
      # otherwise npx's "would you like to install" prompt/refusal would be
      # mistaken for a real lint failure.
      output=$(run_lint "npx eslint" npx --no-install eslint "$file_path" 2>&1) || status=$?
    fi
    ;;
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      output=$(run_lint "ruff" ruff check "$file_path" 2>&1) || status=$?
    elif command -v flake8 >/dev/null 2>&1; then
      output=$(run_lint "flake8" flake8 "$file_path" 2>&1) || status=$?
    fi
    ;;
  *.sh | *.bash)
    if command -v shellcheck >/dev/null 2>&1; then
      output=$(run_lint "shellcheck" shellcheck "$file_path" 2>&1) || status=$?
    fi
    ;;
  *)
    # Unsupported file type for this example hook — nothing to do.
    exit 0
    ;;
esac

# No applicable linter was found on PATH — skip silently.
if [ -z "$output" ] && [ "$status" -eq 0 ]; then
  exit 0
fi

if [ "$status" -ne 0 ]; then
  echo "$output" >&2
  exit 2
fi

echo "$output"
exit 0
