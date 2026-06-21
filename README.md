# Server Health Check Toolkit

A PowerShell toolkit for Windows Server health evidence and selected guarded repairs.

## Diagnostic script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Server_Health_Check_Toolkit.ps1
```

## Repair script

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Server_Health_Repair_Toolkit.ps1 -RepairSystemFiles -DryRun
```

Examples:

```powershell
.\Server_Health_Repair_Toolkit.ps1 -RestartService DNS,Spooler
.\Server_Health_Repair_Toolkit.ps1 -ScanVolume C
.\Server_Health_Repair_Toolkit.ps1 -RepairSystemFiles
.\Server_Health_Repair_Toolkit.ps1 -ClearTemp
```

## What the repair does

- Restarts explicitly selected Windows services.
- Runs an online scan of one selected volume.
- Runs DISM RestoreHealth and System File Checker.
- Removes stale files older than seven days from the Windows temp directory.
- Captures OS, installed-role, disk, service and reboot state before and after repair.
- Supports `-DryRun`, confirmation prompts, logs and clear exit codes.

## Safety

Service restarts can interrupt server workloads. The tool does not add or remove roles, change shares, edit firewall rules or reboot automatically.

## Author

Dewald Pretorius — L2 IT Support Engineer
