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

;--------------------------------
;Installer Sections

Section "Dummy Section" SecDummy

  SetOutPath "$INSTDIR"

  !insertmacro DotNetCoreGetLatestVersion 3.1 $0
  DetailPrint "Latest Version of 3.1 is $0"

  !insertmacro DotNetCoreGetInstalledVersion 3.1 $0
  DetailPrint "Installed Version of 3.1 is $0"

  !insertmacro DotNetCoreGetLatestVersion 5.0 $0
  DetailPrint "Latest Version of 5.0 is $0"

  !insertmacro DotNetCoreGetInstalledVersion 5.0 $0
  DetailPrint "Installed Version of 5.0 is $0"

  !insertmacro DotNetCoreGetLatestVersion 6.0 $0
  DetailPrint "Latest Version of 6.0 is $0"

  !insertmacro DotNetCoreGetInstalledVersion 6.0 $0
  DetailPrint "Installed Version of 6.0 is $0"

  !insertmacro CheckDotNetCore 3.1
  !insertmacro CheckDotNetCore 5.0
  !insertmacro CheckDotNetCore 6.0
  
  
  !insertmacro AspNetCoreGetLatestVersion 3.1 $0
  DetailPrint "Latest Version of 3.1 is $0"

  !insertmacro AspNetCoreGetInstalledVersion 3.1 $0
  DetailPrint "Installed Version of 3.1 is $0"

  !insertmacro AspNetCoreGetLatestVersion 5.0 $0
  DetailPrint "Latest Version of 5.0 is $0"

  !insertmacro AspNetCoreGetInstalledVersion 5.0 $0
  DetailPrint "Installed Version of 5.0 is $0"

  !insertmacro AspNetCoreGetLatestVersion 6.0 $0
  DetailPrint "Latest Version of 6.0 is $0"

  !insertmacro AspNetCoreGetInstalledVersion 6.0 $0
  DetailPrint "Installed Version of 6.0 is $0"
   
  !insertmacro CheckAspNetCore 3.1
  !insertmacro CheckAspNetCore 5.0
  !insertmacro CheckAspNetCore 6.0

  WriteRegStr HKCU "Software\DotNetCore Test" "" $INSTDIR
  WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd

Section "Uninstall"

  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  DeleteRegKey /ifempty HKCU "Software\DotNetCore Test"
SectionEnd
