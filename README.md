# Super Snake (Terminal)

Super Snake is a fast terminal snake game with score tracking, timed powerups, a beat indicator, and ASCII game-over art.

<img width="361" height="394" alt="image" src="https://github.com/user-attachments/assets/ee7b8830-b9c2-4479-8169-d44c864e4fd6" />

## Requirements
- Windows with Git for Windows installed (for `bash.exe`), or any system with Bash.

## Start the game
- Windows: run `play.bat`
- Bash: run `./snake.sh`

## Controls
- Move up: `W` or `Up Arrow`
- Move down: `S` or `Down Arrow`
- Move left: `A` or `Left Arrow`
- Move right: `D` or `Right Arrow`
- Quit: `Q`

## How to play
- Eat food (`*`) to grow and increase score.
- Avoid hitting your own body.
- Avoid walls unless wrap mode is active.
- Collect powerups (`P`) for temporary bonuses.

## Scoring
- Food: `+10`
- Powerup: `+25`
- Chain count increases on consecutive food pickups.

## Powerups
- `speed`: faster movement for 40 ticks.
- `wrap`: pass through one wall and appear on the opposite side for 40 ticks.

## HUD
- `Score`: current points.
- `Speed`: `normal` or `boost`.
- `Wrap`: `off` or `on`.
- `Chain`: consecutive food streak.
- `Beat`: frame beat marker (`0..3`).

## Game over
On collision, the game clears the screen, shows centered ASCII game-over art with your final score, and waits for a keypress (or 8-second timeout).

## Sound effects
- Food pickup: short beep.
- Powerup pickup: double beep.
- Game over: triple beep.
- Disable sound: run with `SNAKE_SOUND=0 ./snake.sh`

## Automated tests
- Local: `./tests/test_features.sh`
- Runtime checks: `./tests/test_runtime.sh`
- CI: GitHub Actions workflow at `.github/workflows/test.yml`

## Crash logging
- Unexpected runtime errors are appended to `crash.log` in the project root.
- Each entry includes timestamp, exit code, line number, command, score, and tick.
