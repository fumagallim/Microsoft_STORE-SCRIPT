@setlocal DisableDelayedExpansion
@echo off
set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
set "_err===== ERROR ===="
set "_lin============================================================="

for /f "tokens=6 delims=[]. " %%# in ('ver') do if %%# lss 18362 goto :version
reg query HKU\S-1-5-19 1>nul 2>nul || goto :uac

if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" goto :noarm
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" goto :noarm
set "xOS=x64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" (if not defined PROCESSOR_ARCHITEW6432 set "xOS=x86")
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
setlocal EnableDelayedExpansion
pushd "!_work!"
if not exist "*WindowsStore*.*xbundle" goto :nofiles
if not exist "*WindowsStore*.xml" goto :nofiles

for %%# in (
Store PurchaseApp AppInstaller XboxIdentity
NF22X64 NF22X86 NR22X64 NR22X86 VCPX64 VCPX86 VCDX64 VCDX86 XM27X64 XM27X86 XM26X64 XM26X86
) do (
set "%%#="
)

for /f %%i in ('dir /b *WindowsStore*.*xbundle 2^>nul') do set "Store=%%i"
call :detect NET.Native.Framework.2.2 NF22
call :detect NET.Native.Runtime.2.2 NR22
call :detect VCLibs.140.00_ VCP
call :detect VCLibs.140.00.UWPDesktop VCD
call :detect Microsoft.UI.Xaml.2.7 XM27
call :detect Microsoft.UI.Xaml.2.6 XM26
goto :proceed

:detect
for /f %%i in ('dir /b *%1*.appx 2^>nul ^| find /i "x64"') do set "%2X64=%%i"
for /f %%i in ('dir /b *%1*.appx 2^>nul ^| find /i "x86"') do set "%2X86=%%i"
goto :eof

:proceed
if /i %xOS%==x64 (
for %%# in (NF22X64 NF22X86 NR22X64 NR22X86 VCPX64 VCPX86 XM27X64 XM27X86) do (if not defined %%# goto :nofiles)
) else (
for %%# in (NF22X86 NR22X86 VCPX86 XM27X86) do (if not defined %%# goto :nofiles)
)

if exist "*StorePurchaseApp*.*xbundle" if exist "*StorePurchaseApp*.xml" (
for /f %%i in ('dir /b *StorePurchaseApp*.*xbundle 2^>nul') do set "PurchaseApp=%%i"
)
if exist "*XboxIdentityProvider*.*xbundle" if exist "*XboxIdentityProvider*.xml" (
for /f %%i in ('dir /b *XboxIdentityProvider*.*xbundle 2^>nul') do set "XboxIdentity=%%i"
)
if exist "*DesktopAppInstaller*.*xbundle" if exist "*DesktopAppInstaller*.xml" (
for /f %%i in ('dir /b *DesktopAppInstaller*.*xbundle 2^>nul') do set "AppInstaller=%%i"
)

if /i %xOS%==x64 (
for %%# in (VCDX64 VCDX86 XM26X64 XM26X86) do (if not defined %%# set "AppInstaller=")
) else (
for %%# in (VCDX86 XM26X86) do (if not defined %%# set "AppInstaller=")
)

if /i %xOS%==x64 (
set "DepStore=%NF22X64%,%NF22X86%,%NR22X64%,%NR22X86%,%VCPX64%,%VCPX86%,%XM27X64%,%XM27X86%"
set "DepInstaller=%VCDX64%,%VCDX86%,%XM26X64%,%XM26X86%"
set "DepPurchase=%NF22X64%,%NF22X86%,%NR22X64%,%NR22X86%,%VCPX64%,%VCPX86%"
set "DepXbox=%NF22X64%,%NF22X86%,%NR22X64%,%NR22X86%,%VCPX64%,%VCPX86%"
) else (
set "DepStore=%NF22X86%,%NR22X86%,%VCPX86%,%XM27X86%"
set "DepInstaller=%VCDX86%,%XM26X86%"
set "DepPurchase=%NF22X86%,%NR22X86%,%VCPX86%"
set "DepXbox=%NF22X86%,%NR22X86%,%VCPX86%"
)

set "_psc=PowerShell -NoLogo -NoProfile -NonInteractive -InputFormat None -ExecutionPolicy Bypass"

echo.
echo %_lin%
echo Adding Microsoft Store
echo %_lin%
echo.
1>nul 2>nul %_psc% Add-AppxProvisionedPackage -Online -PackagePath %Store% -DependencyPackagePath %DepStore% -LicensePath Microsoft.WindowsStore_8wekyb3d8bbwe.xml
for %%i in (%DepStore%) do (
%_psc% Add-AppxPackage -Path %%i -ForceApplicationShutdown
)
%_psc% Add-AppxPackage -Path %Store%

if defined PurchaseApp (
echo.
echo %_lin%
echo Adding Store Purchase App
echo %_lin%
echo.
1>nul 2>nul %_psc% Add-AppxProvisionedPackage -Online -PackagePath %PurchaseApp% -DependencyPackagePath %DepPurchase% -LicensePath Microsoft.StorePurchaseApp_8wekyb3d8bbwe.xml
%_psc% Add-AppxPackage -Path %PurchaseApp%
)

if defined XboxIdentity (
echo.
echo %_lin%
echo Adding Xbox Identity Provider
echo %_lin%
echo.
1>nul 2>nul %_psc% Add-AppxProvisionedPackage -Online -PackagePath %XboxIdentity% -DependencyPackagePath %DepXbox% -LicensePath Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.xml
%_psc% Add-AppxPackage -Path %XboxIdentity%
)

if defined AppInstaller (
echo.
echo %_lin%
echo Adding App Installer
echo %_lin%
echo.
1>nul 2>nul %_psc% Add-AppxProvisionedPackage -Online -PackagePath %AppInstaller% -DependencyPackagePath %DepInstaller% -LicensePath Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.xml
for %%i in (%DepInstaller%) do (
%_psc% Add-AppxPackage -Path %%i
)
%_psc% Add-AppxPackage -Path %AppInstaller%
)

echo.
echo Done
goto :fin

:noarm
echo %_err%
echo Windows 10 ARM64 is not supported
goto :fin

:uac
echo %_err%
echo Run the script as administrator
goto :fin

:version
echo %_err%
echo This pack is for Windows 10 build 18362 and later
goto :fin

:nofiles
echo %_err%
echo Required files are missing in the current directory

:fin
echo.
echo Press any key to exit.
goto :eof
