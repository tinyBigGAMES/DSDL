@echo off
setlocal
cd /d "%~dp0"

REM Check if DSDL.zip exists and delete it
if exist DSDL.zip (
    echo Deleting existing DSDL.zip...
    del DSDL.zip
)

REM Create a new archive
echo Creating new archive: DSDL.zip...
git archive --format=zip --output=DSDL.zip HEAD

echo Archive created successfully: DSDL.zip
endlocal
pause
