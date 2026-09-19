@echo off
rem ============================================================================
rem  build_apk.bat  --  ONE-COMMAND Android release build + size guard (E.1)
rem ----------------------------------------------------------------------------
rem  Builds BOTH release APKs in one run:
rem     armeabi-v7a (32-bit) - for older/entry Android phones (e.g. Galaxy M11)
rem     arm64-v8a    (64-bit) - for modern phones
rem  Each build runs code-size analysis, FAILS if that APK exceeds the 75 MB
rem  budget (SIZE-REGRESSION GUARD), and copies the artifact to dist/.
rem
rem  Usage:  build_apk.bat
rem  Output:
rem     deploy_android\dist\music-collection-armeabi-v7a-release.apk
rem     deploy_android\dist\music-collection-arm64-v8a-release.apk
rem ============================================================================
setlocal enabledelayedexpansion

set "FLUTTER=C:\Users\Sathvik Srivathsan\flutter\bin\flutter.bat"
set "JAVA_HOME=C:\Program Files\java\jdk-17.0.1"
set "REPO=%~dp0.."
set "SIZE_LIMIT_MB=75"
set "OUT_DIR=%~dp0dist"
set "SOURCE_APK=%REPO%\build\app\outputs\flutter-apk\app-release.apk"

if not exist "%REPO%" ( echo ERROR: repo not found & exit /b 1 )
if not exist "%FLUTTER%" ( echo ERROR: flutter.bat not found & exit /b 1 )
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo == Toolchain sanity (flutter doctor, android section) ==
call "%FLUTTER%" doctor 2>nul | findstr /i "Android toolchain" || ( echo WARNING: flutter doctor android check unseen )

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

rem ---- build + copy one ABI (subroutine style) ---------------------------------
call :build_abi armeabi-v7a android-arm  music-collection-armeabi-v7a-release.apk
if errorlevel 1 exit /b %errorlevel%

call :build_abi arm64-v8a    android-arm64 music-collection-arm64-v8a-release.apk
if errorlevel 1 exit /b %errorlevel%

echo.
echo Done. Sideload the matching APK (self-signed); see BUILD_APK.md.
dir "%OUT_DIR%\*.apk"
exit /b 0

rem ============================================================================
rem  build_abi <friendly-name> <flutter-target-platform> <dist-filename>
rem ============================================================================
:build_abi
set "ABI_NAME=%~1"
set "TARGET_PLATFORM=%~2"
set "DIST_FILE=%~3"

echo.
echo ============================================================
echo == Building %ABI_NAME% release APK + code-size analysis ==
echo ============================================================
pushd "%REPO%"
call "%FLUTTER%" build apk --release --analyze-size --target-platform "%TARGET_PLATFORM%"
set "BUILD_EXIT=%ERRORLEVEL%"
popd
if not "%BUILD_EXIT%"=="0" ( echo BUILD FAILED for %ABI_NAME% (exit %BUILD_EXIT%) & exit /b %BUILD_EXIT% )

if not exist "%SOURCE_APK%" ( echo ERROR: expected APK not found: %SOURCE_APK% & exit /b 1 )

for %%F in ("%SOURCE_APK%") do set "BYTES=%%~zF"
set /a "MB_CEIL=(%BYTES% + 1048575) / 1048576"

echo.
echo APK: %SOURCE_APK%
echo Size: %BYTES% bytes  (approx %MB_CEIL% MiB)   limit: %SIZE_LIMIT_MB% MB
if %MB_CEIL% GTR %SIZE_LIMIT_MB% (
    echo SIZE-REGRESSION GUARD: %ABI_NAME% APK exceeds %SIZE_LIMIT_MB% MB -- build FAILING.
    exit /b 2
)

copy /y "%SOURCE_APK%" "%OUT_DIR%\%DIST_FILE%" >nul
echo Copied -^> %OUT_DIR%\%DIST_FILE%
exit /b 0