# ================================================
# Windows 11 Repair Tool
# Brand: anon2k24-design
# GitHub: https://github.com/anon2k24-design
# Donate: https://www.paypal.com/donate/?business=UNP6WN3E95EAL&no_recurring=0&item_name=unemployment+fund+pls&currency_code=USD
# ================================================

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    $argList = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $argList
    exit
}

$BrandName = "anon2k24-design"
$GitHubUrl = "https://github.com/anon2k24-design"
$DonateUrl = "https://www.paypal.com/donate/?business=UNP6WN3E95EAL&no_recurring=0&item_name=unemployment+fund+pls&currency_code=USD"

$LogRoot = Join-Path $env:ProgramData "Anon2K24Design\RepairLogs"
$ExportRoot = Join-Path $LogRoot "Exports"
New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
New-Item -Path $ExportRoot -ItemType Directory -Force | Out-Null

$TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = Join-Path $LogRoot "Windows11Repair_$TimeStamp.log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level.ToUpper(), $Message
    Add-Content -Path $LogFile -Value $line

    switch ($Level.ToUpper()) {
        "ERROR"   { Write-Host $line -ForegroundColor Red }
        "WARN"    { Write-Host $line -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $line -ForegroundColor Green }
        default   { Write-Host $line -ForegroundColor Cyan }
    }
}

function Append-FileToLog {
    param([string]$Path)

    if (Test-Path $Path) {
        Add-Content -Path $LogFile -Value ""
        Add-Content -Path $LogFile -Value "----- BEGIN OUTPUT: $Path -----"
        Get-Content -Path $Path | Add-Content -Path $LogFile
        Add-Content -Path $LogFile -Value "----- END OUTPUT: $Path -----"
        Add-Content -Path $LogFile -Value ""
    }
}

function Run-ExternalCommand {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$FriendlyName
    )

    $safeName = ($FriendlyName -replace '[^A-Za-z0-9_-]', '_')
    $outFile = Join-Path $env:TEMP "$safeName-stdout-$([guid]::NewGuid().ToString()).txt"
    $errFile = Join-Path $env:TEMP "$safeName-stderr-$([guid]::NewGuid().ToString()).txt"

    Write-Log "Running $FriendlyName"
    Write-Host ""
    Write-Host ">>> $FriendlyName" -ForegroundColor Magenta

    try {
        $process = Start-Process -FilePath $FilePath `
                                 -ArgumentList $Arguments `
                                 -Wait `
                                 -NoNewWindow `
                                 -PassThru `
                                 -RedirectStandardOutput $outFile `
                                 -RedirectStandardError $errFile

        Append-FileToLog -Path $outFile
        Append-FileToLog -Path $errFile

        if ($process.ExitCode -eq 0) {
            Write-Log "$FriendlyName completed successfully." "SUCCESS"
            return $true
        }
        else {
            Write-Log "$FriendlyName finished with exit code $($process.ExitCode)." "WARN"
            return $false
        }
    }
    catch {
        Write-Log "$FriendlyName failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
    finally {
        Remove-Item $outFile, $errFile -ErrorAction SilentlyContinue
    }
}

function Pause-Continue {
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Show-Banner {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor DarkCyan
    Write-Host "            Windows 11 Repair Tool" -ForegroundColor Cyan
    Write-Host "               by $BrandName" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor DarkCyan
    Write-Host "GitHub : $GitHubUrl" -ForegroundColor Yellow
    Write-Host "Donate : $DonateUrl" -ForegroundColor Yellow
    Write-Host "Log    : $LogFile" -ForegroundColor Gray
    Write-Host ""
}

function Run-QuickRepair {
    Write-Log "Starting Quick Repair sequence."
    $dismOk = Run-ExternalCommand -FilePath "dism.exe" -Arguments @("/Online","/Cleanup-Image","/RestoreHealth") -FriendlyName "DISM RestoreHealth"
    $sfcOk  = Run-ExternalCommand -FilePath "sfc.exe"  -Arguments @("/scannow") -FriendlyName "SFC ScanNow"

    if ($dismOk -and $sfcOk) {
        Write-Log "Quick Repair completed." "SUCCESS"
    }
    else {
        Write-Log "Quick Repair completed with warnings. Review the log." "WARN"
    }
}

function Run-FullRepair {
    Write-Log "Starting Full Repair sequence."
    Run-ExternalCommand -FilePath "dism.exe" -Arguments @("/Online","/Cleanup-Image","/CheckHealth")   -FriendlyName "DISM CheckHealth"   | Out-Null
    Run-ExternalCommand -FilePath "dism.exe" -Arguments @("/Online","/Cleanup-Image","/ScanHealth")    -FriendlyName "DISM ScanHealth"    | Out-Null
    Run-ExternalCommand -FilePath "dism.exe" -Arguments @("/Online","/Cleanup-Image","/RestoreHealth") -FriendlyName "DISM RestoreHealth" | Out-Null
    Run-ExternalCommand -FilePath "sfc.exe"  -Arguments @("/scannow")                                   -FriendlyName "SFC ScanNow"       | Out-Null
    Export-RepairLogs
    Write-Log "Full Repair sequence finished." "SUCCESS"
}

function Run-SourceRepair {
    Write-Host ""
    Write-Host "Enter the full DISM source value." -ForegroundColor Yellow
    Write-Host "Example WIM: WIM:D:\sources\install.wim:1" -ForegroundColor Gray
    Write-Host "Example ESD: ESD:D:\sources\install.esd:1" -ForegroundColor Gray
    Write-Host ""
    $sourceValue = Read-Host "Source"

    if ([string]::IsNullOrWhiteSpace($sourceValue)) {
        Write-Log "No source value entered. Source repair cancelled." "WARN"
        return
    }

    Write-Log "Starting source-based DISM repair using: $sourceValue"
    $dismOk = Run-ExternalCommand -FilePath "dism.exe" -Arguments @("/Online","/Cleanup-Image","/RestoreHealth","/Source:$sourceValue","/LimitAccess") -FriendlyName "DISM RestoreHealth With Source"
    $sfcOk  = Run-ExternalCommand -FilePath "sfc.exe"  -Arguments @("/scannow") -FriendlyName "SFC ScanNow"
    Export-RepairLogs

    if ($dismOk -and $sfcOk) {
        Write-Log "Source-based repair completed." "SUCCESS"
    }
    else {
        Write-Log "Source-based repair completed with warnings. Review the log." "WARN"
    }
}

function Reset-WindowsUpdateComponents {
    Write-Log "Starting Windows Update component reset."

    $services = @("bits","wuauserv","appidsvc","cryptsvc","msiserver")
    foreach ($svc in $services) {
        Run-ExternalCommand -FilePath "sc.exe" -Arguments @("stop",$svc) -FriendlyName "Stop service $svc" | Out-Null
    }

    $qmgrPath = Join-Path $env:ALLUSERSPROFILE "Application Data\Microsoft\Network\Downloader\qmgr*.dat"
    Get-ChildItem -Path $qmgrPath -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

    $softwareDistribution = Join-Path $env:windir "SoftwareDistribution"
    $catroot2 = Join-Path $env:windir "System32\catroot2"

    if (Test-Path $softwareDistribution) {
        Rename-Item -Path $softwareDistribution -NewName ("SoftwareDistribution.old_" + $TimeStamp) -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path $catroot2) {
        Rename-Item -Path $catroot2 -NewName ("catroot2.old_" + $TimeStamp) -Force -ErrorAction SilentlyContinue
    }

    foreach ($svc in $services) {
        Run-ExternalCommand -FilePath "sc.exe" -Arguments @("start",$svc) -FriendlyName "Start service $svc" | Out-Null
    }

    Write-Log "Windows Update component reset completed." "SUCCESS"
}

function Schedule-Chkdsk {
    Write-Log "Preparing CHKDSK schedule for drive C:"

    $cmd = 'echo Y|chkdsk C: /F /R'
    Run-ExternalCommand -FilePath "cmd.exe" -Arguments @("/c",$cmd) -FriendlyName "Schedule CHKDSK C: /F /R" | Out-Null

    Write-Log "CHKDSK scheduled. It should run on reboot if the system drive is in use." "WARN"
}

function Export-RepairLogs {
    Write-Log "Exporting CBS and DISM logs."

    $cbsLog = Join-Path $env:windir "Logs\CBS\CBS.log"
    $dismLog = Join-Path $env:windir "Logs\DISM\dism.log"

    if (Test-Path $cbsLog) {
        Copy-Item -Path $cbsLog -Destination (Join-Path $ExportRoot "CBS_$TimeStamp.log") -Force
        Write-Log "CBS log exported." "SUCCESS"
    }
    else {
        Write-Log "CBS log not found." "WARN"
    }

    if (Test-Path $dismLog) {
        Copy-Item -Path $dismLog -Destination (Join-Path $ExportRoot "DISM_$TimeStamp.log") -Force
        Write-Log "DISM log exported." "SUCCESS"
    }
    else {
        Write-Log "DISM log not found." "WARN"
    }

    $sfcdetails = Join-Path $ExportRoot "SFC_Details_$TimeStamp.txt"
    if (Test-Path $cbsLog) {
        Select-String -Path $cbsLog -Pattern "\[SR\]" | ForEach-Object { $_.Line } | Set-Content -Path $sfcdetails
        Write-Log "Filtered SFC details exported." "SUCCESS"
    }
}

function Open-LogFolder {
    if (Test-Path $LogRoot) {
        Start-Process explorer.exe $LogRoot
        Write-Log "Opened log folder."
    }
}

function Ask-Reboot {
    Write-Host ""
    $answer = Read-Host "Reboot now? (Y/N)"
    if ($answer -match '^[Yy]') {
        Write-Log "User chose to reboot the system." "WARN"
        Restart-Computer -Force
    }
    else {
        Write-Log "User skipped reboot."
    }
}

Write-Log "Script started by $env:USERNAME on $env:COMPUTERNAME"
Write-Log "Brand: $BrandName | GitHub: $GitHubUrl | Donate: $DonateUrl"

do {
    Show-Banner
    Write-Host "1. Quick Repair (DISM RestoreHealth + SFC)" -ForegroundColor White
    Write-Host "2. Full Repair (CheckHealth + ScanHealth + RestoreHealth + SFC + Export Logs)" -ForegroundColor White
    Write-Host "3. Repair with ISO/WIM/ESD Source" -ForegroundColor White
    Write-Host "4. Reset Windows Update Components" -ForegroundColor White
    Write-Host "5. Schedule CHKDSK on C: for next reboot" -ForegroundColor White
    Write-Host "6. Export CBS/DISM/SFC Logs" -ForegroundColor White
    Write-Host "7. Open Log Folder" -ForegroundColor White
    Write-Host "8. Exit" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "Select an option (1-8)"

    switch ($choice) {
        "1" {
            Run-QuickRepair
            Ask-Reboot
            Pause-Continue
        }
        "2" {
            Run-FullRepair
            Ask-Reboot
            Pause-Continue
        }
        "3" {
            Run-SourceRepair
            Ask-Reboot
            Pause-Continue
        }
        "4" {
            Reset-WindowsUpdateComponents
            Pause-Continue
        }
        "5" {
            Schedule-Chkdsk
            Ask-Reboot
            Pause-Continue
        }
        "6" {
            Export-RepairLogs
            Pause-Continue
        }
        "7" {
            Open-LogFolder
            Pause-Continue
        }
        "8" {
            Write-Log "User exited the script."
        }
        default {
            Write-Log "Invalid menu selection: $choice" "WARN"
            Pause-Continue
        }
    }
}
while ($choice -ne "8")