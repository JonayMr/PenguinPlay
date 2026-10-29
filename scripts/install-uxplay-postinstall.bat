@echo off
REM =============================================================================
REM PenguinPlay Post-Installation Script
REM This script automatically installs UxPlay and GStreamer after NSIS installation
REM =============================================================================

REM Define MSYS2 root directory
set MSYS2_ROOT=C:\msys64

REM Check if MSYS2 is installed
if not exist "%MSYS2_ROOT%\ucrt64\bin\pacman.exe" (
    echo [⚠️] MSYS2 is not installed on this system.
    echo Please install MSYS2 from https://www.msys2.org/
    echo The installer will not automatically install UxPlay without MSYS2.
    pause
    exit /b 1
)

REM Update MSYS2 environment
where msys2.exe >nul 2>&1
if %errorlevel% neq 0 (
    where msys2.exe >nul 2>&1
)

REM Try to find MSYS2 executable
set MSYS2_PATH=""
for %%i in ("C:\Program Files\msys64\msys2_shell.exe","C:\Program Files (x86)\msys64\msys2_shell.exe","C:\msys64\msys2_shell.exe") do (
    if exist "%%i" (
        set MSYS2_PATH=%%i
        goto found_msys2
    )
)

:found_msys2
REM Launch MSYS2 with UCRT environment
"%MSYS2_PATH%" -here -c "pacman -S --needed gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-libav"

REM Check if GStreamer was installed successfully
where gstreamer-1.0 >nul 2>&1
if %errorlevel% neq 0 (
    echo [❌] Failed to install GStreamer. Please install it manually from MSYS2.
    pause
    exit /b 1
)

REM Check if UxPlay is already installed
where uxplay.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo [✅] UxPlay is already installed.
    goto install_uxplay
)

:install_uxplay
REM Build UxPlay from source using MSYS2
REM This will clone the repository and build the binary

REM Check if git is available in MSYS2
"%MSYS2_ROOT%\ucrt64\bin\git.exe" --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [⚠️] Git is not available in MSYS2.
    echo Please install MSYS2 with all packages, or install UxPlay manually.
    pause
    exit /b 1
)

REM Clone UxPlay repository
"%MSYS2_ROOT%\ucrt64\bin\git.exe" clone --depth 1 https://github.com/FDH2/UxPlay.git "%TEMP%\uxplay_build"
if %errorlevel% neq 0 (
    echo [❌] Failed to clone UxPlay repository. Please check your internet connection.
    pause
    exit /b 1
)

REM Build UxPlay
cd "%TEMP%\uxplay_build"
"%MSYS2_ROOT%\ucrt64\bin\make.exe" -j$(nproc 2>$null || echo 4)
if %errorlevel% neq 0 (
    echo [❌] Failed to build UxPlay.
    pause
    exit /b 1
)

REM Copy UxPlay binary to MSYS2 bin directory
if exist "%TEMP%\uxplay_build\bin\uxplay.exe" (
    copy "%TEMP%\uxplay_build\bin\uxplay.exe" "%MSYS2_ROOT%\ucrt64\bin\uxplay.exe" >nul 2>&1
    echo [✅] UxPlay installed successfully.
) else (
    echo [❌] UxPlay binary not found at expected location.
    pause
    exit /b 1
)

REM Add MSYS2 bin directory to PATH
setx PATH "%PATH%;%MSYS2_ROOT%\ucrt64\bin" /M

echo [✅] Installation completed successfully!
echo [✅] You can now launch PenguinPlay from the Start Menu or desktop shortcut.
pause
