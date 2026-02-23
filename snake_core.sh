#!/usr/bin/env bash
set -euo pipefail

width=40
height=18
base_delay=0.05
sound_enabled=${SNAKE_SOUND:-1}
powerup_gap=60

reset_game_state() {
  speed_boost_ticks=0
  wrap_ticks=0
  powerup_item_type="none"
  powerup_item_x=-1
  powerup_item_y=-1
  next_powerup_tick=0
  tick_count=0
  score=0
  chain=0
  snake_x=(20 19 18 17 16)
  snake_y=(9 9 9 9 9)
  dir_x=1
  dir_y=0
  last_dir_x=1
  last_dir_y=0
  food_x=0
  food_y=0
}

render_game_over_text() {
  local final_score=$1
  cat <<EOF
    ____   __    ___  _   _
   / ___| / /   / _ \\| \\ | |
  | |  _ / /   | | | |  \\| |
  | |_| / /___ | |_| | |\\  |
   \\____|____(_)___/ |_| \\_|

   Final Score: $final_score
   Press Esc to exit
   Press any key to replay
EOF
}

show_game_over_screen() {
  local final_score=$1
  local text
  local term_lines term_cols text_lines pad_top
  text="$(render_game_over_text "$final_score")"
  term_lines=$(tput lines 2>/dev/null || printf '24')
  term_cols=$(tput cols 2>/dev/null || printf '80')
  text_lines=$(printf '%s\n' "$text" | wc -l | tr -d ' ')
  pad_top=$(( (term_lines - text_lines) / 2 ))
  (( pad_top < 0 )) && pad_top=0

  clear
  for ((i=0; i<pad_top; i+=1)); do
    printf '\n'
  done
  while IFS= read -r line; do
    local line_len left_pad
    line_len=${#line}
    left_pad=$(( (term_cols - line_len) / 2 ))
    (( left_pad < 0 )) && left_pad=0
    printf '%*s%s\n' "$left_pad" '' "$line"
  done <<< "$text"
}

show_pause_menu() {
  local text
  text=$(
    cat <<EOF
PAUSED

Esc/Q: exit game
R: replay
Any other key: continue
EOF
  )
  clear
  printf '%s\n' "$text"
}

play_sfx() {
  (( sound_enabled == 0 )) && return 0
  case "${1:-}" in
    food)
      printf '\a'
      ;;
    powerup)
      printf '\a\a'
      ;;
    game_over)
      printf '\a'
      sleep 0.05
      printf '\a'
      sleep 0.05
      printf '\a'
      ;;
  esac
}

is_snake_cell() {
  local cx=$1 cy=$2
  for i in "${!snake_x[@]}"; do
    [[ "${snake_x[i]}" -eq "$cx" && "${snake_y[i]}" -eq "$cy" ]] && return 0
  done
  return 1
}

generate_food() {
  local x y
  while :; do
    x=$((RANDOM % width))
    y=$((RANDOM % height))
    is_snake_cell "$x" "$y" && continue
    [[ "$x" -eq "$powerup_item_x" && "$y" -eq "$powerup_item_y" ]] && continue
    food_x=$x
    food_y=$y
    break
  done
}

spawn_powerup() {
  local x y
  while :; do
    x=$((RANDOM % width))
    y=$((RANDOM % height))
    is_snake_cell "$x" "$y" && continue
    [[ "$x" -eq "$food_x" && "$y" -eq "$food_y" ]] && continue
    powerup_item_x=$x
    powerup_item_y=$y
    if (( RANDOM % 2 == 0 )); then
      powerup_item_type="speed"
    else
      powerup_item_type="wrap"
    fi
    next_powerup_tick=$((tick_count + powerup_gap))
    break
  done
}

calc_next_head() {
  local head_x=$1 head_y=$2 dir_x=$3 dir_y=$4 wrap_flag=$5
  local new_x=$((head_x + dir_x))
  local new_y=$((head_y + dir_y))
  if (( wrap_flag > 0 )); then
    new_x=$(((new_x + width) % width))
    new_y=$(((new_y + height) % height))
  fi
  printf '%d %d' "$new_x" "$new_y"
}

is_out_of_bounds() {
  local x=$1 y=$2
  (( x < 0 || x >= width || y < 0 || y >= height ))
}

eat_food() {
  ((score += 10))
  ((chain += 1))
  play_sfx food
}

reset_chain() {
  chain=0
}

activate_powerup() {
  local type=$1
  case "$type" in
    speed)
      speed_boost_ticks=40
      ;;
    wrap)
      wrap_ticks=40
      ;;
  esac
}

get_delay() {
  if (( speed_boost_ticks > 0 )); then
    awk "BEGIN {printf \"%.3f\", $base_delay * 0.55}"
  else
    printf '%s' "$base_delay"
  fi
}

handle_input() {
  input_event="NONE"
  local key
  local esc_suffix=''
  if read -rsn1 -t 0.01 key; then
    if [[ $key == $'\e' ]]; then
      if read -rsn2 -t 0.01 esc_suffix; then
        key="$key$esc_suffix"
      else
        input_event="ESC"
        return 0
      fi
    fi
    case "$key" in
      w|W|$'\e[A')
        if [[ $last_dir_y -ne 1 ]]; then dir_x=0; dir_y=-1; fi
        ;;
      s|S|$'\e[B')
        if [[ $last_dir_y -ne -1 ]]; then dir_x=0; dir_y=1; fi
        ;;
      a|A|$'\e[D')
        if [[ $last_dir_x -ne 1 ]]; then dir_x=-1; dir_y=0; fi
        ;;
      d|D|$'\e[C')
        if [[ $last_dir_x -ne -1 ]]; then dir_x=1; dir_y=0; fi
        ;;
      q|Q)
        input_event="QUIT"
        return 0
        ;;
    esac
  fi
}

pause_menu() {
  pause_menu_action="continue"
  local key=''
  show_pause_menu
  if read -rsn1 key; then
    if [[ "$key" == $'\e' || "$key" == "q" || "$key" == "Q" ]]; then
      pause_menu_action="exit"
      return 0
    fi
    if [[ "$key" == "r" || "$key" == "R" ]]; then
      pause_menu_action="replay"
      return 0
    fi
  fi
}

border_line() {
  printf '%*s' "$width" '' | tr ' ' '-'
}

draw() {
  printf '\033[H'
  printf 'Esc: menu\n'
  local speed_state="normal"
  ((speed_boost_ticks>0)) && speed_state="boost"
  local wrap_state="off"
  ((wrap_ticks>0)) && wrap_state="on"
  printf 'Score %s | Speed %s | Wrap %s | Chain %s\n' "$score" "$speed_state" "$wrap_state" "$chain"
  printf '+%s+\n' "$(border_line)"
  for ((y=0; y<height; y++)); do
    printf '|'
    for ((x=0; x<width; x++)); do
      local char=' '
      if [[ $x -eq $food_x && $y -eq $food_y ]]; then
        char='*'
      elif [[ $x -eq $powerup_item_x && $y -eq $powerup_item_y ]]; then
        char='P'
      else
        for i in "${!snake_x[@]}"; do
          if [[ "${snake_x[i]}" -eq "$x" && "${snake_y[i]}" -eq "$y" ]]; then
            if [[ $i -eq 0 ]]; then
              char="@"
            else
              char="o"
            fi
          fi
        done
      fi
      printf "%s" "$char"
    done
    printf '|\n'
  done
  printf '+%s+\n' "$(border_line)"
  local beat_frame=$((tick_count % 4))
  printf 'Beat %s\n' "$beat_frame"
}

game_over() {
  game_over_action="replay"
  show_game_over_screen "$score"
  local key=''
  if read -rsn1 -t 8 key; then
    if [[ "$key" == $'\e' ]]; then
      game_over_action="exit"
      return 0
    fi
    game_over_action="replay"
  fi
}

main_loop() {
  main_loop_action="exit"
  reset_game_state
  generate_food
  spawn_powerup
  clear
  draw
  while :; do
    handle_input
    if [[ "$input_event" == "QUIT" ]]; then
      main_loop_action="exit"
      return 0
    fi
    if [[ "$input_event" == "ESC" ]]; then
      pause_menu
      if [[ "$pause_menu_action" == "exit" ]]; then
        main_loop_action="exit"
        return 0
      fi
      if [[ "$pause_menu_action" == "replay" ]]; then
        main_loop_action="replay"
        return 0
      fi
      clear
      draw
    fi
    ((tick_count += 1))
    local head_x=${snake_x[0]}
    local head_y=${snake_y[0]}
    read -r new_x new_y <<< "$(calc_next_head "$head_x" "$head_y" "$dir_x" "$dir_y" "$wrap_ticks")"
    last_dir_x=$dir_x
    last_dir_y=$dir_y
    if (( wrap_ticks <= 0 )) && is_out_of_bounds "$new_x" "$new_y"; then
      break
    fi
    is_snake_cell "$new_x" "$new_y" && break
    snake_x=("$new_x" "${snake_x[@]}")
    snake_y=("$new_y" "${snake_y[@]}")
    if [[ $new_x -eq $food_x && $new_y -eq $food_y ]]; then
      eat_food
      generate_food
      ((next_powerup_tick = tick_count + powerup_gap))
    else
      # Avoid negative-index unset edge cases under strict mode.
      local tail_index=$(( ${#snake_x[@]} - 1 ))
      if (( tail_index >= 0 )); then
        unset "snake_x[$tail_index]"
        unset "snake_y[$tail_index]"
      else
        break
      fi
      reset_chain
    fi
    if [[ $new_x -eq $powerup_item_x && $new_y -eq $powerup_item_y ]]; then
      activate_powerup "$powerup_item_type"
      powerup_item_type="none"
      powerup_item_x=-1
      powerup_item_y=-1
      ((score += 25))
      play_sfx powerup
    fi
    if ((speed_boost_ticks > 0)); then
      speed_boost_ticks=$((speed_boost_ticks - 1))
    fi
    if ((wrap_ticks > 0)); then
      wrap_ticks=$((wrap_ticks - 1))
    fi
    if [[ "$powerup_item_type" == "none" ]] && (( tick_count >= next_powerup_tick )); then
      spawn_powerup
    fi
    draw
    sleep "$(get_delay)"
  done
  play_sfx game_over
  game_over
  main_loop_action="$game_over_action"
}
