# ==============================================================================
# Module: Logger (Level-Based Logging Module)
# ==============================================================================
# ---- PowerShell version check -------------------------------------------------
$IsPS7 = $PSVersionTable.PSEdition -eq 'Core' -and
         $PSVersionTable.PSVersion.Major -ge 7
if (-not $IsPS7) {
    throw @"
This PowerShell profile requires PowerShell 7 or later.
Current version: $($PSVersionTable.PSVersion)
Please start pwsh instead of Windows PowerShell 5.1.
"@
}
# ---- Module variables and functions -------------------------------------------------
$script:MODULE_NAME = "LevelBasedLoggingModule"
$script:MODULE_CODE = "Logger"

$script:DebugEnabled = $false

function Set-LoggerDebugEnabled {
    param(
        [bool]$Enabled
    )
    $script:DebugEnabled = $Enabled
    Write-Host "Debug mode is now: $($Enabled ? 'ON' : 'OFF')" -ForegroundColor Cyan
}

<#
.SYNOPSIS
  Displays help.  Displays help information for the module.

  By default, the function displays a summary of all exported 
  commands with their synopsis. It can also display detailed help for
  a specific command or the full module help.

.PARAMETER Name
  Name or partial name of an command to display detailed help for.

.PARAMETER Module
  Displays the full help of the module.

.EXAMPLE
  Show-LoggerHelp

.EXAMPLE
  Show-LoggerHelp -Name Get-LocalizedMessage

.EXAMPLE
  Show-LoggerHelp -Module

.NOTES
  This function is based entirely on Comment-Based Help and Get-Help.
  It is intended as the canonical discovery entry point for i18n features.
#>

function Show-LoggerHelp {
    param(
        [string]$Name
    )

    $moduleName = $script:MODULE_NAME

    # --- Full module help -----------------------------------------------------
    if (-not $Name) {
        Get-Help $moduleName -Full
        return
    }

    # --- Help for a specific command -----------------------------------------
    $commands = Get-Command -Module $moduleName -CommandType Function |
                Where-Object Name -like "*$Name*"

    if (-not $commands) {
        Write-Warning "No module command found matching '$Name'."
        return
    }

    foreach ($cmd in $commands) {
        Get-Help $cmd.Name -Full
    }
}

# --- Load module messages -----------------------------------------------------
function Get-i18nMessages {
  if (-not $script:MESSAGES) {
    $script:MESSAGES = Import-ModuleMessages -ModuleName $script:MODULE_NAME -BasePath $PSScriptRoot
  }
  return $script:MESSAGES
}


# script debug level (can be modified elsewhere
# This module implements a simple logger to debug other features.

# Keep attention to $DebugPreference
# "SilentlyContinue"	Default. No messages showed.
# "Continue"	Debug messages showed in console
# "Stop"	PowerShell stops execution meeting Write-Debug.
# "Inquire"	PowerShell user input before continue.

$script:LogLevel = "INFO"

# Level maps
$script:LogLevels = @{
    "DEBUG" = 0
    "INFO"  = 1
    "WARN"  = 2
    "ERROR" = 3
}

# Logging on file
$script:LogToFile = $false
$script:LogFilePath = "$env:USERPROFILE\ps_scripts_log.txt"
$script:LoggingFunction = "Write-LogWithDebug"


<#
.SYNOPSIS
  Writes a log message level is DEBUG, the message is written using Write-Debug,  Writes a log message using level-based filtering with optional debug integration.
  allowing it to be filtered via $DebugPreference.

  For other log levels (INFO, WARN, ERROR), the message is written to the
  console using Write-Host with optional color support.

  If file logging is enabled, the message is also appended to the configured
  log file.

.PARAMETER Message
  The log message to write.

.PARAMETER Level
  Severity level of the message.
  Supported values are: DEBUG, INFO, WARN, ERROR.

.PARAMETER ColorToConsole
  When specified, enables colored output to the console using Write-Host.
  This parameter has no effect when Level is DEBUG, as Write-Debug does not
  support colored output.

.EXAMPLE
  Write-LogWithDebug -Message "Initialization complete" -Level INFO

.EXAMPLE
  Write-LogWithDebug -Message "Configuration missing" -Level WARN

.EXAMPLE
  Write-LogWithDebug -Message "Entering debug mode" -Level DEBUG

.NOTES
  - DEBUG messages are written using Write-Debug and respect $DebugPreference.
  - This function is typically used as an internal logging backend.
  - File logging behavior depends on the global logging configuration.

.DESCRIPTION
  Writes a log message according to the configured log level and output mode.

#>
# FLollow 3 modes to write log:
# 1) With Write-Debug (no color, but can be filtered by $DebugPreference)
function Write-LogWithDebug {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [ValidateSet('DEBUG','INFO','WARN','ERROR')]
        [string]$Level = 'INFO',

        # To have colors in console, Write-Debug does not support it, so we can use Write-Host instead, but it is not filterable by $DebugPreference. This switch allows to choose if use Write-Debug (no color, filterable) or Write-Host (colored, but not filterable).
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
        }else{
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
        }

        # 3) Log su file se abilitato
        if ($script:LogToFile) {
            $dir = Split-Path -Parent $script:LogFilePath
            if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
            Add-Content -Path $script:LogFilePath -Value $formatted
        }
    }
}
<#
.SYNOPSIS
  Writes a log message using level-based filtering does not use Write-Debug and therefore does not interact  Writes a log message using level-based filtering without using Write-Debug.
  with $DebugPreference.

  If file logging is enabled, the message is also appended to the configured
  log file.

.PARAMETER Message
  The log message to write.

.PARAMETER Level
  Severity level of the message.
  Supported values are: DEBUG, INFO, WARN, ERROR.

.EXAMPLE
  Write-LogWithoutDebug -Message "System started" -Level INFO

.EXAMPLE
  Write-LogWithoutDebug -Message "Configuration missing" -Level WARN

.EXAMPLE
  Write-LogWithoutDebug -Message "Detailed trace" -Level DEBUG

.NOTES
  - All output is written using Write-Host with severity-based colors.
  - This function does not respect $DebugPreference.
  - Intended for scenarios where consistent, always-visible console output
    is required.

.DESCRIPTION
  Writes a log message to the console using Write-Host with colored output,
  applying level-based filtering based on the configured log level.

  Messages with a severity lower than the current log level are ignored.
#>
# 2) With Write-Host
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

    # Skeep if lower than setted log level
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
<# Messages are filtered according to the configured log level.
  Messages with a severity lower than the current log level are ignored.

  This function does not use Write-Debug and does not respect
  $DebugPreference. Output is written to the success stream, which means
  it can be captured, redirected, or further processed in the pipeline.

  If file logging is enabled, the unstyled version of the message is
  appended to the configured log file.

.PARAMETER Message
  The log message to write.

.PARAMETER Level
  Severity level of the message.
  Supported values are: DEBUG, INFO, WARN, ERROR.

.EXAMPLE
  Write-LogWithStyle -Message "Operation completed" -Level INFO

.EXAMPLE
  Write-LogWithStyle -Message "Something might be wrong" -Level WARN

.EXAMPLE
  Write-LogWithStyle -Message "Detailed diagnostics" -Level DEBUG

.NOTES
  - Uses ANSI styling via $PSStyle.
  - Output is written to the pipeline (Write-Output), not directly to the host.
  - ANSI styling may not be supported by all consoles or output targets.
  - Intended as an alternative backend for structured or redirected output.

.SYNOPSIS
  Writes a log message using ANSI-styled output.

.DESCRIPTION
  Writes a log message using ANSI escape sequences provided by $PSStyle
  to produce colored output on the pipeline (Write-Output).

#>
# 3) With Write-Output (colored with ANSI codes, but not filterable and may not work in all consoles)
function Write-LogWithStyle {
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
<#
.SYNOPSIS
  Writes a log message using the configured logging backend.

.DESCRIPTION
  Writes a log message with the specified severity level using the
  currently configured logging backend.

  The actual logging behavior (Write-Debug, Write-Host, ANSI-styled
  output, file logging, etc.) is delegated to the internal logging
  function selected by the module configuration.

  This function represents the primary, user-facing logging API
  and should be preferred over calling backend functions directly.

.PARAMETER Message
  The log message to write.

.PARAMETER Level
  Severity level of the message.
  Supported values are: DEBUG, INFO, WARN, ERROR.

.EXAMPLE
  Write-Log -Message "Application started"

.EXAMPLE
  Write-Log -Message "Invalid configuration detected" -Level WARN

.EXAMPLE
  Write-Log -Message "Detailed diagnostics enabled" -Level DEBUG

.NOTES
  - This function acts as a dispatcher and does not implement logging
    logic directly.
  - The effective logging behavior depends on the selected backend
    and current logger configuration.
#>
function Write-Log {
	param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [ValidateSet('DEBUG','INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )
	& $script:LoggingFunction $Message $Level
}
<#
.SYNOPSIS
  Enables logging to a file.

.DESCRIPTION
  Enables file-based logging for the logger.

  If a file path is provided, the log file path is updated before enabling
  logging. If no log file path is configured, a warning message is emitted
  and logging to file is not enabled.

  When enabled, all subsequent log messages that pass level filtering
  are appended to the configured log file.

.PARAMETER file
  Optional path to the log file.
  If specified, updates the log file path before enabling file logging.

.EXAMPLE
  Enable-LogToFile

.EXAMPLE
  Enable-LogToFile -file "C:\Logs\app.log"

.NOTES
  - This function modifies global logging state.
  - A valid log file path must be configured before enabling file logging.
#>
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
    if (-not $script:LogFilePath) {
        Write-Warning (Get-LocalizedMessage -Messages (Get-i18nMessages) -Id LOG_FILE_PATH_NEEDED)
        return # Non attivare il log se non c'è un percorso
    }

    $script:LogToFile = $true
    Write-Host (Get-LocalizedMessage -Messages (Get-i18nMessages) -Id LOG_TO_FILE_ENABLED)
}
<#
.SYNOPSIS
  Disables log file path is preserved but not used while disabled.  Disables logging to a file.

.DESCRIPTION
  Disables file-based logging for the logger.
  Logging continues to the console or other configured outputs,
  but messages are no longer written to the log file.

.EXAMPLE
  Disable-LogToFile

.NOTES
  - This function modifies global logging state.
  - The configured log file path is preserved and can be re-enabled later.
#>
function Disable-LogToFile {
    $script:LogToFile = $false
}
<#
.SYNOPSIS
  Sets the log file path used for file.PARAMETER file  Sets the log file path used for file-based logging.
  Path to the log file to use for file-based logging.

.EXAMPLE
  Set-LogFilePath -file "C:\Logs\app.log"

.NOTES
  - This function modifies global logging state.
  - The directory is created automatically when logging occurs if it
    does not already exist.

.DESCRIPTION
  Updates the file path used by the logger when file logging is enabled.

  This function does not automatically enable file logging; it only sets
  the path that will be used once file logging is activated.

#>
function Set-LogFilePath {
	param (
        [Parameter(Mandatory=$true)]
        [string]$file       
    )
	$script:LogFilePath=$file
}
<#
.SYNOPSIS
  Sets the minimum log level for message output.

.DESCRIPTION
  Sets the minimum severity level that log messages must have in order
  to be processed and written to the console or log file.

  Messages with a severity lower than the configured level are ignored.

.PARAMETER Level
  Minimum log severity level.
  Supported values are: DEBUG, INFO, WARN, ERROR.

.EXAMPLE
  Set-LogLevel -Level INFO

.EXAMPLE
  Set-LogLevel -Level DEBUG

.NOTES
  - This function modifies global logging state.
  - The default log level is INFO.
#>
function Set-LogLevel {
	param (
      [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
      [string]$Level = "INFO"
    )
	$script:LogLevel=$Level
}

function Initialize-Logger {
  param (
    [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
    [string]$Level,
    [string]$File
  )
  $null = Get-i18nMessages
  if($Level) { Set-LogLevel -Level $Level }
  if($File) { Enable-LogToFile -file $File }
}

Export-ModuleMember -Function Initialize-Logger,
  Show-LoggerHelp, 
  Set-LoggerDebugEnabled,
  Write-Log, 
  Set-LogLevel, 
  Set-LogFilePath, 
  Enable-LogToFile, 
  Disable-LogToFile