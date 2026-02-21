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
    # Write-Host "Executing as ADMINISTRATOR" -ForegroundColor Green
	return
} else {
    # Write-Host "Executing as standard user" -ForegroundColor Yellow
}

$env:MY_SCRIPTS = Join-Path $env:USERPROFILE '\Scripts'
$env:PATH += ";$env:MY_SCRIPTS"

# Useful Scripts PowerShell section
$CurrentScriptDir = Split-Path -Parent $PSCommandPath
$useful_scripts_folder=$CurrentScriptDir
$useful_scripts_poweshell_functions_folder="$useful_scripts_folder\functions"
Write-Host "Loading functions from: $useful_scripts_poweshell_functions_folder ..." -ForegroundColor Cyan
if (Test-Path $useful_scripts_poweshell_functions_folder) {
	# Get all .ps1 files in current and sub folders
	$files = Get-ChildItem -Path $useful_scripts_poweshell_functions_folder -Filter "*.ps1" -Recurse -File
	foreach ($file in $files) {
		try {
			. $file.FullName
		}
		catch {
			Write-Error "Error loading $($file.FullName): $_"
		}
	}
	Write-Host "Functions loaded!!!." -ForegroundColor Cyan
}
else {
	Write-Error "Folder not found : $$useful_scripts_folder"
}
Resolve-EnvVariableRecursive-Wrapper("PATH")

$override_function="Set-Location"
if ($override_function="prompt") {
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
				Enable-PythonVirtualEnvironment | Out-Null
				Enable-JupyterLab | Out-Null
			}
			catch {
				Write-Warning "Error while initializing promp: $_"
			}
		}

		# Definisci l'aspetto visivo del prompt (il classico PS C:\percorso>)
		#$promptString = "PS $($currentPath)$((Get-Date).ToString(' HH:mm:ss'))" # Aggiunto orario opzionale
		#Write-Host -Object $promptString -NoNewline -ForegroundColor Cyan
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
					Enable-PythonVirtualEnviroment-AndJupyter | Out-Null
				}
				catch {
					Write-Host "Erro checking python venv or JupyterLab: $_"
				}
			}
		} catch {
			Write-Host "Folder not found $LiteralPath"
			return ${Code=-1;Value="Folder $LiteralPath not exists"}
		}
	}
}