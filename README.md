# POSProvision — Big Boy POS Provisioning Toolkit

**Author:** Matthew Gilmour / ITD Services, LLC
**License:** GNU General Public License v3.0

A PowerShell-based deployment toolkit for provisioning Oracle/Micros Point-of-Sale workstations and kitchen display systems at restaurant locations. Automates network configuration, software installation, and Windows maintenance tasks into a single guided workflow.

---

## Supported Hardware

| Device ID | Hardware Model | Description |
|-----------|---------------|-------------|
| WS820 | Oracle Workstation 8 Series | Primary POS workstation |
| WS625X | Micros Workstation 6 Series 2 | Legacy POS workstation |
| WS721P | DTRI DT317CR | Workstation 721P |
| KDS210 | DTRI DT166CR | Kitchen Display Controller |
| ES410 | Micros Express Station 4 | Express station terminal |

---

## Repository Structure

```
POSProvision/
├── Run Provisioning Script.bat       # Launch point — run this to start provisioning
├── README.md
│
├── zBin/                             # Core scripts and utilities
│   ├── Provisioning Script.ps1       # Main provisioning automation script
│   ├── Autologon64.exe               # SysInternals autologon utility
│   └── FIX ORACLE.txt                # Oracle Simphony quick-reference troubleshooting
│
├── Installers/                       # Third-party software packages
│   ├── ITDS-Client-AllDevices.msi    # ScreenConnect remote support client
│   ├── ITDS-SyncroClient-AllDevices.msi  # Syncro MSP management client
│   └── OPOS/
│       └── EPSON_OPOS_ADK_V3.00ER16.exe  # EPSON OPOS ADK for POS peripherals
│
└── System Erase Scripts/             # Destructive database/system reset tools (IT use only)
    └── CLEAR CAPS - MSSQL.bat        # Full Oracle Simphony DB wipe and Micros directory removal
```

---

## Getting Started

### Prerequisites

- Windows workstation with PowerShell 5.1 or later
- Administrator account access
- Logged in as the terminal user account configured in the script (see [Configuration](#configuration) below)
- Network connectivity (for Windows Update and remote management software installation)

### Configuration

Before deploying, open [zBin/Provisioning Script.ps1](zBin/Provisioning%20Script.ps1) and update the **Set Custom Variables** section at the top of the script for your environment:

| Variable | Description | Must Change? |
|----------|-------------|--------------|
| `$SV_Global_Terminal_Username` | The local Windows account name on the terminal | **Yes** — set to the account used at this brand/location |
| `$SV_Global_Terminal_Password` | Password for the terminal account | **Yes** — set per your security policy |
| `$SV_Global_FS_Archive_POSDir` | Where the provisioning folder is archived post-deployment | Optional |
| `$SV_Global_Network_DNS1/2` | Primary and secondary DNS servers | Optional |
| `$SV_Global_Enable_ScreenConnect` | Toggle ScreenConnect installation on/off | Optional |
| `$SV_Global_Enable_SyncroMSP` | Toggle Syncro MSP installation on/off | Optional |

> **Important:** The script will exit early if the current Windows session username does not match `$SV_Global_Terminal_Username`. Make sure this is set correctly before running.

---

### Running the Provisioning Script

1. Copy the entire `POSProvisioning` folder to the target workstation (any location).
2. Right-click **`Run Provisioning Script.bat`** and select **Run as administrator** — it will set execution policy and launch the interactive menu.
3. Select the appropriate option from the menu (see below).
4. The script auto-detects the workstation model and applies the correct configuration for that device.

> **Note:** The script requires administrator privileges. Simply double-clicking the `.bat` file will not work — you must right-click and choose **Run as administrator**.

> **Note:** The script checks the Windows registry for a prior provisioning record. If the device has already been provisioned, it will warn you before proceeding.

---

## Provisioning Menu Options

| Option | Action |
|--------|--------|
| **A** | Full workstation deployment (all steps including Windows Updates) |
| **B** | Configure Firewall settings only |
| **C** | Configure DNS settings only |
| **D** | Configure AutoLogon only |
| **E** | Configure UAC settings only |
| **F** | Install ScreenConnect only |
| **G** | Install Syncro MSP only |
| **H** | Install OPOS drivers only |
| **I** | Install Windows Updates only |
| **X** | Exit |

Option **A** performs the full deployment sequence: firewall configuration, DNS configuration, AutoLogon setup, UAC disable, copies FIX ORACLE.txt to the terminal desktop, ScreenConnect installation, and Syncro MSP installation — then archives the working directory to `C:\POSProvisioning\`, removes the source, and runs Windows Updates. **OPOS is not included in Option A** — run Option H separately if needed.

---

## What the Script Configures

**Network**
- Sets DNS to `1.1.1.1` (primary) and `8.8.8.8` (secondary) on the device-specific network interface(s)

**Security**
- Disables Windows Firewall (all profiles)
- Disables User Account Control (UAC)

**Authentication**
- Resets the configured terminal account password and sets it to never expire
- Configures automatic logon for the terminal account using Autologon64.exe

**Software**
- Installs ScreenConnect remote support client (`ITDS-Client-AllDevices.msi`)
- Installs Syncro MSP management client (`ITDS-SyncroClient-AllDevices.msi`)
- Installs EPSON OPOS ADK (`EPSON_OPOS_ADK_V3.00ER16.exe`) for POS peripheral support (Option H only)

**Maintenance**
- Installs available Windows Updates via the `PSWindowsUpdate` PowerShell module

**Post-Deployment**
- Writes a provisioning record to `HKLM:\SOFTWARE\POSProvisioning` (device type, timestamp, script version)
- Copies `FIX ORACLE.txt` to the terminal user's desktop
- Archives the working directory to `C:\POSProvisioning\` and removes the source folder

---

## DANGEROUS — System Erase Scripts

> **WARNING: These scripts are irreversible. Only run them under IT direction.**

`CLEAR CAPS - MSSQL.bat` performs a full Oracle Simphony system reset:
- Stops all POS-related Windows services
- Connects to MSSQL Express in single-user mode and drops all Simphony databases
- Deletes all Micros registry keys
- Deletes the entire `C:\Micros\` directory

This is used to wipe a workstation before reimaging or reassigning it to a new location.

---

## Oracle Simphony Troubleshooting

If Oracle Simphony does not launch after the workstation restarts:

1. Restart the terminal and wait for it to fully boot.
2. If Simphony still does not open automatically, contact IT.

See `zBin/FIX ORACLE.txt` for the quick-reference version of these steps.

---

## License

This project is licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).
Copyright © Matthew Gilmour / ITD Services, LLC
