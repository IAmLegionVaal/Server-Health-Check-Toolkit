[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
 [string[]]$RestartService,
 [ValidatePattern('^[A-Z]$')][string]$ScanVolume,
 [switch]$RepairSystemFiles,
 [switch]$ClearTemp,
 [switch]$RestartServerManager,
 [switch]$DryRun,[switch]$Yes,
 [string]$OutputPath=(Join-Path $env:ProgramData 'ServerHealthRepair')
)
$ErrorActionPreference='Stop';$script:Failures=0;$script:Actions=0
$run=Join-Path $OutputPath (Get-Date -Format yyyyMMdd_HHmmss);New-Item -ItemType Directory $run -Force|Out-Null
$log=Join-Path $run 'repair.log';$before=Join-Path $run 'before.json';$after=Join-Path $run 'after.json'
function Log($m){"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $m"|Tee-Object -FilePath $log -Append}
function Admin{$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
function State{[pscustomobject]@{Collected=Get-Date;OS=Get-CimInstance Win32_OperatingSystem|Select-Object Caption,Version,BuildNumber,LastBootUpTime,FreePhysicalMemory;Volumes=Get-Volume|Select-Object DriveLetter,FileSystem,HealthStatus,SizeRemaining,Size;AutoServices=Get-CimInstance Win32_Service|Where-Object {$_.StartMode -eq 'Auto' -and $_.State -ne 'Running'}|Select-Object Name,State,ExitCode;Roles=Get-WindowsFeature -ErrorAction SilentlyContinue|Where-Object Installed|Select-Object Name,DisplayName;PendingReboot=[bool](Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending')}}
function Act($d,[scriptblock]$a){$script:Actions++;Log $d;if($DryRun){Log "DRY-RUN: $d";return};try{&$a;Log "SUCCESS: $d"}catch{$script:Failures++;Log "FAILED: $d - $($_.Exception.Message)"}}
State|ConvertTo-Json -Depth 6|Set-Content $before -Encoding UTF8
if(-not($RestartService -or $ScanVolume -or $RepairSystemFiles -or $ClearTemp -or $RestartServerManager)){Write-Error 'Choose at least one repair action.';exit 2}
if(-not $DryRun -and -not(Admin)){Write-Error 'Run from elevated PowerShell.';exit 4}
if(-not $Yes -and -not $DryRun){if((Read-Host 'Apply selected Windows Server repairs? Type YES') -ne 'YES'){Log 'Cancelled.';exit 10}}
foreach($s in @($RestartService)){Get-Service $s -ErrorAction Stop|Out-Null;Act "Restarting service $s" {Restart-Service $s -Force}}
if($ScanVolume){Act "Scanning volume ${ScanVolume}:" {Repair-Volume -DriveLetter $ScanVolume -Scan -ErrorAction Stop|Out-Null}}
if($RepairSystemFiles){Act 'Running DISM RestoreHealth' {$p=Start-Process dism.exe -ArgumentList '/Online','/Cleanup-Image','/RestoreHealth' -Wait -PassThru -NoNewWindow;if($p.ExitCode){throw "DISM exited $($p.ExitCode)"}};Act 'Running System File Checker' {$p=Start-Process sfc.exe -ArgumentList '/scannow' -Wait -PassThru -NoNewWindow;if($p.ExitCode -notin 0,1){throw "SFC exited $($p.ExitCode)"}}}
if($ClearTemp){Act 'Removing stale system temp files older than seven days' {Get-ChildItem "$env:SystemRoot\Temp" -Force -ErrorAction SilentlyContinue|Where-Object LastWriteTime -lt (Get-Date).AddDays(-7)|Remove-Item -Recurse -Force -ErrorAction SilentlyContinue}}
if($RestartServerManager){if(Get-Service ServerManager -ErrorAction SilentlyContinue){Act 'Restarting Server Manager service' {Restart-Service ServerManager -Force}}else{Log 'ServerManager service not present on this build.'}}
Start-Sleep 3;State|ConvertTo-Json -Depth 6|Set-Content $after -Encoding UTF8
if($script:Failures){Log "Completed with $script:Failures failure(s).";exit 20};Log "Repair completed. Actions: $script:Actions";exit 0
