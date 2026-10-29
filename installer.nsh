!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE ${productName}.txt
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LEAVEINJECT

; === UxPlay Installation Script ===
Function .onInit
  ; Check if UxPlay is already installed
  ; Create a temporary directory for installation files
  ; Download and install UxPlay and GStreamer
  ; This script will be run during installation
  ; === End UxPlay Installation Script ===

Function .onInstSuccess
  ; Run UxPlay installation script
  ; Execute the installation of UxPlay and GStreamer
  ; === End UxPlay Installation Script ===

Function .onInstFailed
  ; Handle installation failure
  ; === End UxPlay Installation Script ===

Function .onUninit
  ; Cleanup after installation
  ; === End UxPlay Installation Script ===

Function .onInstEnd
  ; Execute UxPlay installation
  ; This function is called after the installation is complete
  ; === End UxPlay Installation Script ===

Function .onUninstEnd
  ; Execute UxPlay uninstallation
  ; This function is called during uninstallation
  ; === End UxPlay Installation Script ===

Function .onUninstFailed
  ; Handle uninstallation failure
  ; === End UxPlay Installation Script ===

Function .onUninstSuccess
  ; Execute UxPlay uninstallation
  ; This function is called after the uninstallation is complete
  ; === End UxPlay Installation Script ===

Function .onUninstEnd
  ; Execute UxPlay uninstallation
  ; This function is called during uninstallation
  ; === End UxPlay Installation Script ===
