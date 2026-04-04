@echo off
set "SCRIPT_DIR=%~dp0"
start powershell -command "& Set-ExecutionPolicy Unrestricted -Confirm:$False -Force"
timeout /t 2
start powershell -command "& '%SCRIPT_DIR%zBin\Provisioning Script.ps1'"
