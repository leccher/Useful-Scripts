## I add my useful variable and setup PATH
$env:MY_SCRIPTS = Join-Path $env:USERPROFILE '\Scripts'

$env:PATH += ";$env:MY_SCRIPTS"

$scriptPath = Join-Path $env:MY_SCRIPTS '\lblf.ps1'
. $scriptPath
$scriptPath = Join-Path $env:MY_SCRIPTS '\pythutils.ps1'
. $scriptPath "load"
$scriptPath = Join-Path $env:MY_SCRIPTS '\wrevr.ps1'
. $scriptPath
Resolve-EnvVariableRecursive-Wrapper("PATH")

Remove-Variable -Name scriptPath

# Sovrascrive la funzione 'cd' (o 'Set-Location') per monitorare i cambiamenti di directory
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
			# Cancella la variabile di ambiente
			Remove-Item env:DISABLE_CUSTOM_FUNCTION_FOR_DIRECTORY_WALKING
		}else{
			# Chiama la funzione per monitorare il cambiamento
			Enable-PythonVirtualEnviroment-AndJupyter
		}
	} catch {
		Write-Host "Folder not found $LiteralPath"
		return ${Code=-1;Value="Folder $LiteralPath not exists"}
	}
}

Write-Host "Loaded my environment scripts"