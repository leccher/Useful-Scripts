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

function Write-LogWIthDebug {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [ValidateSet('DEBUG','INFO','WARN','ERROR')]
        [string]$Level = 'INFO',

        # Se vuoi poter colorare la console quando non scrivi su file
        [switch]$ColorToConsole = $true
    )

    # Mappa livelli a priorità (se non già definite fuori)
    if (-not $script:LogLevels) {
        $script:LogLevels = @{
            'DEBUG' = 10
            'INFO'  = 20
            'WARN'  = 30
            'ERROR' = 40
        }
    }
    if (-not $script:LogLevel) { $script:LogLevel = 'INFO' }           # livello minimo corrente
    if (-not $script:LogToFile) { $script:LogToFile = $false }         # logging su file sì/no
    if (-not $script:LogFilePath) { $script:LogFilePath = "$PWD\app.log" }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $formatted = "[$timestamp][$Level] $Message"

    # Filtra per livello
    if ($script:LogLevels[$Level] -ge $script:LogLevels[$script:LogLevel]) {

        # 1) Stream debug (senza colore: Write-Debug non lo supporta)
        if ($Level -eq 'DEBUG') {
            Write-Debug $formatted
        }

        # 2) Console colorata (facoltativa) con Write-Host
        if ($ColorToConsole) {
            $fg = switch ($Level) {
                'DEBUG' { 'DarkGray' }
                'INFO'  { 'White' }
                'WARN'  { 'Yellow' }
                'ERROR' { 'Red' }
            }
            Write-Host $formatted -ForegroundColor $fg
        }

        # 3) Log su file se abilitato
        if ($script:LogToFile) {
            $dir = Split-Path -Parent $script:LogFilePath
            if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
            Add-Content -Path $script:LogFilePath -Value $formatted
        }
    }
}

function Write-LogWithoutDebug {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet('DEBUG','INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )

    if (-not $script:LogLevels) {
        $script:LogLevels = @{ DEBUG=10; INFO=20; WARN=30; ERROR=40 }
    }
    if (-not $script:LogLevel) { $script:LogLevel = 'INFO' }
    if (-not $script:LogToFile) { $script:LogToFile = $false }
    if (-not $script:LogFilePath) { $script:LogFilePath = "$PWD\app.log" }

    if ($script:LogLevels[$Level] -lt $script:LogLevels[$script:LogLevel]) { return }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $formatted = "[$timestamp][$Level] $Message"

    $fg = switch ($Level) {
        'DEBUG' { 'DarkGray' }
        'INFO'  { 'White' }
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red' }
    }

    Write-Host $formatted -ForegroundColor $fg

    if ($script:LogToFile) {
        $dir = Split-Path -Parent $script:LogFilePath
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        Add-Content -Path $script:LogFilePath -Value $formatted
    }
}

function Write-LogWIthPSTyle {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet('DEBUG','INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )

    if (-not $script:LogLevels) {
        $script:LogLevels = @{ DEBUG=10; INFO=20; WARN=30; ERROR=40 }
    }
    if (-not $script:LogLevel) { $script:LogLevel = 'INFO' }
    if (-not $script:LogToFile) { $script:LogToFile = $false }
    if (-not $script:LogFilePath) { $script:LogFilePath = "$PWD\app.log" }

    if ($script:LogLevels[$Level] -lt $script:LogLevels[$script:LogLevel]) { return }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $formatted = "[$timestamp][$Level] $Message"

    $color = switch ($Level) {
        'DEBUG' { $PSStyle.Foreground.BrightBlack }
        'INFO'  { $PSStyle.Foreground.White }
        'WARN'  { $PSStyle.Foreground.Yellow }
        'ERROR' { $PSStyle.Foreground.Red }
    }
    $reset = $PSStyle.Reset

    # Scrive sullo stream "Success" (Output)
    $colored = "$color$formatted$reset"
    Write-Output $colored

    if ($script:LogToFile) {
        $dir = Split-Path -Parent $script:LogFilePath
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        Add-Content -Path $script:LogFilePath -Value $formatted   # su file senza codici ANSI
    }
}

function Write-Log {
	param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet('DEBUG','INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )
	Write-LogWIthPSTyle $Message $Level
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