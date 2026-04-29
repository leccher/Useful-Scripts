# ==============================================================================
# Module: PEM (Python Environment Manager Module)
# Require: PowerShell 7.0+
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
$script:MODULE_NAME = "MyPythonEnvironmentManagerModule"
$script:MODULE_CODE = "PEM"
function Get-ModuleName() {
    return $script:MODULE_NAME
}

function Get-ModuleCode() {
    return $script:MODULE_CODE
}

$script:DebugEnabled = $false

function Set-PEMDebugEnabled {
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
function Show-PEMHelp {
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

# --- FUNZIONI INTERNE / PRIVATE ---
<#
.SYNOPSIS
  Cleans and result. On success, the updated PATH value is written  Cleans and normalizes the PATH environment variable.
  back to the current environment.

.OUTPUTS
  Hashtable with the following keys:
    - Code    : 0 on success, negative value on failure
    - Value   : Updated PATH value (on success)
    - Message : Localized status message

.EXAMPLE
  Fix-Path

.NOTES
  - This function modifies the PATH variable in the current PowerShell session.
  - Variable expansion is performed before deduplication.
  - Intended to fix issues caused by malformed or unresolved PATH entries.

.DESCRIPTION
  Reads the current PATH environment variable, expands all embedded
  environment variable references, removes invalid or empty entries,
  and normalizes the result.

  Each path element is processed using
  [Environment]::ExpandEnvironmentVariables to resolve references such as
  %VAR_NAME%. Duplicate entries are removed while preserving order.

  If an invalid path entry cannot be expanded, the function aborts and  returns an error message indicating the problematic entry. On success, the
#>

function Fix-Path {
    if ($script:DebugEnabled) {
        Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id FIX_PATH_CALLED)
    }
    $currentPaths = $env:PATH -split ';' | Where-Object { $_ -ne '' }
    $cleanPaths = foreach ($p in $currentPaths) {
        try{
            [Environment]::ExpandEnvironmentVariables($p)
        }
        catch {
            if ($script:DebugEnabled) {
                Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id FIX_PATH_FAILED -Arguments $p) -foregroundColor Yellow
            }
            return @{Code=-1; Value=$null; Message=(Get-LocalizedMessage -Messages $script:MESSAGES -Id FIX_PATH_FAILED -Arguments $p)}
        }
    }
    $env:PATH = ($cleanPaths | Select-Object -Unique) -join ';'
    return @{Code=0; Value=$env:PATH; Message=(Get-LocalizedMessage -Messages $script:MESSAGES -Id FIX_PATH_SUCCEEDED)}
}
<#
.SYNOPSIS
  Retrieves the version of the following keys:  Retrieves the version of the currently active Python executable.
    - Code    : 0 on success, positive value on parsing failure,
                negative value if Python is not found or execution fails
    - Value   : Python version string (on success), otherwise $null
    - Message : Localized status message

.EXAMPLE
  Get-CurrentPythonVersion

.NOTES
  - This function depends on the availability of the `python` command
    in the current environment or PATH.
  - The detected version reflects the Python interpreter currently
    resolved by the shell.
  - Intended to be used for environment inspection and diagnostics.


.DESCRIPTION
  Executes the `python --version` command and attempts to extract the
  version number from its output.

  The function captures both standard output and standard error to
  handle differences between Python versions and platforms.

  If a valid version number is found, it is returned as part of a
  structured result. If Python is not available or the version cannot
  be parsed, an error result is returned.

.OUTPUTS
    Hashtable with the following keys:
        - Code    : 0 on success, positive value on parsing failure,
                    negative value if Python is not found or execution fails
        - Value   : Python version string (on success), otherwise $null
        - Message : Localized status message
#>
function Get-CurrentPythonVersion {
    if ($script:DebugEnabled) {
        Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id GET_CURRENT_PYTHON_VERSION_CALLED) -foregroundColor yellow
    }
    try {
        $rawVersion = python --version 2>&1 | Out-String
        if ($script:DebugEnabled) {
            Write-Host $rawVersion -foregroundColor yellow
        }        
        if ($rawVersion -match '(\d+\.\d+(\.\d+)?)') {
            if ($script:DebugEnabled) {
                Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id GET_CURRENT_PYTHON_VERSION_MATCHED) -foregroundColor yellow
            }
            return @{ Code = 0; Value = $Matches[1]; Message = (Get-LocalizedMessage -Messages $script:MESSAGES -Id GET_CURRENT_PYTHON_VERSION_MATCHED) }
        }
        if ($script:DebugEnabled) {
            Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id GET_CURRENT_PYTHON_VERSION_NOT_MATCHED) -foregroundColor yellow
        }
        return @{ Code = 1; Value = $null; Message = (Get-LocalizedMessage -Messages $script:MESSAGES -Id GET_CURRENT_PYTHON_VERSION_NOT_MATCHED) }
    }
    catch {
        if ($script:DebugEnabled) {
            Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id GET_CURRENT_PYTHON_VERSION_NOT_FOUND) -foregroundColor yellow
        }
        return @{ Code = -1; Value = $null; Message = (Get-LocalizedMessage -Messages $script:MESSAGES -Id GET_CURRENT_PYTHON_VERSION_NOT_FOUND) }
    }
}

# --- FUNZIONI CORE (Exportabili) ---
<#
.SYNOPSIS
  Selects and activates a specific Python version.

.DESCRIPTION
  Sets the active Python version by selecting a Python installation
  defined through environment variables with the prefix `PYTHON_HOME_`.

  The function compares the requested version with the currently active
  Python version. If the requested version is already active, no changes
  are made.

  When a matching version is found, the function updates the `PYTHON_HOME`
  environment variable (both session and user scope), rebuilds the PATH
  using machine and user PATH entries, and normalizes it using Fix-Path.

  If the requested version is not available, a list of available Python
  versions is returned in the result message.

.PARAMETER Version
  Python version to activate (e.g. "3.11", "3.10").
  The version must correspond to a `PYTHON_HOME_<version>` environment
  variable.

.OUTPUTS
  Hashtable with the following keys:
    - Code    : 0 on success, negative value on failure
    - Value   : Selected Python version (on success)
    - Message : Localized status message

.EXAMPLE
  Set-PythonVersion -Version 3.11

.EXAMPLE
  Set-PythonVersion -Version 3.10

.NOTES
  - Available Python installations are discovered via environment
    variables named `PYTHON_HOME_<version>`.
  - This function modifies environment variables for the current
    PowerShell session and user profile.
  - PATH is rebuilt and normalized as part of the activation process.
#>
function Set-PythonVersion {
    param ([Parameter(Mandatory=$true)][string]$Version)
    
    $cv = Get-CurrentPythonVersion
    if ($Version -eq $cv.Value) {
		if ($script:DebugEnabled) {
			Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id SET_PYTHON_VERSION_ALREADY_ACTIVE -Arguments $Version) -foregroundColor Yellow
		}
        return @{ Code = 0; Value = $Version; Message = (Get-LocalizedMessage -Messages $script:MESSAGES -Id SET_PYTHON_VERSION_ALREADY_ACTIVE -Arguments $Version) }
    }

    $pythonEnvPaths = @{}
    $prefix = "PYTHON_HOME_"
    Get-ChildItem Env: | Where-Object { $_.Name -like "$prefix*" } | ForEach-Object {
		if ($script:DebugEnabled) {
			Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id SET_PYTHON_VERSION_FOUND -Arguments $_) -foregroundColor Yellow
		}
        $v = $_.Name.Substring($prefix.Length).Replace("_", ".")
        $pythonEnvPaths[$v] = $_.Value
    }
    if ($script:DebugEnabled) {
        Write-Host "Isolated:" -foregroundColor Yellow
        Write-Host "$pythonEnvPaths" -foregroundColor Yellow
    }

    if ($pythonEnvPaths.ContainsKey($Version)) {
        $targetPath = $pythonEnvPaths[$Version]
        $env:PYTHON_HOME = $targetPath
        [System.Environment]::SetEnvironmentVariable("PYTHON_HOME", $targetPath, "User")
        
        $mPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        $uPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        $env:PATH = "$mPath;$uPath"
        $calledFix = Fix-Path
        if ($calledFix.Code) {
            if($script:DebugEnabled) {
                Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id FIX_PATH_SUCCEEDED -Arguments $calledFix.Message) -foregroundColor Green
            }
        }
        else {
            if($script:DebugEnabled) {
                Write-Warning (Get-LocalizedMessage -Messages $script:MESSAGES -Id FIX_PATH_FAILED -Arguments $calledFix.Message)
            }
        }
        return @{ Code = 0; Value = $Version; Message = (Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_SELECTED -Arguments $Version) }
    }
    
    $available = ($pythonEnvPaths.Keys | Sort-Object) -join ", "
    if ($script:DebugEnabled) {
        Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_AVAILABLE -Arguments $available) -foregroundColor Yellow
    }
    return @{ Code = -1; Value = $null; Message = Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_UNAVAILABLE -Arguments $Version, $available }
}
<#
.SYNOPSIS
  Creates a Python virtual environment in the current folder.

.DESCRIPTION
  Creates a Python virtual environment using the specified or currently
  active Python version.

  If no version is provided, the function uses the version returned by
  Get-CurrentPythonVersion. If a version is specified, the function
  attempts to activate it using Set-PythonVersion before creating the
  virtual environment.

  If no name is provided, the user is prompted to enter one interactively.
  The virtual environment directory name is generated using the following
  conventions:

    - .venv_<version>_<name>
    - .venv_<version>

  If the target directory already exists, it is reused and not recreated.

.PARAMETER Version
  Python version to use when creating the virtual environment.
  If omitted, the currently active Python version is used.

.PARAMETER Name
  Optional name of the virtual environment.
  If omitted or empty, the user is prompted to provide a name.

.OUTPUTS
  Hashtable with the following keys:
    - Code    : 0 on success, non-zero on failure
    - Value   : Name of the virtual environment directory
    - Message : Localized status message

.EXAMPLE
  Create-PythonVenv

.EXAMPLE
  Create-PythonVenv -Version 3.11

.EXAMPLE
  Create-PythonVenv -Version 3.10 -Name "dev"

.NOTES
  - This function may prompt the user for input.
  - Virtual environments are created using `python -m venv`.
  - Existing virtual environment directories are not overwritten.
#>
function Create-PythonVenv {
    param ([string]$Version, [string]$Name)
    
    if (-not $Version) { $Version = (Get-CurrentPythonVersion).Value }
    else {
        $res = Set-PythonVersion -Version $Version
        if ($res.Code -ne 0) { return $res }
    }

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = Read-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_NAME_PROMPT)
    }

    $venvName = if ($Name) { ".venv_${Version}_${Name}" } else { ".venv_$Version" }

    if (-not (Test-Path $venvName)) {
        Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_CREATING -Arguments $venvName) -foregroundColor Cyan
        & python -m venv $venvName
    }
    return @{ Code = 0; Value = $venvName; Message = (Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_READY -Arguments $venvName) }
}

<#< If the function is executed inside Visual Studio Code (detected via
  the TERM_PROGRAM environment variable), selection is skipped and a
  special result is returned.

  When one or more virtual environments are found, the user is presented
  with a numbered list and prompted to choose one. The function returns
  a structured result indicating the selection outcome.

.OUTPUTS
  Hashtable with the following keys:
    - Code    : Selection result code
                *  2 : virtual environment selected
                *  1 : running inside VS Code
                *  0 : user cancelled
                * -1 : error or no virtual environments found
    - Value   : Selected virtual environment name (when applicable)
    - Message : Localized status message (on error or cancellation)

.EXAMPLE
  Get-PythonVenv

.NOTES
  - Virtual environments are discovered by searching for directories
    matching the `.venv*` pattern in the current folder.
  - This function may prompt the user for input.
  - Designed to integrate with interactive environment selection
    workflows.

.SYNOPSIS
  Detects and selects an available Python virtual environment.

.DESCRIPTION
  Scans the current directory for Python virtual environments following
  the `.venv*` naming convention and allows the user to select one
  interactively.
#>

function Get-PythonVenv {
    if ($Env:TERM_PROGRAM -eq "vscode") { return @{ Code = 1; Value = "vscode" } }

    $folders = Get-ChildItem -Directory -Filter ".venv*"
    if (-not $folders) { return @{ Code = -1; Message = (Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_NOT_FOUND) } }

    Write-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_SELECTION_HDR) -foregroundColor Cyan
    for ($i=0; $i -lt $folders.Count; $i++) {
        Write-Host "$($i+1). $($folders[$i].Name)"
    }

    $sel = Read-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_SELECTION_PROMPT)
    if ($sel -eq "0") { return @{ Code = 0; Message = (Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_CANCELLED) } }
    if ([string]::IsNullOrWhiteSpace($sel)) { $sel = 1 }

    $idx = [int]$sel - 1
    if ($idx -ge 0 -and $idx -lt $folders.Count) {
        return @{ Code = 2; Value = $folders[$idx].Name }
    }
    return @{ Code = -1; Message = (Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_SELECTION_BAD) }
}

<#
 found.SYNOPSIS
    - Activates the selected or newly created virtual environment

  Activation is performed by invoking the `Activate.ps1` script located
  in the `Scripts` directory of the virtual environment.

.PARAMETER Folder
  Optional path or folder name of the Python virtual environment to activate.
  If omitted, an interactive selection or creation workflow is triggered.

.OUTPUTS
  Hashtable with the following keys:
    - Code    : 0 on success, negative value on failure
    - Value   : Activated virtual environment name or path (on success)
    - Message : Localized status message

.EXAMPLE
  Enable-PythonVenv

.EXAMPLE
  Enable-PythonVenv -Folder ".venv_3.11_dev"

.NOTES
  - This function modifies the current PowerShell session environment.
  - Virtual environment activation is not persistent across sessions.
  - Designed to integrate with interactive Python environment workflows.
  Activates a Python virtual environment in the current PowerShell session.

.DESCRIPTION
  Activates a Python virtual environment by sourcing its activation script.

  If a target folder is explicitly provided, the function attempts to
  activate the virtual environment located in that folder.

  If no folder is specified, the function performs the following steps:
    - Attempts to select an existing virtual environment using Get-PythonVenv
    - If no virtual environments are found, it prompts the user to create a new one using Create-PythonVenv
    - If a virtual environment is selected or created, it proceeds to activate it
#>
function Enable-PythonVenv {
    param ([string]$Folder)
    
    $target = $Folder
    if (-not $target) {
        $sel = Get-PythonVenv
        if ($sel.Code -eq 2) { $target = $sel.Value }
        elseif ($sel.Code -lt 0) { $target = (Create-PythonVenv).Value }
        else { return $sel }
    }

    $act = Join-Path $target "Scripts\Activate.ps1"
    if (Test-Path $act) {
        & $act
        return @{ Code = 0; Value = $target; Message = (Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_SELECTED -Arguments $target) }
    }
    return @{ Code = -1; Message = (Get-LocalizedMessage -Messages $script:MESSAGES -Id VENV_NOT_FOUND) }
}

# --- WRAPPERS PUBBLICI (Interfaccia Modulo) ---
<#
.SYNOPSIS
    Activates a Python virtual environment with user-friendly output.

.PARAMETER Folder
  Optional path or folder name of the Python virtual environment to activate.
  If omitted, an interactive selection or creation workflow is triggered.

.OUTPUTS
  Hashtable with the following keys:
    - Code    : 0 on success, non-zero on failure
    - Value   : Activated virtual environment name or path (on success)
    - Message : Localized status message

.EXAMPLE
  Enable-Venv

.EXAMPLE
  Enable-Venv -Folder ".venv_3.11_dev"

.NOTES
  - This function prints messages to the console for user feedback.
  - It returns the same structured result as Enable-PythonVenv.
  - Intended as a convenience command for interactive sessions.

.DESCRIPTION
  Wrapper around Enable-PythonVenv that activates a Python virtual
  environment and immediately displays a success or warning message
  to the console.
#>
function Enable-Venv {
    param ([string]$Folder)
    $res = Enable-PythonVenv -Folder $Folder
    if ($res.Code -eq 0) { Write-Host $res.Message -foregroundColor Green }
    else { Write-Warning $res.Message }
    return $res
}

function Initialize-PEM {
    if($script:DebugEnabled) {
        Write-Host "Initializing My Python Environment Manager Module..." -ForegroundColor Green
    }
    # Load localized messages
    $null = Get-i18nMessages | Out-Null
}
<#
.SYNOPSIS
  Module directory watcher hook for Python virtual environment activation.

.DESCRIPTION
  This internal function is invoked automatically by the framework when
  the module directory context changes (for example on load, reload, or
  directory navigation).

  Its responsibility is to ensure that a Python virtual environment is
  enabled for the current context by delegating the logic to Enable-Venv.

  The function is discovered and executed via naming convention and is
  not intended to be called directly by users.

.NOTES
  - Internal framework hook.
  - Automatically discovered by the directory watcher mechanism.
  - Do not rename or export this function.
#>
function myenvmm:__ModuleDirectoryWatcher {
    Enable-Venv
}

Export-ModuleMember -Function Show-PEMHelp, Set-PEMDebugEnabled,Enable-Venv, myenvmm:__ModuleDirectoryWatcher