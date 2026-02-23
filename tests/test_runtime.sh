#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$script_dir/../snake.sh"

fail() {
  printf 'failed: %s\n' "$1"
  exit 1
}

test_crash_log_entry() {
  local temp_log
  temp_log="$(mktemp)"
  crash_log="$temp_log"
  score=77
  tick_count=88

  log_crash 1 42 "bad_command"

  if ! grep -q 'crash exit=1 line=42 cmd=bad_command score=77 tick=88' "$temp_log"; then
    fail "crash log entry missing expected fields"
  fi
}

main() {
  test_crash_log_entry
  printf 'runtime tests passed\n'
}

main
