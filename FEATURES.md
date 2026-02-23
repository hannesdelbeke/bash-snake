# Super Snake Features

## Core gameplay
- Grid-based snake movement in four directions.
- Snake grows when food (`*`) is eaten.
- Self-collision ends the game.
- Wall collision ends the game unless wrap power is active.

## Controls
- Move: `W`, `A`, `S`, `D` or arrow keys.
- Quit: `Q`.
- 180-degree reversal is blocked to prevent instant self-collision.

## Beat and pulse
- A beat indicator is shown each frame (`Beat 0..3`).
- The beat updates every tick and can be used as the pulse reference for effects.

## Sound
- Uses terminal bell (`\a`) effects for gameplay feedback.
- Food pickup: single bell.
- Powerup pickup: double bell.
- Game over: triple bell.
- Config: set `SNAKE_SOUND=0` to disable.

## Powerups
- Powerup token: `P`.
- `speed` powerup:
  - Temporarily reduces tick delay (snake moves faster).
  - Duration: 40 ticks.
- `wrap` powerup:
  - Temporarily enables edge wrapping (exit one side, appear opposite side).
  - Duration: 40 ticks.
- Powerups spawn on a timer and never overlap snake or food.

## Scoring and chain
- Food gives `+10` points.
- Powerup pickup gives `+25` points.
- Chain counter increments on consecutive food pickups.
- Chain resets on non-food movement.

## Game over
- On death, screen clears and displays centered-style ASCII game-over art.
- Final score is shown under the art.

## Test coverage
The automated test suite (`tests/test_features.sh`) covers:
- Movement step calculation with and without wrap.
- Boundary detection.
- Food generation placement constraints.
- Scoring and chain behavior.
- Powerup spawn rules and timer setup.
- Speed and wrap powerup activation.
- Tick delay reduction when speed boost is active.

## Run locally
- From Windows: run `play.bat`.
- From Bash: `./snake.sh`.

## CI
- GitHub Actions workflow: `.github/workflows/test.yml`.
- Runs the Bash feature tests on every push and pull request.
