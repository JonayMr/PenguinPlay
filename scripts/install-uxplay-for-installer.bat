@echo off
REM UxPlay Installation Script for PenguinPlay Windows Installer
REM This script installs UxPlay and GStreamer automatically

setlocal EnableDelayedExpansion

REM Configuration
set "MSYS2_ROOT=C:\msys64"
set "UCRT64_BIN=%MSYS2_ROOT%\ucrt64\bin"
set "MINGW64_BIN=%MSYS2_ROOT%\mingw64\bin"
set "UXPLAY_EXE=%MSYS2_ROOT%\ucrt64\bin\uxplay.exe"

REM Check if MSYS2 is installed
:check_msys2
powershell -Command "Test-Path -Path '%MSYS2_ROOT%\ucrt64\bin\pacman.exe' -PathType File -ErrorAction SilentlyContinue"
if %errorlevel% equ 0 (
    echo MSYS2 found at %MSYS2_ROOT%
    goto :update_msys2
)

:msys2_not_installed
echo MSYS2 not found. Please install MSYS2 first from https://www.msys2.org/
echo.
echo To install MSYS2:
echo 1. Download MSYS2 from https://www.msys2.org/
echo 2. Run the installer
echo 3. Open MSYS2 UCRT64 terminal
echo.
echo You can skip this step if MSYS2 is already installed.
pause
exit /b 1

:update_msys2
echo Updating MSYS2 environment...
powershell -Command "& '%MSYS2_ROOT%\ucrt64\bin\pacman.exe' -Syu"

REM Check if GStreamer is installed
:check_gstreamer
echo Checking for GStreamer...
powershell -Command "Test-Path -Path '%MSYS2_ROOT%\ucrt64\bin\gstreamer-1.0' -PathType File -ErrorAction SilentlyContinue"
if %errorlevel% equ 0 (
    echo GStreamer found at %MSYS2_ROOT%
    goto :check_uxplay
)

:install_gstreamer
echo Installing GStreamer and dependencies...
powershell -Command "& '%MSYS2_ROOT%\ucrt64\bin\pacman.exe' -S --needed gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-libav"

REM Check if UxPlay is installed
:check_uxplay
echo Checking for UxPlay...
powershell -Command "Test-Path -Path '%UXPLAY_EXE' -PathType File -ErrorAction SilentlyContinue"
if %errorlevel% equ 0 (
    echo UxPlay already installed at %UXPLAY_EXE%
    goto :complete
)

:install_uxplay
echo Installing UxPlay...
powershell -Command "& '%MSYS2_ROOT%\ucrt64\bin\pacman.exe' -S --needed git cmake gcc pkgconf openssl libplist avahi gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-libav && curl -fsSLo '%MSYS2_ROOT%\ucrt64\bin\uxplay.exe' 'https://raw.githubusercontent.com/JonayMr/UxPlay/main/bin/uxplay.exe'"

:complete
echo.
echo === UxPlay Installation Summary ===
echo UxPlay installed at: %UXPLAY_EXE%
echo GStreamer installed at: %MSYS2_ROOT%
echo PATH updated to include: %MSYS2_ROOT%\ucrt64\bin
echo.
echo You can now use PenguinPlay without additional installation steps.
echo.
echo To run PenguinPlay, double-click the PenguinPlay shortcut in Start Menu.
echo.

REM Add UxPlay to system PATH
setx PATH "%MSYS2_ROOT%\ucrt64\bin;%PATH%" /M

REM Display completion message
echo Installation completed successfully!
pause
exit /b 0
