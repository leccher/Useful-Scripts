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

$script:MESSAGES = $null

function Get-MyCommandHelpMessages {
    if (-not $script:MESSAGES) {
        $script:MESSAGES = Import-ModuleMessages `
            -ModuleName 'MyCommandHelpModule' `
            -BasePath $PSScriptRoot
    }
    return $script:MESSAGES
}

function Initialize-MyCommandHelp {
    $null = Get-MyCommandHelpMessages
}

function Get-FileHeaderComment {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Module
    )
    
    $mod = Get-Module $Module -ErrorAction SilentlyContinue
    if (-not $mod) {
        return @{ Code = 1; Message = "Module '$Module' is not loaded." }
    }

    $content = Get-Content $mod.Path -Raw

    if ($content -match '(?s)^\s*<#[\r\n]*(.*?)[\r\n]*#>') {
        return @{Code=0;Message=$Matches[1].Trim()}
    }

    return @{Code=1;Message="No header comment found in module '$Module'."}
}

function Get-MyFrameworkModules {
    Get-Module | Where-Object {
        $_.Path -like "*\modules\*"
    }
}

function Show-Help {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    $messages = Get-MyCommandHelpMessages

    #
    # 1. Prova come comando / funzione
    #
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        Get-Help $cmd.Name -Full
        return
    }

    #
    # 2. Prova come modulo dei tuoi moduli
    #
    $module = Get-MyFrameworkModules | Where-Object Name -eq $Name
    if ($module) {

        # 2.1 Header comment del .psm1
        $header = Get-FileHeaderComment -Module $Name
        if ($header.Code -eq 0) {
            Write-Host "=== $Name ===" -ForegroundColor Cyan
            Write-Host $header.Message
            return
        }

        # 2.2 README.md fallback
        $readme = Join-Path (Split-Path $module.Path -Parent) 'Readme.md'
        if (Test-Path $readme) {
            Write-Host "=== $Name (README) ===" -ForegroundColor Cyan
            Get-Content $readme -Raw
            return
        }

        Write-Warning (
            Get-LocalizedMessage `
                -Messages $messages `
                -Id 'HELP_NOT_FOUND_FOR_MODULE' `
                -Args $Name
        )
        return
    }

    #
    # 3. Nulla trovato
    #
    Write-Warning (
        Get-LocalizedMessage `
            -Messages $messages `
            -Id 'HELP_NOT_FOUND' `
            -Args $Name
    )
}

Export-ModuleMember -Function Show-Help