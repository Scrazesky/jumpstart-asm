@echo off
REM ============================================================
REM  JumpStart ASM — Build Script (NASM + GoLink)
REM  Run from project root: build\build.bat
REM ============================================================

echo.
echo  ======================================
echo   JumpStart Learning Adventures
echo   NASM + GoLink Build System
echo  ======================================
echo.

REM ---- Paths (adjust these if your tools are elsewhere) ----
set NASM=nasm
set GOLINK=GoLink

REM ---- Directories ----
set SRC=..\src
set OUT=..\build

REM ---- Assemble ----
echo [1/2] Assembling game.asm ...
%NASM% -f win32 -o %OUT%\game.obj %SRC%\game.asm
if errorlevel 1 (
    echo.
    echo  ERROR: Assembly failed. Check syntax.
    pause
    exit /b 1
)
echo       OK  game.obj created

REM ---- Link ----
echo [2/2] Linking with GoLink ...
%GOLINK% /entry _WinMain@16 /console %OUT%\game.obj ^
    kernel32.dll user32.dll gdi32.dll
if errorlevel 1 (
    echo.
    echo  ERROR: Linking failed. Are GoLink and DLLs accessible?
    pause
    exit /b 1
)

REM GoLink produces game.exe in current directory; move to build/
if exist game.exe move /Y game.exe %OUT%\game.exe >nul

echo Copying audio files ...
copy /Y "..\Music Jumpy\*.wav" "%OUT%\" >nul

echo Copying background images ...
copy /Y "..\Backgrounds\*.bmp" "%OUT%\" >nul

echo.
echo  ======================================
echo   BUILD SUCCESSFUL!
echo   Output: build\game.exe
echo  ======================================
echo.
echo  Run with:  build\game.exe
echo  Controls:  Arrow keys to move, Space to jump
echo             ESC to return to title
echo.
pause
