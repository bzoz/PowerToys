<#

.SYNOPSIS
Build the PowerToys project.

.DESCRIPTION
This script can build the PowerToy project. Optionally it can also build the settings-web and create MSI and MSIX installers.

TODO:
  - use https://github.com/Microsoft/vssetup.powershell to find msbuild
  - have the settings-web build script not copy the 200.html and 404.html files
  - MSIX: https://github.com/microsoft/PowerToys/pull/993
  - set proper version in all the places based on a single entry
  - generate the list of DLL modules
  - Comments!

.PARAMETER BuildDebug
If specified, Debug version of PowerToys will be built.

.PARAMETER Clean
Clean the output files.

.PARAMETER MSBuild
Location of the msbuild.exe executable. By default the one on the PATH enviroment variable will be used.

.PARAMETER Platform
Platform for which to build the PowerToys. Right now only x64 is supported.

.PARAMETER BuildSettingsWeb
If specified will build the settings-web React app, used by the settings screen. Requires that both npm and node are in the 
PATH enviroment variable.

.PARAMETER NoBuild
Skip building the PowerToys, will run other steps (settings-web, msi).

.PARAMETER BuildMSI
Will build the MSI installer.

.PARAMETER BuildMSIX
Will build the MSIX installer.

.LINK
https://github.com/microsoft/PowerToys

#>
[CmdletBinding()]
param(
    [switch] $BuildDebug = $false,
    [switch] $Clean = $false,
    [string] $MSBuild = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe',
    [ValidateSet('x64')][string] $Platform = 'x64',
    [switch] $BuildSettingsWeb = $false,
    [switch] $NoBuild = $false,
    [switch] $BuildMSI = $false,
    [switch] $BuildMSIX = $false
)

$Configuration = if ($BuildDebug) {'Debug'} else {'Release'}

if ($BuildSettingsWeb) {
    Set-Location .\src\settings-web\
    npm install -q
    if (-Not $?) {
        Set-Location .\..\..
        Exit
    }
    npm run build -q
    if (-Not $?) {
        Set-Location .\..\..
        Exit
    }
    Set-Location .\..\..
}

if ($Clean) {
    $NoBuild = $false
}
if (-Not $NoBuild) {
    $Target = if ($Clean) {'Clean'} else {'runner'}
    &${MSBuild} PowerToys.sln -m /t:${Target} /p:Configuration=${Configuration} /p:Platform=${Platform} -verbosity:minimal -nologo
    if (-Not $?) { Exit }
}

if ($Target -eq 'Clean') {
    Remove-Item ".\installer\PowerToysSetupCustomActions\${Platform}\${Configuration}\PowerToysSetupCustomActions.dll" -ErrorAction Ignore
    Remove-Item ".\installer\PowerToysSetup\${Platform}\${Configuration}\PowerToysSetup.msi" -ErrorAction Ignore
    Exit
}

if ($BuildMSI) {
    &${MSBuild} installer\PowerToysSetup.sln -m /t:Build /p:Configuration=${Configuration} /p:Platform=${Platform} -verbosity:minimal -nologo
    if (-Not $?) { Exit }
}

if ($BuildMSIX) {
    # Build MSIX
    if (-Not $?) { Exit }
}
