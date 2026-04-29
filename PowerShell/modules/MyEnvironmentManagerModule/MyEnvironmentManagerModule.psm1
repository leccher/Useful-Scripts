# ==============================================================================
# Module: MEM (My Environment Manager Module)
# ==============================================================================
# ---- PowerShell version check -------------------------------------------------
$IsPS7 = $PSVersionTable.PSEdition -eq 'Core' -and
         $PSVersionTable.PSVersion.Major -ge 7
if (-not $IsPS7) {
    Write-Error @"
This PowerShell profile requires PowerShell 7 or later.
Current version: $($PSVersionTable.PSVersion)
Please start pwsh instead of Windows PowerShell 5.1.
"@
    return
}
# ---- Module variables and functions -------------------------------------------------
$script:MODULE_NAME = "MyEnvironmentManagerModule"
$script:MODULE_CODE = "MEM"
function Get-ModuleName() {
    return $script:MODULE_NAME
}

function Get-ModuleCode() {
    return $script:MODULE_CODE
}

$script:DebugEnabled = $false

function Set-MEMDebugEnabled {
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
  Show-i18nHelp

.EXAMPLE
  Show-i18nHelp -Name Get-LocalizedMessage

.EXAMPLE
  Show-i18nHelp -Module

.NOTES
  This function is based entirely on Comment-Based Help and Get-Help.
  It is intended as the canonical discovery entry point for i18n features.
#>
function Show-MEMHelp {
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

# --- Initialize module messages -----------------------------------------------------
function Get-i18nMessages {
  if (-not $script:MESSAGES) {
    $script:MESSAGES = Import-ModuleMessages -ModuleName $script:MODULE_NAME -BasePath $PSScriptRoot
  }
  return $script:MESSAGES
}


# --- WRAPPERS PUBBLICI (Interfaccia Modulo) ---
<# 
.SYNOPSIS
  Resolves an environment variable by recursively expanding embedded variables.

.DESCRIPTION
  Reads the value of the specified environment variable and resolves any
  nested references using the Windows-style syntax `%VARIABLE%`.

  If the variable value contains references to other environment variables,
  those variables are resolved recursively until no further substitutions
  are necessary.

  The function does NOT directly modify the environment.

.PARAMETER envVarName
  Name of the environment variable to resolve.

.OUTPUTS
  Hashtable with the following keys:
    - Code    : 0 on success, negative value on error
    - Value   : Resolved variable value or error description
    - Message : Optional localized message (on error)

.EXAMPLE
  Resolve-EnvVariableRecursively -envVarName 'PATH'

.NOTES
  This function is intended for internal use.
  It performs recursive resolution but does not persist changes to the
  environment.
#>
function Resolve-EnvVariableRecursively {
    param (
        [Parameter(Mandatory=$true)]
        [string]$envVarName
    )

    if ($script:DebugEnabled) {
        Write-Host "[DEBUG] $(Get-LocalizedMessage -Id 'DEBUG_ANALYZE_VAR' -Args $envVarName)" -foregroundColor Yellow
    }

    # Recupero il valore grezzo dalla memoria
    $envVarValue = [System.Environment]::GetEnvironmentVariable($envVarName)

    if (-not $envVarValue) {
        return @{
			Code=-1
			Value=(Get-LocalizedMessage -Id 'ERROR_VAR_NOT_FOUND' -Args $envVarName)
			Message=(Get-LocalizedMessage -Id 'ERROR_VAR_NOT_FOUND' -Args $envVarName)
		}
    }

    if ($script:DebugEnabled) {
        Write-Host "[DEBUG] $(Get-LocalizedMessage -Id 'DEBUG_VALUE_FOUND' -Args $envVarValue)" -foregroundColor Gray
    }

    # Regex per trovare pattern %VARIABILE%
    $matches = [regex]::Matches($envVarValue, '%(\w+)%')
    
    if ($matches.Count -gt 0) {
        # Estraggo i nomi univoci delle variabili trovate all'interno
        $nestedVars = $matches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

        foreach ($nestedName in $nestedVars) {
            # CHIAMATA RICORSIVA (Nota: senza parentesi)
            $subResult = Resolve-EnvVariableRecursively -envVarName $nestedName
            
            if ($subResult.Code -eq 0) {
                $oldValue = "%$nestedName%"
                $newValue = $subResult.Value
                
                if ($script:DebugEnabled) {
                    Write-Host "[DEBUG] $(Get-LocalizedMessage -Id 'DEBUG_REPLACE' -Args $oldValue, $newValue)" -foregroundColor DarkGray
                }
                $envVarValue = $envVarValue.Replace($oldValue, $newValue)
            }
        }
    }

    return @{Code=0; Value=$envVarValue}
}
<#
.SYNOPSIS
  Resolve a variable by recursively expanding  Resolves and updates an environment variable by expanding nested references.
  any nested environment variable references using the Windows-style
  `%VARIABLE%` syntax.

  The resolution logic is delegated to Resolve-EnvVariableRecursively.
  If resolution succeeds, the environment variable is updated in the
  current PowerShell session.

  If resolution fails, a warning message is logged using the logging
  framework, and the environment is not modified.

.PARAMETER envVarName
  Name of the environment variable to resolve and update.

.EXAMPLE
  Resolve-RecursiveVariable -envVarName 'PATH'

.NOTES
  This function modifies the current PowerShell session environment.
  Resolution is performed recursively and supports deeply nested variables.

.DESCRIPTION
    Resolves an environment variable by recursively expanding any nested
    references using the Windows-style `%VARIABLE%` syntax. If resolution
    is successful, the environment variable is updated in the current
    PowerShell session. If resolution fails, a warning message is logged
    and the environment is not modified.
#>
function Resolve-RecursiveVariable {
    param (
        [Parameter(Mandatory=$true)]
        [string]$envVarName
    )
    
    $result = Resolve-EnvVariableRecursively -envVarName $envVarName
    
    if ($result.Code -ne 0) {
        Write-Log (Get-LocalizedMessage -Id 'WARN_MEMM_PREFIX' -Args $result.Value)
    } else {
        # AGGIORNAMENTO: Usiamo [System.Environment] per maggiore stabilità con variabili lunghe come PATH
        $envPath = "Env:$envVarName"
        Set-Item -Path $envPath -Value $result.Value
        Write-Log (Get-LocalizedMessage -Id 'VAR_RESOLVED_SUCCESS' -Args $envVarName)
    }
}

function Initialize-MEM {
    # Inizializzazione del modulo, se necessaria
    if($script:DebugEnabled) {
        Write-Host ("Initializing module $($script:MODULE_NAME)") -ForegroundColor Yellow
    }
    $null = Get-i18nMessages
}

Export-ModuleMember -Function Initialize-MEM, 
  Show-MEMHelp, 
  Set-MEMDebugEnabled,
  Resolve-RecursiveVariable