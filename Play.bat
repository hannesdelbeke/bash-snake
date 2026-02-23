@echo off
setlocal
"%ProgramFiles%\Git\bin\bash.exe" -lc "cd /d/repos/bash-snake && chmod +x snake.sh && ./snake.sh"
endlocal
