# DotNetCore NSIS macro

This repository contains macro scripts intended to check whether a particular version of the dotnet
core runtime is installed and, if not, install it.

All current runtimes (as of early 2025) can be installed checked and installed (dotnet, AspNetCore, WindowsDesktop).

The platform can be defined or detected during installation and the appropriate runtime installer will be used.
Supports `ARM64`, `X86` and `X86` platforms.

# Usage

Include the macro header file
```
!include "DotNetCore.nsh"
```

The structure of the macro command is as following:
```
!insertmacro CheckRuntime <Runtime> <Version> <Platform>
```

`<Runtime>` must be one of `"DotNetCore"`, `"AspNetCore"` or `"WindowsDesktop"` to specify the desired runtime
to check and (if necessary) to install. `<Version>` defines the major dotnet release version in a 2 digit
form (e.g. `3.1`, `6.0` or `7.0`). `<Platform>` is an optional parameter to define the target platform.
Allowed inputs are `"x86"`, `"x64"`, `"arm64"` and `""` (empty). If this input is empty, the installer will
determine the target platform based on the system.

Complete commands look like the following:
```
!insertmacro CheckRuntime "DotNetCore" 3.1 ""
!insertmacro CheckRuntime "AspNetCore" 3.1 ""
!insertmacro CheckRuntime "AspNetCore" 3.1 "x64"
!insertmacro CheckRuntime "WindowsDesktop" 3.1 ""
!insertmacro CheckRuntime "WindowsDesktop" 3.1 "x86"
...
```

For backwards compatibility reasons, the old macros are still available and map to the new macros. However,
they should not be used in new code because the naming is wrong ("DotNetCore" macro maps on WindowsDesktop
functionality, which was the case in the original implementation)!!!