!include "MUI2.nsh"
!addincludedir "..\src"
!include "DotNetCore.nsh"

Name "DotNetCore Macro Test Script"
OutFile "testMacro.exe"

InstallDir "$LOCALAPPDATA\DotNetCore Test" 
InstallDirRegKey HKCU "Software\DotNetCore Test" ""

RequestExecutionLevel admin

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
 
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
  
!insertmacro MUI_LANGUAGE "English"

; -----------------------------------------------------------
;Installer Sections
; -----------------------------------------------------------

Section "Dummy Section" SecDummy

  SetOutPath "$INSTDIR"

; -----------------------------------------------------------
; DotNetCore
; -----------------------------------------------------------

  !insertmacro RuntimeGetLatestVersion "DotNetCore" 9.0 $0
  DetailPrint "Latest Version of DotNetCore 9.0 is $0"

  !insertmacro RuntimeGetInstalledVersion "DotNetCore" 9.0 $0
  DetailPrint "Installed Version of DotNetCore 9.0 is $0"

  !insertmacro CheckRuntime "DotNetCore" 9.0 ""

; -----------------------------------------------------------
; AspNetCore
; -----------------------------------------------------------

  !insertmacro RuntimeGetLatestVersion "AspNetCore" 9.0 $0
  DetailPrint "Latest Version of AspNetCore 9.0 is $0"

  !insertmacro RuntimeGetInstalledVersion "AspNetCore" 9.0 $0
  DetailPrint "Installed Version of AspNetCore 9.0 is $0"

  !insertmacro CheckRuntime "AspNetCore" 9.0 ""
  
; -----------------------------------------------------------
; WindowsDesktop
; -----------------------------------------------------------

  !insertmacro RuntimeGetLatestVersion "WindowsDesktop" 3.1 $0
  DetailPrint "Latest Version of WindowsDesktop 3.1 is $0"

  !insertmacro RuntimeGetInstalledVersion "WindowsDesktop" 3.1 $0
  DetailPrint "Installed Version of WindowsDesktop 3.1 is $0"

  !insertmacro RuntimeGetLatestVersion "WindowsDesktop" 9.0 $0
  DetailPrint "Latest Version of WindowsDesktop 9.0 is $0"

  !insertmacro RuntimeGetInstalledVersion "WindowsDesktop" 9.0 $0
  DetailPrint "Installed Version of WindowsDesktop 9.0 is $0"
   
  !insertmacro CheckRuntime "WindowsDesktop" 3.1 ""
  !insertmacro CheckRuntime "WindowsDesktop" 9.0 ""

; -----------------------------------------------------------
; Backwards Compatibility
; -----------------------------------------------------------

  !insertmacro DotNetCoreGetLatestVersion 6.0 $0
  DetailPrint "Latest Version of 6.0 is $0"

  !insertmacro DotNetCoreGetInstalledVersion 6.0 $0
  DetailPrint "Installed Version of 6.0 is $0"

  !insertmacro CheckDotNetCore 6.0

  !insertmacro AspNetCoreGetLatestVersion 6.0 $0
  DetailPrint "Latest Version of 6.0 is $0"

  !insertmacro AspNetCoreGetInstalledVersion 6.0 $0
  DetailPrint "Installed Version of 6.0 is $0"

  !insertmacro CheckAspNetCore 6.0

  WriteRegStr HKCU "Software\DotNetCore Test" "" $INSTDIR
  WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

Section "Uninstall"

  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  DeleteRegKey /ifempty HKCU "Software\DotNetCore Test"
SectionEnd
