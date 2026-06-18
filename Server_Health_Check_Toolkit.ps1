#requires -Version 5.1
<#
.SYNOPSIS
    Server Health Check Toolkit.
.DESCRIPTION
    Read-only Windows Server health reporter for L2/L3 support.
#>
[CmdletBinding()]
param([string]$OutputPath,[int]$Hours=48)
$RunStamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Server_Health_Reports'}
New-Item -Path $OutputPath -ItemType Directory -Force|Out-Null
function Export-Data{param($Name,$Data)$Data|Export-Csv (Join-Path $OutputPath "$Name.csv") -NoTypeInformation -Encoding UTF8;$Data|ConvertTo-Json -Depth 6|Set-Content (Join-Path $OutputPath "$Name.json") -Encoding UTF8}
$os=Get-CimInstance Win32_OperatingSystem;$cs=Get-CimInstance Win32_ComputerSystem
$summary=[PSCustomObject]@{Computer=$env:COMPUTERNAME;OS=$os.Caption;Build=$os.BuildNumber;LastBoot=$os.LastBootUpTime;MemoryGB=[math]::Round($cs.TotalPhysicalMemory/1GB,2);Generated=Get-Date}
$disks=Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"|Select-Object DeviceID,VolumeName,FileSystem,@{n='SizeGB';e={[math]::Round($_.Size/1GB,2)}},@{n='FreeGB';e={[math]::Round($_.FreeSpace/1GB,2)}}
$services=Get-Service|Where-Object {$_.StartType -eq 'Automatic' -and $_.Status -ne 'Running'}|Select-Object Name,DisplayName,Status,StartType
try{$features=Get-WindowsFeature|Where-Object Installed|Select-Object Name,DisplayName,InstallState}catch{$features=@()}
try{$shares=Get-SmbShare|Select-Object Name,Path,Description,Special}catch{$shares=@()}
$start=(Get-Date).AddHours(-1*$Hours);$events=Get-WinEvent -FilterHashtable @{LogName='System';Level=1,2,3;StartTime=$start} -ErrorAction SilentlyContinue|Select-Object -First 150 TimeCreated,Id,ProviderName,LevelDisplayName,Message
$pending=(Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending')
Export-Data "summary_$RunStamp" @($summary);Export-Data "disks_$RunStamp" $disks;Export-Data "auto_services_not_running_$RunStamp" $services;Export-Data "installed_features_$RunStamp" $features;Export-Data "smb_shares_$RunStamp" $shares;Export-Data "system_events_$RunStamp" $events
$status=[PSCustomObject]@{PendingReboot=$pending;AutomaticServicesNotRunning=@($services).Count;SystemEventCount=@($events).Count;Generated=Get-Date}
$html="<h1>Server Health Check - $env:COMPUTERNAME</h1><p>Generated $(Get-Date)</p><h2>Status</h2>$(@($status)|ConvertTo-Html -Fragment)<h2>Disks</h2>$($disks|ConvertTo-Html -Fragment)<h2>Automatic Services Not Running</h2>$($services|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Server Health Check'|Set-Content (Join-Path $OutputPath "server_health_$RunStamp.html") -Encoding UTF8
$status|Format-List
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
Start-Process explorer.exe -ArgumentList "`"$OutputPath`"" -ErrorAction SilentlyContinue
