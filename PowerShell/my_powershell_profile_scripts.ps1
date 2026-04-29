<#
# This script is a sample of PowerSehl profile configurations script.
# See $PROFILE | Select-Object *
# AllUsersAllHosts       : C:\Program Files\PowerShell\7\profile.ps1
# AllUsersCurrentHost    : C:\Program Files\PowerShell\7\Microsoft.PowerShell_profile.ps1
# CurrentUserAllHosts    : C:\Users\YOUR_USER\Documents\PowerShell\profile.ps1
# CurrentUserCurrentHost : C:\Users\YOUR_USER\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

# For creating CurrentUser files
# New-Item -ItemType File -Path $PROFILE -Force

# For a Specific one
# New-Item -ItemType File -Path "$env:USERPROFILE\Documents\PowerShell\Profile.ps1" -Force

#>

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


$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Write-Host "Executing as ADMINISTRATOR" -foregroundColor Green
	return
} else {
    # Write-Host "Executing as standard user" -foregroundColor Yellow
}

$env:MY_SCRIPTS = Join-Path $env:USERPROFILE '\Scripts'
$env:PATH += ";$env:MY_SCRIPTS"
$script:DebugEnabled=$false
$script:myModulesLoaded=$false


<#
.SYNOPSIS
  Returns the directory path of the currently executing script.
  the current working directory is returned as a fallback.

.OUTPUTS
  System.String

.EXAMPLE
  $root = Get-CurrentScriptDir
  Write-Host "Current script directory: $root"  

.DESCRIPTION
  Determines the directory in which the current script resides.
  If the script path cannot be resolved (e.g. interactive session), it falls back to the current working directory.
  This function is useful for reliably locating resources relative to the script location.
  It works in both script and interactive contexts, making it versatile for profile scripts.
#>
function Get-CurrentScriptDir {
	# Works in PS 3.0+, handles interactive sessions gracefully
	$scriptPath = if ($PSCommandPath) {
		$PSCommandPath
	} elseif ($MyInvocation.MyCommand.Path) {
		$MyInvocation.MyCommand.Path
	} else {
		$null
	}

	$CurrentScriptDir = if ($scriptPath) {
		Split-Path -Parent $scriptPath
	} else {
		# Decide what you want in interactive sessions:
		# Option A: use the current directory
		(Get-Location).Path

		# Option B (stricter): fail fast with a clear message
		# throw "This code must be run from a script file; no script path available in interactive session."
	}
	return $CurrentScriptDir
}

<#
.SYNOPSIS
  Loads all custom PowerShell modules with dependency resolution.

.DESCRIPTION
  Scans the `modules` directory relative to the current script location
  and loads each module in the correct order, based on the dependencies
  declared in each module manifest (.psd1).

  The function iteratively loads modules whose dependencies are already
  satisfied, detecting circular or missing dependencies.

  Debug output can be enabled via the internal DebugEnabled flag.

.PARAMETER ModulesToLoad
  Optional list of module names to load. If not provided, all modules
  found in the modules directory are considered.

.PARAMETER LoadedModules
  Internal parameter used during recursive calls to track loaded modules.

.OUTPUTS
  Hashtable with the following keys:
    - Code    : 0 on success, otherwise error code
    - Value   : Boolean indicating success
    - Message : Human-readable status message

.EXAMPLE
  Load-MyPowerShellModules

.NOTES
  This function is intended to be called during profile initialization.
#>
function Load-MyPowerShellModules {
	param(
        [string[]]$ModulesToLoad = $null,
        [string[]]$LoadedModules = @()
    )

    $root = Get-CurrentScriptDir
    $modulesPath = Join-Path $root 'modules'
	if (-not (Test-Path $modulesPath)) {
		throw "Modules folder not found: $modulesPath"
	}
	# Step 1 - Init lists
	if (-not $ModulesToLoad) {
		Write-Host "Loading modules from: $modulesPath ..." -ForegroundColor Cyan
		$ModulesToLoad = Get-ChildItem -Path $modulesPath -Directory | Select-Object -ExpandProperty Name
	}

	$initialCount = $ModulesToLoad.Count

	Write-Host "Modules remaining: $($ModulesToLoad -join ', ')" -ForegroundColor Cyan

    $CoreInitQueue = @()
	foreach ($moduleName in @($ModulesToLoad)) {

        $moduleDir = Join-Path $modulesPath $moduleName
        $psd1      = Join-Path $moduleDir "$moduleName.psd1"

		if (-not $moduleName) {
			Write-Warning "Empty module name found, skipping."
			continue
		}

        if (-not (Test-Path $psd1)) {
            throw "Invalid module: missing $psd1"
        }

        $manifest = Import-PowerShellDataFile $psd1
        $required = @($manifest.RequiredModules)
		if($script:DebugEnabled) {
			Write-Host "Module $moduleName requires: $($required -join ', ')" -ForegroundColor Yellow
		}

		# STEP 2.1 — nessuna dipendenza or
		# STEP 2.2 — tutte le dipendenze sono già state caricate
        if (-not $required -or ($required | Where-Object { $_ -notin $LoadedModules }).Count -eq 0) {
			Write-Host "Loading module $moduleName" -ForegroundColor Magenta
			$spd1 = Join-Path $moduleDir "$moduleName.psd1"
			if($script:DebugEnabled) {
				Write-Host "Importing module $moduleName from $psd1" -ForegroundColor Yellow
            	Import-Module $psd1 -Force -Verbose -ErrorAction Stop
			}else{
				Import-Module $psd1 -Force -ErrorAction Stop
			}
			
			
            $LoadedModules += $moduleName
            $ModulesToLoad = $ModulesToLoad | Where-Object { $_ -ne $moduleName }
        }else{
			if($script:DebugEnabled) {
				if($required) {
					Write-Host "Module $moduleName dependencies $($required): loaded" -ForegroundColor Red
				}
			}
		}

    }

	# STEP 4 — exit condition
    if ($ModulesToLoad.Count -eq 0) {
        Write-Host "✅ All modules loaded successfully" -ForegroundColor Green
        return @{Code=0; Value=$true; Message="All modules loaded successfully"}
    }

	# STEP 5 — loop detection
    if ($ModulesToLoad.Count -eq $initialCount) {
		if($script:DebugEnabled) {
			Write-Warning "Possible circular dependency detected. Remaining modules: ModulesToLoads Count:$($ModulesToLoad.Count), Initial Count: $($initialCount)"
		}
        throw @"
❌ Dependency resolution failed.
Remaining modules: $($ModulesToLoad -join ', ')
Loaded modules:    $($LoadedModules -join ', ')
Possible circular or missing dependencies.
"@
    }

	# STEP 6 — ricorsione
    Load-MyPowerShellModules -ModulesToLoad $ModulesToLoad -LoadedModules $LoadedModules
}

<#
.SYNOPSIS
  Unloads all custom PowerShell modules safely.

.DESCRIPTION
  Iterates over all modules in the `modules` directory and attempts to
  unload them. The function collects dependency information from module
  manifests and validates that no required modules remain loaded.

  This function is useful for development, debugging, or full framework
  reset scenarios.

.OUTPUTS
  Hashtable with the following keys:
    - Code    : 0 on full success, >0 on partial unload, <0 on error
    - Value   : Boolean indicating logical success
    - Message : Summary message

.EXAMPLE
  Unload-MyPowerShellModules
#>
function Unload-MyPowerShellModules {
	$root=Get-CurrentScriptDir
	$modulesPath="$root\modules"
	Write-Host "Loading modules from: $modulesPath ..." -foregroundColor Cyan
	if (Test-Path $modulesPath) {
		$ModulesToUnload = Get-ChildItem -Path $modulesPath -Directory | Select-Object -ExpandProperty Name
		$unloadedModules = @()
		$required = @()
		foreach ($moduleName in @($ModulesToUnload)) {
			$moduleDir = Join-Path $modulesPath $moduleName
			$psd1      = Join-Path $moduleDir "$moduleName.psd1"
			if (Test-path $psd1) {
				$manifest = Import-PowerShellDataFile $psd1
				$required += @($manifest.RequiredModules)
			} else {
				Write-Warning "Module manifest not found for $moduleName, skipping dependency check."
			}

			Write-Host "Unloading module $moduleName" -ForegroundColor Magenta
			Remove-Module $moduleName -Force -ErrorAction SilentlyContinue
			
			if (-not (Get-Module $moduleName)) {
				$unloadedModules += $moduleName
			}
		}
	}
	else {
		$message="Folder not found : $root"
		Write-Error "$message" -foregroundColor Yellow
		return @{
			Code=-1
			Value=$false
			Message="$message"
		}
	}
	$script:myModulesLoaded=$false
	# Remove duplicates and empty entries from required modules list
	$required = $required | Where-Object { $_ } | Select-Object -Unique
	# Consider only unloaded modules for the final check
	$required = $required | Where-Object { $_ -in $ModulesToUnload }
	# Now verify difference between required and unloaded modules
	$missing = $required | Where-Object { $_ -notin $unloadedModules }

	if ($missing.Count -eq 0) {
		$message = "All required modules are unloaded: $($unloadedModules -join ', ')"
		Write-Host "✅ $message" -foregroundColor Green
		return @{
			Code=0
			Value=$true
			Message=$message
		}
	}
	$message = "Some required modules were not unloaded: $($missing -join ', '). Unloaded modules: $($unloadedModules -join ', ')"
	Write-Warning "❌ $message"
	return @{
		Code=1
		Value=$true
		Message=$message
	}
}

<#
.SYNOPSIS
  Dispatches directory change events to registered module watchers.

.DESCRIPTION  Tracks the current working directory and detects changes compared.DESCRIPTION
  to the last recorded path. When a directory change is detected,
  all functions following the `*:__ModuleDirectoryWatcher` convention
  are invoked.

  Each module can define its own directory watcher function
  to react to context changes (e.g. activating virtual environments).

.NOTES
  Errors raised by individual watchers are isolated and do not stop
  execution of other watchers.
#>
function Invoke-DirectoryWatcher {
	$global:__MYFW_LastPath ??= $null;

    $current = (Get-Location).ProviderPath

    if ($current -ne $global:__MYFW_LastPath) {
        $global:__MYFW_LastPath = $current

        Get-Command -CommandType Function |
            Where-Object Name -like '*:__ModuleDirectoryWatcher' |
            ForEach-Object {
                try {
                    & $_ | Out-Null
                } catch {
                    Write-Verbose "Directory watcher failed: $($_.Name)"
                }
            }
    }
}

$script:result = Load-MyPowerShellModules
$script:myModulesLoaded = $script:result.Value

if ($script:myModulesLoaded) {
	# same result but with more risks: override funciton "prompt"
	# override 'cd' function (o 'Set-Location') for monitoring folder browsing
	
	<#
	.SYNOPSIS
	Overrides Set-Location to trigger directory watcher hooks.

	.DESCRIPTION
	Wraps the original Set-Location command to intercept directory changes.
	After successfully changing directory, directory watcher hooks are
	executed unless explicitly disabled via an environment variable.

	This approach is preferred over overriding the prompt function,
	as Set-Location semantically represents directory change events.

	.NOTES
	To temporarily disable directory watchers, set:
		$env:DISABLE_CUSTOM_FUNCTION_FOR_DIRECTORY_WALKING = 1
	#>
	function Set-Location {
		param (
			[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
			[Alias("Path")]
			[string]$LiteralPath
		)
		try {
			# Usa il comando originale per cambiare directory
			Microsoft.PowerShell.Management\Set-Location -LiteralPath $LiteralPath -ErrorAction Stop
			if($env:DISABLE_CUSTOM_FUNCTION_FOR_DIRECTORY_WALKING){
				# Remove environment variable
				Remove-Item env:DISABLE_CUSTOM_FUNCTION_FOR_DIRECTORY_WALKING
			}else{
				try {
					Invoke-DirectoryWatcher | Out-Null
				}
				catch {
					Write-Warning "Error calling Invoke-DirectoryWatcher: $_"
				}
			}
		} catch {
			Write-Warning "Folder not found $LiteralPath"
			return ${Code=-1; Value="Folder $LiteralPath not exists"}
		}
	}
}

