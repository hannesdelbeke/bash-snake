#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$script_dir/../snake_core.sh"

reset_state() {
  tick_count=0
  score=0
  chain=0
  speed_boost_ticks=0
  wrap_ticks=0
  powerup_item_type="none"
  powerup_item_x=-1
  powerup_item_y=-1
  next_powerup_tick=0
  snake_x=(20 19 18 17 16)
  snake_y=(9 9 9 9 9)
  dir_x=1
  dir_y=0
  last_dir_x=1
  last_dir_y=0
  food_x=0
  food_y=0
}

fail() {
  printf 'failed: %s\n' "$1"
  exit 1
}

assert_eq() {
  local expected=$1
  local actual=$2
  if [[ "$expected" != "$actual" ]]; then
    fail "expected '$expected' but got '$actual'"
  fi
}

assert_true() {
  if ! "$@"; then
    fail "expected true: $*"
  fi
}

assert_false() {
  if "$@"; then
    fail "expected false: $*"
  fi
}

test_movement_step_no_wrap() {
  reset_state
  local output
  output=$(calc_next_head 20 9 1 0 0)
  assert_eq "21 9" "$output"
}

test_movement_step_with_wrap() {
  reset_state
  local output
  output=$(calc_next_head 0 0 -1 0 1)
  assert_eq "$((width - 1)) 0" "$output"
}

test_boundary_detection() {
  reset_state
  assert_true is_out_of_bounds -1 0
  assert_true is_out_of_bounds 0 -1
  assert_true is_out_of_bounds "$width" 0
  assert_false is_out_of_bounds 0 0
}

test_food_generation_not_on_snake_or_powerup() {
  reset_state
  powerup_item_x=0
  powerup_item_y=0
  generate_food
  assert_false is_snake_cell "$food_x" "$food_y"
  if [[ "$food_x" -eq "$powerup_item_x" && "$food_y" -eq "$powerup_item_y" ]]; then
    fail "food spawned on powerup"
  fi
}

test_scoring_and_chain() {
  reset_state
  eat_food
  eat_food
  assert_eq 20 "$score"
  assert_eq 2 "$chain"
  reset_chain
  assert_eq 0 "$chain"
}

test_powerup_spawn_and_timer() {
  reset_state
  food_x=1
  food_y=1
  tick_count=7
  spawn_powerup
  assert_false is_snake_cell "$powerup_item_x" "$powerup_item_y"
  if [[ "$powerup_item_x" -eq "$food_x" && "$powerup_item_y" -eq "$food_y" ]]; then
    fail "powerup spawned on food"
  fi
  if [[ "$powerup_item_type" != "speed" && "$powerup_item_type" != "wrap" ]]; then
    fail "powerup type invalid: $powerup_item_type"
  fi
  assert_eq "$((tick_count + powerup_gap))" "$next_powerup_tick"
}

test_powerup_activation_speed() {
  reset_state
  wrap_ticks=5
  activate_powerup speed
  assert_eq 40 "$speed_boost_ticks"
  assert_eq 5 "$wrap_ticks"
}

test_powerup_activation_wrap() {
  reset_state
  activate_powerup wrap
  assert_eq 40 "$wrap_ticks"
}

test_delay_changes_with_speed_boost() {
  reset_state
  local normal_delay
  local boosted_delay
  normal_delay=$(get_delay)
  speed_boost_ticks=10
  boosted_delay=$(get_delay)
  assert_eq "$base_delay" "$normal_delay"
  if awk "BEGIN {exit !($boosted_delay < $normal_delay)}"; then
    :
  else
    fail "boosted delay ($boosted_delay) should be less than normal ($normal_delay)"
  fi
}

test_game_over_text_contains_expected_content() {
  reset_state
  local text
  text="$(render_game_over_text 123)"
  [[ "$text" == *"____"* ]] || fail "game over ascii header missing"
  [[ "$text" == *"Final Score: 123"* ]] || fail "final score line missing"
  [[ "$text" == *"Press Esc to exit"* ]] || fail "esc prompt missing"
  [[ "$text" == *"Press any key to replay"* ]] || fail "replay prompt missing"
}

main() {
  test_movement_step_no_wrap
  test_movement_step_with_wrap
  test_boundary_detection
  test_food_generation_not_on_snake_or_powerup
  test_scoring_and_chain
  test_powerup_spawn_and_timer
  test_powerup_activation_speed
  test_powerup_activation_wrap
  test_delay_changes_with_speed_boost
  test_game_over_text_contains_expected_content
  printf 'tests passed\n'
}

main
