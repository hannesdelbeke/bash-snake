#!/usr/bin/env bash
set -euo pipefail
set -E

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$script_dir/snake_core.sh"

crash_log="$script_dir/crash.log"

log_crash() {
  local exit_code=$1
  local line_no=${2:-unknown}
  local cmd=${3:-unknown}
  {
    printf '[%s] crash exit=%s line=%s cmd=%s score=%s tick=%s\n' \
      "$(date '+%Y-%m-%d %H:%M:%S')" \
      "$exit_code" \
      "$line_no" \
      "$cmd" \
      "${score:-na}" \
      "${tick_count:-na}"
  } >> "$crash_log"
}

cleanup() {
  stty "$old_stty" >/dev/null 2>&1 || true
  tput cnorm
  printf '\n'
}

run_game() {
  old_stty="$(stty -g)"
  trap 'log_crash "$?" "${LINENO}" "$BASH_COMMAND"' ERR
  trap cleanup EXIT
  stty -echo -icanon time 0 min 0 >/dev/null 2>&1
  tput civis
  clear

  while :; do
    main_loop
    if [[ "${main_loop_action:-exit}" == "exit" ]]; then
      break
    fi
    if [[ "${main_loop_action:-exit}" == "replay" ]]; then
      continue
    fi
    break
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  run_game
fi
