# Global debug level (can be modified elsewhere
# This module implements a simple logger to debug other features.

# Keep attention to $DebugPreference
# "SilentlyContinue"	Default. No messages showed.
# "Continue"	Debug messages showed in console
# "Stop"	PowerShell stops execution meeting Write-Debug.
# "Inquire"	PowerShell user in put before continue.

$Global:LogLevel = "INFO"

# Level maps
$Global:LogLevels = @{
    "DEBUG" = 0
    "INFO"  = 1
    "WARN"  = 2
    "ERROR" = 3
}

# Logging on file
$Global:LogToFile = $false
$Global:LogFilePath = "$env:USERPROFILE\ps_scripts_log.txt"

function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
	
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formatted = "[$timestamp][$Level] $Message"

	if ($LogLevels[$Level] -ge $LogLevels[$LogLevel]) {
        Write-Debug $formatted
		if ($LogToFile) {
			Add-Content -Path $LogFilePath -Value $formatted
		}
    }
}

function Write-Log-Module-Help {
	Write-Host "Write-Log for PowerShell module"
	Write-Host "This module implements Write-Log function."
	Write-Host 'Possilbe levels are: "DEBUG", "INFO", "WARN", "ERROR"'
	Write-Host 'It uses Write-Debug, so enable all by $DebugPreference="Continue"'
	Write-Host ""
	Write-Host "Usage:"
	Write-Host 'LogLevel = "DEBUG"'
	Write-Host "Write-Log 'Message' -Level 'WARN'"
	Write-Host ""
	Write-Host "Optionally logs can also be written on file"
	Write-Host "LogToFile = true"
	Write-Host "LogPathFile = \$env:USERPROFILE\ps_scripts_log.txt"
}

Write-Host 'Module WriteLog for PowerShell enabled (see Write-Log-Module-Help for usage)'