; A set of NSIS macros to check whether a dotnet core runtime is installed and, if not, offer to
; download and install it. Supports dotnet versions 3.1 and newer - latest tested version is 7.0.
;
; Inspired by & initially based on NsisDotNetChecker, which does the same thing for .NET framework
; https://github.com/alex-sitnikov/NsisDotNetChecker

!include "WordFunc.nsh"
!include "TextFunc.nsh"
!include "X64.nsh"

!ifndef DOTNETCORE_INCLUDED
!define DOTNETCORE_INCLUDED

;------------------------------------------------------------------------------------------------------
; Main Macro Section
;------------------------------------------------------------------------------------------------------

; Check that a specific version of a specified runtime is installed and, if not, attempts to
; install it
;
; \param Runtime Define the desired runtime. Allowed are 'DotNetCore', 'AspNetCore' and 'WindowsDesktop'
; \param Version The desired dotnet core runtime version as a 2 digit version. e.g. 3.1, 6.0, 7.0
!macro CheckRuntime Runtime Version Platform

	; Save registers
	Push $R0
	Push $R1
	Push $R2
	Push $R3

	; Push and pop parameters so we don't have conflicts if parameters are $R#
	Push ${Runtime}
	Pop $R0 ; Runtime
	Push ${Version}
	Pop $R1 ; Version
	Push `${Platform}`
	Pop $R2 ; Platform

	${Switch} $R0
		${Case} 'DotNetCore'
		${Case} 'AspNetCore'
		${Case} 'WindowsDesktop'
			DetailPrint 'Run check for runtime of $R0'
			${Break}
		${Default}
			DetailPrint "Runtime is not defined correctly in CheckRuntime. 'DotNetCore', 'AspNetCore' or 'WindowsDesktop' expected. Found: $0"
			Abort
			${Break}
	${EndSwitch}

	!define ID ${__LINE__}

	; Check current installed version
	!insertmacro RuntimeGetInstalledVersion $R0 $R1 $R3

	; If $R3 is blank then there is no version installed, otherwise it is installed
	; todo in future we might want to support "must be at least 6.0.7", for now we only deal with "yes/no" for a major version (e.g. 6.0)
	StrCmp $R3 "" notinstalled_${ID}
	DetailPrint "$R0 version $R3 already installed"
	Goto end_${ID}

	notinstalled_${ID}:
	DetailPrint "$R0 $R1 is not installed"

	!insertmacro RuntimeGetLatestVersion $R0 $R1 $R3
	DetailPrint "Latest Version of $R0 $R1 is $R3"

	!insertmacro RuntimeInstallVersion $R0 $R3 $R2

	end_${ID}:
	!undef ID

	; Restore registers
	Pop $R3
	Pop $R2
	Pop $R1
	Pop $R0

!macroend

; Gets the latest version of the runtime for a specified dotnet version. This uses the same endpoint
; as the dotnet-install scripts to determine the latest full version of a dotnet version
;
; \param[in] Runtime Define the desired runtime. Allowed are 'DotNetCore', 'AspNetCore' and 'WindowsDesktop'
; \param[in] Version The desired runtime version as a 2 digit version. e.g. 3.1, 6.0, 7.0
; \param[out] Result The full version number of the latest version - e.g. 6.0.7
!macro RuntimeGetLatestVersion Runtime Version Result

	; Save registers
	Push $R0
	Push $R1
	Push $R2
	Push $R3

	; Push and pop parameters so we don't have conflicts if parameters are $R#
	Push ${Runtime}
	Pop $R0 ; Runtime
	Push ${Version}
	Pop $R1 ; Version

	${Switch} $R0
		${Case} 'DotNetCore'
			StrCpy $R2 https://dotnetcli.azureedge.net/dotnet/Runtime/$R1/latest.version
			${Break}
		${Case} 'AspNetCore'
			StrCpy $R2 https://dotnetcli.azureedge.net/dotnet/aspnetcore/Runtime/$R1/latest.version
			${Break}
		${Case} 'WindowsDesktop'
			StrCpy $R2 https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/$R1/latest.version
			${Break}
		${Default}
			DetailPrint "Runtime is not defined correctly in RuntimeGetLatestVersion. 'DotNetCore', 'AspNetCore' or 'WindowsDesktop' expected. Found: $0"
			Abort
			${Break}
	${EndSwitch}
	
	DetailPrint "Querying latest version of $R0 $R1 from $R2"

	; Fetch latest version of the desired dotnet version
	; todo error handling in the PS script? so we can check for errors here
	StrCpy $R3 "Write-Host (Invoke-WebRequest -UseBasicParsing -URI $\"$R2$\").Content;"
	!insertmacro ExecPSScript $R3 $R3
	; $R3 contains latest version, e.g. 6.0.7

	; todo error handling here

	; Push the result onto the stack
	${TrimNewLines} $R3 $R3
	Push $R3

	; Restore registers
	Exch
	Pop $R3
	Exch
	Pop $R2
	Exch
	Pop $R1
	Exch
	Pop $R0

	; Set result
	Pop ${Result}

!macroend

; Gets the currently installed version of the runtime for a specified dotnet version. This uses the dotnet executable
; as the dotnet-install scripts do to determine the latest installed version
;
; \param[in] Runtime Define the desired runtime. Allowed are 'DotNetCore', 'AspNetCore' and 'WindowsDesktop'
; \param[in] Version The desired runtime version as a 2 digit version. e.g. 3.1, 6.0, 7.0
; \param[out] Result The full version number of the latest version - e.g. 6.0.7
!macro RuntimeGetInstalledVersion Runtime Version Result
	!define DNC_INS_ID ${__LINE__}

	; Save registers
	Push $R0
	Push $R1
	Push $R2
	Push $R3

	; Push and pop parameters so we don't have conflicts if parameters are $R#
	Push ${Runtime}
	Pop $R0 ; Runtime
	Push ${Version}
	Pop $R1 ; Version

	${Switch} $R0
		${Case} 'DotNetCore'
			StrCpy $R2 "dotnet --list-runtimes | % { if($$_ -match $\".*NETCore.*($R1.\d+).*$\") { $$matches[1] } } | Sort-Object {[int]($$_ -replace '\d.\d.(\d+)', '$$1')} -Descending | Select-Object -first 1"
			${Break}
		${Case} 'AspNetCore'
			StrCpy $R2 "dotnet --list-runtimes | % { if($$_ -match $\".*AspNet.*($R1.\d+).*$\") { $$matches[1] } } | Sort-Object {[int]($$_ -replace '\d.\d.(\d+)', '$$1')} -Descending | Select-Object -first 1"
			${Break}
		${Case} 'WindowsDesktop'
			StrCpy $R2 "dotnet --list-runtimes | % { if($$_ -match $\".*WindowsDesktop.*($R1.\d+).*$\") { $$matches[1] } } | Sort-Object {[int]($$_ -replace '\d.\d.(\d+)', '$$1')} -Descending | Select-Object -first 1"
			${Break}
		${Default}
			DetailPrint "Runtime is not defined correctly in RuntimeGetInstalledVersion. 'DotNetCore', 'AspNetCore' or 'WindowsDesktop' expected. Found: $0"
			Abort
			${Break}
	${EndSwitch}

	DetailPrint "Checking installed version of $R0 $R1"

	!insertmacro ExecPSScript $R2 $R2
	; $R2 contains highest installed version, e.g. 6.0.7

	${TrimNewLines} $R2 $R2

	; If there is an installed version it should start with the same two "words" as the input version,
	; otherwise assume we got an error response

	; todo improve this simple test which checks there are at least 3 "words" separated by periods
	${WordFind} $R2 "." "E#" $R3
	IfErrors error_${DNC_INS_ID}
	; $R3 contains number of version parts in R2 (dot separated words = version parts)

	; If less than 3 parts, or more than 4 parts, error
	IntCmp $R3 3 0 error_${DNC_INS_ID}
	IntCmp $R3 4 0 0 error_${DNC_INS_ID}

	; todo more error handling here / validation

	; Seems to be OK, skip the "set to blank string" error handler
	Goto end_${DNC_INS_ID}

	error_${DNC_INS_ID}:
	StrCpy $R2 "" ; Set result to blank string if any error occurs (means not installed)

	end_${DNC_INS_ID}:
	!undef DNC_INS_ID

	; Push the result onto the stack
	Push $R2

	; Restore registers
	Exch
	Pop $R3
	Exch
	Pop $R2
	Exch
	Pop $R1
	Exch
	Pop $R0

	; Set result
	Pop ${Result}

!macroend

; Downloads a specific version of a runtime.
;
; \param Runtime Define the desired runtime. Allowed are 'DotNetCore', 'AspNetCore' and 'WindowsDesktop'
; \param Version The desired full version as a 3 digit version. e.g. 3.1.32, 6.0.12, 7.0.0
; \param Platform Specifies the desired platform of the installer. Allowed are 'x86', 'x64' and 'arm64'. If this parameter is "", the platform is determined by the installer
!macro RuntimeInstallVersion Runtime Version Platform

	; Save registers
	Push $R0
	Push $R1
	Push $R2
	Push $R3
	Push $R4

	; Push and pop parameters so we don't have conflicts if parameters are $R#
	Push ${Runtime}
	Pop $R0 ; Runtime
	Push ${Version}
	Pop $R1 ; Version
	Push `${Platform}`
	Pop $R4 ; Platform

	${Switch} $R4
		${Case} 'x86'
		${Case} 'x64'
		${Case} 'arm64'
			DetailPrint "Specified platform is $R4"
			${Break}
		${Default}
			DetailPrint "Platform not specified. Check current platform"
			${If} ${IsNativeAMD64}
				StrCpy $R4 "x64"
			${ElseIf} ${IsNativeARM64}
				StrCpy $R4 "arm64"
			${ElseIf} ${IsNativeIA32}
				StrCpy $R4 "x86"
			${Else}
				StrCpy $R4 "unknown"
			${EndIf}
			${Break}
	${EndSwitch}

	${Switch} $R0
		${Case} 'DotNetCore'
			; todo can download as a .zip, which is smaller, then we'd need to unzip it before running it...
			StrCpy $R2 https://dotnetcli.azureedge.net/dotnet/Runtime/$R1/dotnet-runtime-$R1-win-$R4.exe
			${Break}
		${Case} 'AspNetCore'
			; todo can download as a .zip, which is smaller, then we'd need to unzip it before running it...
			StrCpy $R2 https://dotnetcli.azureedge.net/dotnet/aspnetcore/Runtime/$R1/dotnet-hosting-$R1-win.exe
			${Break}
		${Case} 'WindowsDesktop'
			; todo can download as a .zip, which is smaller, then we'd need to unzip it before running it...
			StrCpy $R2 https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/$R1/windowsdesktop-runtime-$R1-win-$R4.exe

			; For dotnet versions less than 5 the WindowsDesktop runtime has a different path
			${WordFind} $R1 "." "+1" $R3
			IntCmp $R3 5 +2 0 +2
			StrCpy $R2 https://dotnetcli.azureedge.net/dotnet/Runtime/$R1/windowsdesktop-runtime-$R1-win-$R4.exe
			${Break}
		${Default}
			DetailPrint "Runtime is not defined correctly in RuntimeInstallVersion. 'DotNetCore', 'AspNetCore' or 'WindowsDesktop' expected. Found: $0"
			Abort
			${Break}
	${EndSwitch}

	DetailPrint "Downloading $R0 runtime $R1 for $R4 from $R2"

	; Create destination file
	GetTempFileName $R3
	nsExec::Exec 'cmd.exe /c rename "$R3" "$R3.exe"'	; Not using Rename to avoid spam in details log
	Pop $R4 ; Pop exit code
	StrCpy $R3 "$R3.exe"
	
	; Fetch runtime installer
	; todo error handling in the PS script? so we can check for errors here
	StrCpy $R2 "Invoke-WebRequest -UseBasicParsing -URI $\"$R2$\" -OutFile $\"$R3$\""
	!insertmacro ExecPSScript $R2 $R2
	; $R2 contains powershell script result

	${WordFind} $R2 "BlobNotFound " "E+1{" $R4
	ifErrors +3 0
	DetailPrint "$R0 runtime installer $R1 not found."
	Goto +10

	; todo error handling for PS result, verify download result

	IfFileExists $R3 +3, 0
	DetailPrint "$R0 runtime installer did not download."
	Goto +7

	DetailPrint "Download complete"

	DetailPrint "Installing $R0 runtime $R1"
	ExecWait "$\"$R3$\" /install /quiet /norestart" $R2
	DetailPrint "Installer completed (Result: $R2)"

	nsExec::Exec 'cmd.exe /c del "$R3"'	; Not using Delete to avoid spam in details log
	Pop $R4 ; Pop exit code

	; Error checking? Verify install result?

	; Restore registers
	Pop $R4
	Pop $R3
	Pop $R2
	Pop $R1
	Pop $R0

!macroend

;------------------------------------------------------------------------------------------------
; Backwards compatibility Section
;------------------------------------------------------------------------------------------------

; DEPRICATED
; Backwards compatible macro for the WindowsDesktop runtime
;
; \param Version The desired dotnet core runtime version as a 2 digit version. e.g. 3.1, 6.0, 7.0
!macro CheckDotNetCore Version
	!insertmacro CheckRuntime "WindowsDesktop" ${Version} ""
!macroend

; DEPRICATED
; Backwards compatible macro for the AspNetCore runtime
;
; \param Version The desired dotnet core runtime version as a 2 digit version. e.g. 3.1, 6.0, 7.0
!macro CheckAspNetCore Version
	!insertmacro CheckRuntime "AspNetCore" ${Version} ""
!macroend

; DEPRICATED
; Backwards compatible macro to get latest WindowsDesktop runtime version
;
; \param[in] Version The desired dotnet core runtime version as a 2 digit version. e.g. 3.1, 6.0, 7.0
; \param[out] Result The full version number of the latest version - e.g. 6.0.7
!macro DotNetCoreGetLatestVersion Version Result
	; Save registers
	Push $R0

	!insertmacro RuntimeGetLatestVersion "WindowsDesktop" ${Version} $R0

	; Push the result onto the stack
	Push $R0

	; Restore registers
	Exch
	Pop $R0

	; Set result
	Pop ${Result}
!macroend

; DEPRICATED
; Backwards compatible macro to get latest AspNetCore runtime version
;
; \param[in] Version The desired dotnet core runtime version as a 2 digit version. e.g. 3.1, 6.0, 7.0
; \param[out] Result The full version number of the latest version - e.g. 6.0.7
!macro AspNetCoreGetLatestVersion Version Result
	; Save registers
	Push $R0

	!insertmacro RuntimeGetLatestVersion 'AspNetCore' ${Version} $R0

	; Push the result onto the stack
	Push $R0

	; Restore registers
	Exch
	Pop $R0

	; Set result
	Pop ${Result}
!macroend

; DEPRICATED
; Backwards compatible macro to get the currently installed WindowsDesktop runtime version
;
; \param[in] Version The desired dotnet core runtime version as a 2 digit version. e.g. 3.1, 6.0, 7.0
; \param[out] Result The full version number of the latest version - e.g. 6.0.7
!macro DotNetCoreGetInstalledVersion Version Result
	; Save registers
	Push $R0

	!insertmacro RuntimeGetInstalledVersion "WindowsDesktop" ${Version} $R0

	; Push the result onto the stack
	Push $R0

	; Restore registers
	Exch
	Pop $R0

	; Set result
	Pop ${Result}
!macroend

; DEPRICATED
; Backwards compatible macro to get the currently installed AspNetCore runtime version
;
; \param[in] Version The desired dotnet core runtime version as a 2 digit version. e.g. 3.1, 6.0, 7.0
; \param[out] Result The full version number of the latest version - e.g. 6.0.7
!macro AspNetCoreGetInstalledVersion Version Result
	; Save registers
	Push $R0

	!insertmacro RuntimeGetInstalledVersion "AspNetCore" ${Version} $R0

	; Push the result onto the stack
	Push $R0

	; Restore registers
	Exch
	Pop $R0

	; Set result
	Pop ${Result}
!macroend

; DEPRICATED
; Backwards compatible macro to install a certain WindowsDesktop runtime version
;
; \param Version The desired dotnet core runtime version as a 2 digit version. e.g. 3.1, 6.0, 7.0
!macro DotNetCoreInstallVersion Version
	!insertmacro RuntimeInstallVersion "WindowsDesktop" ${Version} ""
!macroend

; DEPRICATED
; Backwards compatible macro to install a certain AspNetCore runtime version
;
; \param Version The desired dotnet core runtime version as a 2 digit version. e.g. 3.1, 6.0, 7.0
!macro AspNetCoreInstallVersion Version
	!insertmacro RuntimeInstallVersion "AspNetCore" ${Version} ""
!macroend

;-------------------------------------------------------------------------------------------------
; Helper Macros and Functions
;-------------------------------------------------------------------------------------------------

; Below is adapted from https://nsis.sourceforge.io/PowerShell_support but avoids using the plugin
; directory in favour of a temp file and providing a return variable rather than returning on the
; stack. Methods renamed to avoid conflicting with use of the original macros

; ExecPSScript
; Executes a powershell script
;
; \param[in] PSCommand The powershell command or script to execute
; \param[out] Result The output from the powershell script
!macro ExecPSScript PSCommand Result

	Push ${PSCommand}
	Call ExecPSScriptFn
	Pop ${Result}

!macroend

; ExecPSScriptFile
; Executes a powershell file
;
; \param[in] FilePath The path to the powershell script file to execute
; \param[out] Result The output from the powershell script
!macro ExecPSScriptFile FilePath Result

	Push ${FilePath}
	Call ExecPSScriptFileFn
	Pop ${Result}

!macroend

Function ExecPSScriptFn

	; Read parameters and save registers
	Exch $R0	; Script
	Push $R1
	Push $R2

	; Write the command into a temp file
	; Note: Using GetTempFileName to get a temp file name, but since we need to have a .ps1 extension
	; on the end we rename it with an extra file extension
	GetTempFileName $R1
	nsExec::Exec 'cmd.exe /c rename "$R1" "$R1.ps1"'	; Not using Rename to avoid spam in details log
	Pop $R2 ; Pop exit code
	StrCpy $R1 "$R1.ps1"

	FileOpen $R2 $R1 w
	FileWrite $R2 $R0
	FileClose $R2

	; Execute the powershell script and delete the temp file
	Push $R1
	Call ExecPSScriptFileFn
	nsExec::Exec 'cmd.exe /c del "$R1"'	; Not using Delete to avoid spam in details log
	Pop $R0 ; Pop exit code

	; Restore registers
	Exch
	Pop $R2
	Exch
	Pop $R1
	Exch
	Pop $R0

	; Stack contains script output only, which we leave as the function result

FunctionEnd

Function ExecPSScriptFileFn

	; Read parameters and save registers
	Exch $R0	; FilePath
	Push $R1

	nsExec::ExecToStack 'powershell -inputformat none -ExecutionPolicy RemoteSigned -File "$R0"  '
	; Stack contain exitCode, scriptOutput, registers

	; Pop exit code & validate
	Pop $R1
	IntCmp $R1 0 +2
	SetErrorLevel 2

	; Restore registers
	Exch
	Pop $R1
	Exch
	Pop $R0

	; Stack contains script output only, which we leave as the function result

FunctionEnd
!endif