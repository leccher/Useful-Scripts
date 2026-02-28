# Global debug level (can be modified elsewhere
# This module implements a simple logger to debug other features.

# Keep attention to $DebugPreference
# "SilentlyContinue"	Default. No messages showed.
# "Continue"	Debug messages showed in console
# "Stop"	PowerShell stops execution meeting Write-Debug.
# "Inquire"	PowerShell user input before continue.

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
		[Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
	
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formatted = "[$timestamp][$Level] $Message"

	if ($LogLevels[$Level] -ge $LogLevels[$LogLevel]) {
        Write-Debug $formatted -foregroundColor Magenta
		if ($LogToFile) {
			Add-Content -Path $LogFilePath -Value $formatted
		}
    }
}

function Enable-LogToFile {
    param (
        [Parameter(Mandatory=$false)]
        [string]$file
    )

    # Se viene fornito un file, aggiorna il percorso
    if ($file) {
        Set-LogFilePath $file
    }

    # Se il percorso globale è ancora vuoto (non era stato passato né prima né ora), avvisa ed esci
    if (-not $Global:LogFilePath) {
        Write-Warning "Log file path needed. Call Enable-LogToFile 'path-to-file'"
        return # Non attivare il log se non c'è un percorso
    }

    $Global:LogToFile = $true
    Write-Host "Logging to file abilitato: $($Global:LogFilePath)"
}

function Disable-LogToFile {
    $Global:LogToFile = $false
}

function Set-LogFilePath {
	param (
        [Parameter(Mandatory=$true)]
        [string]$file       
    )
	$Global:LogFilePath=$file
}

function Set-LogLevel {
	param (
        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
	$Global:LogLevel=$Level
}

function Show-WriteLogHelp {
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

Export-ModuleMember -Function Show-WriteLogHelp, Write-Log, Set-LogFilePath, Enable-LogToFile, Disable-LogToFile