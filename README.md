# Windows 11 Repair Tool

Windows 11 repair PowerShell tool for system corruption, update issues, and file integrity problems. This script combines DISM, SFC, Windows Update reset options, CHKDSK scheduling, and log export into one menu-based repair utility.

## Created By

**anon2k24-design**

- GitHub: https://github.com/anon2k24-design
- Donate: https://www.paypal.com/donate/?business=UNP6WN3E95EAL&no_recurring=0&item_name=unemployment+fund+pls&currency_code=USD

## Overview

This tool is designed to help repair common Windows 11 problems using built-in Microsoft repair commands. It runs image repair with DISM, scans protected system files with SFC, can reset Windows Update components, schedule CHKDSK for the system drive, and export repair logs for troubleshooting.

## Features

- Automatic administrator elevation
- Quick repair mode using DISM and SFC
- Full repair mode with `CheckHealth`, `ScanHealth`, `RestoreHealth`, and `sfc /scannow`
- Optional source-based repair using WIM or ESD files
- Windows Update component reset
- CHKDSK scheduling for next reboot
- Export of `CBS.log`, `DISM.log`, and filtered SFC repair details
- Centralized logging for each repair session
- Reboot prompt after major repair actions

## Repair Functions

### 1. Quick Repair

Runs:

```powershell
DISM /Online /Cleanup-Image /RestoreHealth
sfc /scannow
```

This is the fast repair option for common Windows corruption and stability issues.

### 2. Full Repair

Runs:

```powershell
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /RestoreHealth
sfc /scannow
```

This mode performs a deeper health check and then exports repair logs after completion.

### 3. Source-Based Repair

Allows you to repair Windows using a local source such as an ISO-mounted `install.wim` or `install.esd`.

Example source values:

```text
WIM:D:\sources\install.wim:1
ESD:D:\sources\install.esd:1
```

### 4. Windows Update Reset

Stops core Windows Update services, resets update cache folders, and starts the services again. This is useful when updates fail, get stuck, or repeatedly return errors.

### 5. CHKDSK Scheduling

Schedules CHKDSK on drive `C:` for the next reboot:

```powershell
chkdsk C: /F /R
```

This is useful for file system errors, bad sector checks, and disk-related repair scenarios.

### 6. Log Export

Exports:

- `C:\Windows\Logs\CBS\CBS.log`
- `C:\Windows\Logs\DISM\dism.log`
- Filtered SFC details from `[SR]` entries in `CBS.log`

These logs can help identify files that were repaired or could not be repaired.

## Why DISM Before SFC

SFC uses the Windows component store as its repair source. If that component store is damaged, Microsoft recommends repairing the image with DISM first and then running SFC afterward.

## Requirements

- Windows 11
- PowerShell
- Administrator privileges

## How To Use

1. Download or copy the script to your PC.
2. Save it as `windows-11-repair-tool.ps1`
3. Right-click PowerShell and choose **Run as Administrator**
4. Run the script:

```powershell
powershell -ExecutionPolicy Bypass -File .\windows-11-repair-tool.ps1
```

5. Choose the repair option you want from the menu.

## Log Location

The script stores logs in:

```text
C:\ProgramData\Anon2K24Design\RepairLogs
```

Exported repair logs are stored in the `Exports` folder inside that directory.

## Use Cases

This tool may help with:

- Corrupted Windows system files
- Broken Windows Update components
- Failed cumulative updates
- OS instability after driver or update issues
- General repair and maintenance troubleshooting
- Support and diagnostics for repair tech workflows

## Notes

- Some repairs may take a long time depending on system speed and corruption level.
- `CHKDSK /F /R` usually requires a reboot on the system drive.
- Source-based DISM repair is useful if online repair fails.
- A reboot is recommended after major repair actions.

## Disclaimer

This tool uses built-in Windows repair commands, but it still makes system-level changes. Use it at your own risk and review logs after running repairs. Always back up important data before making major system changes.

## Support

If this script helped you, you can support future Windows repair and optimization tools here:

- GitHub: https://github.com/anon2k24-design
- Donate: https://www.paypal.com/donate/?business=UNP6WN3E95EAL&no_recurring=0&item_name=unemployment+fund+pls&currency_code=USD
