# This script provide funtions to manage diferent installed version of python on wywtem.
# It needs that environment has some variables:
# PYTHON_HOME_version for each python installations where version should be as 3_13 
# PYTHON_HOME = %PYTHON_HOME_version%
# PATH = ...;%PYTHON_HOME%
param(
	[Parameter(Position=0)]
	[string]$Function,
	
	[Parameter(Position=1)]
	[string]$Version,
	
	[Parameter(Position=2)]
	[string]$Name
)
# This script works only with Poser SHell versions higher than or equal 7.0
# Checking if Power Shell version is higher than or equal 7.0
$_PSVersion=$PSVersionTable.PSVersion
if ($_PSVersion.Major -ge 7) {
    Write-Debug "PowerShell version is 7 or above ($_PSVersion)."
} else {
    Write-Host "PowerShell version is below 7.0 ($_PSVersion): I can't go on!"
	exit -10
}


# If call directly, the script provides some features
$available_functions=@{
	"setvenv" = "enablePythonVenv"
	"newvenv" = "createPythonVenv"
	"setversion" = "setPythonVersion"
	"load" = "justloadthscript"
}
$help_functions = @{
	"setvenv" = "Enable available python venv in this folder (.venv* folders)"
	"newvenv" = "-Version python_version -Name venv_name : to create python venv (.venv_Version_Name)"
	"setversion" = "-Version python_version: to set python version (if installed and configured in env as PYTHON_HOME_version) "
}


# This function replaces variable values in PATH environment variable
function fixPath{
	# Get PATH content
	$path = $env:PATH

	# Split pathes by ";"
	$paths = $path -split ';'
	$path=""
	# Expanding reference to other variables
	foreach ($p in $paths) {
		if ($p -ne '') { # Ignore empty values
			$expandedPath = [Environment]::ExpandEnvironmentVariables($p)
			#Write-Host $expandedPath
			if($path -ne '') {
				$path=$path+";"
			}
			$path=$path+$expandedPath
		}
	}
	$env:PATH=$path
}

# Just write enabled python version
function getCurrentPythonVersion{
	$rawVersion = python --version 2>&1 | Out-String
	$cleanVersion = ($rawVersion -replace "Python", "").Trim()
    
    Write-Host "Current python version is ${cleanVersion}"
    return $cleanVersion
}

# If python reference in environment variables are well formed, it enable the desired python version
function setPythonVersion{
	param (
		[Parameter(Mandatory=$true,Position=0)]
		[string]$Version
	)
	$cv=getCurrentPythonVersion
	if ($Version -eq $cv){
		Write-Host "$Version is already the current one"
		return 0
	}
	# Maps versions to pathes defined by other env variables
	#$pythonEnvPaths = @{
	#	"3.7" = $env:PYTHON_HOME_3_7
	#	"3.10" = $env:PYTHON_HOME_3_10
	#	"3.11" = $env:PYTHON_HOME_3_11
	#	"3.13" = $env:PYTHON_HOME_3_13
	#}
	$versions = Get-ChildItem Env: |
    Where-Object { $_.Name -like 'PYTHON_HOME*' } |
    ForEach-Object {
        $_.Name.Substring(11).TrimStart('_').Replace("_",".")
    } | Where-Object { $_ -ne '' }
	#$versions = @("3.7", "3.10", "3.11", "3.13")
	$pythonEnvPaths = @{}
	foreach ($v in $versions) {
		#Write-Host $v
		$varName = "PYTHON_HOME_" + $v.Replace(".", "_")#+"%"
		#Write-Host $varName
		# Dynamic access by PATH environment variable
		$value = [Environment]::ExpandEnvironmentVariables($varName)#$env:${varName}  # oppure: $value = $env[$varName]

		if ($value) {
			$pythonEnvPaths[$v] = $value
		}
	}
	# Check if wanted python version is mapped in environment
	if ($pythonEnvPaths.ContainsKey($Version)) {
		# Imposta PYTHON_HOME alla variabile corrispondente
		$env:PYTHON_HOME = [System.Environment]::GetEnvironmentVariable($pythonEnvPaths[$Version],"User")
		
		# Save real path value for next session
		[System.Environment]::SetEnvironmentVariable("PYTHON_HOME", [Environment]::ExpandEnvironmentVariables($pythonEnvPaths[$Version]), [System.EnvironmentVariableTarget]::User)
		
		$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
		# Expands and immediately available the new variable values
		fixPath
		Write-Host "PYTHON_HOME setted to: $env:PYTHON_HOME"
	} else {
		Write-Host "Error: Version $Version usupported."
		# Show mapped in enviroment versions
		Write-Host "Avaliable versions:"
		$pythonEnvPaths.Keys | ForEach-Object { Write-Host " - $_" }
		return -1
	}
	return 0
}

function choosePythonVenv{
	# Get folders starting with .venv in current folder
	$folders = Get-ChildItem -Directory | Where-Object { $_.Name -like ".venv*" }
	# Check if .venv folders exists
	if ($folders.Count -eq 0) {
		Write-Host "No '.venv' folder found!"
		return 0
	}

	# Show indexed list of available .venv folders
	Write-Host "Choose a venv to enable from list:"
	for ($i = 0; $i -lt $folders.Count; $i++) {
		Write-Host "$($i + 1): $($folders[$i].Name)"
	}

	# Ask user to choose one by index
	do {
		$selection = Read-Host "Choose number of '.venv':(0 to exit)"
		# Convert selection in an integer
		$selectionInt=$selection -as [int]
		# verifica che sia valida
		if ($selectionInt -eq $null){
			Write-Host "Invalid input($selection)! ..."
		}else{
			if($selectionInt -eq 0){
				exit 1
			}else{
				# Check if it is valid
				$isValid = ($selection -gt 0) -and ($selection -le $folders.Count)
				if (-not $isValid) {
					Write-Host "No valid choise, choose beetween 0 yo $($folders.Count)."
				}
			}
		}
	} until ($isValid)

	# Get selected folder
	$selectedFolder = $folders[$selection - 1]

	# Show selected folder
	Write-Host "You choose: $($selectedFolder.FullName)"
	return $selectedFolder.Name
}

# Create a venv folder using the specified python version
function createPythonVenv{
	param (
		[Parameter(Mandatory=$false,Position=0)]
		[string]$version,
		
		[Parameter(Mandatory=$false,Position=0)]
		[string]$name
	)
	# Write-Host "Version: $Version, Name: $Name"
	if(-not $Version){
		$Version=getCurrentPythonVersion
	}else{
		Write-Host "Going to set python version to ${Version} if exists:"
		$result = setPythonVersion -Version $Version
		# Check result by Code
		if ($result -ne 0) {
			Write-Host "Exit with value $result"
			exit $result
		}
		Write-Host "Python version setted up!"		
	}
	if(-not $Name){
		# Ask user the venv suffix to identify it
		$Name=$userinput = Read-Host "Give me the name of venv for ${Version}"
		if($Name -eq ""){
			Write-Host "U gave me null"
			$venvFolderName = ".venv_$Version"
		}else{
			Write-Host "U gave me ${Name}"
			$venvFolderName = ".venv_${Version}_${Name}"
		}
	}else{
		$venvFolderName = ".venv_${Version}_${Name}"
	}

	# Check if folder exists
	if (Test-Path $venvFolderName) {
		Write-Host "The venv $venvFolderName folder exists, I use it..."
	} else {
		Write-Host "The venv $venvFolderName does not exist, I will create it (waiting untill venv is created) ..."
		& python -m venv "$venvFolderName"
		Write-Host "Created $venvFolderName!"
	}
	return $venvFolderName
}

# Enable a python venv
function enablePythonVenv{
	param(
		[Parameter(Mandatory=$false,Position=0)]
		[string]$venvFolderName
	)
	if($venvFolderName -eq ""){
		$venvFolderName = choosePythonVenv
	}
	if($venvFolderName -eq 0){
		$venvFolderName =  createPythonVenv
	}
	Write-Host "Enabling $venvFolderName!"
	# Enable the venv
	& "$venvFolderName\Scripts\activate.ps1"
	Write-Host "Enabled!!!"
	Write-Host 'Use command "deactivate" to exit venv environment!'
}

# This funciton enable if exists a vevn in the current folder
function Enable-PythonVirtualEnvironment {
	if ($Env:TERM_PROGRAM -eq "vscode") {
		# This script is executed inside vscode.
		return @{Code=0;Value="Inside vscode"}
	}
	$Env:TERM_PROGRAM
    # Get current location
    $currentDir = Get-Location

    # Check if in current folder exists some .venv
	$venvFolders = Get-ChildItem -Directory | Where-Object { $_.Name -like ".venv*" }
	# If not .venv folcers, exit
	if ($venvFolders.Count -eq 0) {
		return @{Code=0;Value="No folders venv"}
	}
	# Show the list of numbered .venv folders
	Write-Host "Select which virtual environment to activate:"
	$counter = 1
	foreach ($folder in $venvFolders) {
		Write-Host "$counter. $($folder.Name)"
		$counter++
	}
	# Ask to the user to make a choise
	$selection = Read-Host "Insert virtual environment number you want activate (0 exit)"
	$selectionInt = $selection -as [int]
	# if null or 0 just exit
	if ($selectionInt -eq $null){
		Write-Host "Bye and good luck!"
		return @{Code=-2;Value="User rejected choise"}
	}
	if ($selectionInt -eq 0){
		Write-Host "Bye and good luck!"
		return @(Code=-3;Value="User rejected loading")
	}
	# Check if choise is valid
	if ($selectionInt -lt 1 -or $selectionInt -gt $venvFolders.Count) {
		Write-Host "Bye and good luck!"
		return @(Code=-4;Value="No valid choise")
	}
	# Get selected .venv folder
	$selectedVenvName = $venvFolders[$selectionInt - 1].Name
	Write-Debug $selectedVenvName
	# Enable its virtual environment
	$venvActivateScript = "${selectedVenvName}\Scripts\Activate.ps1"
	Write-Debug $venvActivateScript
	if (Test-Path $venvActivateScript) {
		Write-Host "Activating venv..."
		# Enable it
		& $venvActivateScript
		Write-Host "Activated!"
		return @{Code=$selectionInt;Value=$selectedVenvName}
	}
	return @{Code=0;Value="No folder for $selectedVenvName"}
}
# This is just a wrapeer that does not provide return
function Enable-PythonVirtualEnvironment-Wrapper {
	$result = Enable-PythonVirtualEnvironment
}

# This funciton enable if exists a kupyter in a provided vevn folder
function Enable-JupyterLab {
	param (
        [string]$venvFolder
	)
	# If inside venv a Jupiter installation, ask if user wanto to enable it
	$jupyterLabBinary = "${venvFolder}\Scripts\jupyter-lab.exe"
	if (Test-Path $jupyterLabBinary) {
		$selection = Read-Host  "Starting Jupyter lab?(y,n)"
		if($selection.StartsWith("y")){
			# Run jupyter inside this session
			& $jupyterLabBinary
			return @{Code=1;Value="Jupyter started"}
		}else{
			return @{Code=0;Value="User refused"}
		}
	}
	return @{Code=-1;Value="No jupyter binary"}
}
# This is just a wrapeer that does not provide return
function Enable-JupyterLab-Wrapper {
	param (
        [string]$venvFolder
	)
	$result = Enable-JupyterLab($venvFolder)
}
# This funciton merge actions by two functions
function Enable-PythonVirtualEnviroment-AndJupyter {
	if ($Env:TERM_PROGRAM -eq "vscode") {
		# This script is executed inside vscode.
		return
	}
	$venvEnabled = Enable-PythonVirtualEnviroment
	# If some error
	if($venvEnabled.Code -lt 0){
		return
	}
	# If no choice
	if($venvEnabled.Code -eq 0){
		return
	}
	# Try starting Jupyter
	Enable-JupyterLab($venvEnabled.Value)
}

# Create an indexed list (hashtable) using suffix of "PYTHON_HOME_" as key and name of variable as value
#$pythonEnvPaths = @{}
#Get-ChildItem Env: | Where-Object { $_.Name -like "PYTHON_HOME_*" } | ForEach-Object {
#    $key = $_.Name.Substring("PYTHON_HOME_".Length).Replace("_",".")   # Rimuove "PYTHON_HOME_" dalla parte iniziale
#	$pythonEnvPaths[$key] = $_.Name
#}
#Write-Host $pythonEnvPaths

# Get name of current command
$thisCommandName = $MyInvocation.MyCommand
function usageThisScript{
	Write-Host "Usage $thisCommandName -Function function [-Version version [-Name name]]"
	Write-Host "`tWhere function is:"
	foreach ($key in $help_functions.Keys) {
		$value = $help_functions[$key]
		Write-Host "`t${key}: $value"
	}
}

# If call directly, I have to manage some params
if(($available_functions.ContainsKey($Function))){
	switch ($Function) {
		"setversion" {
			& setPythonVersion -Version $Version
		}
		"newvenv" {
			& createPythonVenv -Version $Version -Name $Name
		}
		"setvenv" {
			& setPythonVenv -Version $Version -Name $Name
		}
		"load" {
			Write-Host "Loaded script: $($MyInvocation.MyCommand.Name)"
			exit 0
		}
		default {
			Write-Host "Unknown function: $Function"
			usageThisScript
		}
	}
}else{
	usageThisScript
}

function pythonUsefulFunctions{
	param(
		[Parameter(Position=0)]
		[string]$Function,
		
		[Parameter(Position=1)]
		[string]$Version,
		
		[Parameter(Position=2)]
		[string]$Name
	)
}