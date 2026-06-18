# Server Health Check Toolkit

A read-only PowerShell toolkit for Windows Server health and escalation evidence.

## Features

- OS, uptime, roles, and feature context
- Disk and memory summary
- Service and event log health indicators
- SMB share inventory
- Pending reboot indicator
- CSV, JSON, and HTML reports

## How to run

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Server_Health_Check_Toolkit.ps1
```

## Safety

Diagnostic-only. It does not change server roles, services, shares, or settings.
