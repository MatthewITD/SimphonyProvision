#Requires -RunAsAdministrator

# Copyright (C) 2026 Matthew Gilmour / ITD Services, LLC
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

## Script ID
$Script_ID_Version = "2.0.1"
$Script_ID_Name = "POS Provisioning Script"
$Script_ID_Creator = "Matthew A. Gilmour"
$Script_ID_Creator_Email = "mgilmour@itd-s.com"

Write-Host "########################################################################################"
Write-Host "########################################################################################"
Write-Host "## $Script_ID_Name - Version: $Script_ID_Version"
Write-Host "##"
Write-Host "## Welcome!"
Write-Host "##"
Write-Host "## Contact $Script_ID_Creator at $Script_ID_Creator_Email for questions."
Write-Host "########################################################################################"
Write-Host "########################################################################################"
Write-Host ""

Write-Host "########################################################################################"
Write-Host "## Set Custom Variables"
Write-Host "########################################################################################"
Write-Host ""

#### Set Authentication Information #####
$SV_Global_Terminal_Username = "OraclePOS"
$SV_Global_Terminal_Password ="OraclePOS1!"

#### Set Directory Variables #####
$SV_Global_FS_Working_POSDir = Split-Path $PSScriptRoot -Parent
$SV_Global_FS_Archive_POSDir = "C:\POSProvisioning"

#### Set File Variables #####
## Programs
$SV_Global_Files_AutoLogon = "AutoLogon64.exe"

## Installers
$SV_Global_Files_ScreenConnectMSI = "ITDS-Client-AllDevices.msi"
$SV_Global_Files_SyncroMSI = "ITDS-SyncroClient-AllDevices.msi"
$SV_Global_Files_EpsonOPOS = "EPSON_OPOS_ADK_V3.00ER16.exe"

#### Set DNS Information #####
$SV_Global_Network_DNS1 = "1.1.1.1"
$SV_Global_Network_DNS2 = "8.8.8.8"

#### Enable/Disable Optional Installers #####
$SV_Global_Enable_ScreenConnect = $false
$SV_Global_Enable_SyncroMSP = $false

Write-Host "########################################################################################"
Write-Host "## Provisioning Check"
Write-Host "########################################################################################"
Write-Host ""

#### Registry Path for Provisioning Record #####
$SV_Global_RegistryPath = "HKLM:\SOFTWARE\POSProvisioning"

If (Test-Path $SV_Global_RegistryPath)
    {
        $FV_PreviousDate = (Get-ItemProperty -Path $SV_Global_RegistryPath).ProvisionedDate
        $FV_PreviousVersion = (Get-ItemProperty -Path $SV_Global_RegistryPath).ScriptVersion
        Write-Host "This workstation was previously provisioned on $FV_PreviousDate with script version $FV_PreviousVersion."
        $SV_Global_AlreadyProvisioned = Read-Host "Are you sure you want to run again? (Y/N)"

        If ($SV_Global_AlreadyProvisioned -eq "N")
        {
            Write-Host "Script will now exit."
            Start-Sleep -seconds 10
            EXIT
        }
    }

Write-Host "########################################################################################"
Write-Host "## User Configuration Check"
Write-Host "########################################################################################"
Write-Host ""

If ($env:USERNAME -eq $SV_Global_Terminal_Username)
    {
        Write-Host "The user account matched the required information"
        Write-Host "Confirming Password Settings"
        $FV_SecuredPassword = ConvertTo-SecureString $SV_Global_Terminal_Password -AsPlainText -Force
        Set-LocalUser $SV_Global_Terminal_Username -Password $FV_SecuredPassword -PasswordNeverExpires $true

    }
Else
    {
        Write-Host "The user account does not match the required information. This terminal requires re-provisioning. Username should be: $SV_Global_Terminal_Username"
        Write-Host "The script will now exit."
        Start-Sleep -Seconds 10
        EXIT
    }

Write-Host "########################################################################################"
Write-Host "## Define Workstation Type"
Write-Host "########################################################################################"
Write-Host ""

$SV_Global_WorkstationInformation = Get-ComputerInfo

If ($SV_Global_WorkstationInformation.CsModel -eq $null)
    {
        Write-Host "This workstation does not use Get-ComputerInfo, use alternate WMI method"
        Start-Service -Name WinRM -Verbose
        Start-Sleep -Seconds 2
        $SV_Global_WorkstationInformation_WinRM = Get-CimInstance -Class Win32_ComputerSystem -ComputerName localhost -ErrorAction Stop | Select-Object *
        
        ## Check Using WinRM
        If ($SV_Global_WorkstationInformation_WinRM.Model -eq "Oracle Workstation 8 Series")
            {
                $SV_Global_WorkstationType = "WS820"
                Write-Host "This is a Workstation 820."
            }
        ElseIf ($SV_Global_WorkstationInformation_WinRM.Model -eq "Oracle America, Inc Micros Workstation 6 Series 2")
            {
                $SV_Global_WorkstationType = "WS625X"
                Write-Host "This is a Workstation 625X."
            }
        Elseif ($SV_Global_WorkstationInformation_WinRM.Model -eq "DTRI DT317CR")
            {
                $SV_Global_WorkstationType = "WS721P"
                Write-Host "This is a Workstation 721P."
            }
        Elseif ($SV_Global_WorkstationInformation_WinRM.Model -eq "DTRI DT166CR")
            {
                $SV_Global_WorkstationType = "KDS210"
                Write-Host "This is a Kitchen Display Controller 210."
            }
        Elseif ($SV_Global_WorkstationInformation_WinRM.Model -eq "Micros Express Station 4")
            {
                $SV_Global_WorkstationType = "ES410"
                Write-Host "This is a Micros Express Station 410."
            }
    }
Else
    {
        ## Check using Get-ComputerInfo
        If ($SV_Global_WorkstationInformation.CsModel -eq "Oracle Workstation 8 Series")
            {
                $SV_Global_WorkstationType = "WS820"
                Write-Host "This is a Workstation 820."
            }
        ElseIf ($SV_Global_WorkstationInformation.CsModel -eq "Micros Workstation 6 Series 2")
            {
                $SV_Global_WorkstationType = "WS625X"
                Write-Host "This is a Workstation 625X."
            }
        Elseif ($SV_Global_WorkstationInformation.CsModel -eq "DTRI DT317CR")
            {
                $SV_Global_WorkstationType = "WS721P"
                Write-Host "This is a Workstation 721P."
            }
        Elseif ($SV_Global_WorkstationInformation.CsModel -eq "DTRI DT166CR")
            {
                $SV_Global_WorkstationType = "KDS210"
                Write-Host "This is a Kitchen Display Controller 210."
            }
        Elseif ($SV_Global_WorkstationInformation.CsModel -eq "Micros Express Station 4")
            {
                $SV_Global_WorkstationType = "ES410"
                Write-Host "This is a Micros Express Station 410."
            }
    }

If($SV_Global_WorkstationType -eq $null)
    {
        Write-Host "Workstation Not Detected. Script Will Exit"
        Start-Sleep -Seconds 15
        EXIT
    }


Start-Sleep -Seconds 5

Write-Host "########################################################################################"
Write-Host "## Global Set Functions"
Write-Host "########################################################################################"
Write-Host ""

Function Set-ProvisioningRecord
    {
        If (-not (Test-Path $SV_Global_RegistryPath))
            {
                New-Item -Path $SV_Global_RegistryPath -Force | Out-Null
            }
        Set-ItemProperty -Path $SV_Global_RegistryPath -Name "ProvisionedDate" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Type String
        Set-ItemProperty -Path $SV_Global_RegistryPath -Name "ScriptVersion" -Value $Script_ID_Version -Type String
        Set-ItemProperty -Path $SV_Global_RegistryPath -Name "WorkstationType" -Value $SV_Global_WorkstationType -Type String
        $Return = "Provisioning record saved to registry."
        Return $Return
    }

Function Archive-WorkingDirectory
    {
        If (Test-Path -Path $SV_Global_FS_Archive_POSDir)
            {
                Write-Host "Existing Archive in Place. This will be removed and the working copy will be archived."
                Remove-Item $SV_Global_FS_Archive_POSDir -Recurse -Verbose
            }
        Else
            {
                Write-Host "No Existing Archive. The archive will be created."
            }
        Copy-Item $SV_Global_FS_Working_POSDir -Destination $SV_Global_FS_Archive_POSDir -Recurse -Verbose
        If (Test-Path -Path $SV_Global_FS_Archive_POSDir)
            {
                Write-Host "Archive verified. Scheduling removal of working directory."
                Start-Process cmd -ArgumentList "/c timeout /t 10 >nul & rmdir /s /q `"$SV_Global_FS_Working_POSDir`"" -WindowStyle Hidden
            }
        Else
            {
                Write-Host "Archive could not be verified. Working directory will not be removed."
            }
    }

Function Set-FirewallDisable
    {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
        $Return = "Firewall Set to Disabled"
        Return $Return
    }

Function Set-DNSServers
    {
        #### POS Network Interfaces #####
        ##820
        $FV_WS820_GbE1 = "GbE1"
        $FV_WS820_GbE2 = "GbE2"
        $FV_WS820_WiFi = "Wi-Fi"
        ##625X
        $FV_WS625X_GbE1 = "GbE1"
        $FV_WS625X_GbE2 = "GbE2"
        $FV_WS625X_WiFi = "Wi-Fi"
        ##721P
        $FV_WS721P_WiFi = "Wi-Fi"
        ##210
        $FV_KDS210_Ethernet = "Ethernet"
        ##410
        $FV_ES410_GbE1 = "GbE1"

        #### Configure DNS from Workstation Type ####
        If ($SV_Global_WorkstationType -eq "WS820")
            {
                Set-DNSClientServerAddress -InterfaceAlias $FV_WS820_GbE1 -ServerAddresses ($SV_Global_Network_DNS1,$SV_Global_Network_DNS2)
                Set-DNSClientServerAddress -InterfaceAlias $FV_WS820_GbE2 -ServerAddresses ($SV_Global_Network_DNS1,$SV_Global_Network_DNS2)
                Set-DNSClientServerAddress -InterfaceAlias $FV_WS820_WiFi -ServerAddresses ($SV_Global_Network_DNS1,$SV_Global_Network_DNS2)
            }
        Elseif ($SV_Global_WorkstationType -eq "WS625X")
            {
                Set-DNSClientServerAddress -InterfaceAlias $FV_WS625X_GbE1 -ServerAddresses ($SV_Global_Network_DNS1,$SV_Global_Network_DNS2)
                Set-DNSClientServerAddress -InterfaceAlias $FV_WS625X_GbE2 -ServerAddresses ($SV_Global_Network_DNS1,$SV_Global_Network_DNS2)
                Set-DNSClientServerAddress -InterfaceAlias $FV_WS625X_WiFi -ServerAddresses ($SV_Global_Network_DNS1,$SV_Global_Network_DNS2)
            }
        Elseif ($SV_Global_WorkstationType -eq "WS721P")
            {
                Set-DNSClientServerAddress -InterfaceAlias $FV_WS721P_WiFi -ServerAddresses ($SV_Global_Network_DNS1,$SV_Global_Network_DNS2)
            }
        Elseif ($SV_Global_WorkstationType -eq "KDS210")
            {
                Set-DNSClientServerAddress -InterfaceAlias $FV_KDS210_Ethernet -ServerAddresses ($SV_Global_Network_DNS1,$SV_Global_Network_DNS2)
            }
        Elseif ($SV_Global_WorkstationType -eq "ES410")
            {
                Set-DNSClientServerAddress -InterfaceAlias $FV_ES410_GbE1 -ServerAddresses ($SV_Global_Network_DNS1,$SV_Global_Network_DNS2)
            }

}


Function Install-ScreenConnect
{
    If (Test-Path -path "$SV_Global_FS_Working_POSDir\Installers\$SV_Global_Files_ScreenConnectMSI")
        {
            Start-Process msiexec "/i `"$SV_Global_FS_Working_POSDir\Installers\$SV_Global_Files_ScreenConnectMSI`" /qn" -Wait;
            $Return = "Installed ScreenConnect"
            Return $Return
        }
    Else
        {
            Throw "You're missing the required files for installation of the ScreenConnect Client. Expected: $SV_Global_FS_Working_POSDir\Installers\$SV_Global_Files_ScreenConnectMSI"
        }
}

Function Install-SyncroMSP
{
    If (Test-Path -path "$SV_Global_FS_Working_POSDir\Installers\$SV_Global_Files_SyncroMSI")
        {
            Start-Process msiexec "/i `"$SV_Global_FS_Working_POSDir\Installers\$SV_Global_Files_SyncroMSI`" /qn" -Wait;
            $Return = "Installed Syncro"
            Return $Return
        }
    Else
        {
            Throw "You're missing the required files for installation of the Syncro Client. Expected: $SV_Global_FS_Working_POSDir\Installers\$SV_Global_Files_SyncroMSI"
        }
}

Function Install-OPOS
{
    If (Test-Path -path "$SV_Global_FS_Working_POSDir\Installers\OPOS\$SV_Global_Files_EpsonOPOS")
        {
            Start-Process "$SV_Global_FS_Working_POSDir\Installers\OPOS\$SV_Global_Files_EpsonOPOS" /quiet -Wait;
            $Return = "Installed OPOS"
            Return $Return
        }
    Else
        {
            Throw "You're missing the required files for installation of the Epson OPOS ADK. Expected: $SV_Global_FS_Working_POSDir\Installers\OPOS\$SV_Global_Files_EpsonOPOS"
        }
}

Function Set-UACDisable
{
    Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0
    $Return = "UAC Disabled"
    Return $Return
}

Function Copy-OracleFixNote
{
    $FV_SourceFile = "$SV_Global_FS_Working_POSDir\zBin\FIX ORACLE.txt"
    $FV_DestinationPath = "C:\Users\$SV_Global_Terminal_Username\Desktop\FIX ORACLE.txt"
    If (Test-Path -Path $FV_SourceFile)
        {
            Copy-Item -Path $FV_SourceFile -Destination $FV_DestinationPath -Force
            $Return = "FIX ORACLE.txt copied to desktop."
            Return $Return
        }
    Else
        {
            $Return = "FIX ORACLE.txt not found in zBin. Skipping."
            Return $Return
        }
}

Function Set-AutoLogon
{
    If (Test-Path -path "$SV_Global_FS_Working_POSDir\zBin\$SV_Global_Files_AutoLogon")
        {
            Start-Process "$SV_Global_FS_Working_POSDir\zBin\$SV_Global_Files_AutoLogon" -ArgumentList "$SV_Global_Terminal_Username $env:USERDOMAIN $SV_Global_Terminal_Password /AcceptEULA" -Wait
            $Return = "AutoLogon Configured"
            Return $Return
        }
    Else
        {
            Throw "You're missing the required files to setup AutoLogon. Expected: $SV_Global_FS_Working_POSDir\zBin\$SV_Global_Files_AutoLogon"
        }
}

Function Update-WindowsSystem
{
    Write-Host "Windows System Update Beginning"

    #### Install Windows Update PowerShell Module ####
    Install-PackageProvider -Name NuGet -Confirm:$False -Force
    Install-Module PSWindowsUpdate -Confirm:$False -Force
    Import-Module PSWindowsUpdate

    #### Run Windows Update ####        
    Get-WindowsUpdate
    Install-WindowsUpdate -Confirm:$False -ForceDownload -ForceInstall -AcceptAll -AutoReboot -Verbose

    $Return = "Updated Windows System"
    Return $Return
}

Write-Host "########################################################################################"
Write-Host "## Select From Options"
Write-Host "## A - Full Workstation Deployment"
Write-Host "## B - Configure Firewall Settings"
Write-Host "## C - Configure DNS Settings"
Write-Host "## D - Configure AutoLogon"
Write-Host "## E - Configure UAC Settings"
Write-Host "## F - Install ITDS ScreenConnect Client"
Write-Host "## G - Install ITDS Syncro Client"
Write-Host "## H - Install Epson OPOS"
Write-Host "## I - Install Windows Updates"
Write-Host "## X - Exit Script"
Write-Host "########################################################################################"
Write-Host ""

$SV_Global_ScriptRunningMode = Read-Host 'Enter your choice here'

If ($SV_Global_ScriptRunningMode -eq "A")
    {
        Set-ExecutionPolicy Unrestricted -Confirm:$false -Force
        $SV_Deployment_Success = $true
        Try
            {
                $ErrorActionPreference = "Stop"
                #### Workstation Installation ####
                Write-Host (Set-FirewallDisable)
                Start-Sleep -Seconds 1
                Set-DNSServers
                Start-Sleep -Seconds 1
                Write-Host (Set-AutoLogon)
                Start-Sleep -Seconds 1
                Write-Host (Set-UACDisable)
                Start-Sleep -Seconds 1
                Write-Host (Copy-OracleFixNote)
                Start-Sleep -Seconds 1
                If ($SV_Global_Enable_ScreenConnect -eq $true)
                    {
                        Write-Host (Install-ScreenConnect)
                        Start-Sleep -Seconds 10
                    }
                Else
                    {
                        Write-Host "ScreenConnect installation is disabled. Skipping."
                    }
                If ($SV_Global_Enable_SyncroMSP -eq $true)
                    {
                        Write-Host (Install-SyncroMSP)
                        Start-Sleep -Seconds 10
                    }
                Else
                    {
                        Write-Host "SyncroMSP installation is disabled. Skipping."
                    }
            }
        Catch
            {
                $SV_Deployment_Success = $false
                Write-Host "Deployment encountered an error: $_"
            }

        If ($SV_Deployment_Success -eq $true)
            {
                Write-Host "All steps completed successfully."
                Write-Host (Set-ProvisioningRecord)
                Write-Host "Archiving working directory."
                Archive-WorkingDirectory
                Write-Host "Archive complete. Starting Windows Updates. System may reboot automatically."
                Write-Host (Update-WindowsSystem)
            }
        Else
            {
                Write-Host "Deployment did not complete successfully. Archive and Windows Updates skipped."
            }
    }
ElseIf ($SV_Global_ScriptRunningMode -eq "B")
    {
        #### Configure Firewall Settings ####
        Try { Write-Host (Set-FirewallDisable) }
        Catch { Write-Host "Error: $_" }
    }
ElseIf ($SV_Global_ScriptRunningMode -eq "C")
    {
        #### Configure DNS Settings ####
        Try { Set-DNSServers }
        Catch { Write-Host "Error: $_" }
    }
ElseIf ($SV_Global_ScriptRunningMode -eq "D")
    {
        #### Configure AutoLogon Settings #####
        Try { Write-Host (Set-AutoLogon) }
        Catch { Write-Host "Error: $_" }
    }
ElseIf ($SV_Global_ScriptRunningMode -eq "E")
    {
        #### Configure UAC Settings ####
        Try { Write-Host (Set-UACDisable) }
        Catch { Write-Host "Error: $_" }
    }
ElseIf ($SV_Global_ScriptRunningMode -eq "F")
    {
        #### Install ITDS ScreenConnect Client ####
        If ($SV_Global_Enable_ScreenConnect -eq $true)
            {
                Try { Write-Host (Install-ScreenConnect) }
                Catch { Write-Host "Error: $_" }
            }
        Else
            { Write-Host "ScreenConnect installation is disabled. Update the Enable/Disable Optional Installers section to enable it." }
    }
ElseIf ($SV_Global_ScriptRunningMode -eq "G")
    {
        #### Install ITDS Syncro Client ####
        If ($SV_Global_Enable_SyncroMSP -eq $true)
            {
                Try { Write-Host (Install-SyncroMSP) }
                Catch { Write-Host "Error: $_" }
            }
        Else
            { Write-Host "SyncroMSP installation is disabled. Update the Enable/Disable Optional Installers section to enable it." }
    }
ElseIf ($SV_Global_ScriptRunningMode -eq "H")
    {
        #### Install Epson OPOS ####
        Try { Write-Host (Install-OPOS) }
        Catch { Write-Host "Error: $_" }
    }
ElseIf ($SV_Global_ScriptRunningMode -eq "I")
    {
        #### Run Windows Updates ####
        Try { Write-Host (Update-WindowsSystem) }
        Catch { Write-Host "Error: $_" }
    }
Elseif ($SV_Global_ScriptRunningMode -eq "X")
    {
        #### Exit Script ####
        Exit
    }
Else
    {
        Write-Host "Invalid Option"
    }

Write-Host "Script Finished"
Start-Sleep 10
EXIT