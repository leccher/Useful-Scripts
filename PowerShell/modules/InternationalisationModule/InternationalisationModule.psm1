<#
In your module add this function to get messages:
```PowerShell
function Get-i18nMessages {
    if (-not $script:MESSAGES) {
        $script:MESSAGES = Import-ModuleMessages `
            -ModuleName $script:MODULE_NAME `
            -BasePath $PSScriptRoot
    }
    return $script:MESSAGES
}
```

#>

# ==============================================================================
# Module: i18n (Internationalisation Helper Module)
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
$script:MODULE_NAME = "InternationalisationModule"
$script:MODULE_CODE = "i18n"

$script:DebugEnabled = $false

function Set-i18nDebugEnabled {
    param(
        [bool]$Enabled
    )
    $script:DebugEnabled = $Enabled
    Write-Host "Debug mode is now: $($script:DebugEnabled ? 'ON' : 'OFF')" -ForegroundColor Cyan
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
function Show-i18nHelp {
    param(
        [string]$Name
    )

    $moduleName = $script:MODULE_NAME

    # --- Full module help -----------------------------------------------------
    if ($Name) {
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
        return
    }
    
# --- Default: summary of module functions
    Write-Host "$moduleName - available commands" -ForegroundColor Cyan
    Write-Host ""

    Get-Command -Module $moduleName -CommandType Function |
    ForEach-Object {
        $help = Get-Help $_.Name
        [pscustomobject]@{
            Command  = $_.Name
            Synopsis = $help.Synopsis
        }
    } | Format-Table -AutoSize
}

# ==============================================================================
# Module core functions
# ==============================================================================

<#
.SYNOPSIS
  Loads localized messages for a specific module.

.DESCRIPTION
  Loads a PowerShell data file (.psd1) containing localized message
  strings for the specified module.

  The function resolves the language using the following order:
  1. Language explicitly provided as parameter
  2. Language defined in MY_CUSTOM_MODULE_LANGUAGE environment variable
  3. English fallback (en-EN)

  If no suitable localisation file is found, an error is raised.

.PARAMETER ModuleName
  Name of the module whose localisation messages should be loaded.
  This value is used to build the localisation file name.

.PARAMETER Language
  Language code to use when loading messages (e.g. en-EN, it-IT).
  Defaults to the value of MY_CUSTOM_MODULE_LANGUAGE or en-EN.

.PARAMETER BasePath
  Base directory where the Localisation folder is located.
  Defaults to the module root path.

.OUTPUTS
  System.Collections.Hashtable

.EXAMPLE
  $messages = Import-ModuleMessages -ModuleName 'MyModule'

.EXAMPLE
  $messages = Import-ModuleMessages -ModuleName 'MyModule' -Language 'it-IT'
#>
function Import-ModuleMessages {
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [string]$Language = ($env:MY_CUSTOM_MODULE_LANGUAGE ?? 'en-EN'),

        [string]$BasePath = $PSScriptRoot
    )
    if($script:DebugEnabled) {
        Write-Host ("In Importing-ModuleMessages: ModuleName: $($ModuleName): language $Language, base path $BasePath") -ForegroundColor Yellow
    }

    $locPath = Join-Path $BasePath "Localisation"
    $langFile = Join-Path $locPath "$ModuleName.messages.$Language.psd1"
    $fallback = Join-Path $locPath "$ModuleName.messages.en-EN.psd1"
    if($script:DebugEnabled) {
        Write-Host ("Importing messages for $($ModuleName): trying $langFile, fallback $fallback") -ForegroundColor Yellow
    }
    if (Test-Path $langFile) {
        if($script:DebugEnabled) {
            Write-Host ("Importing PowerShell data from $langFile") -ForegroundColor Yellow
        }
        return Import-PowerShellDataFile $langFile
    }
    elseif (Test-Path $fallback) {
        if($script:DebugEnabled) {
            Write-Host ("Importing PowerShell data from $fallback") -ForegroundColor Yellow
        }
        return Import-PowerShellDataFile $fallback
    }
    else {
        throw "No Localisation file found for module $ModuleName"
    }
}

<#
.SYNOPSIS
  Retrieves a localized message by identifier.

  If the message is not found, a placeholder string is returned.
  Optional formatting arguments can be supplied to format
  the resolved message.

.PARAMETER Messages
  Hashtable containing localized messages loaded via Import-ModuleMessages.

.PARAMETER Id
  Identifier of the message to retrieve.

.PARAMETER Args
  Optional formatting arguments applied using string formatting (-f).

.OUTPUTS
  System.String

.EXAMPLE
  Get-LocalizedMessage -Messages $messages -Id 'HELP_HEADER'

.EXAMPLE
  Get-LocalizedMessage -Messages $messages -Id 'WELCOME_USER' 'Lorenzo'
#>
function Get-LocalizedMessage {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Messages,

        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(ValueFromRemainingArguments)]
        [object[]]$Args
    )

    if (-not $Messages.ContainsKey($Id)) {
        $message = "!! Missing message: $Id !!"
         if($script:DebugEnabled) {
            Write-Host $message -ForegroundColor Red
        }
        return $message
    }

    return $Args ? ($Messages[$Id] -f $Args) : $Messages[$Id]
}

function Initialize-i18n {
  param(
    [string]$Language = ($env:MY_CUSTOM_MODULE_LANGUAGE ?? 'en-EN')
  )
  if($script:DebugEnabled) {
      Write-Host "Initializing i18n module..." -ForegroundColor Yellow
  }
  $env:MY_CUSTOM_MODULE_LANGUAGE = $Language
}

function Get-i18nLanguage {
    return $env:MY_CUSTOM_MODULE_LANGUAGE
}

Export-ModuleMember -Function Show-i18nHelp, Set-i18nDebugEnabled, Import-ModuleMessages, Get-LocalizedMessage, Initialize-i18n, Get-i18nLanguage