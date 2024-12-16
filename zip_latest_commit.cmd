
@echo off
setlocal
cd /d "%~dp0"

git archive --format=zip --output=DSDL.zip HEAD

endlocal
pause
