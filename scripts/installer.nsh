; =============================================================================
; PenguinPlay Windows Installer - NSIS Script
; This script automatically installs UxPlay and GStreamer during installation
; =============================================================================

!include "MUI2.nsh"
!include "LogicLib.nsh"

; Define installation directories
!define MUI_ABORTWARNING 1

; Set output directory
OutFile "PenguinPlay-Setup-${PRODUCT_VERSION}.exe"

; Set default installation directory
InstallDir "$PROGRAMFILES\PenguinPlay"
InstallDirRegKey "HKEY_LOCAL_MACHINE" "SOFTWARE\PenguinPlay" "InstallDir"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "PenguinPlay.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Language
RequestExecutionLevel user

; Initialize the installer
Section "PenguinPlay Installer" SecInstall

  ; Set registry key for installation directory
  WriteRegStr HKLM "SOFTWARE\PenguinPlay" "InstallDir" "$INSTDIR"

  ; Extract files
  SetOverwrite 1
  ; This would extract the application files
  ; The extraction is handled by electron-builder

  ; =============================================================================
  ; UxPlay and GStreamer Automatic Installation
  ; =============================================================================
  
  ; Main installation logic
  ; This section runs after file extraction

  ; Check if MSYS2 is installed
  FileExists "$MSYS2_ROOT\ucrt64\bin\pacman.exe"
  IfFileExists "$MSYS2_ROOT\ucrt64\bin\pacman.exe", +2
  
  ; MSYS2 not installed, show message
  MessageBox MB_OK|MB_ICONINFORMATION "MSYS2 is not installed.\n\nPlease install MSYS2 from https://www.msys2.org/\n\nThe installer will not automatically install UxPlay without MSYS2." IDOK
  Goto SkipUxPlayInstall

  ; MSYS2 installed, proceed with installation
  
  ; Update MSYS2 environment
  ExecShell "run" "$MSYS2_ROOT\ucrt64\bin\pacman.exe" "-Syu"
  
  ; Check if GStreamer is installed
  Exec "$MSYS2_ROOT\ucrt64\bin\gstreamer-1.0" >nul 2>&1
  IfErrorLevel 0
    ; GStreamer is installed
    Goto SkipGStreamerInstall
  
  ; GStreamer not installed, install it
  Exec "$MSYS2_ROOT\ucrt64\bin\pacman.exe" "-S --needed gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-libav"
  
  SkipGStreamerInstall:
  
  ; Check if UxPlay is installed
  FileExists "$MSYS2_ROOT\ucrt64\bin\uxplay.exe"
  IfFileExists "$MSYS2_ROOT\ucrt64\bin\uxplay.exe", +2
  
  ; UxPlay not installed, install it
  ; We'll build UxPlay from source or download pre-built binary
  
  ; For now, we'll use MSYS2 to build UxPlay
  Exec "$MSYS2_ROOT\ucrt64\bin\git.exe" "clone --depth 1 https://github.com/FDH2/UxPlay.git"
  Exec "$MSYS2_ROOT\ucrt64\bin\make.exe" -C "UxPlay" -j$(nproc 2>$null || echo 4)
  
  ; Copy UxPlay binary to MSYS2 bin directory
  CopyFiles "$INSTDIR\UxPlay\bin\uxplay.exe" "$MSYS2_ROOT\ucrt64\bin\uxplay.exe"

  SkipUxPlayInstall:

  SectionEnd

; End of installation section

; =============================================================================
; Post-Installation Script
; This script is executed after the main installation to install UxPlay and GStreamer
; =============================================================================

; Function to execute post-installation script
Function .onInitPostInstall
  ; Check if MSYS2 is installed
  FileExists "$MSYS2_ROOT\ucrt64\bin\pacman.exe"
  IfFileExists "$MSYS2_ROOT\ucrt64\bin\pacman.exe", +2
  
  ; MSYS2 not installed, show message
  MessageBox MB_OK|MB_ICONINFORMATION "MSYS2 is not installed.\n\nPlease install MSYS2 from https://www.msys2.org/\n\nThe installer will not automatically install UxPlay without MSYS2." IDOK
  Return

  ; MSYS2 installed, proceed with installation
  
  ; Update MSYS2 environment
  ExecShell "run" "$MSYS2_ROOT\ucrt64\bin\pacman.exe" "-Syu"
  
  ; Check if GStreamer is installed
  Exec "$MSYS2_ROOT\ucrt64\bin\gstreamer-1.0" >nul 2>&1
  IfErrorLevel 0
    ; GStreamer is installed
    Goto SkipGStreamerInstall
  
  ; GStreamer not installed, install it
  Exec "$MSYS2_ROOT\ucrt64\bin\pacman.exe" "-S --needed gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-libav"
  
  SkipGStreamerInstall:
  
  ; Check if UxPlay is installed
  FileExists "$MSYS2_ROOT\ucrt64\bin\uxplay.exe"
  IfFileExists "$MSYS2_ROOT\ucrt64\bin\uxplay.exe", +2
  
  ; UxPlay not installed, install it
  
  ; Clone UxPlay repository
  Exec "$MSYS2_ROOT\ucrt64\bin\git.exe" "clone --depth 1 https://github.com/FDH2/UxPlay.git "$INSTDIR\UxPlay"
  
  ; Build UxPlay
  cd "$INSTDIR\UxPlay"
  Exec "$MSYS2_ROOT\ucrt64\bin\make.exe" -j$(nproc 2>$null || echo 4)
  
  ; Copy UxPlay binary to MSYS2 bin directory
  CopyFiles "$INSTDIR\UxPlay\bin\uxplay.exe" "$MSYS2_ROOT\ucrt64\bin\uxplay.exe"

FunctionEnd

; Hook the post-install function
!insertmacro MUI_FUNCTION_LICENSE "MUI_FUNCTION_FIRST" 0
!insertmacro MUI_PAGE_CUSTOMFUNCTION_PRE .onInitPostInstall
!insertmacro MUI_PAGE_CUSTOMFUNCTION_LEAVE .onInitPostInstall
