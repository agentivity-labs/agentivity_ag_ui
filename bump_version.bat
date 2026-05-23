@echo off
:: bump_version.bat — thin launcher for bump_version.ps1
::
:: Usage:
::   bump_version.bat <version> ["changelog message"] [options]
::
:: Options:
::   --dry-run    Simulate only, no files changed
::   --no-push    Commit + tag locally but don't push
::   --no-tag     Skip creating the git tag
::   --no-analyze Skip dart analyze
::
:: Examples:
::   bump_version.bat 0.4.0
::   bump_version.bat 0.4.0 "Improved streaming performance"
::   bump_version.bat 0.4.0 "Fix SSE reconnect" --no-push
::   bump_version.bat 0.4.0 --dry-run

setlocal EnableDelayedExpansion

:: Build PowerShell argument list, converting --kebab-case flags to -PascalCase
set PS_ARGS=
set POSITIONAL_COUNT=0

for %%A in (%*) do (
    set ARG=%%~A
    if /i "!ARG!"=="--dry-run"    ( set PS_ARGS=!PS_ARGS! -DryRun
    ) else if /i "!ARG!"=="--no-push"    ( set PS_ARGS=!PS_ARGS! -NoPush
    ) else if /i "!ARG!"=="--no-tag"     ( set PS_ARGS=!PS_ARGS! -NoTag
    ) else if /i "!ARG!"=="--no-analyze" ( set PS_ARGS=!PS_ARGS! -NoAnalyze
    ) else (
        set /a POSITIONAL_COUNT+=1
        if !POSITIONAL_COUNT!==1 ( set PS_ARGS=!PS_ARGS! "!ARG!"
        ) else if !POSITIONAL_COUNT!==2 ( set PS_ARGS=!PS_ARGS! "!ARG!"
        )
    )
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bump_version.ps1"%PS_ARGS%

exit /b %ERRORLEVEL%
