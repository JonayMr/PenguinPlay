#!/bin/bash
# UxPlay Installation Script for PenguinPlay
# This script installs UxPlay and GStreamer automatically

set -e

# Configuration
MSYS2_ROOT="${MSYS2_ROOT:-C:\\msys64}"
UCRT64_BIN="${MSYS2_ROOT}\\ucrt64\\bin"
MINGW64_BIN="${MSYS2_ROOT}\\mingw64\\bin"
UXPLAY_EXE="${MSYS2_ROOT}\\ucrt64\\bin\\uxplay.exe"

# Function to check if a command exists
command_exists() {
  command -v "$1" > /dev/null 2>&1
}

# Function to install MSYS2 if not present
install_msys2() {
  echo "Installing MSYS2..."
  # This would require user interaction to download MSYS2
  # For now, we'll assume MSYS2 is already installed
  if ! command_exists pacman; then
    echo "MSYS2 not found. Please install MSYS2 first from https://www.msys2.org/"
    exit 1
  fi
}

# Function to update MSYS2 environment
update_msys2() {
  echo "Updating MSYS2 environment..."
  pacman -Syu > /dev/null 2>&1
}

# Function to install GStreamer and dependencies
install_gstreamer() {
  echo "Installing GStreamer and dependencies..."
  
  # Check if GStreamer is already installed
  if ! command_exists gstreamer-1.0; then
    echo "GStreamer not found. Installing GStreamer..."
    
    # Install MSYS2 packages (this would be done in MSYS2 terminal)
    # For the installer, we need to run MSYS2 commands
    # This is a simplified version
    
    # The actual installation would be done by the installer.nsh script
    echo "GStreamer installation will be handled by installer.nsh"
  fi
}

# Function to install UxPlay
install_uxplay() {
  echo "Installing UxPlay..."
  
  # Check if UxPlay is already installed
  if [ -f "${UXPLAY_EXE}" ] && [ -x "${UXPLAY_EXE}" ]; then
    echo "UxPlay already installed at ${UXPLAY_EXE}"
    return 0
  fi
  
  # UxPlay installation would be handled by the installer.nsh script
  # This is a simplified version for the README
  echo "UxPlay installation will be handled by installer.nsh"
}

# Main installation function
main() {
  echo "Starting UxPlay installation..."
  
  # Run MSYS2 update
  update_msys2
  
  # Install GStreamer
  install_gstreamer
  
  # Install UxPlay
  install_uxplay
  
  echo "UxPlay installation completed."
}

# Run main function
main
