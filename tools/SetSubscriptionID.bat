@echo off
setlocal enabledelayedexpansion

rem Set the directory path where the files are located
set "directory=../samples/grafana-dashboards/"

rem Set the placeholder string
set "placeholder=<Placeholder_subID>"

rem Prompt the user to enter the new string
set /p "newString=Enter the new string: "

rem Iterate over each file in the directory
for %%F in ("%directory%\*.*") do (
    rem Check if the file is not a directory
    if not "%%~aF"=="d" (
        rem Search for the placeholder string in the file
        findstr /C:"%placeholder%" "%%F" >nul
        if !errorlevel! equ 0 (
            rem Replace the placeholder string with the new string
            powershell -Command "(Get-Content '%%F') -replace '%placeholder%', '%newString%' | Out-File '%%F' -Encoding UTF8"
            echo "Placeholder replaced in: %%F"
        ) else (
            echo "Placeholder not found in: %%F"
        )
    )
)