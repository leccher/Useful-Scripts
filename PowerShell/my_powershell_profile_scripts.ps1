# This script is a sample of PowerSehl profile configurations script.
# See $PROFILE | Select-Object *
# AllUsersAllHosts       : C:\Program Files\PowerShell\7\profile.ps1
# AllUsersCurrentHost    : C:\Program Files\PowerShell\7\Microsoft.PowerShell_profile.ps1
# CurrentUserAllHosts    : C:\Users\cripergine\Documents\PowerShell\profile.ps1
# CurrentUserCurrentHost : C:\Users\cripergine\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

# For creating CurrentUser files
# New-Item -ItemType File -Path $PROFILE -Force

# For a Specific one
# New-Item -ItemType File -Path "$env:USERPROFILE\Documents\PowerShell\Profile.ps1" -Force


$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Write-Host "Executing as ADMINISTRATOR" -foregroundColor Green
	return
} else {
    # Write-Host "Executing as standard user" -foregroundColor Yellow
}

$env:MY_SCRIPTS = Join-Path $env:USERPROFILE '\Scripts'
$env:PATH += ";$env:MY_SCRIPTS"
$script:myModulesLoaded=$false
function Load-MyPowerShellModules {
	# Useful Scripts PowerShell section
	$CurrentScriptDir = Split-Path -Parent $PSCommandPath
	$useful_scripts_folder=$CurrentScriptDir
	$useful_scripts_poweshell_modules_folder="$useful_scripts_folder\modules"
	Write-Host "Loading modules from: $useful_scripts_poweshell_modules_folder ..." -foregroundColor Cyan
	if (Test-Path $useful_scripts_poweshell_modules_folder) {
		#$env:PSModulePath += ";$useful_scripts_poweshell_modules_folder"
		Get-ChildItem -Filter "*.psd1" -Recurse -File | ForEach-Object { 
			Write-Host "Loading ... $($_.Name)" -ForegroundColor Magenta
			Import-Module $_.FullName -Force 
		}
	}
	else {
		$message="Folder not found : $useful_scripts_folder"
		Write-Host $message -foregroundColor Yellow
		return @{
			Code=-2
			Value=$false
			Message=$message
		}
	}
	$message="My Modules Loaded!!!"
	Write-Host $message -foregroundColor Cyan
	try {
		Resolve-MEMMRecursiveVariable("PATH")
	}
	catch {
		$message = "Modules not loaded"
		Write-Host $message -foregroundColor Yellow
		return @{
			Code=-3
			Value=$false
			Message=$message
		}
	}
	$script:myModulesLoaded=$true
	return @{
		Code=1
		Value=$true
		Message=$message
	}
}

function Unload-MyPowerShellModules {
	# Useful Scripts PowerShell section
	$CurrentScriptDir = Split-Path -Parent $PSCommandPath
	$useful_scripts_folder=$CurrentScriptDir
	$useful_scripts_poweshell_modules_folder="$useful_scripts_folder\modules"
	Write-Host "Loading modules from: $useful_scripts_poweshell_modules_folder ..." -foregroundColor Cyan
	if (Test-Path $useful_scripts_poweshell_modules_folder) {
		$manifests = Get-ChildItem -Path "." -Filter "*.psd1" -Recurse
		foreach ($file in $manifests) {
			Remove-Module -Name $file.BaseName -ErrorAction SilentlyContinue
    		Write-Host "Modulo $($file.BaseName) removed from session." -foregroundColor Yellow
		}
	}
	else {
		$message="Folder not found : $useful_scripts_folder"
		Write-Error $message -foregroundColor Yellow
		return @{
			Code=-1
			Value=$false
			Message=$message
		}
	}
	$script:myModulesLoaded=$true
	return @{
		Code=1
		Value=$true
		Message=$message
	}
}

$script:result = Load-MyPowerShellModules
$script:myModulesLoaded = $script:result.Value

if ($script:myModulesLoaded) {
	$script:override_function="Set-Location"
	if ($script:override_function="prompt") {
		# Global variable to save last visited path
		$Global:LastPath = ""
		function prompt {
			# Get current path
			$currentPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path

			# Check if path is changed from last time
			if ($currentPath -ne $Global:LastPath) {
				$Global:LastPath = $currentPath

				# Call to custom fuction I want to call
				# Using Try/Catch to avoid error in script will stop the prompt
				try {
					Enable-MPMVenvAndJupyterLab | Out-Null
				}
				catch {
					Write-Warning "Error while initializing promp: $_"
				}
			}

			# Definisci l'aspetto visivo del prompt (il classico PS C:\percorso>)
			#$promptString = "PS $($currentPath)$((Get-Date).ToString(' HH:mm:ss'))" # Aggiunto orario opzionale
			#Write-Host -Object $promptString -NoNewline -foregroundColor Cyan
			#return "> "
			#$promptString = "PS $($currentPath)"
			#Write-Host -Object $promptString -NoNewline
			return "PS $($currentPath)> "
		}
	} 
	else {
		# override 'cd' function (o 'Set-Location') for monitoring folder browsing
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
						# Call function to check if a python venv is present
						#Enable-PythonVirtualEnvironment | Out-Null
						# Call function to check if a jupyter is installed
						#Enable-JupyterLab | Out-Null
						Enable-MPMVenvAndJupyterLab | Out-Null
					}
					catch {
						Write-Warning "Error checking python venv or JupyterLab: $_"
					}
				}
			} catch {
				Write-Host "Folder not found $LiteralPath"
				return ${Code=-1;Value="Folder $LiteralPath not exists"}
			}
		}
	}
}