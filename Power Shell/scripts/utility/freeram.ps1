
<#
.SYNOPSIS
  Frees RAM by trimming the working set of processes and optionally clears the Standby List (if you have EmptyStandbyList.exe).

.PARAMETER TrimWorkingSets
  Trims the working set of non-system and non-critical processes.

.PARAMETER ClearStandbyListPath
  Path to EmptyStandbyList.exe (Sysinternals). If provided, executes: standbylist and modifiedpagelist.

.PARAMETER Exclude
  List of process names to exclude (without extension), e.g. -Exclude "chrome","code","Teams"

.EXAMPLE
  .\Free-RAM.ps1 -TrimWorkingSets

.EXAMPLE
  .\Free-RAM.ps1 -TrimWorkingSets -ClearStandbyListPath "C:\Tools\EmptyStandbyList.exe"

.EXAMPLE
  .\Free-RAM.ps1 -TrimWorkingSets -Exclude "chrome","firefox"
#>

[CmdletBinding()]
param(
    [switch]$TrimWorkingSets = $true,
    [string]$ClearStandbyListPath,
    [string[]]$Exclude = @()
)

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Import Win32 function to empty the working set of a process.
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Psapi {
    [DllImport("psapi.dll", SetLastError=true)]
    public static extern bool EmptyWorkingSet(IntPtr hProcess);
}
"@

# List of processes NOT to touch (critical/system)
$defaultExclusions = @(
    "System","Idle","Registry","smss","csrss","wininit","winlogon","services","lsass",
    "svchost","Memory Compression","Secure System","dwm","sihost","ShellExperienceHost",
    "explorer","fontdrvhost","SearchIndexer","audiodg","spoolsv","conhost","WmiPrvSE",
    "MsMpEng","TiWorker","dllhost"
)

$allExclusions = ($defaultExclusions + $Exclude) | Select-Object -Unique

$results = [System.Collections.Generic.List[pscustomobject]]::new()

Write-Host "=== Free-RAM: started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -ForegroundColor Cyan

# 1) Trim working sets (optional)
if ($TrimWorkingSets) {
    Write-Host "`n[1/2] Trimming process working sets..." -ForegroundColor Yellow
    $procs = Get-Process | Where-Object {
        $_.Name -notin $allExclusions -and $_.Id -ne $PID -and $_.Handle -ne $null
    }

    foreach ($p in $procs) {
        try {
            $before = $p.WorkingSet64
            [void][Psapi]::EmptyWorkingSet($p.Handle)
            Start-Sleep -Milliseconds 20
            $p.Refresh()
            $after = $p.WorkingSet64

            $results.Add([pscustomobject]@{
                Process      = $p.Name
                Id           = $p.Id
                BeforeMB     = [Math]::Round($before/1MB,2)
                AfterMB      = [Math]::Round($after/1MB,2)
                FreedMB      = [Math]::Round(($before-$after)/1MB,2)
                Timestamp    = (Get-Date)
                Action       = "TrimWorkingSet"
            })
        }
        catch {
            $results.Add([pscustomobject]@{
                Process      = $p.Name
                Id           = $p.Id
                Action       = "Skipped: " + ($_.Exception.Message)
            })
        }
    }

    $freedTotal = ($results | Where-Object {$_.FreedMB} | Measure-Object FreedMB -Sum).Sum
    if (-not $freedTotal) { $freedTotal = 0 }
    Write-Host ("  -> Estimated physical memory freed: {0} MB" -f [Math]::Round($freedTotal,2)) -ForegroundColor Green
}

# 2) Clear Standby List (if specified)
if ($ClearStandbyListPath) {
    Write-Host "`n[2/2] Clearing Standby List..." -ForegroundColor Yellow

    if (-not (Test-Path $ClearStandbyListPath)) {
        Write-Warning "Invalid path: $ClearStandbyListPath"
    }
    elseif (-not (Test-Admin)) {
        Write-Warning "Run PowerShell as Administrator to clear the Standby List."
    }
    else {
        try {
            & $ClearStandbyListPath "standbylist" | Out-Null
            Start-Sleep -Seconds 1
            & $ClearStandbyListPath "modifiedpagelist" | Out-Null
            Write-Host "  -> Standby List cleared." -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to execute EmptyStandbyList.exe: $($_.Exception.Message)"
        }
    }
}

# Summary output
if ($results.Count -gt 0) {
    $results | Format-Table -AutoSize
}

Write-Host "`nCompleted!" -ForegroundColor Cyan
