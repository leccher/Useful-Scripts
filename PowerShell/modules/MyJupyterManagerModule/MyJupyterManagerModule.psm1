# ==============================================================================
# Module: MJM (My Jupyter Manager Module)
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
$script:MODULE_NAME = "MyJupyterManagerModule"
$script:MODULE_CODE = "MJM"
$script:DebugEnabled = $false

function Set-MJMDebugEnabled {
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
function Show-MJMHelp {
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

# --- FUNZIONI CORE (Exportabili) ---
<#
.SYNOPSIS
  Starts JupyterLab environment  Starts JupyterLab from a Python virtual environment.
  located in the specified folder.

  The function looks for the `jupyter-lab.exe` executable inside the
  `Scripts` directory of the provided folder. If found, the user is
  prompted for confirmation before launching JupyterLab.

  If the executable is not found, a localized error message is returned.
  The function returns a structured result indicating success or failure.

.PARAMETER Folder
  Path to the root directory of the Python virtual environment.

.OUTPUTS
  Hashtable with the following keys:
    - Code    : 0 on success, non-zero on failure
    - Message : Localized status message

.EXAMPLE
  Start-JupyterLab -Folder $env:VIRTUAL_ENV

.NOTES
  - This function may prompt for user confirmation.
  - JupyterLab is launched only if the executable is found in the
    virtual environment.
  - Intended for use within a Python virtual environment workflow.

.DESCRIPTION
    This function attempts to start JupyterLab by locating the `jupyter-lab.exe`
    executable within the `Scripts` directory of the specified folder, which is
    expected to be a Python virtual environment.
    
    If the executable is found, the user is prompted to confirm whether they
    want to start JupyterLab. If the user confirms, JupyterLab is launched.
    
    The function returns a hashtable indicating whether JupyterLab was started
    successfully or if there was an issue (e.g., executable not found, user
    declined to start).
#>
function Start-JupyterLab {
    param ([Parameter(Mandatory=$true)]$Folder)
    # I use alternative check for jupyter-lab command because in some cases it is not correctly registered in PATH, but it is present in the virtual environment's Scripts folder
    #if (-not (Get-Command jupyter-lab -ErrorAction SilentlyContinue)) {
    #    return @{ Code = 1; Message = "Jupyter Lab command not found in PATH." }
    #}
    $bin = Join-Path $Folder "Scripts\jupyter-lab.exe"
    if (Test-Path $bin) {
        $choice = Read-Host (Get-LocalizedMessage -Messages $script:MESSAGES -Id PROMPT_START_JUPYTER)
        if ($choice -eq 'y') { & $bin; return @{ Code = 0; Message = Get-LocalizedMessage -Messages $script:MESSAGES -Id JUPYTER_STARTED } }
    }
    else{
        if($script:debugEnabled){
            Write-Host Get-LocalizedMessage -Messages $script:MESSAGES -Id NONE_VENV_ENABLED
        }
        return @{ Code = 1; Message = Get-LocalizedMessage -Messages $script:MESSAGES -Id NO_VENV_ENABLE }
    }
    Start-JupyterLab -Folder $env:VIRTUAL_ENV
    return @{ Code = 0; Message = Get-LocalizedMessage -Messages $script:MESSAGES -Id JUPYTER_ENABLED }
}

<#
.SYNOPSIS
  Installs JupyterLab in the active PythonLab using the `pip` executable from the currently  Installs JupyterLab in the active Python virtual environment.
  active Python virtual environment.

  If JupyterLab is already available in the environment, no action
  is taken and a corresponding message is returned.

  If no virtual environment is active or `pip` cannot be found,
  the function returns an error result with a localized message.

.OUTPUTS
  Hashtable with the following keys:
    - Code    : 0 on success, non-zero on failure
    - Message : Localized status message

.EXAMPLE
  Install-JupyterLab

.NOTES
  - Requires an active Python virtual environment ($env:VIRTUAL_ENV).
  - Uses the environment-specific `pip.exe` to avoid global installs.

.DESCRIPTION
    This function checks if JupyterLab is already installed in the active Python virtual environment. If it is not installed, it attempts to locate the `pip.exe` executable within the `Scripts` directory of the virtual environment and uses it to install JupyterLab.

    The function returns a hashtable indicating whether JupyterLab was installed successfully, if it was already present, or if there was an issue (e.g., no active virtual environment, `pip` not found).
#>
function Install-JupyterLab {
    if ($env:VIRTUAL_ENV) {
        if (-not (Get-Command jupyter-lab -ErrorAction SilentlyContinue)) {
            $pip = Join-Path $env:VIRTUAL_ENV "Scripts\pip.exe"
            if (Test-Path $pip) {
                & $pip install jupyterlab
                return @{ Code = 0; Message = Get-LocalizedMessage -Messages $script:MESSAGES -Id JUPYTER_INSTALL_OK }
            }
            return @{ Code = -1; Message = Get-LocalizedMessage -Messages $script:MESSAGES -Id PIP_NOT_FOUND }
        }
        return @{ Code = 0; Message = Get-LocalizedMessage -Messages $script:MESSAGES -Id JUPYTER_ALREADY }
    }
    return @{ Code = 1; Message = Get-LocalizedMessage -Messages $script:MESSAGES -Id NO_VENV_INSTALL }
}

function Initialize-MJM {
    if($script:DebugEnabled) {
        Write-Host "Initializing My Jupyter Manager Module..." -ForegroundColor Green
    }
    # Load localized messages
    $null = Get-i18nMessages | Out-Null
}

<# module
  directory context changes (for example on load or reload).

  It checks whether JupyterLab can be enabled for the current environment
  and triggers the appropriate activation logic.

.NOTES
  - Internal framework hook.
  - Not intended to be called directly by users.
  - Naming convention is used for automatic discovery by the directory watcher.

.SYNOPSIS
  Reacts to directory changes to enable JupyterLab automatically.

.DESCRIPTION
    This function is designed to be called by the module's directory watcher
    whenever the module's directory context changes (e.g., on load or reload).

    It checks if JupyterLab can be enabled for the current Python virtual environment
    and triggers the appropriate activation logic. This allows for automatic
    enabling of JupyterLab when the module is loaded or when the user changes
    directories within a Python virtual environment.
#>
# Funciton called every time the module directory is changed (e.g. on load or reload) to check if Jupyter Lab can be enabled
function myenvmm:__ModuleDirectoryWatcher {
    Enable-JupyterLab
}

Export-ModuleMember -Function Initialize-MJM, Show-MJMHelp, Set-MJMDebugEnabled, Enable-JupyterLab, myenvmm:__ModuleDirectoryWatcher